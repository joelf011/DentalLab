import pg from 'pg';
import { configuracao } from '../configuracao.ts';

// O PostgreSQL devolve os BIGINT (os nossos ids) como texto: "1" em vez de 1.
// Os ids nunca chegam perto do limite dos números do JavaScript, por isso convertemos.
pg.types.setTypeParser(pg.types.builtins.INT8, (valor) => Number(valor));

// As datas sem hora (DATE) ficam como texto "2026-11-03".
// Sem isto, o fuso horário podia fazer a data aparecer como o dia anterior.
pg.types.setTypeParser(pg.types.builtins.DATE, (valor) => valor);

// Pool = conjunto de ligações à base de dados, que a API vai reutilizando.
// Para ler usa-se assim: const resultado = await bd.query('SELECT * FROM vw_...');
export const bd = new pg.Pool(configuracao.bd);

// Para escrever (funções fn_* e procedimentos pr_*) usa-se o escreverComo, com o id de quem faz a alteração:
//   const resultado = await escreverComo(request.user.id, 'SELECT fn_..._crud(...) AS id', [...]);
// Assim, os triggers de auditoria registam em registo_auditoria quem fez cada alteração.
// O pr_definir_utilizador só vale dentro de uma transação, por isso tudo é feito numa só ligação:
//   BEGIN → CALL pr_definir_utilizador(id) → o SQL → COMMIT (ou ROLLBACK, se der erro).
// O idUtilizador é null quando ainda não há ninguém com sessão iniciada (ex.: o registo de uma clínica).
export async function escreverComo(idUtilizador: number | null, sql: string, valores: unknown[] = []) {
  const ligacao = await bd.connect();
  try {
    await ligacao.query('BEGIN');
    await ligacao.query('CALL pr_definir_utilizador($1)', [idUtilizador]);
    const resultado = await ligacao.query(sql, valores);
    await ligacao.query('COMMIT');
    return resultado;
  } catch (erro) {
    await ligacao.query('ROLLBACK');
    throw erro;
  } finally {
    // devolve a ligação ao pool, corra bem ou mal
    ligacao.release();
  }
}
