import type { FastifyReply, FastifySchemaValidationError } from 'fastify';

// Erros da API: o formato das respostas de erro e as mensagens em português.

// Todas as respostas de erro da API têm este formato (regra de AI3):
//   { "codigo": 400, "mensagem": "Tem de indicar o nome e o NIF do cliente" }
//   { "codigo": 400, "mensagem": "...", "detalhes": [{ "campo": "nif", "problema": "..." }] }
// - codigo: o mesmo número do código HTTP da resposta;
// - mensagem: o texto para mostrar ao utilizador;
// - detalhes: só aparece quando o problema é de campos concretos do pedido.
export interface DetalheErro {
  campo: string;
  problema: string;
}

// O mesmo formato em esquema, para as respostas e a documentação ({ $ref: 'Erro#' }).
// Regista-se uma vez, em plugins/tratamento-erros.ts.
export const esquemaErro = {
  $id: 'Erro',
  type: 'object',
  description: 'Resposta de erro, igual em toda a API.',
  properties: {
    codigo: { type: 'integer', minimum: 400, maximum: 599, description: 'O mesmo número do código HTTP.' },
    mensagem: { type: 'string', description: 'Em português, pronta a mostrar ao utilizador.' },
    detalhes: {
      type: 'array',
      description: 'Só aparece quando o problema é de campos concretos do pedido.',
      items: {
        type: 'object',
        properties: { campo: { type: 'string' }, problema: { type: 'string' } },
        required: ['campo', 'problema'],
      },
    },
  },
  required: ['codigo', 'mensagem'],
};

// Envia uma resposta de erro. Nas rotas usa-se assim:
//   return enviarErro(reply, 404, 'O cliente não existe.');
export function enviarErro(reply: FastifyReply, codigo: number, mensagem: string, detalhes: DetalheErro[] = []) {
  const corpo = detalhes.length > 0 ? { codigo, mensagem, detalhes } : { codigo, mensagem };
  return reply.code(codigo).send(corpo);
}

// Mensagens para as regras das tabelas (CHECK e UNIQUE) que o utilizador pode violar.
// A chave é o nome da regra, tal como está em ModelosBaseDeDados/sql/01_tabelas.sql.
// Uma regra que não esteja aqui usa a mensagem genérica. Quem criar uma regra nova, acrescenta-a aqui.
const mensagensRegras: Record<string, string> = {
  // cliente e utilizador
  ck_cliente_nif: 'O NIF tem de ter 9 algarismos.',
  cliente_nif_key: 'Já existe um cliente com este NIF.',
  uq_utilizador_email: 'Já existe uma conta com este email.',
  cargo_designacao_key: 'Já existe um cargo com esta designação.',
  // pedidos de alteração dos dados da clínica
  uq_alteracao_cliente_pendente: 'Já existe um pedido de alteração à espera de aprovação.',
  ck_alteracao_cliente_dados: 'Indique pelo menos um dado a alterar.',
  ck_alteracao_cliente_motivo: 'Tem de indicar o motivo da rejeição.',
  // catálogo
  estado_ordem_designacao_key: 'Já existe um estado com esta designação.',
  tipo_trabalho_nome_key: 'Já existe um tipo de trabalho com este nome.',
  etapa_nome_key: 'Já existe uma etapa com este nome.',
  tipo_ficheiro_designacao_key: 'Já existe um tipo de ficheiro com esta designação.',
  pk_etapa_tipo_trabalho: 'Este tipo de trabalho já tem uma etapa nessa posição.',
  etapa_tipo_trabalho_ordem_check: 'A posição de uma etapa tem de ser 1 ou mais.',
  // ordens e trabalhos
  ck_ordem_idade: 'A idade do paciente tem de estar entre 0 e 130.',
  ck_ordem_sexo: 'O sexo do paciente tem de ser M ou F.',
  ck_ordem_aceitacao: 'Para aceitar a ordem é preciso indicar o prazo de entrega.',
  ck_trabalho_natureza: 'A natureza do trabalho tem de ser FISICO ou DIGITAL.',
  ck_trabalho_dente_fdi: 'Número de dente inválido (numeração FDI: 11 a 48, ou 51 a 85 nos dentes de leite).',
  // produção
  uq_etapa_trabalho_ordem: 'Este trabalho já tem uma etapa nessa posição.',
  etapa_trabalho_ordem_check: 'A posição de uma etapa tem de ser 1 ou mais.',
  ck_etapa_trabalho_inicio: 'Uma etapa só pode começar com um responsável.',
  ck_etapa_trabalho_conclusao: 'Uma etapa só pode ser concluída depois de iniciada.',
  // comunicação
  ck_comentario_associacao: 'Um comentário pertence a uma ordem ou a um trabalho, nunca aos dois.',
  ck_ficheiro_associacao: 'Um ficheiro pertence a uma ordem ou a um trabalho, nunca aos dois.',
};

