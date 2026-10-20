# Documentação de Arquitetura do Sistema

## 1. Alvo de hardware e flags de compilação
* **CPU:** AMD A4-3300M — família 14h (Llano), 2 núcleos, sem AVX/FMA.
* **Arquitetura GCC:** `btver1`, que habilita exatamente o conjunto de instruções
  da família 14h (MMX, SSE, SSE2, SSE3, SSSE3, SSE4A, ABM, CX16 e x86-64).
* **Vídeo:** Radeon HD 6480G (IGP Sumo, família r600/NI), driver kernel `radeon`,
  Mesa com `VIDEO_CARDS="radeon r600"`, aceleração `vaapi`/`vdpau`.
* **Firmware:** `sys-kernel/linux-firmware` fornece os blobs `radeon/SUMO_*.bin`
  necessários para o display e para a decodificação UVD.

As flags ficam em [portage/make.conf](../portage/make.conf) e são aplicadas
**apenas dentro do chroot do Catalyst**. O host de build (runner do GitHub) usa
o perfil padrão do stage3, evitando gerar ferramentas de build incompatíveis
com a CPU do runner.

## 2. Estratégia de compilação em nuvem (GitHub Actions)
O notebook não tem potência para compilar o ecossistema Gentoo. A ISO é
construída no runner com o Catalyst em três etapas encadeadas:

1. **stage3** — o `current-stage3-amd64-openrc` mais recente é baixado e
   verificado (SHA-256) para `/var/tmp/catalyst/builds/default`.
2. **snapshot** — `catalyst -s stable` cria o snapshot squashfs do repositório
   Gentoo. O SHA do commit é capturado e fixado nos dois arquivos de spec, de
   modo que stage1 e stage2 usem exatamente a mesma árvore.
3. **livecd-stage1** — instala em um chroot limpo todos os aplicativos
   (Openbox, FBPanel, SLiM, Firefox-bin, Kodi, VLC, Strawberry, LibreOffice-bin,
   Flatpak, drivers, firmware...). O `portage_confdir` aponta para
   [portage/](../portage), que contém `make.conf`, `package.use` e
   `package.accept_keywords`.
4. **livecd-stage2** — compila o kernel com `gentoo-sources` + genkernel,
   aplica o [overlay/](../overlay) (SLiM, Openbox, FBPanel, Xorg, locale),
   executa o [fsscript](../catalyst/fsscript.sh), habilita os serviços OpenRC e
   gera a ISO squashfs híbrida (BIOS + UEFI) com GRUB.

O script que orquestra tudo é [scripts/build-iso.sh](../scripts/build-iso.sh).

## 3. Interface gráfica
* **Openbox + FBPanel:** o Openbox desenha apenas as janelas; o FBPanel fornece
  a barra estilo Windows 95 e consome poucos MB de RAM.
* **SLiM + `display-manager-init`:** o SLiM faz autologin no usuário `a4` e
  executa `~/.xinitrc`, que inicia `dbus-launch` + `openbox-session`. O serviço
  OpenRC `display-manager` é habilitado pela opção `livecd/rcadd`.
* **Configuração do FBPanel:** o FBPanel lê **somente**
  `~/.config/fbpanel/default` (não existe suporte a `/etc/fbpanel`). Por isso o
  menu está em [overlay/home/a4/.config/fbpanel/default](../overlay/home/a4/.config/fbpanel/default).

## 4. Gerenciamento de dependências e licenças
* **Licenças:** `ACCEPT_LICENSE="*"` no `make.conf` libera firmwares
  proprietários da AMD e o Firefox-bin.
* **Ciclo de dependências:** o perfil desktop exige `media-libs/freetype[harfbuzz]`
  (por causa do pango) e isso cria o ciclo
  `docutils -> pillow[truetype] -> harfbuzz -> glib -> docutils`. A correção
  está em [portage/package.use/a4-target](../portage/package.use/a4-target)
  (`pillow -truetype` + `freetype harfbuzz`).
* **Firefox-bin / LibreOffice-bin:** versões pré-compiladas para reduzir o tempo
  de build e caber no limite de 6 horas do GitHub Actions.
* **Clementine -> Strawberry:** o `media-sound/clementine` foi removido do
  repositório Gentoo. O Strawberry é o fork mantido e usa a mesma biblioteca
  musical; por isso é o player instalado.
* **Perfil:** `default/linux/amd64/23.0/desktop` já é OpenRC. Não existe o
  perfil `desktop/no-systemd` utilizado na versão anterior do workflow.
