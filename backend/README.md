# Backend DentalLab

API em **Node.js + Fastify**, ligada ao **PostgreSQL**.

> Quem vai trabalhar no backend (ou a AI que usar) deve ler primeiro o [GUIA_BACKEND.md](GUIA_BACKEND.md): regras, receitas e divisão de tarefas.

A lógica da base de dados (tabelas, vistas `vw_*` e funções `fn_*_crud`) é criada no pgAdmin, a partir dos ficheiros de [`ModelosBaseDeDados/`](../ModelosBaseDeDados/).
A API só faz duas coisas:

- **ler:** `SELECT * FROM vw_...`
- **escrever:** `SELECT fn_..._crud('CREATE' | 'UPDATE' | 'DELETE', ...)`

## Arrancar

1. Criar a base de dados `abd_lab_cd` no pgAdmin e correr os ficheiros SQL (ver abaixo).
2. Copiar `.env.example` para `.env` e preencher:
   - `DB_PASSWORD`: a palavra-passe do PostgreSQL;
   - `JWT_SEGREDO`: um texto longo e aleatório (o `.env.example` tem o comando para o gerar);
   - `CORS_ORIGENS`: os endereços dos sites React (já vem preenchido para o Vite).
3. No terminal, dentro da pasta `backend`:

```bash
npm install     # só da primeira vez (e sempre que o package.json mudar)
npm run dev     # arranca a API na porta 3000 (reinicia sozinha quando gravas um ficheiro)
```

4. Abrir http://localhost:3000/api/v1/saude no navegador. Deve mostrar `{"api":"ok","bd":"ok"}`.
5. Abrir a documentação, http://localhost:3000/api/v1/docs. Tem todas as rotas, com os dados que cada uma recebe e devolve, e permite experimentá-las:
   1. Em `POST /api/v1/auth/login`, carregar em **Try it out** e entrar com o admin: `admin@dentallab.local`, palavra-passe `Admin#2026`.
   2. Copiar o `token` da resposta, carregar em **Authorize** (no topo) e colá-lo.
   3. A partir daí, as outras rotas já funcionam.

   O mesmo contrato, em JSON (OpenAPI 3), está em http://localhost:3000/api/v1/docs/json.

## Base de dados no pgAdmin

A base de dados chama-se **`abd_lab_cd`**. Para a criar:

1. No pgAdmin, criar uma base de dados vazia `abd_lab_cd`.
2. No **Query Tool** dessa BD, correr `ModelosBaseDeDados/sql/script_completo.sql` (tabelas, vistas, funções, procedimentos, triggers e dados iniciais).
3. Opcional: correr `ModelosBaseDeDados/sql/07_dados_exemplo.sql`, que cria uma colaboradora, uma clínica (`clinica.teste@dentallab.local` / `Clinica#2026`) e ordens de exemplo.

Como mudar a BD, e o que é cada ficheiro: ver [ModelosBaseDeDados/README.md](../ModelosBaseDeDados/README.md).

## Organização

```text
src/
  servidor.ts           só arranca a API
  app.ts                constrói a API: liga os plugins e os módulos (construirApp)
  configuracao.ts       lê o ficheiro .env
  comum/                peças usadas por todos os módulos
    bd.ts               ligação à base de dados: ler (bd.query) e escrever (escreverComo)
    acesso.ts           controlo de acesso às rotas (exigirLogin, exigirCargo)
    erros.ts            formato das respostas de erro e mensagens em português
    esquemas.ts         peças dos esquemas usadas por todos os módulos (id no endereço, respostas, erros)
    respostas.ts        respostas de sucesso com regras (201 com Location) e o prefixo /api/v1
  plugins/              peças do Fastify ligadas uma vez, para toda a API
    cache.ts            Cache-Control em todas as respostas
    cors.ts             sites React autorizados
    documentacao.ts     documentação da API (OpenAPI), em /api/v1/docs
    jwt.ts              tokens de login
    tratamento-erros.ts respostas de erro e rota inexistente
    validacao.ts        confirma os dados dos pedidos com os esquemas
  modulos/              um por área
    cargos/
      cargos.rotas.ts     as rotas: quem pode, o que se lê ou escreve na BD
      cargos.esquemas.ts  os dados que cada rota recebe e devolve
    saude/  autenticacao/  conta/  clientes/  alteracoes-cliente/  utilizadores/   (iguais)
```

Os nomes seguem os da app (`lib/comum`, `lib/autenticacao`, `configuracao.dart`) e os do servidor de AI3 (`servidor.js`).