// O que interessa de um erro (do PostgreSQL ou do Fastify)
interface Erro {
  code?: string; // código do erro (ex.: '23505')
  message: string;
  constraint?: string; // nome da regra violada (só nos erros do PostgreSQL)
}

// Para os erros conhecidos (da BD ou do Fastify), devolve o código HTTP e a mensagem para o utilizador.
// Devolve null quando o erro não é conhecido (aí é um erro inesperado: 500).
export function traduzirErro(erro: Erro): { codigo: number; mensagem: string } | null {
  const regra = erro.constraint ?? '';
  // Os erros nos dados enviados são todos 400 (pedido inválido).
  const dadosInvalidos = (mensagem: string) => ({ codigo: 400, mensagem });

  switch (erro.code) {
    // RAISE EXCEPTION sem código nas funções da BD: a mensagem já vem em português
    // (a regra dos códigos está no início do ModelosBaseDeDados/sql/03_funcoes.sql)
    case 'P0001':
      return dadosInvalidos(erro.message);

    // RAISE EXCEPTION ... USING ERRCODE = 'no_data_found': o registo pedido não existe
    case 'P0002':
      return { codigo: 404, mensagem: erro.message };

    // Valor repetido. É 409 (conflito) e não 400: os dados estão bem escritos,
    // mas chocam com um registo que já existe (regra de AI3).
    // Vem de uma função (RAISE ... USING ERRCODE = 'unique_violation', com a mensagem dela)
    // ou da própria tabela (regra UNIQUE, com o nome da regra).
    case '23505':
      if (!erro.constraint) {
        return { codigo: 409, mensagem: erro.message };
      }
      return { codigo: 409, mensagem: mensagensRegras[regra] ?? 'Já existe um registo com estes dados.' };

    // RAISE ... USING ERRCODE = 'object_not_in_prerequisite_state' ou 'object_in_use':
    // o pedido choca com o estado atual (ex.: conta já aprovada, cargo com utilizadores). Também é 409.
    case '55000':
    case '55006':
      return { codigo: 409, mensagem: erro.message };

    // CHECK: valor que não cumpre uma regra da tabela
    case '23514':
      return dadosInvalidos(mensagensRegras[regra] ?? 'Os dados não cumprem as regras definidas.');

    // FOREIGN KEY: refere um registo que não existe (ou apaga um que ainda está a ser usado)
    case '23503':
      return dadosInvalidos('A operação refere um registo que não existe ou que ainda está a ser usado.');

    // NOT NULL: falta um dado obrigatório
    case '23502':
      return dadosInvalidos('Falta um dado obrigatório.');

    // texto maior do que a coluna aceita
    case '22001':
      return dadosInvalidos('Um dos textos é demasiado longo.');

    // formato errado: letras num número, número grande demais, data impossível...
    case '22P02':
    case '22003':
    case '22007':
    case '22008':
      return dadosInvalidos('Há um valor com formato inválido.');

    // erros do Fastify ao ler o corpo do pedido
    case 'FST_ERR_CTP_INVALID_JSON_BODY':
      return dadosInvalidos('O corpo do pedido não é JSON válido.');
    case 'FST_ERR_CTP_EMPTY_JSON_BODY':
      return dadosInvalidos('O pedido diz que envia JSON (Content-Type: application/json) mas vem sem corpo.');
    case 'FST_ERR_CTP_BODY_TOO_LARGE':
      return { codigo: 413, mensagem: 'O pedido é demasiado grande.' };
    // erros do envio de ficheiros (@fastify/multipart, modulos/ficheiros)
    case 'FST_REQ_FILE_TOO_LARGE':
      return { codigo: 413, mensagem: 'O ficheiro é demasiado grande (máximo 50 MB).' };
    case 'FST_FILES_LIMIT':
      return { codigo: 413, mensagem: 'Envie um ficheiro de cada vez.' };
    case 'FST_INVALID_MULTIPART_CONTENT_TYPE':
      return { codigo: 415, mensagem: 'O ficheiro tem de ser enviado em multipart/form-data, no campo "ficheiro".' };
    case 'FST_ERR_CTP_INVALID_MEDIA_TYPE':
      return { codigo: 415, mensagem: 'Os dados têm de ser enviados em JSON (Content-Type: application/json).' };

    default:
      return null;
  }
}

