# Backend DentalLab

API em **Node.js + Fastify**, ligada ao **PostgreSQL**.

> Quem vai trabalhar no backend (ou a AI que usar) deve ler primeiro o [GUIA_BACKEND.md](GUIA_BACKEND.md): regras, receitas e divisão de tarefas.

A lógica da base de dados (tabelas, vistas `vw_*` e funções `fn_*_crud`) é criada no pgAdmin, a partir dos ficheiros de [`ModelosBaseDeDados/`](../ModelosBaseDeDados/).
A API só faz duas coisas:

- **ler:** `SELECT * FROM vw_...`
- **escrever:** `SELECT fn_..._crud('CREATE' | 'UPDATE' | 'DELETE', ...)`

## Arrancar

1. Criar a base de dados `dentallab` no pgAdmin e correr os ficheiros SQL (ver abaixo).
2. Copiar `.env.example` para `.env` e pôr a palavra-passe do PostgreSQL em `DB_PASSWORD`.
3. No terminal, dentro da pasta `backend`:

```bash
npm install     # só da primeira vez
npm run dev     # arranca a API em http://localhost:3000 (reinicia sozinha quando gravas um ficheiro)
```

4. Abrir no navegador:
   - http://localhost:3000/api/health deve mostrar `{"api":"ok","bd":"ok"}`
   - http://localhost:3000/api/cargos deve mostrar os 3 cargos

## Base de dados no pgAdmin

No **Query Tool** da base de dados `dentallab`, correr por esta ordem:

1. `ModelosBaseDeDados/modelofisico.sql` (tabelas e dados iniciais)
2. Os quatro ficheiros de `ModelosBaseDeDados/crud/` (vistas e funções)

## Organização

```text
src/
  server.ts    cria o servidor, regista as rotas e arranca
  config.ts    lê o ficheiro .env
  db.ts        ligação à base de dados
  rotas/       um ficheiro por entidade (cargos.ts, clientes.ts, ...)
pedidos/       pedidos de teste (.http) para a extensão REST Client do VS Code
```

## Erros

Todas as respostas de erro têm o formato `{ "erro": "mensagem" }`.
As mensagens das funções da BD (`RAISE EXCEPTION`) chegam tal como foram escritas no pgAdmin, com o código 400.

## Rotas

| Rota | O que faz |
| --- | --- |
| `GET /api/health` | Verifica a API e a ligação à BD |
| `POST /api/auth/login` | Login: `{ "email": "...", "password": "..." }`. Devolve `{ token, utilizador }` |
| `GET /api/auth/eu` | Quem está ligado (precisa de login) |
| `PUT /api/auth/password` | Muda a palavra-passe de quem está ligado: `{ "password_atual": "...", "password_nova": "..." }` |
| `GET /api/cargos` | Lista os cargos |
| `GET /api/cargos/:id` | Mostra um cargo |
| `POST /api/cargos` | Cria um cargo: `{ "designacao": "..." }` |
| `PUT /api/cargos/:id` | Altera um cargo: `{ "designacao": "..." }` |
| `DELETE /api/cargos/:id` | Apaga um cargo (só se não tiver utilizadores) |

## Comandos

| Comando | O que faz |
| --- | --- |
| `npm run dev` | Arranca a API e reinicia-a sempre que gravas um ficheiro |
| `npm start` | Arranca a API (sem reiniciar sozinha) |
| `npm run typecheck` | Verifica se há erros de TypeScript |
