# Base de dados DentalLab (`abd_lab_cd`)

A base de dados do projeto chama-se **`abd_lab_cd`** (PostgreSQL 12 ou mais recente). É a mesma para todos: no PC de cada um e no servidor da ESTGV.

## Ficheiros

| Ficheiro | O que tem |
| --- | --- |
| `sql/01_tabelas.sql` | 18 tabelas e índices |
| `sql/02_vistas.sql` | Vistas `vw_*` (a API lê sempre destas) |
| `sql/03_funcoes.sql` | Funções `fn_*` (CRUD de cada entidade, login, registo de clínica...) |
| `sql/04_procedimentos.sql` | Procedimentos `pr_*` (aceitar ordem, mudar estado, iniciar/concluir etapa...) |
| `sql/05_triggers.sql` | Triggers: auditoria, notificações, datas e validações automáticas |
| `sql/06_dados_iniciais.sql` | Cargos, estados, tipos de ficheiro e o administrador |
| `sql/07_dados_exemplo.sql` | Dados para experimentar (opcional; corre-se à parte) |
| `sql/script_completo.sql` | Os ficheiros 01 a 06 juntos, numa só transação. **Não se edita à mão**: é gerado pelo `juntar.py` |
| `sql/juntar.py` | Gera o `script_completo.sql` |
| `sql/testes/` | Testes das funções, procedimentos e triggers. Desfazem tudo no fim (`ROLLBACK`); o resultado aparece no separador **Messages** do pgAdmin |
| `modelofisico.sql`, `modeloconceptual*.plantuml` | Modelos originais (documentação; não se correm) |

## Criar a base de dados

1. No pgAdmin, criar uma base de dados vazia chamada `abd_lab_cd`.
2. No **Query Tool** dessa BD, abrir `sql/script_completo.sql` e correr tudo (F5).
3. Opcional: abrir `sql/07_dados_exemplo.sql` e correr. Cria estas contas:

   | Email | Palavra-passe | Cargo |
   | --- | --- | --- |
   | `admin@dentallab.local` | `Admin#2026` | Administrador |
   | `ana@dentallab.local` | `Admin#2026` | Colaborador |
   | `clinica.teste@dentallab.local` | `Clinica#2026` | Cliente |

## Mudar a base de dados

1. Combinar a mudança com a outra pessoa.
2. Editar o ficheiro numerado certo (`01` a `06`), nunca o `script_completo.sql`.
3. Voltar a gerar o script completo:
   ```bash
   python ModelosBaseDeDados/sql/juntar.py
   ```
4. Aplicar a mudança na tua BD:
   - **Vistas, funções e procedimentos** (`02`, `03`, `04`): basta correr de novo esse ficheiro, porque usam `CREATE OR REPLACE`.
     - Se mudares os **parâmetros** de uma função ou procedimento, faz primeiro `DROP FUNCTION` ou `DROP PROCEDURE` da versão antiga. Senão ficam duas.
     - Numa vista, as colunas novas só podem ir para o fim.
   - **Tabelas e triggers** (`01`, `05`): o mais simples é recriar a BD. Apaga-a no pgAdmin (botão direito → Delete), cria-a outra vez e corre o `script_completo.sql` (e o `07_dados_exemplo.sql`). Perdem-se os dados que lá tinhas.
5. No PR, avisar a outra pessoa do que tem de correr.
