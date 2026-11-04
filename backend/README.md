# Backend DentalLab

API em **Node.js + Fastify**, ligada ao **PostgreSQL**.

> Quem vai trabalhar no backend (ou a AI que usar) deve ler primeiro o [GUIA_BACKEND.md](GUIA_BACKEND.md): regras, receitas e divisão de tarefas.

A lógica da base de dados (tabelas, vistas `vw_*` e funções `fn_*_crud`) é criada no pgAdmin, a partir dos ficheiros de [`ModelosBaseDeDados/`](../ModelosBaseDeDados/).
A API só faz duas coisas:

- **ler:** `SELECT * FROM vw_...`
- **escrever:** `SELECT fn_..._crud('CREATE' | 'UPDATE' | 'DELETE', ...)`

## Arrancar

1. Criar a base de dados `dentallab` no pgAdmin e correr os ficheiros SQL (ver abaixo).
2. Copiar `.env.example` para `.env` e preencher:
   - `DB_PASSWORD`: a palavra-passe do PostgreSQL;
   - `JWT_SEGREDO`: um texto longo e aleatório (o `.env.example` tem o comando para o gerar);
   - `CORS_ORIGENS`: os endereços dos sites React (já vem preenchido para o Vite).
3. No terminal, dentro da pasta `backend`:

```bash
npm install     # só da primeira vez (e sempre que o package.json mudar)
npm run dev     # arranca a API na porta 3000 (reinicia sozinha quando gravas um ficheiro)
```

4. Abrir http://localhost:3000/api/health no navegador. Deve mostrar `{"api":"ok","bd":"ok"}`.
5. Testar o login com [`pedidos/auth.http`](pedidos/auth.http): admin `admin@dentallab.local`, palavra-passe `Admin#2026`.

## Base de dados no pgAdmin

No **Query Tool** da base de dados `dentallab`, correr por esta ordem:

1. `ModelosBaseDeDados/modelofisico.sql` (tabelas e dados iniciais)
2. Os ficheiros de `ModelosBaseDeDados/alteracoes/`, por ordem de número (tabelas acrescentadas depois; cada um corre-se uma só vez)
3. Os ficheiros de `ModelosBaseDeDados/crud/` (vistas e funções; podem voltar a correr-se sempre que mudam)

Os ficheiros `teste_*.sql` de `ModelosBaseDeDados/testes/` experimentam as funções e desfazem tudo no fim (`ROLLBACK`). Os resultados aparecem no separador **Messages** do Query Tool.

O `dados_teste_clinica.sql` é diferente: **deixa na BD** uma clínica com a conta já aprovada, para experimentar a API como clínica (`clinica.teste@dentallab.local` / `Clinica#2026`).

## Organização

```text
src/
  server.ts         cria o servidor, trata os erros, regista as rotas e arranca
  config.ts         lê o ficheiro .env
  db.ts             ligação à base de dados
  autenticacao.ts   proteção das rotas com login (exigirLogin, exigirCargo)
  erros.ts          mensagens em português para os erros dos dados (regras da BD, formato errado...)
  rotas/            um ficheiro por entidade (auth.ts, cargos.ts, ...)
pedidos/       pedidos de teste (.http) para a extensão REST Client do VS Code
```

## Como usar a API no frontend (React e Flutter)

O site, o backoffice (React) e a app (Flutter) usam a mesma API, com os mesmos pedidos e as mesmas respostas.

### 1. Endereço da API

A API tem de estar a correr (`npm run dev`) no PC.

| De onde | Endereço |
| --- | --- |
| React, no navegador do mesmo PC | `http://localhost:3000/api` |
| Flutter, no emulador Android | `http://10.0.2.2:3000/api` (endereço especial que aponta para o PC) |
| Flutter, no simulador iOS | `http://localhost:3000/api` |
| Flutter, num telemóvel real | `http://<IP do PC>:3000/api`. O IP aparece no terminal ao correr `npm run dev` (o que não é `127.0.0.1`). O telemóvel tem de estar na **mesma rede Wi-Fi** |

- Guarda o endereço num único sítio do projeto (uma constante ou uma variável de ambiente), para mudar facilmente quando a API for para o servidor.
- **Telemóvel real:**
  - Na primeira vez, o Windows pergunta se o Node.js pode aceder à rede: escolhe "Redes privadas".
  - As redes da escola costumam impedir que os aparelhos falem entre si. Se o telemóvel não chegar à API, usa o emulador ou o hotspot do telemóvel.
- **Flutter com `http://` (sem `s`):**
  - No Android, durante o desenvolvimento, é preciso acrescentar `android:usesCleartextTraffic="true"` à tag `<application>` do `android/app/src/main/AndroidManifest.xml`.
  - No iOS, é preciso uma exceção `NSAppTransportSecurity` no `Info.plist`.
- **React:** a porta do site tem de estar no `CORS_ORIGENS` do `.env` da API. Já lá estão a 5173 e a 5174, que são as do Vite. Sem isso, o navegador bloqueia os pedidos.

### 2. Login e token

1. `POST /api/auth/login` com `{ "email": "...", "password": "..." }`.
2. A resposta traz `{ "token": "...", "utilizador": { "id", "nome", "cargo", "cliente_id", "email", "password_temporaria" } }`.
3. Guarda o `token`:
   - React: `localStorage`;
   - Flutter: o pacote `flutter_secure_storage`.