**Acrescentar uma área nova** (ex.: ordens):
1. Criar a pasta `src/modulos/ordens/` com os ficheiros `ordens.rotas.ts` e `ordens.esquemas.ts`, iguais aos outros.
2. No `ordens.esquemas.ts`, descrever cada rota: o que recebe (`params`, `querystring`, `body`) e o que devolve (`response`). Com isto, a API recusa dados errados (400, com `detalhes`) e a rota aparece na documentação.
3. A resposta só leva os campos que estão no esquema. Se acrescentarem uma coluna à vista, acrescentem-na também ao esquema (ex.: `esquemaCargo`), senão não aparece na resposta.
4. Registar o módulo no `app.ts`: `app.register(rotasOrdens, versao1);`.

As regras de negócio ficam na base de dados (funções e procedimentos). Por isso, cada rota só verifica quem pode fazer o pedido, lê de uma vista ou chama uma função, e devolve a resposta. Não há camadas (controller, service, repository) por cima.

## Como usar a API no frontend (React e Flutter)

O site, o backoffice (React) e a app (Flutter) usam a mesma API, com os mesmos pedidos e as mesmas respostas.

### 1. Endereço da API

A API tem de estar a correr (`npm run dev`) no PC.

| De onde | Endereço |
| --- | --- |
| React, no navegador do mesmo PC | `http://localhost:3000/api/v1` |
| Flutter, no emulador Android | `http://10.0.2.2:3000/api/v1` (endereço especial que aponta para o PC) |
| Flutter, no simulador iOS | `http://localhost:3000/api/v1` |
| Flutter, num telemóvel real | `http://<IP do PC>:3000/api/v1`. O IP aparece no terminal ao correr `npm run dev` (o que não é `127.0.0.1`). O telemóvel tem de estar na **mesma rede Wi-Fi** |

- Guarda o endereço num único sítio do projeto (uma constante ou uma variável de ambiente), para mudar facilmente quando a API for para o servidor.
- **Telemóvel real:**
  - Na primeira vez, o Windows pergunta se o Node.js pode aceder à rede: escolhe "Redes privadas".
  - As redes da escola costumam impedir que os aparelhos falem entre si. Se o telemóvel não chegar à API, usa o emulador ou o hotspot do telemóvel.
- **Flutter com `http://` (sem `s`):**
  - No Android, durante o desenvolvimento, é preciso acrescentar `android:usesCleartextTraffic="true"` à tag `<application>` do `android/app/src/main/AndroidManifest.xml`.
  - No iOS, é preciso uma exceção `NSAppTransportSecurity` no `Info.plist`.
- **React:** a porta do site tem de estar no `CORS_ORIGENS` do `.env` da API. Já lá estão a 5173 e a 5174, que são as do Vite. Sem isso, o navegador bloqueia os pedidos.

### 2. Login e token

1. `POST /api/v1/auth/login` com `{ "email": "...", "password": "..." }`.
2. A resposta traz `{ "token": "...", "utilizador": { "id", "nome", "cargo", "cliente_id", "email", "password_temporaria" } }`.
3. Guarda o `token`:
   - React: `localStorage`;
   - Flutter: o pacote `flutter_secure_storage`.
4. Envia-o em **todos** os outros pedidos, no cabeçalho `Authorization: Bearer <token>`.
5. Usa o `cargo` (`Administrador`, `Colaborador` ou `Cliente`) para escolher que ecrãs mostrar. Quem decide o que cada cargo pode fazer é a API; o frontend só esconde o que não faz sentido mostrar.
6. Se `password_temporaria` for `true`, leva a pessoa para um ecrã de mudar a palavra-passe (`PUT /api/v1/conta/palavra-passe`) antes de continuar.
7. Quando a app abre e já tem um token guardado, chama `GET /api/v1/auth/eu`:
   - 200: a sessão continua válida;
   - 401: apaga o token e mostra o ecrã de login.
8. O token dura 7 dias. Terminar sessão é apagar o token guardado.

**React (`fetch`):**

```js
const API = 'http://localhost:3000/api/v1';

// Login
const resposta = await fetch(`${API}/auth/login`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password }),
});
const dados = await resposta.json();
if (!resposta.ok) {
  mostrarErro(dados.mensagem); // a mensagem já vem pronta a mostrar
} else {
  localStorage.setItem('token', dados.token);
}

// Qualquer outro pedido
const cargos = await fetch(`${API}/cargos`, {
  headers: { Authorization: `Bearer ${localStorage.getItem('token')}` },
});
```

**Flutter (pacote `http`):**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

const api = 'http://10.0.2.2:3000/api/v1';

