// Peças dos esquemas das rotas, usadas por todos os módulos (cada módulo tem o seu <area>.esquemas.ts).
//
// Um esquema descreve os dados de um pedido ou de uma resposta. O Fastify usa-os para três coisas:
// - validar os pedidos (plugins/validacao.ts): o que não cumpre o esquema dá 400 e a rota nem corre;
// - escrever as respostas: só saem os campos que estão no esquema, por isso nada sai por engano;
// - gerar a documentação da API (plugins/documentacao.ts).

// :id no endereço (ex.: /cargos/5): número inteiro, 1 ou mais
export const paramId = {
  type: 'object',
  properties: {
    id: { type: 'integer', minimum: 1, description: 'Identificador do registo.' },
  },
  required: ['id'],
};

// Uma palavra-passe nova: pelo menos 8 caracteres. No máximo 72, porque o bcrypt só usa os primeiros 72 bytes
// e ignorava o resto sem avisar.
export const palavraPasseNova = { type: 'string', minLength: 8, maxLength: 72 };

// O Cache-Control de cada resposta (plugins/cache.ts), para aparecer na documentação
function cacheControl(valor: string): Record<string, object> {
  return { 'Cache-Control': { type: 'string', enum: [valor] } };
}

// Resposta de sucesso com corpo. Por omissão, a cache é a das leituras (GET) de quem tem login.
// Uso: 200: resposta('Lista dos cargos.', { type: 'array', items: { $ref: 'Cargo#' } })
export function resposta(descricao: string, esquema: object, cache = 'private, no-cache') {
  return { description: descricao, headers: cacheControl(cache), ...esquema };
}

// { id } nas respostas de escrita
const esquemaId = {
  type: 'object',
  properties: { id: { type: 'integer' } },
  required: ['id'],
};

// 201: registo criado (enviarCriado, em comum/respostas.ts)
export const respostaCriado = {
  description: 'Criado. Devolve o id e o cabeçalho Location com o endereço do registo novo.',
  headers: {
    Location: { type: 'string', description: 'Endereço do registo novo, ex.: /api/v1/cargos/5' },
    ...cacheControl('no-store'),
  },
  ...esquemaId,
};

// 200 com { id }: alteração ou ação feita
export const respostaId = resposta('Feito. Devolve o id do registo.', esquemaId, 'no-store');

// 204: feito, sem corpo na resposta (DELETE)
export const respostaSemConteudo = {
  description: 'Feito. A resposta não tem corpo.',
  headers: cacheControl('no-store'),
  type: 'null',
};

// Uma resposta de erro (formato Erro, comum/erros.ts) com uma descrição própria.
// Uso: 401: respostaErro('Email ou palavra-passe incorretos.')
export function respostaErro(descricao: string) {
  return { description: descricao, headers: cacheControl('no-store'), $ref: 'Erro#' };
}

// O que quer dizer cada código de erro, para a documentação
const descricoesErros = {
  400: 'Dados inválidos. Quando o problema é de campos concretos, a lista vem em detalhes.',
  401: 'Sem sessão, sessão expirada ou conta desativada.',
  403: 'O cargo de quem está ligado não pode fazer isto.',
  404: 'O registo não existe.',
  409: 'Conflito: já existe um registo com esse valor, ou o registo não está no estado certo para isto.',
  413: 'O pedido (ou o ficheiro enviado) é demasiado grande.',
  415: 'O formato do pedido não é o esperado (Content-Type).',
  500: 'Erro inesperado na API.',
  503: 'A API não consegue ligar-se à base de dados.',
};

type CodigoErro = keyof typeof descricoesErros;

// Respostas de erro de uma rota, todas no formato Erro (comum/erros.ts). O 500 junta-se sempre.
// Uso: response: { 200: ..., ...respostasErro(400, 401, 404) }
export function respostasErro(...codigos: CodigoErro[]) {
  const respostas: Record<number, object> = {};
  for (const codigo of [...codigos, 500] as CodigoErro[]) {
    const erro = respostaErro(descricoesErros[codigo]);
    // O 401 diz no cabeçalho WWW-Authenticate porque falhou (comum/acesso.ts)
    if (codigo === 401) {
      erro.headers = {
        ...erro.headers,
        'WWW-Authenticate': {
          type: 'string',
          enum: ['Bearer', 'Bearer error="invalid_token"'],
          description: 'Bearer: não veio token. Bearer error="invalid_token": o token é falso, expirou ou a conta foi desativada.',
        },
      };
    }
    respostas[codigo] = erro;
  }
  return respostas;
}