4. Envia-o em **todos** os outros pedidos, no cabeçalho `Authorization: Bearer <token>`.
5. Usa o `cargo` (`Administrador`, `Colaborador` ou `Cliente`) para escolher que ecrãs mostrar. Quem decide o que cada cargo pode fazer é a API; o frontend só esconde o que não faz sentido mostrar.
6. Se `password_temporaria` for `true`, leva a pessoa para um ecrã de mudar a palavra-passe (`PUT /api/auth/password`) antes de continuar.
7. Quando a app abre e já tem um token guardado, chama `GET /api/auth/eu`:
   - 200: a sessão continua válida;
   - 401: apaga o token e mostra o ecrã de login.
8. O token dura 7 dias. Terminar sessão é apagar o token guardado.

**React (`fetch`):**

```js
const API = 'http://localhost:3000/api';

// Login
const resposta = await fetch(`${API}/auth/login`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password }),
});
const dados = await resposta.json();
if (!resposta.ok) {
  mostrarErro(dados.erro); // a mensagem já vem pronta a mostrar
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

const api = 'http://10.0.2.2:3000/api';

// Login
final resposta = await http.post(
  Uri.parse('$api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'email': email, 'password': password}),
);
final dados = jsonDecode(resposta.body);
if (resposta.statusCode != 200) {
  mostrarErro(dados['erro']); // a mensagem já vem pronta a mostrar
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
- **`Content-Type: application/json` só se envia nos pedidos com corpo** (`POST` e `PUT`). Num `DELETE` sem corpo, esse cabeçalho dá erro 400.
- **Datas:**
  - as datas sem hora vêm como `"2026-11-20"`;
  - as datas com hora vêm em ISO, `"2026-11-04T10:30:00.000Z"`, em UTC, e convertem-se para a hora local ao mostrar.
- **Ids:** vêm como números.
- **Respostas de sucesso:**

  | Situação | Código | Corpo |
  | --- | --- | --- |
  | Lista | 200 | `[ {...}, {...} ]` |
  | Um registo | 200 | `{...}` |
  | Criado | 201 | `{ "id": 5 }` |
  | Alterado, apagado ou ação | 200 | `{ "id": 5 }` |

### 4. Erros

Todas as respostas de erro têm o formato `{ "erro": "mensagem" }`. A mensagem está em português e pode mostrar-se diretamente ao utilizador.

| Código | Significa | O que o frontend deve fazer |
| --- | --- | --- |
| 400 | Dados inválidos (ex.: "Tem de indicar a designação do cargo") | Mostrar a mensagem e deixar a pessoa corrigir |
| 401 | Sem sessão, sessão expirada ou conta desativada | Apagar o token e voltar ao ecrã de login |
| 403 | O cargo não tem permissão; ou, no login, a conta está desativada ou ainda por aprovar | Mostrar a mensagem |
| 404 | O registo não existe | Mostrar a mensagem, ou voltar à lista |
| 500 | Erro inesperado na API | Mostrar "Ocorreu um erro inesperado. Tente novamente." |

As mensagens das funções da BD (`RAISE EXCEPTION`) chegam tal como foram escritas no pgAdmin, com o código 400.

No **login**, o 401 significa "email ou palavra-passe incorretos". Aí mostra-se a mensagem, sem apagar nada.

## Rotas

| Rota | O que faz |
| --- | --- |
| `GET /api/health` | Verifica a API e a ligação à BD |
| `POST /api/auth/login` | Login: `{ "email": "...", "password": "..." }`. Devolve `{ token, utilizador }` |
| `GET /api/auth/eu` | Quem está ligado (precisa de login) |
| `PUT /api/auth/password` | Muda a palavra-passe de quem está ligado: `{ "password_atual": "...", "password_nova": "..." }` |
| `GET /api/cargos` | Lista os cargos (login) |
| `GET /api/cargos/:id` | Mostra um cargo (login) |
| `POST /api/cargos` | Cria um cargo: `{ "designacao": "..." }` (Administrador) |
| `PUT /api/cargos/:id` | Altera um cargo: `{ "designacao": "..." }` (Administrador) |
| `DELETE /api/cargos/:id` | Apaga um cargo, só se não tiver utilizadores (Administrador) |
| `GET /api/clientes` | Lista as clínicas (Administrador) |
| `GET /api/clientes/:id` | Mostra uma clínica (Administrador; uma clínica só a sua) |
| `POST /api/clientes` | Cria uma clínica, sem conta de acesso: `{ "nome", "nif", "morada_faturacao", "email", "telefone" }` (Administrador) |
| `PUT /api/clientes/:id` | Altera uma clínica; `"ativo": false/true` desativa ou reativa a clínica e as contas dela (Administrador) |
| `DELETE /api/clientes/:id` | Desativa a clínica e as contas dela (Administrador) |
| `POST /api/alteracoes-cliente` | A clínica pede para mudar os seus dados: `{ "nome", "morada_faturacao", "email", "telefone" }`, só os que mudam (Cliente) |
| `GET /api/alteracoes-cliente` | Pedidos de alteração; `?estado=pendente` só os que estão à espera (Administrador: todos; Cliente: os seus) |
| `GET /api/alteracoes-cliente/:id` | Um pedido de alteração (Administrador; Cliente: só os seus) |
| `POST /api/alteracoes-cliente/:id/aprovar` | Aprova: os dados novos passam para a clínica (Administrador) |
| `POST /api/alteracoes-cliente/:id/rejeitar` | Rejeita: `{ "motivo_rejeicao": "..." }` (Administrador) |

## Comandos

| Comando | O que faz |
| --- | --- |
| `npm run dev` | Arranca a API e reinicia-a sempre que gravas um ficheiro |
| `npm start` | Arranca a API (sem reiniciar sozinha) |
| `npm run typecheck` | Verifica se há erros de TypeScript |
