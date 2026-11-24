import type { FastifyInstance } from 'fastify';
import { exigirCargo } from '../../comum/acesso.ts';
import { escreverComo } from '../../comum/bd.ts';
import { alterarTrabalho } from './trabalhos.esquemas.ts';

// Rotas dos trabalhos (cada trabalho pertence a uma ordem: ex.: a coroa de um paciente).
// Os trabalhos criam-se com a encomenda (POST /ordens). Escrever: fn_trabalho_crud.
// As regras dos dados estão em trabalhos.esquemas.ts.

// O que o Administrador pode mudar num trabalho
interface DadosTrabalho {
  natureza?: string;
  cor?: string;
  dentes?: number[];
}

export async function rotasTrabalhos(app: FastifyInstance) {
  // PATCH /api/v1/trabalhos/1: o Administrador altera um trabalho (só os campos que vierem)
  app.patch('/trabalhos/:id', { schema: alterarTrabalho, preHandler: exigirCargo('Administrador') }, async (request) => {
    const { id } = request.params as { id: number };
    const dados = request.body as DadosTrabalho;
    const resultado = await escreverComo(
      request.user.id,
      `SELECT fn_trabalho_crud(
         p_operacao => 'UPDATE',
         p_id       => $1,
         p_natureza => $2,
         p_cor      => $3,
         p_dentes   => $4
       ) AS id`,
      [id, dados.natureza, dados.cor, dados.dentes],
    );
    return resultado.rows[0];
  });
}
