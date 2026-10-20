#!/bin/bash
# Executado DENTRO do chroot do livecd pelo Catalyst (etapa livecd/fsscript).
set -e

# Grupos que podem não existir no stage3 mínimo.
for group in users wheel audio video cdrom input plugdev; do
    getent group "${group}" >/dev/null || groupadd "${group}"
done

# Usuário padrão do livecd (autologin no SLiM).
if ! id a4 >/dev/null 2>&1; then
    useradd -m -G users,wheel,audio,video,cdrom,input,plugdev -s /bin/bash a4
fi

# Locale pt-BR (o stage3 só traz C/POSIX).
if ! grep -q '^pt_BR.UTF-8' /etc/locale.gen; then
    printf '%s\n' 'pt_BR.UTF-8 UTF-8' >> /etc/locale.gen
fi
locale-gen

echo 'America/Sao_Paulo' > /etc/timezone
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# O root_overlay é copiado com o uid do runner; corrige a propriedade.
chown -R root:root /etc/slim.conf /etc/conf.d/display-manager \
    /etc/X11/xorg.conf.d /etc/xdg/openbox /etc/env.d/02locale
chown -R a4:users /home/a4
chmod 0755 /home/a4/.xinitrc

env-update
