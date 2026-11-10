# Guia do backend DentalLab

Este guia é para as duas pessoas que fazem o backend e para as AI que cada uma usa.
Explica como o backend funciona, as regras que os dois seguem e quem faz o quê.

> **Se és uma AI:** lê este ficheiro todo antes de escrever código. Depois lê os ficheiros de `backend/src/`,
> sobretudo [`src/rotas/cargos.ts`](src/rotas/cargos.ts), que é o modelo a copiar.
> Segue as [regras](#4-regras-para-pessoas-e-para-a-ai) à letra. Se uma tarefa te obrigar a quebrar uma regra, pára e pergunta.

---

## 1. O projeto

O DentalLab é o sistema de gestão do Laboratório de Prótese Dentária Catarina Domingos (Projeto Integrado IV, ESTGV).

**Quem usa o sistema** (tabela `cargo`):

| Cargo | Quem é | O que faz |
| --- | --- | --- |
| Administrador | O laboratório | Gere tudo: clínicas, contas, catálogo, encomendas |
| Colaborador | Técnico do laboratório | Executa as etapas de produção dos trabalhos |
| Cliente | Uma clínica dentária | Faz encomendas e acompanha o estado |

**Quem fala com o backend:**

- **React:** o backoffice e o site, em `frontend/`
- **Flutter:** a app mobile, em `app_mobile/`

Os dois usam **a mesma API**. Fazem os mesmos pedidos HTTP com JSON e recebem as mesmas respostas.

**O caminho de uma encomenda:**
1. A clínica cria uma **ordem de trabalho**. Uma ordem é um paciente com um ou mais **trabalhos**.
2. O laboratório aceita ou rejeita a ordem e define o prazo de entrega.
3. Cada trabalho tem um **tipo** (ex.: Coroa), e o tipo tem uma lista ordenada de **etapas** (ex.: Gesso, CAD/CAM, Acabamento).
4. Ao criar o trabalho, essas etapas são copiadas para ele (`etapa_trabalho`).
5. Os colaboradores executam as etapas uma a uma, pela ordem.

---

## 2. Como funciona o backend

```text
React / Flutter  ──HTTP + JSON──▶  API (Node.js + Fastify)  ──SQL──▶  PostgreSQL
                                     │                                 │
                                     │  ler:     SELECT * FROM vw_...  │  vistas  vw_*
                                     │  escrever: SELECT fn_..._crud() │  funções fn_*
                                     │                                 │  tabelas (a API nunca lhes toca)
```

- A **base de dados** tem a lógica: tabelas, vistas `vw_*` e funções `fn_*`. Cria-se no **pgAdmin**, a partir dos ficheiros SQL de [`ModelosBaseDeDados/`](../ModelosBaseDeDados/).
- A **API** é fina. Recebe o pedido, verifica quem é o utilizador, chama uma vista ou uma função e devolve o resultado em JSON.
- As **validações dos dados** (campos obrigatórios, duplicados, regras de negócio) estão nas funções da BD, que usam `RAISE EXCEPTION 'mensagem em português'`. A API devolve essa mensagem ao frontend sem a alterar.

**Ferramentas:**

| Ferramenta | Para quê |
| --- | --- |
| Node.js 22+ e TypeScript | Linguagem da API. O `tsx` corre o TypeScript sem compilar |
| Fastify | Servidor web: rotas, pedidos, respostas |
| `pg` (node-postgres) | Ligação ao PostgreSQL |
| PostgreSQL 18 + pgAdmin 4 | Base de dados (local) |
| REST Client (extensão do VS Code) | Testar as rotas com os ficheiros `pedidos/*.http` |

**Não usamos:** ORM (Sequelize, Prisma, TypeORM…), migrações, Docker, Express.

**Organização das pastas:**

```text
ModelosBaseDeDados/
  modelofisico.sql      tabelas e dados iniciais
  crud/                 vistas e funções, um ficheiro por entidade
backend/
  .env.example          modelo do ficheiro .env (o .env tem a palavra-passe e não vai para o Git)
  src/
    server.ts           cria o servidor, trata os erros, regista as rotas e arranca
    config.ts           lê o .env
    db.ts               ligação à BD (bd.query)
    rotas/              um ficheiro por entidade (cargos.ts, ...)
  pedidos/              pedidos de teste .http, um ficheiro por entidade
```

---

## 3. Preparar o computador

1. Instalar o **PostgreSQL 18**, que já traz o pgAdmin 4, e o **Node.js 22** ou mais recente.
2. `git pull` do ramo `backend`.
3. No pgAdmin, criar a base de dados `dentallab`. No **Query Tool** dessa BD, correr por esta ordem:
   1. `ModelosBaseDeDados/modelofisico.sql`
   2. os ficheiros de `ModelosBaseDeDados/alteracoes/`, por ordem de número (cada um só uma vez)
   3. todos os ficheiros de `ModelosBaseDeDados/crud/`
4. Em `backend/`, copiar `.env.example` para `.env` e pôr em `DB_PASSWORD` a palavra-passe do PostgreSQL.
5. No terminal, dentro de `backend/`, correr `npm install` e depois `npm run dev`.
6. Abrir http://localhost:3000/api/health. Deve aparecer `{"api":"ok","bd":"ok"}`.
7. No VS Code, instalar a extensão **REST Client** (autor: Huachao Mao) e experimentar [`pedidos/cargos.http`](pedidos/cargos.http).

O `modelofisico.sql` cria uma conta de administrador: `admin@dentallab.local`, com a palavra-passe `Admin#2026`.

---

## 4. Regras (para pessoas e para a AI)

### Simplicidade
1. **O código é para estudantes perceberem.**
   - Nada de camadas (controller/service/repository), classes, genéricos de TypeScript ou "boas práticas" de empresa.
   - Cada rota lê-se de cima a baixo.
2. **O padrão é o de [`src/rotas/cargos.ts`](src/rotas/cargos.ts).** Cada entidade tem um ficheiro de rotas igual a esse.
3. **Pacotes novos só com acordo das duas pessoas.** Os que já estão previstos estão indicados em cada tarefa.
4. **Os comentários são curtos e em português** e explicam o que o código faz.

### Base de dados
5. **A API nunca faz `INSERT`, `UPDATE`, `DELETE` nem `SELECT` às tabelas.**
   - Lê sempre de uma vista: `SELECT * FROM vw_...`.
   - Escreve sempre através de uma função: `SELECT fn_..._crud(...)`.
   - Se falta uma vista ou uma função, cria-se primeiro na BD.
6. **Quem decide o quê:**

   | O quê | Onde | Exemplos |
   | --- | --- | --- |
   | O que é válido nos dados | Funções da BD, com `RAISE EXCEPTION` | Campos obrigatórios, duplicados, sequência das etapas, transições de estado |
   | Quem pode fazer cada ação | API, com `exigirCargo(...)` | Ver o cargo do utilizador; confirmar que a ordem é da clínica de quem pede |

7. **Uma ação que mexe em várias tabelas é uma só função na BD.** Ex.: registar uma clínica cria o cliente e o utilizador. Assim, ou corre tudo ou não fica nada. A API não faz várias escritas seguidas.
8. **As mensagens de `RAISE EXCEPTION` são para o utilizador final.** Escrevem-se em português, claras e sem termos técnicos: `'Tem de indicar o prazo de entrega'`.
9. **Todo o SQL fica num ficheiro do repositório.** O que se cria no pgAdmin vive só na BD local de quem o criou.
   - Vistas e funções de uma entidade ficam em `ModelosBaseDeDados/crud/crud_<entidade>.sql` e usam `CREATE OR REPLACE`.
   - Para mudar uma vista ou função, edita-se o ficheiro, volta-se a correr no pgAdmin e avisa-se a outra pessoa.
   - **Criar ou alterar tabelas** (`CREATE TABLE`, `ALTER TABLE`) só depois de combinar com a outra pessoa. O SQL vai para um ficheiro numerado em `ModelosBaseDeDados/alteracoes/`, com o número seguinte ao último que lá estiver (ex.: `002_trabalho_observacoes.sql`). Ver o `001_alteracao_cliente.sql` como exemplo.
10. **Cuidados com o `CREATE OR REPLACE`:**
    - Se mudares os **parâmetros** de uma função, primeiro faz `DROP FUNCTION fn_x(tipos...)`. Senão o PostgreSQL cria uma segunda função com o mesmo nome e as chamadas deixam de funcionar.
    - Numa **vista** só podes acrescentar colunas **no fim**. Para tirar ou reordenar colunas, faz `DROP VIEW` e cria-a outra vez.

### API
11. **Os valores vão sempre em `$1, $2…`.** Nunca se colam no texto do SQL, porque isso permite SQL injection.
12. **Funções com mais de 3 parâmetros chamam-se com nomes**, que é mais claro e permite saltar os opcionais. Ver a [receita](#52-ficheiro-de-rotas).
13. **Os campos do JSON têm os nomes das colunas da BD**, em snake_case e sem o `p_`. Isto vale para os pedidos e para as respostas.
    - Ex.: `{ "nome_medico_responsavel": "Dr. Silva", "prazo_entrega": "2026-11-20" }`.
    - Assim não há código para converter nomes.
14. **Rotas:**
    - começam por `/api/` e usam o plural em português com hífens: `/api/tipos-trabalho`, `/api/estados-ordem`;
    - os sub-recursos ficam debaixo do recurso pai: `/api/ordens/:id/trabalhos`;
    - as ações que não são CRUD usam `POST` com um verbo: `POST /api/ordens/:id/aceitar`.
15. **Respostas:**

    | Situação | Código | Corpo |
    | --- | --- | --- |
    | Lista | 200 | `[ {...}, {...} ]` |
    | Um registo | 200 | `{...}` |
    | Criado | 201 | `{ "id": 5 }` |
    | Alterado, apagado ou ação | 200 | `{ "id": 5 }` |
    | Erro de dados (`RAISE EXCEPTION`) | 400 | `{ "erro": "mensagem" }` (é automático) |
    | Sem login | 401 | `{ "erro": "..." }` (é automático) |
    | Cargo sem permissão | 403 | `{ "erro": "..." }` (é automático) |
    | Registo não existe, ou não é seu | 404 | `{ "erro": "..." }` |

    - As datas sem hora vêm como `"2026-11-20"`; as datas com hora vêm em ISO: `"2026-11-04T10:30:00.000Z"`.
    - Os ids vêm como números.
16. **Uma clínica (cargo Cliente) só vê e mexe no que é dela.**
    - Usa-se o `cliente_id` de quem fez login.
    - Se o registo for de outra clínica, a resposta é 404: não se revela que existe.
    - A clínica **nunca** vê o que é interno do laboratório: etapas, e comentários ou ficheiros associados a um trabalho.

### Antes de dar uma tarefa como feita
17. `npm run typecheck` corre sem erros.
18. Cada rota foi testada no ficheiro `pedidos/<entidade>.http`, incluindo os casos de erro. O terminal da API não mostra nenhum `ERROR` (erro 500).
19. O SQL novo está em `ModelosBaseDeDados/` e as rotas novas estão na tabela de rotas do [README](README.md).

---

## 5. Receitas

### 5.1 Vista e função CRUD na BD

Segue o padrão dos ficheiros de `ModelosBaseDeDados/crud/`. A função recebe a operação, o id e os campos, e devolve o id do registo afetado.

```sql
-- ModelosBaseDeDados/crud/crud_etapa.sql

CREATE OR REPLACE VIEW vw_etapa AS
SELECT e.id, e.nome, e.descricao, e.ativa
FROM etapa e;

-- CREATE, UPDATE e DELETE; devolve o id do registo afetado.
-- Em UPDATE, os parâmetros a NULL mantêm o valor atual.
-- DELETE desativa a etapa (ativa = FALSE).
CREATE OR REPLACE FUNCTION public.fn_etapa_crud(
    p_operacao  character varying,
    p_id        bigint,
    p_nome      character varying DEFAULT NULL,
    p_descricao text              DEFAULT NULL,
    p_ativa     boolean           DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_operacao character varying := upper(p_operacao);
    v_id       bigint;
    n          integer;
BEGIN
    IF v_operacao IN ('UPDATE', 'DELETE') THEN
        SELECT count(*) INTO n FROM etapa WHERE id = p_id;
        IF n = 0 THEN
            RAISE EXCEPTION 'A etapa % não existe', p_id;
        END IF;
    END IF;

    IF v_operacao = 'CREATE' THEN
        IF p_nome IS NULL OR trim(p_nome) = '' THEN
            RAISE EXCEPTION 'Tem de indicar o nome da etapa';
        END IF;
        INSERT INTO etapa(nome, descricao) VALUES (p_nome, p_descricao)
        RETURNING id INTO v_id;

    ELSIF v_operacao = 'UPDATE' THEN
        UPDATE etapa
        SET nome      = COALESCE(p_nome, nome),
            descricao = COALESCE(p_descricao, descricao),
            ativa     = COALESCE(p_ativa, ativa)
        WHERE id = p_id;
        v_id := p_id;

    ELSIF v_operacao = 'DELETE' THEN
        UPDATE etapa SET ativa = FALSE WHERE id = p_id;
        v_id := p_id;

    ELSE
        RAISE EXCEPTION 'Operação inválida: % (use CREATE, UPDATE ou DELETE)', p_operacao;
    END IF;

    RETURN v_id;
END;
$BODY$;
```

Para testar no Query Tool antes de passar à API:

```sql
SELECT fn_etapa_crud('CREATE', NULL, 'Gesso');
SELECT * FROM vw_etapa;
```

**Apagar:**
- Os registos com histórico não se apagam. Desativam-se com `ativo`/`ativa = FALSE`, ou marcam-se com `eliminado_em = now()`, conforme a coluna que a tabela tiver.
- As vistas de dados com `eliminado_em` escondem os eliminados (`WHERE eliminado_em IS NULL`).

### 5.2 Ficheiro de rotas

Cria-se copiando [`src/rotas/cargos.ts`](src/rotas/cargos.ts). Este é um exemplo com uma função de vários parâmetros, chamada com nomes:

```ts
import type { FastifyInstance } from 'fastify';
import { bd } from '../db.ts';

// Rotas dos tipos de trabalho (Coroa, Ponte, ...).
// Ler: vista vw_tipo_trabalho. Criar, alterar e apagar: função fn_tipo_trabalho_crud.

// O que o frontend envia no corpo do pedido (POST e PUT)
interface DadosTipoTrabalho {
  nome?: string;
  descricao?: string;
  ativo?: boolean;
}

export async function rotasTiposTrabalho(app: FastifyInstance) {
  // GET /api/tipos-trabalho: lista os tipos de trabalho
  app.get('/api/tipos-trabalho', async () => {
    const resultado = await bd.query('SELECT * FROM vw_tipo_trabalho ORDER BY nome');
    return resultado.rows;
  });

  // POST /api/tipos-trabalho com { "nome": "Coroa", "descricao": "..." }: cria um tipo de trabalho
  app.post('/api/tipos-trabalho', async (request, reply) => {
    const dados = request.body as DadosTipoTrabalho | undefined;
    const resultado = await bd.query(
      `SELECT fn_tipo_trabalho_crud(
         p_operacao  => 'CREATE',
         p_id        => NULL,
         p_nome      => $1,
         p_descricao => $2
       ) AS id`,
      [dados?.nome, dados?.descricao],
    );
    return reply.code(201).send(resultado.rows[0]);
  });

  // ... GET /:id, PUT /:id e DELETE /:id como em cargos.ts
}
```

Depois regista-se o ficheiro em [`src/server.ts`](src/server.ts), com duas linhas:

```ts
import { rotasTiposTrabalho } from './rotas/tipos-trabalho.ts';   // em cima, com os outros imports
app.register(rotasTiposTrabalho);                                  // junto aos outros app.register
```

**Arrays:** um array de JavaScript passa-se diretamente. Ex.: `[dados?.dentes]` com `dentes: [11, 12]` chega à BD como `smallint[]`.

**Limitação conhecida:** com o `COALESCE` das funções, um `PUT` não consegue pôr um campo a `NULL`. Um campo enviado a `null` mantém o valor que tinha.

### 5.3 Proteger uma rota com login

O login vem com a tarefa **A1**. Até ela estar no ramo `backend`, deixa as rotas sem proteção, com um comentário `// PROTEGER: Administrador`. Quando estiver pronta, acrescenta o `preHandler`:

```ts
import { exigirCargo, exigirLogin } from '../autenticacao.ts';

// Qualquer pessoa com login
app.get('/api/tipos-trabalho', { preHandler: exigirLogin }, async () => { ... });

// Só alguns cargos (responde 401 sem login e 403 com outro cargo)
app.post('/api/tipos-trabalho', { preHandler: exigirCargo('Administrador') }, async (request, reply) => { ... });
app.post('/api/ordens/:id/aceitar', { preHandler: exigirCargo('Administrador', 'Colaborador') }, async (request) => { ... });
```

Dentro de uma rota protegida, `request.user` é quem fez login. Os dados vêm da BD em cada pedido: se o Administrador mudar o cargo de alguém, conta logo o novo; se desativar a conta, o pedido dá 401.

```ts
request.user.id          // id do utilizador (para criado_por, responsavel_id, ...)
request.user.nome
request.user.cargo       // 'Administrador' | 'Colaborador' | 'Cliente'
request.user.cliente_id  // id da clínica, se o cargo for Cliente; null nos outros cargos
```

Os ids de quem faz a ação (`criado_por`, `aceite_por`, `responsavel_id`, `utilizador_id`, `carregado_por`) **vêm sempre de `request.user.id`**, nunca do corpo do pedido.

O React e o Flutter enviam o token recebido no login em cada pedido:

```http
Authorization: Bearer <token>
```

### 5.4 Ficheiro de testes `.http`

Copia [`pedidos/cargos.http`](pedidos/cargos.http). Para rotas protegidas, faz primeiro o login. O REST Client guarda sozinho o token da resposta (ver [`pedidos/auth.http`](pedidos/auth.http)):

```http
@api = http://localhost:3000/api
@token = {{login.response.body.$.token}}

### Login (faz este pedido primeiro; o token fica guardado em {{token}})
# @name login
POST {{api}}/auth/login
Content-Type: application/json

{ "email": "admin@dentallab.local", "password": "Admin#2026" }

### Criar um tipo de trabalho
POST {{api}}/tipos-trabalho
Authorization: Bearer {{token}}
Content-Type: application/json

{ "nome": "Coroa" }
```

---

## 6. Divisão de tarefas

Há duas pessoas:
- **Pessoa A (Joel):** autenticação, contas e comunicação;
- **Pessoa B (colega):** catálogo, encomendas e produção.

Trabalham em paralelo, por fases. Cada fase só começa quando a anterior das duas pessoas estiver no ramo `backend`.

| Fase | Pessoa A (Joel) | Pessoa B (colega) |
| --- | --- | --- |
| 1 | **A1** Login e permissões; **A2** Ligar o React e o Flutter | **B1** Catálogo: estados de ordem, tipos de trabalho, etapas e etapas de cada tipo |
| 2 | **A3** Clientes e utilizadores (registo de clínica e aprovação) | **B2** Ordens de trabalho, trabalhos e material recebido |
| 3 | **A4** Comentários, ficheiros e notificações | **B3** Produção: execução das etapas dos trabalhos |

**Dependências:**
- O B1 não precisa de login. As rotas protegem-se no fim da fase 1, quando o A1 estiver pronto.
- O B2 precisa do A1, por causa do `request.user`.
- Para testar o B2 antes do A3 estar pronto, cria uma clínica no Query Tool: `SELECT fn_cliente_crud('CREATE', NULL, 'Clínica Teste', '123456789');`.
- O B3 precisa do B2.
- O A4 precisa do B2, porque os comentários e ficheiros pertencem a ordens e trabalhos.

### Ficheiros de cada pessoa

Cada pessoa só mexe nos seus ficheiros. Assim não há conflitos no Git.

| Pessoa A | Pessoa B |
| --- | --- |
| `src/server.ts`, `src/config.ts`, `src/db.ts`, `src/autenticacao.ts` | — |
| `rotas/cargos.ts`, `auth.ts`, `clientes.ts`, `utilizadores.ts`, `comentarios.ts`, `ficheiros.ts`, `notificacoes.ts` | `rotas/estados-ordem.ts`, `tipos-trabalho.ts`, `etapas.ts`, `ordens.ts`, `trabalhos.ts`, `materiais.ts`, `producao.ts` |
| `crud/crud_cargo_utilizador.sql`, `crud_cliente*.sql`, `crud_comentario.sql`, `crud_ficheiro.sql`, `crud_notificacao.sql` | `crud/crud_estado_ordem_ordem_trabalho.sql`, `crud_tipo_trabalho_trabalho.sql`, `crud_etapa*.sql`, `crud_material_recebido.sql`, `crud_producao.sql` |

**Exceções:**
- A Pessoa B pode acrescentar, no `server.ts`, só as linhas de `import` e de `app.register(...)` das suas rotas.
- Em `src/erros.ts`, qualquer pessoa pode acrescentar mensagens à lista `mensagensRegras`. A lista tem a mensagem em português de cada regra `CHECK` ou `UNIQUE` das tabelas, pelo nome da regra. Quem criar uma regra nova numa tabela acrescenta lá a sua mensagem.
- A tabela de rotas do README é dos dois. Cada pessoa acrescenta as suas linhas.
- O `crud_cliente_etapa_trabalho.sql` tem uma parte de cada pessoa: a parte de `cliente` é da A e a de `etapa_trabalho` é da B. Quem lhe mexer avisa o outro.

---

### Tarefas da Pessoa B (colega)

#### B1 — Catálogo (fase 1)

Isto é o que o Administrador configura antes de haver encomendas.

**Na BD:**
- `vw_estado_ordem`, `fn_estado_ordem_crud`, `vw_tipo_trabalho` e `fn_tipo_trabalho_crud` **já existem**.
- Criar `vw_etapa` e `fn_etapa_crud` em `crud/crud_etapa.sql`. A [receita 5.1](#51-vista-e-função-crud-na-bd) é exatamente esta. Atenção: a coluna chama-se `ativa`, não `ativo`.
- Criar, em `crud/crud_etapa_tipo_trabalho.sql`:
  - `vw_etapa_tipo_trabalho`, com `tipo_trabalho_id`, `ordem`, `etapa_id` e o nome da etapa, ordenada por `ordem`.
  - `fn_definir_etapas_tipo_trabalho(p_tipo_trabalho_id bigint, p_etapas bigint[]) RETURNS bigint`:
    - substitui a lista inteira, apagando as linhas desse tipo e inserindo `p_etapas` pela ordem do array (ordem 1, 2, 3…);
    - valida que o tipo existe e que todas as etapas existem e estão ativas;
    - a mesma etapa pode repetir-se (ex.: duas provas);
    - devolve o id do tipo.
    - O `modelofisico.sql` explica que esta tabela é configuração: pode apagar-se e voltar a inserir. Os trabalhos já criados não são afetados, porque têm a sua própria cópia das etapas.

**Rotas:**

| Rota | Quem | O que faz |
| --- | --- | --- |
| `GET /api/estados-ordem` | Login | Lista os estados |
| `GET /api/tipos-trabalho` e `GET /api/tipos-trabalho/:id` | Login | Lista e mostra |
| `POST`, `PUT /:id`, `DELETE /:id` em `/api/tipos-trabalho` | Administrador | CRUD (o `DELETE` desativa) |
| `GET /api/etapas` e `GET /api/etapas/:id` | Login | Lista e mostra |
| `POST`, `PUT /:id`, `DELETE /:id` em `/api/etapas` | Administrador | CRUD (o `DELETE` desativa) |
| `GET /api/tipos-trabalho/:id/etapas` | Login | Etapas do tipo, por ordem |
| `PUT /api/tipos-trabalho/:id/etapas` com `{ "etapas": [3, 1, 5] }` | Administrador | Substitui a lista de etapas |

**Ficheiros:**
- `rotas/estados-ordem.ts`, `rotas/tipos-trabalho.ts` e `rotas/etapas.ts`;
- `pedidos/estados-ordem.http`, `pedidos/tipos-trabalho.http` e `pedidos/etapas.http`.

#### B2 — Ordens de trabalho, trabalhos e material recebido (fase 2)

**Na BD:**
- `vw_ordem_trabalho`, `fn_ordem_trabalho_crud`, `vw_trabalho` e `fn_trabalho_crud` **já existem**.
  - O `fn_trabalho_crud`, ao criar um trabalho, já copia as etapas do tipo e grava os dentes.
- Acrescentar **no fim** da `vw_ordem_trabalho` as colunas `o.cliente_id`, `o.estado_ordem_id` e `o.criado_por AS criado_por_id`. Fica em `crud/crud_estado_ordem_ordem_trabalho.sql`.
  - Sem o `cliente_id` não é possível mostrar a cada clínica só as suas ordens.
- Criar uma função para as **mudanças de estado** da ordem, por exemplo `fn_ordem_trabalho_estado(p_id, p_estado, p_utilizador_id, p_motivo, p_prazo_entrega)`. Deve validar as transições:
  - `Em avaliação` passa a `Por iniciar` (aceitar: precisa do prazo, e preenche `aceite_por` e `data_aceitacao`) ou a `Rejeitado` (precisa de `motivo_rejeicao`);
  - `Por iniciar` passa a `Em processamento`, que preenche `data_inicio`;
  - `Em processamento`, `Em espera` (precisa de `motivo_espera`) e `Em prova` podem passar uns para os outros;
  - `Em processamento` passa a `Concluído`, que preenche `data_conclusao`;
  - `Concluído` passa a `Entregue`, que preenche `data_entrega`;
  - qualquer outra mudança dá `RAISE EXCEPTION`.
  - Se o grupo combinar outras transições, muda-se só esta função.
- Criar `vw_material_recebido` e `fn_material_recebido_crud` em `crud/crud_material_recebido.sql`.
  - "Marcar como recebido" preenche `data_rececao`.
  - O `DELETE` preenche `eliminado_em`.

**Rotas:**

| Rota | Quem | O que faz |
| --- | --- | --- |
| `GET /api/ordens` | Login | Lab: todas. Cliente: só as da sua clínica |
| `GET /api/ordens/:id` | Login | Uma ordem (Cliente: só se for sua, senão 404) |
| `POST /api/ordens` | Cliente, Administrador | Cria. Cliente: `cliente_id` = o seu. Admin: indica o `cliente_id`. `criado_por` = `request.user.id` |
| `PUT /api/ordens/:id` | Cliente, Administrador | Altera os dados (Cliente: só a sua e só em `Em avaliação`) |
| `DELETE /api/ordens/:id` | Administrador | Eliminação lógica |
| `POST /api/ordens/:id/aceitar` com `{ "prazo_entrega": "2026-11-20" }` | Administrador, Colaborador | Aceita |
| `POST /api/ordens/:id/rejeitar` com `{ "motivo_rejeicao": "..." }` | Administrador, Colaborador | Rejeita |
| `POST /api/ordens/:id/estado` com `{ "estado": "Em espera", "motivo_espera": "..." }` | Administrador, Colaborador | Muda o estado |
| `GET /api/ordens/:id/trabalhos` | Login | Trabalhos da ordem (Cliente: só se a ordem for sua) |
| `POST /api/ordens/:id/trabalhos` com `{ "tipo_trabalho_id": 1, "natureza": "FISICO", "cor": "A2", "dentes": [11, 12] }` | Cliente, Administrador | Cria um trabalho |
| `GET /api/trabalhos/:id`, `PUT /api/trabalhos/:id`, `DELETE /api/trabalhos/:id` | Login / Cliente, Admin / Admin | Mostra, altera e elimina |
| `GET`, `POST /api/ordens/:id/materiais`; `PUT`, `DELETE /api/materiais/:id` | Login / Cliente, Admin | Material que a clínica envia |
| `POST /api/materiais/:id/recebido` | Administrador, Colaborador | Marca como recebido |

**Ficheiros:**
- `rotas/ordens.ts`, `rotas/trabalhos.ts` e `rotas/materiais.ts`, mais os `.http` correspondentes.

Antes de cada ação de um Cliente, confirma que a ordem é da sua clínica: lê a vista e compara o `cliente_id` com `request.user.cliente_id`.

#### B3 — Produção: etapas dos trabalhos (fase 3)

A produção é interna do laboratório: só Administrador e Colaborador.

**Na BD:**
- `vw_etapa_trabalho`, `fn_etapa_trabalho_crud` e `vw_trabalho_etapa_atual` **já existem**.
  - A etapa atual é a primeira por concluir.
- Criar, em `crud/crud_producao.sql`:
  - `fn_iniciar_etapa_trabalho(p_id, p_responsavel_id)`:
    - só a **etapa atual** do trabalho pode ser iniciada;
    - não pode estar já iniciada;
    - a ordem tem de estar aceite;
    - preenche `responsavel_id` e `data_inicio = now()`;
    - se for a primeira etapa a começar na ordem, passa a ordem para `Em processamento`.
  - `fn_concluir_etapa_trabalho(p_id, p_utilizador_id)`:
    - a etapa tem de estar iniciada e por concluir;
    - preenche `data_conclusao = now()`.
    - Combinar com o grupo se, quando todas as etapas de todos os trabalhos estão concluídas, a ordem passa sozinha para `Concluído`.
  - `vw_trabalhos_a_executar`: um trabalho por linha, com a etapa atual, o responsável, o id da ordem, a clínica e o `prazo_entrega`, ordenada por prazo. Serve para a lista do colaborador.

**Rotas:**

| Rota | Quem | O que faz |
| --- | --- | --- |
| `GET /api/producao` | Administrador, Colaborador | Trabalhos a executar, por prazo |
| `GET /api/trabalhos/:id/etapas` | Administrador, Colaborador | Etapas de um trabalho |
| `POST /api/etapas-trabalho/:id/iniciar` | Administrador, Colaborador | Assume e inicia a etapa (`responsavel_id` = `request.user.id`) |
| `POST /api/etapas-trabalho/:id/concluir` | Administrador, Colaborador | Conclui a etapa |
| `POST /api/trabalhos/:id/etapas` e `DELETE /api/etapas-trabalho/:id` | Administrador | Acrescenta ou retira uma etapa de um trabalho (usa `fn_etapa_trabalho_crud`) |

**Ficheiros:**
- `rotas/producao.ts` e `pedidos/producao.http`.

---

### Tarefas da Pessoa A (Joel)

Estão aqui para a Pessoa B saber o que vai receber.

#### A1 — Login e permissões (fase 1)
- **Pacotes:** `@fastify/jwt` (token) e `bcryptjs`. A palavra-passe do admin do `modelofisico.sql` está em bcrypt.
- **Na BD:** uma função para ler as credenciais pelo e-mail, porque a `vw_utilizador` esconde de propósito o `password_hash`.
- **Ficheiro `src/autenticacao.ts`:** exporta `exigirLogin` e `exigirCargo(...)`, e define o `request.user` (ver [5.3](#53-proteger-uma-rota-com-login)).
- **Rotas:**
  - `POST /api/auth/login` com `{ email, password }` devolve `{ token, utilizador }`;
  - `GET /api/auth/eu`;
  - `PUT /api/auth/password`, para alterar a palavra-passe (obrigatório quando `password_temporaria` é `true`).
- **Regras:** contas inativas ou por aprovar não entram.
- **Proteções:** passa a proteger as rotas dos cargos.
- **`.env`:** novo `JWT_SEGREDO`.

#### A2 — Ligar o React e o Flutter (fase 1)
- **CORS** (`@fastify/cors`): as origens do React ficam no `.env`.
- **A API passa a ouvir em `0.0.0.0`**, para o telemóvel e o emulador lhe conseguirem chegar.
  - No emulador Android, o endereço da API é `http://10.0.2.2:3000`.
  - Num telemóvel real, é o IP do PC na mesma rede Wi-Fi.

#### A3 — Clientes e utilizadores (fase 2)
- CRUD de `/api/clientes` (Administrador).
- CRUD de `/api/utilizadores` (Administrador). O `DELETE` desativa a conta.
- `POST /api/utilizadores/:id/aprovar`.
- `POST /api/auth/registo` (público): a clínica regista-se e fica por aprovar. Na BD é uma função que cria o cliente e o utilizador de uma só vez.

#### A4 — Comentários, ficheiros e notificações (fase 3)
- **Comentários** de uma ordem (a clínica vê) ou de um trabalho (só o laboratório).
- **Upload de ficheiros** (`@fastify/multipart`): STL, fotografias, documentos. Ficam numa pasta do servidor e na tabela `ficheiro`. A clínica só vê os da ordem.
- **Notificações:**
  - são criadas por **triggers na BD** quando algo muda (ex.: nova ordem, mudança de estado);
  - a Pessoa B **não precisa** de criar notificações no seu código;
  - rotas: `GET /api/notificacoes` (as minhas) e `POST /api/notificacoes/:id/lida`.

### Para depois (a combinar)
- Registo de auditoria (`registo_auditoria`).
- Números para o painel inicial do backoffice.
- Enviar a BD para o servidor da ESTGV:
  - no pgAdmin, botão direito na BD → **Backup**, formato **Plain**;
  - confirmar antes que a versão do PostgreSQL do servidor suporta o que usamos.

---

## 7. Trabalhar em conjunto com o Git

1. O ramo base é o **`backend`**. Antes de começar uma tarefa: `git checkout backend` e `git pull`.
2. Cada tarefa tem o seu ramo: `git checkout -b b1-catalogo` (ou `a1-login`, ...).
3. Faz commits pequenos e frequentes, com mensagens em português: `Rotas das etapas`.
4. No fim da tarefa (ver as [regras 17 a 19](#antes-de-dar-uma-tarefa-como-feita)), faz `git push` e abre um **Pull Request para `backend`**. A outra pessoa dá uma vista de olhos e faz merge.
5. Depois de cada `git pull`:
   - Se apareceram ficheiros novos ou alterados em `ModelosBaseDeDados/`, corre-os no pgAdmin: primeiro os novos de `alteracoes/` (por ordem de número, cada um só uma vez), depois os de `crud/`.
   - Se o `package.json` mudou, corre `npm install`.
6. O `.env` **nunca** vai para o Git. Se alguém acrescentar uma variável, acrescenta-a também ao `.env.example` e avisa.

### Como pedir à AI

Começa cada conversa com algo como:

> Lê o ficheiro `backend/GUIA_BACKEND.md` e os ficheiros de `backend/src/`. Sou a Pessoa B. Quero fazer a tarefa B1, começando pela parte da base de dados. Faz uma coisa de cada vez, explica-me o que fizeste e diz-me como testar.

Se a AI propuser algo fora das regras (um ORM, camadas, escrever diretamente nas tabelas, pacotes novos), lembra-lhe as regras da secção 4.
