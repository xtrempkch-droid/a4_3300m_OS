# Manual de Instalação e Pós-Instalação

## 💾 Passo 1: Gravando a Mídia
1. Baixe o arquivo `.iso` gerado nos artefatos do seu GitHub Actions.
2. Utilize o **Rufus** (modo DD) ou insira a ISO em um pen drive configurado com
   o **Ventoy**. A ISO é híbrida (BIOS legado + UEFI).

## 💻 Passo 2: Inicialização (Boot)
1. Conecte o pen drive no notebook AMD A4.
2. Ligue pressionando a tecla de Boot (F12, F11 ou F9, conforme a marca).
3. Selecione o pen drive (UEFI se disponível; o BIOS legado também funciona).
4. No menu do GRUB, a opção padrão inicia o sistema. O parâmetro `dokeymap`
   permite escolher o teclado ABNT2 antes da inicialização.

## 🚀 Passo 3: O Ambiente de Trabalho
O SLiM faz **autologin** no usuário `a4` (sem senha) e abre o Openbox com a
barra cinza estilo Windows 95. Para obter root use:

```bash
sudo -i
```

Menu **Iniciar**:
* **Firefox** — navegador;
* **Kodi** — central de mídia;
* **LibreOffice Writer / Calc** — escritório;
* **Strawberry** — músicas (substitui o Clementine, que saiu do Gentoo);
* **VLC** — vídeos;
* **Terminal (xterm)**;
* **Reiniciar / Desligar**.

### Rede
Com cabo, o `dhcpcd` já sobe automaticamente. Para Wi-Fi:

```bash
sudo -i
wpa_passphrase "NOME_DA_REDE" "SENHA" > /etc/wpa_supplicant/wpa_supplicant.conf
wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
dhcpcd wlan0
```

### Flatpak
```bash
flatpak remote-add --if-not-exists flathub https://flathub.org
flatpak install flathub com.spotify.Client
```

## 🔋 Recomendações de Uso no Dia a Dia
* **Abas do navegador:** evite abrir mais de 4 ou 5 abas simultaneamente; o
  processador dual-core sofre com muitos scripts paralelos.
* **uBlock Origin:** instale imediatamente no Firefox para bloquear anúncios e
  scripts pesados.
* **Aceleração de vídeo:** VLC e Kodi já usam `vaapi`/`vdpau`. Em 1080p, prefira
  o backend VDPAU (a iGPU Sumo decodifica H.264 via UVD).
* **Locale:** o sistema inicia em `pt_BR.UTF-8`, com teclado ABNT2 configurado
  no autostart do Openbox e fuso `America/Sao_Paulo`.
