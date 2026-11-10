-- =====================================================================
-- ABD — Lab CD (DentalLab) — 02. Vistas
-- Origem: modelofisico.sql (vw_trabalho_etapa_atual) e pasta crud/ (restantes)
-- Correr depois de 01_tabelas.sql.
-- =====================================================================

-- (origem: modelofisico.sql)
-- Etapa em que cada trabalho se encontra (primeira por concluir)
CREATE OR REPLACE VIEW vw_trabalho_etapa_atual AS
SELECT DISTINCT ON (et.trabalho_id)
       et.trabalho_id,
       et.id AS etapa_trabalho_id,
       et.nome,
       et.ordem,
       et.responsavel_id,
       et.data_inicio
FROM etapa_trabalho et
WHERE et.data_conclusao IS NULL
ORDER BY et.trabalho_id, et.ordem;


-- (origem: crud/crud_cargo_utilizador.sql)
-- cargo

CREATE OR REPLACE VIEW vw_cargo AS
SELECT c.id, c.designacao
FROM cargo c;


-- (origem: crud/crud_cargo_utilizador.sql)
-- utilizador

-- Não mostra o password_hash.
-- cargo_id e cliente_id estão no fim porque foram acrescentados depois
-- (o CREATE OR REPLACE VIEW só aceita colunas novas no fim).
CREATE OR REPLACE VIEW vw_utilizador AS
SELECT u.id, u.nome, u.email,
       c.designacao AS cargo,
       cl.nome      AS cliente,
       u.password_temporaria, u.ativo,
       u.aprovado_por, u.data_aprovacao, u.criado_em,
       u.cargo_id, u.cliente_id
FROM utilizador u
JOIN cargo c         ON c.id = u.cargo_id
LEFT JOIN cliente cl ON cl.id = u.cliente_id;


-- (origem: crud/crud_cliente_etapa_trabalho.sql)
-- cliente

CREATE OR REPLACE VIEW vw_cliente AS
SELECT c.id, c.nome, c.nif, c.morada_faturacao, c.email, c.telefone, c.ativo, c.criado_em
FROM cliente c;


-- (origem: crud/crud_cliente_etapa_trabalho.sql)
-- etapa_trabalho

CREATE OR REPLACE VIEW vw_etapa_trabalho AS
SELECT et.id, et.trabalho_id, et.nome, et.ordem,
       u.nome AS responsavel,
       et.data_inicio, et.data_conclusao,
       CASE WHEN et.data_conclusao IS NOT NULL THEN 'Concluída'
            WHEN et.data_inicio IS NOT NULL    THEN 'Em curso'
            ELSE 'Por iniciar'
       END AS estado
FROM etapa_trabalho et
JOIN trabalho t        ON t.id = et.trabalho_id
LEFT JOIN utilizador u ON u.id = et.responsavel_id
WHERE t.eliminado_em IS NULL;


-- (origem: crud/crud_alteracao_cliente.sql)
-- Mostra cada pedido ao lado dos dados atuais da clínica, para o Administrador comparar.
CREATE OR REPLACE VIEW vw_alteracao_cliente AS
SELECT a.id, a.cliente_id,
       up.nome AS pedido_por,
       a.data_pedido,
       -- dados atuais
       c.nome             AS nome_atual,
       c.morada_faturacao AS morada_faturacao_atual,
       c.email            AS email_atual,
       c.telefone         AS telefone_atual,
       -- dados pedidos (NULL = não muda)
       a.nome, a.morada_faturacao, a.email, a.telefone,
       -- decisão
       a.estado,
       ud.nome AS decidido_por,
       a.data_decisao, a.motivo_rejeicao
FROM alteracao_cliente a
JOIN cliente c          ON c.id = a.cliente_id
JOIN utilizador up      ON up.id = a.pedido_por
LEFT JOIN utilizador ud ON ud.id = a.decidido_por;


-- (origem: crud/crud_estado_ordem_ordem_trabalho.sql)
-- estado_ordem

CREATE OR REPLACE VIEW vw_estado_ordem AS
SELECT e.id, e.designacao
FROM estado_ordem e;


-- (origem: crud/crud_estado_ordem_ordem_trabalho.sql)
-- ordem_trabalho

-- Não mostra as ordens eliminadas.
CREATE OR REPLACE VIEW vw_ordem_trabalho AS
SELECT o.id,
       c.nome  AS cliente,
       uc.nome AS criado_por,
       ua.nome AS aceite_por,
       e.designacao AS estado,
       o.nome_medico_responsavel, o.nome_paciente, o.sexo_paciente, o.idade_paciente,
       o.data_proxima_consulta, o.observacoes, o.prazo_entrega,
       o.data_criacao, o.data_aceitacao, o.data_inicio, o.data_conclusao, o.data_entrega,
       o.motivo_espera, o.motivo_rejeicao
FROM ordem_trabalho o
JOIN cliente c          ON c.id = o.cliente_id
JOIN utilizador uc      ON uc.id = o.criado_por
LEFT JOIN utilizador ua ON ua.id = o.aceite_por
JOIN estado_ordem e     ON e.id = o.estado_ordem_id
WHERE o.eliminado_em IS NULL;


-- (origem: crud/crud_tipo_trabalho_trabalho.sql)
-- tipo_trabalho

CREATE OR REPLACE VIEW vw_tipo_trabalho AS
SELECT t.id, t.nome, t.descricao, t.ativo
FROM tipo_trabalho t;


-- (origem: crud/crud_tipo_trabalho_trabalho.sql)
-- trabalho

-- Mostra os dentes (trabalho_dente) e a etapa atual (vista vw_trabalho_etapa_atual
-- do modelo físico). Não mostra trabalhos eliminados.
CREATE OR REPLACE VIEW vw_trabalho AS
SELECT t.id, t.ordem_trabalho_id,
       tt.nome AS tipo_trabalho,
       t.natureza, t.cor,
       ARRAY(SELECT d.numero_fdi FROM trabalho_dente d
             WHERE d.trabalho_id = t.id ORDER BY d.numero_fdi) AS dentes,
       ea.nome AS etapa_atual
FROM trabalho t
JOIN tipo_trabalho tt ON tt.id = t.tipo_trabalho_id
LEFT JOIN vw_trabalho_etapa_atual ea ON ea.trabalho_id = t.id
WHERE t.eliminado_em IS NULL;
