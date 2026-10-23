#!/usr/bin/env bash
# Publica as últimas linhas dos logs do Catalyst na branch build-logs.
#
# Motivo: os logs do GitHub Actions exigem autenticação para download, então
# sem isso não é possível diagnosticar a falha. A branch build-logs é pública.
set -uo pipefail

STEP=${1:-stage1}
WORKDIR=${GITHUB_WORKSPACE:-$PWD}

echo "workspace=${WORKDIR} step=${STEP}"
git config --global --add safe.directory "${WORKDIR}" || true

mkdir -p "${WORKDIR}/.build-logs"
OUT="${WORKDIR}/.build-logs/last-failure.log"

{
    echo "run: ${GITHUB_RUN_ID}  commit: ${GITHUB_SHA}  step: ${STEP}"
    echo "=== binpkgs disponíveis ==="
    find /var/tmp/catalyst/packages -name '*.gpkg.tar' 2>/dev/null | wc -l
    echo "=== espaço em disco ==="
    df -h / 2>/dev/null || true
    echo "=== logs do Catalyst ==="
    find /var/tmp/catalyst/logs -type f 2>/dev/null | while read -r f; do
        echo "----- ${f} (últimas 300 linhas) -----"
        tail -n 300 "$f"
    done
} > "${OUT}" 2>&1

cp /tmp/livecd-stage1.spec /tmp/livecd-stage2.spec "${WORKDIR}/.build-logs/" 2>/dev/null || true
cp /etc/catalyst/catalyst.conf "${WORKDIR}/.build-logs/catalyst.conf" 2>/dev/null || true

if ! git -C "${WORKDIR}" rev-parse --git-dir > /dev/null 2>&1; then
    echo "AVISO: ${WORKDIR} não é um repositório git; log não publicado." >&2
    echo "       Últimas linhas:" >&2
    tail -n 60 "${OUT}" >&2
    exit 0
fi

git -C "${WORKDIR}" checkout -B build-logs
git -C "${WORKDIR}" add -f .build-logs
git -C "${WORKDIR}" -c user.name="github-actions[bot]" \
    -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
    commit -m "log: falha no run ${GITHUB_RUN_ID} (${STEP})" || true
git -C "${WORKDIR}" push -f origin HEAD:build-logs
