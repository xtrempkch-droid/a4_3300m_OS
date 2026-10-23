#!/usr/bin/env bash
# Prepara o container gentoo/stage3 para rodar o Catalyst.
#
# Roda como root dentro do container do job. Instala o Catalyst (e o GRUB do
# host) via binpkgs oficiais — essas ferramentas são genéricas e não precisam
# de -march=btver1, o que economiza ~15 min por execução.
set -euo pipefail

mkdir -p /etc/portage/package.accept_keywords /etc/portage/package.use
mkdir -p /etc/portage/binrepos.conf

cat > /etc/portage/binrepos.conf/gentoo.conf <<'EOF'
[gentoo]
priority = 9999
sync-uri = https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64/
verify-signature = false
EOF

emerge-webrsync

# O Catalyst só é publicado como ~amd64 no repositório oficial.
echo 'dev-util/catalyst ~amd64' > /etc/portage/package.accept_keywords/catalyst

# GRUB do host precisa gerar ISO bootável em BIOS e UEFI.
cat >> /etc/portage/make.conf <<'EOF'
GRUB_PLATFORMS="efi-32 efi-64 pc"
MAKEOPTS="-j4"
EMERGE_DEFAULT_OPTS="--jobs=2 --load-average=8"
EOF

# USE exigida por dependência do Catalyst: sem isso o emerge aborta com
# "The following USE changes are necessary to proceed".
echo '>=sys-apps/util-linux-2.42.3 python' > /etc/portage/package.use/catalyst

emerge --oneshot --getbinpkg --usepkg \
    --autounmask-write=y --autounmask-continue=y \
    dev-util/catalyst sec-keys/openpgp-keys-gentoo-release app-crypt/gnupg

# CRÍTICO: sem "jobs" o Catalyst exporta MAKEOPTS="" para o chroot e o emerge
# compila em série (-j1), estourando o tempo do runner.
# "pkgcache" garante que os binpkgs sejam gravados em /var/tmp/catalyst/packages,
# que é o caminho cacheado pelo workflow (é o que torna o build incremental).
# var_tmpfs_portage fica desligado: tmpfs num runner de 16 GB causa OOM em
# llvm/mesa/kodi.
python3 - <<'PY'
import re

path = "/etc/catalyst/catalyst.conf"
text = open(path).read()

match = re.search(r"options\s*=\s*\[(.*?)\]", text, re.S)
if match:
    body = match.group(1)
    if '"pkgcache"' not in body:
        body = body.rstrip() + '\n\t"pkgcache",\n'
    text = text[:match.start(1)] + body + text[match.end(1):]
else:
    text += '\noptions = [ "pkgcache" ]\n'

text = re.sub(r"(?m)^\s*(jobs|load-average|port_logdir)\s*=.*$", "", text)
text += '\njobs = 4\nload-average = 8.0\nport_logdir = "/var/tmp/catalyst/logs"\n'
open(path, "w").write(text)
PY

grep -q '"pkgcache"' /etc/catalyst/catalyst.conf
mkdir -p /var/tmp/catalyst/logs
echo "==> Catalyst pronto: $(catalyst --version 2>&1 | head -1)"
