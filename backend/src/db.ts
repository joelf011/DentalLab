import pg from 'pg';
import { config } from './config.ts';

// O PostgreSQL devolve os BIGINT (os nossos ids) como texto: "1" em vez de 1.
// Os ids nunca chegam perto do limite dos números do JavaScript, por isso convertemos.
pg.types.setTypeParser(pg.types.builtins.INT8, (valor) => Number(valor));

// As datas sem hora (DATE) ficam como texto "2026-11-03".
// Sem isto, o fuso horário podia fazer a data aparecer como o dia anterior.
pg.types.setTypeParser(pg.types.builtins.DATE, (valor) => valor);

// Pool = conjunto de ligações à base de dados, que a API vai reutilizando.
// Usa-se assim: const resultado = await bd.query('SELECT ...');
export const bd = new pg.Pool(config.bd);
