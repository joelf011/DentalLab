import fastifyMultipart from '@fastify/multipart';
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { randomUUID } from 'node:crypto';
import { createReadStream, createWriteStream, existsSync, mkdirSync, unlinkSync } from 'node:fs';
import { basename, extname, join } from 'node:path';
import { pipeline } from 'node:stream/promises';
import { type UtilizadorLogin, exigirCargo, exigirLogin, podeVerOrdem } from '../../comum/acesso.ts';
import { bd, escreverComo } from '../../comum/bd.ts';
import { enviarErro } from '../../comum/erros.ts';
import { enviarCriado } from '../../comum/respostas.ts';
import { configuracao } from '../../configuracao.ts';
import {
  descarregarFicheiro,
  enviarFicheiroOrdem,
  enviarFicheiroTrabalho,
  esquemaFicheiro,
  listarFicheirosOrdem,
  listarFicheirosTrabalho,
} from './ficheiros.esquemas.ts';

// Rotas dos ficheiros (STL, fotografias, documentos). Um ficheiro pertence a uma ordem ou a um trabalho:
// - ordem: a clínica vê-o (ex.: os STL e as fotografias que envia com a encomenda);
// - trabalho: interno do laboratório (ex.: fotografias da produção).
// O ficheiro fica guardado numa pasta do servidor (configuracao.ficheiros.pasta), com um nome aleatório;
// a BD guarda o nome original e onde está (localizacao). Ler: vista vw_ficheiro. Escrever: fn_ficheiro_crud.

// Extensões aceites, e o tipo de conteúdo com que cada uma é descarregada
const tiposConteudo: Record<string, string> = {
  '.stl': 'model/stl',
  '.zip': 'application/zip',
  '.ply': 'application/octet-stream',
  '.obj': 'model/obj',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.heic': 'image/heic',
  '.webp': 'image/webp',
  '.pdf': 'application/pdf',
};

const pasta = configuracao.ficheiros.pasta;

// Recebe o ficheiro do pedido, guarda-o na pasta e regista-o na BD (na ordem OU no trabalho).
// Se algo falhar depois de o ficheiro estar gravado, apaga-o, para não ficarem ficheiros perdidos na pasta.
async function guardarFicheiro(
  request: FastifyRequest,
  reply: FastifyReply,
  associacao: { ordemId?: number; trabalhoId?: number },
) {
  const { tipo } = request.query as { tipo: string };
  const parte = await request.file();
  if (!parte || parte.fieldname !== 'ficheiro') {
    return enviarErro(reply, 400, 'Envie o ficheiro no campo "ficheiro" (multipart/form-data).');
  }
  const extensao = extname(parte.filename).toLowerCase();
  if (!(extensao in tiposConteudo)) {
    parte.file.resume(); // descarta o que falta receber
    return enviarErro(reply, 400, 'Este tipo de ficheiro não é aceite.', [
      { campo: 'ficheiro', problema: `Extensões aceites: ${Object.keys(tiposConteudo).join(', ')}.` },
    ]);
  }

  // Nome aleatório no disco: dois ficheiros com o mesmo nome não se substituem,
  // e o nome enviado (que pode ter "../") nunca é usado como caminho.
  const nomeGuardado = `${randomUUID()}${extensao}`;
  const caminho = join(pasta, nomeGuardado);
  try {
    await pipeline(parte.file, createWriteStream(caminho));
  } catch (erro) {
    // a ligação caiu a meio do envio (por exemplo): apaga o que já estava gravado
    if (existsSync(caminho)) {
      unlinkSync(caminho);
    }
    throw erro;
  }
  // Passou dos 50 MB: o plugin corta o ficheiro e marca-o como "truncated" (não chega a dar erro aqui)
  if (parte.file.truncated) {
    unlinkSync(caminho);
    return enviarErro(reply, 413, 'O ficheiro é demasiado grande (máximo 50 MB).');
  }

  try {
    const tipoFicheiro = await bd.query('SELECT id FROM vw_tipo_ficheiro WHERE designacao = $1', [tipo]);
    const resultado = await escreverComo(
      request.user.id,
      `SELECT fn_ficheiro_crud(
         p_operacao          => 'CREATE',
         p_id                => NULL,
         p_tipo_ficheiro_id  => $1,
         p_ordem_trabalho_id => $2,
         p_trabalho_id       => $3,
         p_carregado_por     => $4,
         p_nome              => $5,
         p_localizacao       => $6
       ) AS id`,
      [
        tipoFicheiro.rows[0].id,
        associacao.ordemId ?? null,
        associacao.trabalhoId ?? null,
        request.user.id,
        parte.filename.slice(0, 255),
        nomeGuardado,
      ],
    );
    return enviarCriado(reply, 'ficheiros', resultado.rows[0].id);
  } catch (erro) {
    unlinkSync(caminho);
    throw erro;
  }
}

