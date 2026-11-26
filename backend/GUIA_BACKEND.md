# Guia do backend DentalLab

Este guia é para quem mexe no backend: na API (`backend/`) ou na base de dados (`ModelosBaseDeDados/`).
Como usar a API no site e na app (endereços, login, erros, rotas) está no [README](README.md).

> **Se és uma AI:** lê este ficheiro todo antes de escrever código e segue as [regras](#2-regras) à letra.
> O modelo a copiar é um módulo que já existe, por exemplo [`src/modulos/etapas/`](src/modulos/etapas/).
> Se uma tarefa te obrigar a quebrar uma regra, pára e pergunta.

---

## 1. Como funciona

- **A base de dados (`abd_lab_cd`) tem as regras de negócio.** Tabelas, vistas `vw_*` (para ler), funções `fn_*` e procedimentos `pr_*` (para escrever), e triggers (auditoria, notificações, datas e validações). Quando uma regra não se cumpre, a função faz `RAISE EXCEPTION` com a mensagem em português.
- **A API (Node.js + Fastify) faz o resto.** Em cada pedido:
  1. confirma quem é (o token da app ou o cookie do site);
  2. confirma os dados com o esquema da rota (se estiverem mal, responde 400 com os problemas);
  3. lê de uma vista ou chama uma função;
  4. responde em JSON.
- **A documentação da API é gerada a partir das rotas**, em http://localhost:3000/api/v1/docs (com a API a correr). Está sempre de acordo com o código.

Cada área tem a sua pasta em `src/modulos/` com dois ficheiros:

| Ficheiro | O que tem |
| --- | --- |
| `<area>.esquemas.ts` | O que cada rota recebe e devolve (valida os pedidos e gera a documentação) |
| `<area>.rotas.ts` | As rotas: quem pode, o que se lê ou escreve na BD |

As peças comuns estão em `src/comum/` (BD, acesso, erros, esquemas, respostas, email) e em `src/plugins/`.

## 2. Regras

### Base de dados

- A API lê **só de vistas** e escreve **só com funções e procedimentos**. Nunca lê nem escreve diretamente nas tabelas.
- As regras de negócio ficam na BD (`RAISE EXCEPTION 'mensagem em português'`). A mensagem chega tal e qual ao utilizador.
- Alguns erros levam um código, para a API responder com o código HTTP certo (a regra está no início do `03_funcoes.sql`):

  | No `RAISE` | Quando | A API responde |
  | --- | --- | --- |
  | `USING ERRCODE = 'no_data_found'` | O registo a alterar, apagar ou usar como "pai" não existe | 404 |
  | `USING ERRCODE = 'unique_violation'` | Já existe um registo com esse valor | 409 |
  | `USING ERRCODE = 'object_not_in_prerequisite_state'` | O registo não está no estado certo (ex.: etapa já iniciada) | 409 |
  | `USING ERRCODE = 'object_in_use'` | O registo ainda está a ser usado (ex.: cargo com utilizadores) | 409 |
  | sem código | Dados inválidos | 400 |

- **Colunas novas numa vista: sempre no fim.** O `CREATE OR REPLACE VIEW` só aceita colunas novas no fim. A coluna também tem de ser acrescentada ao esquema da API (`esquemaX` no `<area>.esquemas.ts`); senão, não aparece na resposta.
- A palavra-passe nunca chega à BD: a API guarda só o hash (bcrypt).
- Edita-se o ficheiro numerado certo (`01` a `06`) e corre-se o `python ModelosBaseDeDados/sql/juntar.py`. O `script_completo.sql` nunca se edita à mão.
- Cada função nova tem um teste em `ModelosBaseDeDados/sql/testes/` (um bloco `DO`, com `RAISE NOTICE` e `ROLLBACK` no fim).

### API

- **Nomes e comentários em português**, código simples (sem camadas a mais).
- **Escrever é sempre com o `escreverComo`** (ou o `transacaoComo`, quando há vários comandos que têm de ficar todos ou nenhum), com o id de quem faz o pedido. É assim que a auditoria regista o autor.
- Os valores vão sempre em `$1, $2...`, nunca colados no texto do SQL (evita SQL injection).
- Os erros respondem-se com o `enviarErro(reply, codigo, mensagem)`. O formato é sempre `{ codigo, mensagem, detalhes }`.
- Códigos de sucesso:

  | Situação | Resposta |
  | --- | --- |
  | Criar | 201, com `{ id }` e o cabeçalho `Location` (`enviarCriado`) |
  | Alterar só alguns campos | `PATCH`, 200 com `{ id }` |
  | Ação (aceitar, concluir...) | `POST /recurso/:id/acao`, 200 com `{ id }` |
  | Apagar ou desativar | 204, sem corpo |

- **Acesso:**
  - `exigirLogin` deixa passar quem tem sessão;
  - `exigirCargo('Administrador', ...)` limita a cargos;
  - `podeVerOrdem` confirma que a ordem é da clínica que a pede.
- **A clínica nunca vê o que é interno do laboratório:** etapas, notas internas e ficheiros dos trabalhos. Nas rotas do laboratório responde-se 403; ao pedir uma ordem de outra clínica, 404 (como se não existisse).
- Os segredos (palavras-passe, `JWT_SEGREDO`, SMTP) ficam só no `.env`, que nunca vai para o Git.

### Antes de dar uma tarefa como feita

1. `npm run typecheck` sem erros.
2. A rota experimentada em http://localhost:3000/api/v1/docs, incluindo os casos de erro (sem sessão, cargo errado, dados errados, registo que não existe).
3. O terminal da API sem nenhum erro 500.
4. A tabela de rotas do [README](README.md) atualizada.
5. Se mexeu na BD: `juntar.py` corrido, e os testes de `sql/testes/` a passar no pgAdmin.

## 3. Receitas

### 3.1 Uma rota nova numa área que já existe

No `<area>.esquemas.ts`, descrever a rota:

```ts
// POST /api/v1/etapas
export const criarEtapa = {
  tags: ['Catálogo'],
  operationId: 'criarEtapa',
  summary: 'Criar uma etapa de produção',
  description: 'Só o Administrador.',
  body: {
    type: 'object',
    properties: { nome: { type: 'string', minLength: 1, maxLength: 100 } },
    required: ['nome'],
    additionalProperties: false, // um campo que não está aqui dá 400
  },
  response: {
    201: respostaCriado,
    ...respostasErro(400, 401, 403, 409),
  },
};
```

No `<area>.rotas.ts`, a rota usa o esquema e escreve com o `escreverComo`:

```ts
// POST /api/v1/etapas: cria uma etapa
app.post('/etapas', { schema: criarEtapa, preHandler: exigirCargo('Administrador') }, async (request, reply) => {
  const dados = request.body as { nome: string };
  const resultado = await escreverComo(request.user.id, "SELECT fn_etapa_crud('CREATE', NULL, p_nome => $1) AS id", [dados.nome]);
  return enviarCriado(reply, 'etapas', resultado.rows[0].id);
});
```

### 3.2 Uma área nova

1. Criar a pasta `src/modulos/<area>/` com os dois ficheiros, copiando um módulo parecido.
2. Se a resposta for um registo de uma vista, criar o esquema com nome (`$id`) e registá-lo no início do módulo: `app.addSchema(esquemaX)`.
3. Registar o módulo no `src/app.ts`: `app.register(rotasArea, versao1);`.
4. Se for preciso, acrescentar a etiqueta (secção) em `src/plugins/documentacao.ts`.

### 3.3 Atualizar a BD de alguém sem apagar os dados

- `02_vistas.sql`, `03_funcoes.sql` e `04_procedimentos.sql` podem correr-se outra vez por inteiro (são `CREATE OR REPLACE`).
- No `05_triggers.sql`, as funções dos triggers também. Mas o `CREATE TRIGGER` dá erro se o trigger já existir: um trigger novo corre-se à parte, com `DROP TRIGGER IF EXISTS ...` antes.
- Tabelas novas ou colunas novas numa tabela (`01`) precisam de um `ALTER TABLE` próprio.
- Com dados só de teste, é mais simples apagar a BD e criá-la de novo com o `script_completo.sql` (e o `07_dados_exemplo.sql`).

## 4. Git

- O backend e o SQL estão na branch `api`.
- Commits pequenos, com a mensagem em português a dizer o que mudou.
- Nunca vão para o Git: o `.env`, a pasta `backend/ficheiros/` (os ficheiros enviados) e o `node_modules/`.
