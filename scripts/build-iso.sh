#!/usr/bin/env bash
# Gera a ISO do A4 Media OS usando Catalyst (stage3 -> stage1 -> stage2).
#
# Uso: build-iso.sh [stage1|stage2|all]     (padrão: all)
#
# O workflow roda stage1 e stage2 em JOBS SEPARADOS, cada um com o limite de
# ~6 h do runner. O stage1 completo tem 471 pacotes (~11 h num runner de
# 4 vCPU), então entre execuções o build é INCREMENTAL: os binpkgs em
# ${STOREDIR}/packages são restaurados pelo cache do GitHub e o portage só
# compila o que ainda falta (--usepkg).
set -euo pipefail

STEP=${1:-all}

REPO_ROOT=${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
VERSION_STAMP=${VERSION_STAMP:-R1}
STOREDIR=${STOREDIR:-/var/tmp/catalyst}
BUILDS="${STOREDIR}/builds/default"
PKGCACHE="${STOREDIR}/packages/default/livecd-stage1-amd64"
SNAPSHOT_REPO="${STOREDIR}/repos/gentoo.git"
SNAPSHOT_SHA_FILE="${STOREDIR}/.snapshot-sha"
STAGE1_SEED="${BUILDS}/livecd-stage1-amd64-${VERSION_STAMP}.tar.bz2"
STAGE3_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc"
STAGE1_TIMEOUT=${STAGE1_TIMEOUT:-16800}
STAGE2_TIMEOUT=${STAGE2_TIMEOUT:-2700}

mkdir -p "${BUILDS}"

binpkg_count() {
    find "${STOREDIR}/packages" -name '*.gpkg.tar' 2>/dev/null | wc -l
}

show_progress() {
    echo "    binpkgs disponíveis: $(binpkg_count)"
}

download_stage3() {
    echo "==> Baixando o stage3 OpenRC mais recente"
    local latest_index stage3_file stage3_path
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
    STAGE3_SUBPATH="default/${stage3_file%.tar.xz}"
    echo "    seed: ${STAGE3_SUBPATH}"
}

resolve_snapshot() {
    if [[ -s "${SNAPSHOT_SHA_FILE}" ]]; then
        SNAPSHOT=$(< "${SNAPSHOT_SHA_FILE}")
        echo "==> Reaproveitando snapshot: ${SNAPSHOT}"
        return
    fi
    echo "==> Criando snapshot do repositório Gentoo"
    catalyst -s stable
    SNAPSHOT=$(git -C "${SNAPSHOT_REPO}" rev-parse stable)
    printf '%s\n' "${SNAPSHOT}" > "${SNAPSHOT_SHA_FILE}"
    echo "    snapshot: ${SNAPSHOT}"

    # Mantém só o squashfs atual: snapshots antigos inchariam o cache do CI.
    find "${STOREDIR}/snapshots" -name 'gentoo-*.sqfs' \
        ! -name "gentoo-${SNAPSHOT}.sqfs" -delete 2>/dev/null || true
}

render_spec() {
    local template=$1 output=$2 escaped_root=${REPO_ROOT//&/\\&}
    sed -e "s|@WORKSPACE@|${escaped_root}|g" \
        -e "s|@VERSION_STAMP@|${VERSION_STAMP}|g" \
        -e "s|@SNAPSHOT@|${SNAPSHOT}|g" \
        -e "s|@STAGE3_SUBPATH@|${STAGE3_SUBPATH:-unused}|g" \
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
        echo "       Os binpkgs construídos ficam no cache; a próxima execução" >&2
        echo "       continua a partir deste ponto." >&2
    fi
    return ${rc}
}

stage1() {
    download_stage3
    resolve_snapshot
    show_progress
    echo "==> Catalyst: livecd-stage1 (pacotes)"
    render_spec "${REPO_ROOT}/catalyst/livecd-stage1.spec.in" /tmp/livecd-stage1.spec
    if ! run_catalyst /tmp/livecd-stage1.spec "${STAGE1_TIMEOUT}" "livecd-stage1"; then
        show_progress
        echo "ERRO: livecd-stage1 não concluiu." >&2
        exit 1
    fi
    show_progress
    ls -lh "${BUILDS}"/livecd-stage1-amd64-"${VERSION_STAMP}".tar.* || true
}

stage2() {
    if ! compgen -G "${BUILDS}/livecd-stage1-amd64-${VERSION_STAMP}.tar.*" > /dev/null; then
        echo "ERRO: não há seed do stage1 em ${BUILDS}." >&2
        echo "      Rode a etapa stage1 antes (ela é feita pelo job anterior)." >&2
        exit 1
    fi
    resolve_snapshot
    echo "==> Catalyst: livecd-stage2 (kernel + ISO)"
    render_spec "${REPO_ROOT}/catalyst/livecd-stage2.spec.in" /tmp/livecd-stage2.spec
    if ! run_catalyst /tmp/livecd-stage2.spec "${STAGE2_TIMEOUT}" "livecd-stage2"; then
        echo "ERRO: livecd-stage2 não concluiu." >&2
        exit 1
    fi
    echo "==> ISO gerada:"
    ls -lh "${BUILDS}"/gentoo-a4-media-*.iso
}

case "${STEP}" in
    stage1) stage1 ;;
    stage2) stage2 ;;
    all)    stage1; stage2 ;;
    *) echo "uso: $0 [stage1|stage2|all]" >&2; exit 2 ;;
esac
