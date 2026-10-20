# Agente de Build: Sistema Customizado Gentoo (AMD A4-3300M)

Este agente descreve o escopo, arquitetura e objetivos de otimização aplicados para a geração da ISO customizada do Gentoo Linux voltada ao hardware legatário.

## 🎯 Objetivo do Sistema
Extrair 100% de performance de processamento e economia de memória RAM em um processador dual-core antigo, criando um ambiente focado em mídia, escritório e internet com interface retrô ultra-leve.

## 💻 Hardware Alvo (Target)
* **Processador:** AMD A4-3300M (2 Cores, 2 Threads, 1.9 GHz)
* **Arquitetura de Compilação:** `btver1` (Geração Llano / Bobcat de 2011)
* **Memória RAM:** 4 GB DDR3
* **Armazenamento:** SSD SATA 2.5"
* **Gráficos:** AMD Radeon HD 6480G (Drivers `radeon` / `r600`)

## 🛠️ Stack de Software Injetado
* **Base:** Gentoo Linux (Perfil Desktop, OpenRC, sem Systemd)
* **Interface Visual:** Openbox WM + FBPanel (Visual Retrô Estilo Windows 95)
* **Navegador:** Firefox-bin (Versão binária oficial para evitar estouro de timeout do GitHub)
* **Multimídia:** Kodi Media Center, VLC Player e Clementine Music Player
* **Produtividade:** Suíte LibreOffice Completa
* **Gerenciador de Pacotes Extra:** Flatpak (Para portabilidade futura)

## ⚡ Regras de Otimização Estrita
1. **Otimização de Instruções nativas:** Uso da flag `-march=btver1` para garantir que o compilador use as instruções exatas que o chip AMD A4 entende.
2. **Ignorar Bloatwares:** Desativação completa dos subsistemas GNOME, KDE e Systemd para garantir que o notebook inicie consumindo menos de 200MB de RAM.
3. **Aceleração de Hardware:** Ativação de diretivas `vaapi` e `vdpau` para aliviar o processador dual-core durante a reprodução de vídeos no VLC e Kodi.
