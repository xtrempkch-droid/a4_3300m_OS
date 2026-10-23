# AGENTS.md

Memória viva do projeto, lida no início de cada turno e atualizada ao fim.

## 1. Onde estou

- Mensagem: ainda não registrado.
- Estado: projeto recém-aberto no Duck Hermes Studio.

## 2. O que estou construindo

- Objetivo: evoluir o Duck Hermes Studio em fases pequenas e verificáveis.

## 3. Ferramentas à disposição

- `read_file` (backend): Lê um arquivo de texto do workspace. Use start/end (1-based, inclusivos) para ler apenas um trecho.
- `write_file` (backend): Propõe o conteúdo completo de um arquivo. A gravação só acontece após aprovação humana no diff.
- `edit_file` (backend): Propõe a substituição de um trecho exato por outro. O trecho antigo deve aparecer uma única vez.
- `run_preview` (navegador): Recarrega o visualizador (Bloco 2) com o estado atual do editor.
- `update_agents_md` (backend): Atualiza uma seção editável do AGENTS.md (1 = onde estou, 5 = decisões recentes).
- `recall_memory` (backend): Lê o AGENTS.md atual (memória viva do projeto).
- `delegate` (backend): Despacha uma tarefa para outro modelo do celeiro (ai-talk) e devolve a resposta dele. Use prefer_role para escolher local, cloud, docker, machine ou any.
- `get_errors` (navegador): Retorna os erros atualmente exibidos no console do visualizador.

## 4. Convenções

- Código e comentários em português.
- Indentação de 2 espaços, sem ponto e vírgula opcional fora do padrão do arquivo.
- Mudanças pequenas, sempre verificadas.

## 5. Decisões recentes

- Nenhuma decisão registrada ainda.

## 6. O que NÃO fazer

- Não gravar arquivos sem aprovação no diff.
- Não executar comandos fora do runner.
- Não adicionar dependências sem necessidade.

## 7. Como me situar se eu (IA) me perder

- Leia este arquivo inteiro antes de agir.
- Use read_file para confirmar o estado real.
- Se o contexto estourar, resuma a seção 5 e continue.
