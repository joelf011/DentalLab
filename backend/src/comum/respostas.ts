import type { FastifyReply } from 'fastify';

// Respostas de sucesso com regras próprias (as de erro estão em erros.ts).

// Endereço base de todas as rotas da versão 1 da API (usado no app.ts e no cabeçalho Location).
export const PREFIXO_API = '/api/v1';

// Resposta 201 (criado): devolve { id } e o cabeçalho Location com o endereço do registo novo (regra de AI3).
// Ex.: enviarCriado(reply, 'cargos', 7)  →  201, Location: /api/v1/cargos/7, corpo { "id": 7 }
export function enviarCriado(reply: FastifyReply, recurso: string, id: number) {
  return reply.code(201).header('Location', `${PREFIXO_API}/${recurso}/${id}`).send({ id });
}
