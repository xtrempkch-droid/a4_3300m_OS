# Documentação de Arquitetura do Sistema

## 1. Decisão do Gerenciador de Janelas (Window Manager)
Foi escolhido o **Openbox** em conjunto com o **FBPanel** em substituição a ambientes tradicionais como LXQt, XFCE ou MATE. 
* **Motivo:** O Openbox renderiza apenas o contorno das janelas sem serviços adicionais rodando em segundo plano. O FBPanel fornece a barra de tarefas clássica consumindo menos de 5MB de memória RAM, mantendo a usabilidade familiar do padrão "Menu Iniciar" sem sacrificar ciclos de CPU.

## 2. Estratégia de Compilação em Nuvem (GitHub Actions)
Como o processador AMD A4-3300M levaria dias para compilar o ecossistema básico do Gentoo devido ao baixo poder de processamento, adotou-se a estratégia de **Cross-Compilation Simulada**.
* O GitHub Actions roda em instâncias modernas com múltiplos núcleos (`MAKEOPTS="-j4"`).
* O compilador em nuvem é instruído pelas flags do `make.conf` a gerar binários que não rodam no servidor do GitHub, mas sim otimizados especificamente para a arquitetura antiga do notebook alvo.

## 3. Gerenciamento de Dependências e Licenças
* **Licenciamento:** Injetou-se a liberação `*/*` em `package.license` para aceitar automaticamente os termos de firmwares proprietários de vídeo da AMD (essenciais para aceleração gráfica da Radeon HD) e da Mozilla (para o Firefox-bin).
* **Firefox-bin vs Firefox-source:** Optou-se pela versão binária pré-compilada da Mozilla para mitigar o limite de 6 horas de execução máxima do GitHub Actions.