// Login
final resposta = await http.post(
  Uri.parse('$api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'email': email, 'password': password}),
);
final dados = jsonDecode(resposta.body);
if (resposta.statusCode != 200) {
  mostrarErro(dados['mensagem']); // a mensagem já vem pronta a mostrar
} else {
  final token = dados['token']; // guardar com flutter_secure_storage
}

// Qualquer outro pedido
final cargos = await http.get(
  Uri.parse('$api/cargos'),
  headers: {'Authorization': 'Bearer $token'},
);
```

### 3. Pedidos e respostas

- Os dados vão e vêm em **JSON**.
- Os nomes dos campos são os das colunas da BD (snake_case): `prazo_entrega`, `cliente_id`, ...
- **`Content-Type: application/json` só se envia nos pedidos com corpo** (`POST`, `PUT` e `PATCH`). Num `DELETE` sem corpo, esse cabeçalho dá erro 400.
- **Alterar um registo é `PATCH`**, só com os campos que mudam (ex.: `PATCH /api/v1/clientes/5` com `{ "telefone": "232000000" }`). Os outros ficam como estão.
- **Campos:** um campo que a rota não conhece dá 400 (ex.: `morada` em vez de `morada_faturacao`), e os tipos têm de estar certos (`"cargo_id": 2`, não `"2"`; `"ativo": true`, não `"true"`).
- **Datas:**
  - as datas sem hora vêm como `"2026-11-20"`;
  - as datas com hora vêm em ISO, `"2026-11-04T10:30:00.000Z"`, em UTC, e convertem-se para a hora local ao mostrar.
- **Ids:** vêm como números.
- **Respostas de sucesso:**

  | Situação | Código | Corpo |
  | --- | --- | --- |
  | Lista | 200 | `[ {...}, {...} ]` |
  | Um registo | 200 | `{...}` |
  | Criado | 201 | `{ "id": 5 }`, mais o cabeçalho `Location` com o endereço do registo novo (ex.: `/api/v1/cargos/5`) |
  | Alterado ou ação (ex.: aprovar) | 200 | `{ "id": 5 }` |
  | Apagado ou desativado (`DELETE`) | 204 | Sem corpo |
- **Cache (`Cache-Control`):** todas as respostas dizem se o navegador as pode guardar.

  | Resposta | `Cache-Control` | O que quer dizer |
  | --- | --- | --- |
  | Leituras (`GET`) de quem tem login | `private, no-cache` | Só o próprio navegador a pode guardar, e tem de confirmar com a API antes de a reutilizar |
  | Escritas, login, sessão (`/auth/eu`), saúde e todos os erros | `no-store` | Nunca se guarda |
  | Dados públicos, iguais para todos | `public, max-age=...` | Pode guardar-se e reutilizar-se durante esse tempo (só nas rotas que o indicarem) |

  É com isto que o service worker do site decide o que pode guardar.

### 4. Erros

Todas as respostas de erro têm este formato (o mesmo das aulas de AI3):

```json
{ "codigo": 409, "mensagem": "Já existe um cliente com o NIF 509990010" }
```

```json
{
  "codigo": 400,
  "mensagem": "Os dados enviados não são válidos.",
  "detalhes": [
    { "campo": "nif", "problema": "Tem de ter 9 algarismos." },
    { "campo": "password", "problema": "Tem de ter pelo menos 8 caracteres." }
  ]
}
```

- `codigo`: o mesmo número do código HTTP da resposta.
- `mensagem`: está em português e pode mostrar-se diretamente ao utilizador.
- `detalhes`: só aparece quando os dados enviados não cumprem as regras da rota. Traz todos os problemas de uma vez, para mostrar cada um ao pé do seu campo.

| Código | Significa | O que o frontend deve fazer |
| --- | --- | --- |
| 400 | Dados inválidos (ex.: "Os dados enviados não são válidos.", com `detalhes`) | Mostrar a mensagem e, se vier `detalhes`, o problema ao pé de cada campo |
| 401 | Sem sessão, sessão expirada ou conta desativada | Apagar o token e voltar ao ecrã de login |
| 403 | O cargo não tem permissão; ou, no login, a conta está desativada ou ainda por aprovar | Mostrar a mensagem |
| 404 | O registo não existe | Mostrar a mensagem, ou voltar à lista |
| 409 | Conflito: já existe um registo com esse valor (ex.: "Já existe um cliente com este NIF"), ou o registo não está no estado certo (ex.: "Esta conta já está aprovada") | Mostrar a mensagem (e, se for preciso, recarregar os dados) |
| 413 | O pedido é demasiado grande | Mostrar a mensagem |
| 415 | Os dados não foram enviados em JSON | Erro do programador: enviar `Content-Type: application/json` |
| 500 | Erro inesperado na API | Mostrar "Ocorreu um erro inesperado. Tente novamente." |
| 503 | A API não consegue ligar-se à base de dados | Mostrar a mensagem e tentar mais tarde |

O 401 traz o cabeçalho `WWW-Authenticate`:
- `Bearer` quando não veio token;
- `Bearer error="invalid_token"` quando o token é falso, expirou, ou a conta foi desativada.

As mensagens das funções da BD (`RAISE EXCEPTION`) chegam tal como foram escritas no pgAdmin, com o código 400; ou 404 e 409, quando a função indica que o registo não existe, que já existe ou que não está no estado certo (regra no início do `03_funcoes.sql`).

No **login**, o 401 significa "email ou palavra-passe incorretos". Aí mostra-se a mensagem, sem apagar nada.

## Rotas

Resumo. Os campos de cada rota, os obrigatórios e as respostas possíveis estão na documentação (http://localhost:3000/api/v1/docs).

| Rota | O que faz |
| --- | --- |
| `GET /api/v1/saude` | Verifica a API e a ligação à BD |
| `POST /api/v1/registos` | Público. Uma clínica regista-se: `{ "nome", "nif", "morada_faturacao", "telefone", "email", "password" }`. A conta fica à espera de aprovação |
| `POST /api/v1/auth/login` | Login: `{ "email": "...", "password": "..." }`. Devolve `{ token, utilizador }` |
| `GET /api/v1/auth/eu` | Quem está ligado (precisa de login) |
| `PUT /api/v1/conta/palavra-passe` | Muda a palavra-passe de quem está ligado: `{ "password_atual": "...", "password_nova": "..." }` |
| `GET /api/v1/cargos` | Lista os cargos, que são fixos: Administrador, Colaborador e Cliente (login) |
| `GET /api/v1/clientes` | Lista as clínicas (Administrador) |
| `GET /api/v1/clientes/:id` | Mostra uma clínica (Administrador; uma clínica só a sua) |
| `POST /api/v1/clientes` | Cria uma clínica, sem conta de acesso: `{ "nome", "nif", "morada_faturacao", "email", "telefone" }` (Administrador) |
| `PATCH /api/v1/clientes/:id` | Altera uma clínica (só os campos que vierem); `"ativo": false/true` desativa ou reativa a clínica e as contas dela (Administrador) |
| `DELETE /api/v1/clientes/:id` | Desativa a clínica e as contas dela (Administrador) |
| `POST /api/v1/alteracoes-cliente` | A clínica pede para mudar os seus dados: `{ "nome", "morada_faturacao", "email", "telefone" }`, só os que mudam (Cliente) |
| `GET /api/v1/alteracoes-cliente` | Pedidos de alteração; `?estado=pendente` só os que estão à espera (Administrador: todos; Cliente: os seus) |
| `GET /api/v1/alteracoes-cliente/:id` | Um pedido de alteração (Administrador; Cliente: só os seus) |
| `POST /api/v1/alteracoes-cliente/:id/aprovar` | Aprova: os dados novos passam para a clínica (Administrador) |
| `POST /api/v1/alteracoes-cliente/:id/rejeitar` | Rejeita: `{ "motivo_rejeicao": "..." }` (Administrador) |
| `GET /api/v1/utilizadores` | Lista as contas; `?por_aprovar=true` só as que estão à espera de aprovação (Administrador) |
| `GET /api/v1/utilizadores/:id` | Mostra uma conta (Administrador) |
| `POST /api/v1/utilizadores` | Cria uma conta já aprovada: `{ "nome", "email", "cargo_id", "cliente_id", "password" }`; a palavra-passe é temporária (Administrador) |
| `PATCH /api/v1/utilizadores/:id` | Altera uma conta (só os campos que vierem); com `"password"`, define uma nova palavra-passe temporária (Administrador) |
| `DELETE /api/v1/utilizadores/:id` | Desativa uma conta ou recusa um registo; não pode ser a própria (Administrador) |
| `POST /api/v1/utilizadores/:id/aprovar` | Aprova uma conta à espera (Administrador) |

## Comandos

| Comando | O que faz |
| --- | --- |
| `npm run dev` | Arranca a API e reinicia-a sempre que gravas um ficheiro |
| `npm start` | Arranca a API (sem reiniciar sozinha) |
| `npm run typecheck` | Verifica se há erros de TypeScript |