// Nomes dos tipos, para as mensagens dos esquemas
const nomesTipos: Record<string, string> = {
  string: 'texto',
  integer: 'um número inteiro',
  number: 'um número',
  boolean: 'true ou false',
  object: 'um objeto JSON',
  array: 'uma lista',
  null: 'null',
};

// Mensagens para os formatos (pattern) usados nos esquemas. A chave é o próprio pattern.
// Um pattern que não esteja aqui usa a mensagem genérica.
const mensagensFormatos: Record<string, string> = {
  '^[0-9]{9}$': 'Tem de ter 9 algarismos.',
};

// Problemas encontrados pelos esquemas das rotas (plugins/validacao.ts): cada um passa a { campo, problema }.
// Exemplo: [{ "campo": "password", "problema": "Tem de ter pelo menos 8 caracteres." }]
export function traduzirValidacao(problemas: FastifySchemaValidationError[]): DetalheErro[] {
  return problemas.map((erro) => {
    const valores = erro.params;
    // O caminho vem como "/email" ou "/trabalhos/0/natureza"; passa a "email" ou "trabalhos[0].natureza".
    const caminho = erro.instancePath.slice(1).replace(/\/(\d+)/g, '[$1]').replace(/\//g, '.');
    // Junta ao caminho o nome de um campo (ex.: o que falta dentro de trabalhos[1])
    const dentroDe = (nome: unknown) => (caminho ? `${caminho}.${nome}` : String(nome));
    // Vazio quer dizer o corpo todo
    let campo = caminho || 'corpo';
    let problema: string;

    switch (erro.keyword) {
      case 'required':
        campo = dentroDe(valores.missingProperty);
        problema = 'É obrigatório.';
        break;
      case 'additionalProperties':
        campo = dentroDe(valores.additionalProperty);
        problema = 'Este campo não existe.';
        break;
      case 'type':
        // Pode ser mais do que um tipo, ex.: "string,null"
        problema = `Tem de ser ${String(valores.type)
          .split(',')
          .map((tipo) => nomesTipos[tipo] ?? tipo)
          .join(' ou ')}.`;
        break;
      case 'minLength':
        problema = valores.limit === 1 ? 'Não pode estar vazio.' : `Tem de ter pelo menos ${valores.limit} caracteres.`;
        break;
      case 'maxLength':
        problema = `Tem de ter no máximo ${valores.limit} caracteres.`;
        break;
      case 'minimum':
        problema = `Tem de ser ${valores.limit} ou mais.`;
        break;
      case 'maximum':
        problema = `Tem de ser ${valores.limit} ou menos.`;
        break;
      case 'format':
        problema = valores.format === 'email' ? 'Tem de ser um email válido.' : 'Não tem o formato certo.';
        break;
      case 'pattern':
        problema = mensagensFormatos[String(valores.pattern)] ?? 'Não tem o formato certo.';
        break;
      case 'enum':
        problema = `Tem de ser um destes valores: ${(valores.allowedValues as unknown[]).join(', ')}.`;
        break;
      case 'minProperties':
        problema = 'Indique pelo menos um campo.';
        break;
      case 'minItems':
        problema = valores.limit === 1 ? 'Indique pelo menos um.' : `Indique pelo menos ${valores.limit}.`;
        break;
      case 'maxItems':
        problema = `Indique no máximo ${valores.limit}.`;
        break;
      default:
        problema = 'Valor inválido.';
    }
    return { campo, problema };
  });
}