// Pode descarregar? Ficheiros da ordem: quem pode ver a ordem. Ficheiros de trabalho: só o laboratório.
async function podeDescarregar(utilizador: UtilizadorLogin, ficheiro: { ordem_trabalho_id: number | null }) {
  if (ficheiro.ordem_trabalho_id !== null) {
    return podeVerOrdem(utilizador, ficheiro.ordem_trabalho_id);
  }
  return utilizador.cargo !== 'Cliente';
}

export async function rotasFicheiros(app: FastifyInstance) {
  // A pasta dos ficheiros é criada se ainda não existir
  mkdirSync(pasta, { recursive: true });

  // Lê os pedidos multipart/form-data (os ficheiros), só neste módulo: um ficheiro de cada vez, até 50 MB
  app.register(fastifyMultipart, { limits: { files: 1, fileSize: configuracao.ficheiros.tamanhoMaximo } });

  // Esquema com nome, usado pelas respostas das listas
  app.addSchema(esquemaFicheiro);

  const laboratorio = exigirCargo('Administrador', 'Colaborador');

  // POST /api/v1/ordens/1/ficheiros?tipo=STL: envia um ficheiro para a ordem (a clínica vê-o)
  app.post('/ordens/:id/ficheiros', { schema: enviarFicheiroOrdem, preHandler: exigirLogin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    if (!(await podeVerOrdem(request.user, id))) {
      return enviarErro(reply, 404, 'A ordem de trabalho não existe.');
    }
    return guardarFicheiro(request, reply, { ordemId: id });
  });

  // POST /api/v1/trabalhos/1/ficheiros?tipo=Fotografia: envia um ficheiro interno do laboratório
  app.post('/trabalhos/:id/ficheiros', { schema: enviarFicheiroTrabalho, preHandler: laboratorio }, async (request, reply) => {
    const { id } = request.params as { id: number };
    // Se o trabalho não existir, a fn_ficheiro_crud responde 404 (e o ficheiro gravado é apagado)
    return guardarFicheiro(request, reply, { trabalhoId: id });
  });

  // GET /api/v1/ordens/1/ficheiros: os ficheiros da ordem
  app.get('/ordens/:id/ficheiros', { schema: listarFicheirosOrdem, preHandler: exigirLogin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    if (!(await podeVerOrdem(request.user, id))) {
      return enviarErro(reply, 404, 'A ordem de trabalho não existe.');
    }
    const resultado = await bd.query('SELECT * FROM vw_ficheiro WHERE ordem_trabalho_id = $1 ORDER BY data_carregamento', [id]);
    return resultado.rows;
  });

  // GET /api/v1/trabalhos/1/ficheiros: os ficheiros internos do trabalho
  app.get('/trabalhos/:id/ficheiros', { schema: listarFicheirosTrabalho, preHandler: laboratorio }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const trabalho = await bd.query('SELECT id FROM vw_trabalho WHERE id = $1', [id]);
    if (trabalho.rows.length === 0) {
      return enviarErro(reply, 404, 'O trabalho não existe.');
    }
    const resultado = await bd.query('SELECT * FROM vw_ficheiro WHERE trabalho_id = $1 ORDER BY data_carregamento', [id]);
    return resultado.rows;
  });

  // GET /api/v1/ficheiros/1: descarrega o ficheiro, com o nome original
  app.get('/ficheiros/:id', { schema: descarregarFicheiro, preHandler: exigirLogin }, async (request, reply) => {
    const { id } = request.params as { id: number };
    const resultado = await bd.query('SELECT * FROM vw_ficheiro WHERE id = $1', [id]);
    const ficheiro = resultado.rows[0];
    // Ficheiro que não existe, ou que quem pede não pode ver: 404 nos dois casos.
    if (!ficheiro || !(await podeDescarregar(request.user, ficheiro))) {
      return enviarErro(reply, 404, 'O ficheiro não existe.');
    }
    // basename: mesmo que a BD tivesse um caminho, nunca se sai da pasta dos ficheiros
    const caminho = join(pasta, basename(ficheiro.localizacao));
    if (!existsSync(caminho)) {
      return enviarErro(reply, 404, 'O ficheiro já não está no servidor.');
    }
    const extensao = extname(ficheiro.localizacao).toLowerCase();
    reply.header('Content-Type', tiposConteudo[extensao] ?? 'application/octet-stream');
    // attachment: o navegador descarrega (com o nome original) em vez de o abrir
    reply.header('Content-Disposition', `attachment; filename*=UTF-8''${encodeURIComponent(ficheiro.nome)}`);
    return reply.send(createReadStream(caminho));
  });
}
