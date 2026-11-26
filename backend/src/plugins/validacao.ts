import { Ajv } from 'ajv';
import formatos from 'ajv-formats';
import type { FastifySchemaCompiler, FastifyServerOptions } from 'fastify';

// Validação dos pedidos com os esquemas das rotas (ficheiros <area>.esquemas.ts).
// O Fastify confirma os dados antes de a rota correr. Se não cumprirem o esquema, a rota nem chega a correr
// e a resposta é um 400 com a lista dos problemas (ver plugins/tratamento-erros.ts).
//
// Há dois validadores, porque as partes do pedido chegam de forma diferente:
// - endereço (/clientes/5?por_aprovar=true): chega tudo como texto, por isso "5" passa a 5 e "true" passa a true;
// - corpo (JSON): os tipos já vêm certos e não se converte nada. Assim, { "ativo": null } dá erro,
//   em vez de passar a false sem ninguém dar por isso.
// Os dois mostram todos os problemas de uma vez (allErrors) e nunca apagam campos às escondidas
// (removeAdditional: false): um campo que não está no esquema dá erro.
function criarValidador(converterTipos: boolean) {
  const ajv = new Ajv({ allErrors: true, coerceTypes: converterTipos, removeAdditional: false, useDefaults: true });
  // Formatos como "email". O .default é por causa da forma como este pacote está publicado.
  formatos.default(ajv);
  return ajv;
}

const validadorEndereco = criarValidador(true);
const validadorCorpo = criarValidador(false);

// Escolhe o validador certo para cada parte do pedido.
const validar: FastifySchemaCompiler<object> = ({ schema, httpPart }) => {
  const validador = httpPart === 'body' ? validadorCorpo : validadorEndereco;
  return validador.compile(schema);
};

// O tipo que o Fastify pede nas opções (schemaController.compilersFactory.buildValidator)
type FabricaValidadores = NonNullable<NonNullable<FastifyServerOptions['schemaController']>['compilersFactory']>['buildValidator'];

// Entra nas opções do Fastify (app.ts), e não com app.setValidatorCompiler: os módulos que registam
// esquemas com nome (app.addSchema) recriam o validador a partir daqui, e assim usam sempre estes dois.
// Os esquemas com nome são só para as respostas; os pedidos não os usam, por isso não se passam ao validador.
// O "as unknown as": o Fastify chama a função com { schema, httpPart }, como em validar, mas os tipos
// do pacote descrevem-na de outra forma.
export const construirValidador = (() => validar) as unknown as FabricaValidadores;
