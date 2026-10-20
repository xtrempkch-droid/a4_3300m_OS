# Manual de Instalação e Pós-Instalação

## 💾 Passo 1: Gravando a Mídia
1. Baixe o arquivo `.iso` gerado nos artefatos do seu GitHub Actions.
2. Utilize o software **Rufus** (em modo DD) ou insira a ISO em um pen drive configurado com o **Ventoy**.

## 💻 Passo 2: Inicialização (Boot)
1. Conecte o pen drive no notebook AMD A4.
2. Ligue o aparelho pressionando a tecla de Boot (geralmente F12, F11 ou F9 dependendo da marca do notebook).
3. Selecione a opção correspondente ao seu pen drive (Dê preferência para o modo **UEFI** se disponível).

## 🚀 Passo 3: O Ambiente de Trabalho
Ao carregar o sistema, a barra cinza clássica estilo Windows 95 aparecerá na parte inferior.
* Clique no botão **Iniciar** para abrir o Firefox, LibreOffice, Kodi, VLC ou Clementine.
* Caso queira instalar novos aplicativos do mundo moderno (como Spotify, Discord, etc.), abra o **Terminal** e utilize o Flatpak:
  ```bash
  flatpak remote-add --if-not-exists flathub https://flathub.org
  flatpak install flathub com.spotify.Client
  ```

## 🔋 Recomendações de Uso no Dia a Dia
* **Abas do Navegador:** Evite abrir mais de 4 ou 5 abas simultaneamente no Firefox. O processador dual-core sofrerá com excesso de scripts paralelos.
* **Extensões Recomendadas:** Instale imediatamente a extensão **uBlock Origin** no Firefox para bloquear anúncios e scripts pesados das páginas da web, poupando processamento.
