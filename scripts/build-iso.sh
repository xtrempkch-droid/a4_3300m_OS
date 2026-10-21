#!/usr/bin/env bash
# Gera a ISO do A4 Media OS usando Catalyst (stage3 -> stage1 -> stage2).
#
# O build é INCREMENTAL entre execuções do GitHub Actions: os binpkgs ficam em
# ${STOREDIR}/packages e são restaurados/salvos pelo cache do workflow. Se uma
# etapa estourar o tempo, o cache é salvo e a próxima execução continua de onde
# parou (portage reaproveita os .gpkg.tar com --usepkg).
set -euo pipefail

REPO_ROOT=${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
VERSION_STAMP=${VERSION_STAMP:-R1}
STOREDIR=${STOREDIR:-/var/tmp/catalyst}
BUILDS="${STOREDIR}/builds/default"
PKGCACHE="${STOREDIR}/packages/default/livecd-stage1-amd64-${VERSION_STAMP}"
SNAPSHOT_REPO="${STOREDIR}/repos/gentoo.git"
STAGE3_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc"
STAGE1_TIMEOUT=${STAGE1_TIMEOUT:-15600}
STAGE2_TIMEOUT=${STAGE2_TIMEOUT:-2700}
LOG_DIR="${STOREDIR}/logs"

mkdir -p "${BUILDS}" "${LOG_DIR}"

show_progress() {
    local pkgs=0
    if [[ -d "${PKGCACHE}" ]]; then
        pkgs=$(find "${PKGCACHE}" -name '*.gpkg.tar' 2>/dev/null | wc -l)
    fi
    echo "    binpkgs já construídos: ${pkgs}"
}

echo "==> Baixando o stage3 OpenRC mais recente"
latest_index=$(curl -fsSL --retry 5 --retry-delay 5 "${STAGE3_URL}/latest-stage3-amd64-openrc.txt")
stage3_file=$(awk '/^stage3-amd64-openrc-[0-9]+T[0-9]+Z\.tar\.xz/ {print $1; exit}' <<< "${latest_index}")
if [[ -z "${stage3_file}" ]]; then
    echo "ERRO: não foi possível descobrir o stage3 mais recente" >&2
    exit 1
fi
stage3_path="${BUILDS}/${stage3_file}"
if [[ ! -f "${stage3_path}" ]]; then
    curl -fL --retry 5 --retry-delay 5 -o "${stage3_path}" "${STAGE3_URL}/${stage3_file}"
    curl -fsSL --retry 5 -o "${stage3_path}.sha256" "${STAGE3_URL}/${stage3_file}.sha256"
    (cd "${BUILDS}" && sha256sum -c "${stage3_file}.sha256")
fi
stage3_subpath="default/${stage3_file%.tar.xz}"
echo "    seed: ${stage3_subpath}"

echo "==> Criando snapshot do repositório Gentoo"
catalyst -s stable
snapshot=$(git -C "${SNAPSHOT_REPO}" rev-parse stable)
echo "    snapshot: ${snapshot}"

render_spec() {
    local template=$1 output=$2 escaped_root=${REPO_ROOT//&/\\&}
    sed -e "s|@WORKSPACE@|${escaped_root}|g" \
        -e "s|@VERSION_STAMP@|${VERSION_STAMP}|g" \
        -e "s|@SNAPSHOT@|${snapshot}|g" \
        -e "s|@STAGE3_SUBPATH@|${stage3_subpath}|g" \
        "${template}" > "${output}"
}

# Executa o Catalyst com limite de tempo. Sai com 0 em sucesso, 124 em timeout.
run_catalyst() {
    local spec=$1 limit=$2 label=$3 rc=0
    set +e
    timeout -k 120 "${limit}" catalyst -f "${spec}"
    rc=$?
    set -e
    if [[ ${rc} -eq 124 || ${rc} -eq 137 ]]; then
        echo "AVISO: ${label} excedeu $((limit / 60)) min e foi interrompido." >&2
        echo "       Os binpkgs construídos foram salvos no cache; a próxima" >&2
        echo "       execução continua a partir deste ponto." >&2
    fi
    return ${rc}
}

show_progress

echo "==> Catalyst: livecd-stage1 (pacotes)"
render_spec "${REPO_ROOT}/catalyst/livecd-stage1.spec.in" /tmp/livecd-stage1.spec
if ! run_catalyst /tmp/livecd-stage1.spec "${STAGE1_TIMEOUT}" "livecd-stage1"; then
    show_progress
    echo "ERRO: livecd-stage1 não concluiu (veja ${LOG_DIR})." >&2
    exit 1
fi
show_progress

echo "==> Catalyst: livecd-stage2 (kernel + ISO)"
render_spec "${REPO_ROOT}/catalyst/livecd-stage2.spec.in" /tmp/livecd-stage2.spec
if ! run_catalyst /tmp/livecd-stage2.spec "${STAGE2_TIMEOUT}" "livecd-stage2"; then
    echo "ERRO: livecd-stage2 não concluiu (veja ${LOG_DIR})." >&2
    exit 1
fi

echo "==> ISO gerada:"
ls -lh "${BUILDS}"/gentoo-a4-media-*.iso
