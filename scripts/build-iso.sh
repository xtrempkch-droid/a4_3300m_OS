#!/usr/bin/env bash
# Gera a ISO do A4 Media OS usando Catalyst (stage3 -> stage1 -> stage2).
set -euo pipefail

REPO_ROOT=${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
VERSION_STAMP=${VERSION_STAMP:-R1}
STOREDIR=${STOREDIR:-/var/tmp/catalyst}
BUILDS="${STOREDIR}/builds/default"
SNAPSHOT_REPO="${STOREDIR}/repos/gentoo.git"
STAGE3_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc"

mkdir -p "${BUILDS}"

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

echo "==> Catalyst: livecd-stage1 (pacotes)"
render_spec "${REPO_ROOT}/catalyst/livecd-stage1.spec.in" /tmp/livecd-stage1.spec
catalyst -f /tmp/livecd-stage1.spec

echo "==> Catalyst: livecd-stage2 (kernel + ISO)"
render_spec "${REPO_ROOT}/catalyst/livecd-stage2.spec.in" /tmp/livecd-stage2.spec
catalyst -f /tmp/livecd-stage2.spec

echo "==> ISO gerada:"
ls -lh "${BUILDS}"/gentoo-a4-media-*.iso
