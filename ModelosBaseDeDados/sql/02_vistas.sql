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
SELECT c.id, c.nome, c.nif, c.morada_faturacao, c.email, c.telefone, c.ativo, c.criado_em,
       -- no fim (acrescentados depois), para o ecrã Clientes do backoffice:
       -- o estado (Suspenso, A aguardar validação ou Ativo) e os trabalhos das ordens por acabar
       CASE
           WHEN NOT c.ativo THEN 'Suspenso'
           WHEN EXISTS (SELECT 1 FROM utilizador u
                        WHERE u.cliente_id = c.id AND u.ativo AND u.data_aprovacao IS NULL)
               THEN 'A aguardar validação'
           ELSE 'Ativo'
       END AS estado,
       (SELECT count(*)
        FROM trabalho t
        JOIN ordem_trabalho o ON o.id = t.ordem_trabalho_id
        JOIN estado_ordem e   ON e.id = o.estado_ordem_id
        WHERE o.cliente_id = c.id
          AND o.eliminado_em IS NULL AND t.eliminado_em IS NULL
          AND e.designacao NOT IN ('Concluído', 'Entregue', 'Rejeitado')) AS trabalhos_ativos
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
       END AS estado,
       -- no fim (acrescentado depois): a API confirma quem é o responsável da etapa
       et.responsavel_id
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
       o.motivo_espera, o.motivo_rejeicao,
       -- ids no fim (acrescentados depois): a API filtra as ordens de cada clínica e pelo estado
       o.cliente_id, o.estado_ordem_id
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


-- (origem: crud/crud_etapa.sql)
-- etapa (catálogo das etapas de produção)

CREATE OR REPLACE VIEW vw_etapa AS
SELECT e.id, e.nome, e.descricao, e.ativa
FROM etapa e;


-- (origem: crud/crud_etapa_tipo_trabalho.sql)
-- Etapas configuradas para cada tipo de trabalho, pela ordem.

CREATE OR REPLACE VIEW vw_etapa_tipo_trabalho AS
SELECT ett.tipo_trabalho_id, ett.ordem, ett.etapa_id, e.nome
FROM etapa_tipo_trabalho ett
JOIN etapa e ON e.id = ett.etapa_id
ORDER BY ett.tipo_trabalho_id, ett.ordem;

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


-- ---------------------------------------------------------------------
-- Comunicação: comentários, notificações e ficheiros
-- ---------------------------------------------------------------------

-- comentario
-- Um comentário pertence a uma ordem (a clínica vê-o) ou a um trabalho (nota interna do laboratório).
-- Não mostra os comentários eliminados.
CREATE OR REPLACE VIEW vw_comentario AS
SELECT c.id, c.ordem_trabalho_id, c.trabalho_id,
       c.utilizador_id,
       u.nome      AS autor,
       ca.designacao AS cargo_autor,
       c.conteudo, c.data_criacao, c.data_edicao
FROM comentario c
JOIN utilizador u ON u.id = c.utilizador_id
JOIN cargo ca     ON ca.id = u.cargo_id
WHERE c.eliminado_em IS NULL;


-- notificacao
CREATE OR REPLACE VIEW vw_notificacao AS
SELECT n.id, n.utilizador_id, n.ordem_trabalho_id, n.trabalho_id,
       n.mensagem, n.data_criacao, n.data_leitura,
       n.data_leitura IS NOT NULL AS lida
FROM notificacao n;


-- tipo_ficheiro (STL, Fotografia, Documento, Outro)
CREATE OR REPLACE VIEW vw_tipo_ficheiro AS
SELECT t.id, t.designacao
FROM tipo_ficheiro t;


-- ficheiro
-- localizacao é onde o ficheiro está guardado no servidor da API (só a API a usa).
-- Não mostra os ficheiros eliminados.
CREATE OR REPLACE VIEW vw_ficheiro AS
SELECT f.id, f.ordem_trabalho_id, f.trabalho_id,
       tf.designacao AS tipo,
       f.nome, f.localizacao,
       f.carregado_por AS carregado_por_id,
       u.nome AS carregado_por,
       f.data_carregamento
FROM ficheiro f
JOIN tipo_ficheiro tf ON tf.id = f.tipo_ficheiro_id
JOIN utilizador u     ON u.id = f.carregado_por
WHERE f.eliminado_em IS NULL;


-- ---------------------------------------------------------------------
-- Registo de Atividades (auditoria)
-- ---------------------------------------------------------------------

-- Cada linha de registo_auditoria (preenchida pelo trigger fn_trg_auditoria), com quem fez a alteração
-- e uma descrição em português. As ações mais comuns têm uma descrição própria; as outras ficam com uma
-- descrição geral ("Alterou a clínica n.º 3"). Os valores antes e depois ficam para ver o pormenor.
CREATE OR REPLACE VIEW vw_registo_auditoria AS
SELECT a.id, a.data_hora, a.utilizador_id,
       u.nome       AS autor,
       c.designacao AS cargo_autor,
       a.acao, a.entidade_afetada, a.id_entidade_afetada,
       CASE
           -- ordens: criada, e cada mudança de estado
           WHEN a.entidade_afetada = 'ordem_trabalho' AND a.acao = 'INSERT'
               THEN format('Criou a ordem n.º %s', a.id_entidade_afetada)
           WHEN a.entidade_afetada = 'ordem_trabalho' AND a.acao = 'UPDATE'
                AND ea.id IS DISTINCT FROM ep.id
               THEN format('A ordem n.º %s passou de "%s" para "%s"', a.id_entidade_afetada, ea.designacao, ep.designacao)

           -- etapas de produção: concluída, começada, atribuída
           WHEN a.entidade_afetada = 'etapa_trabalho' AND a.acao = 'UPDATE'
                AND a.valores_anteriores ->> 'data_conclusao' IS NULL
                AND a.valores_posteriores ->> 'data_conclusao' IS NOT NULL
               THEN format('Concluiu a etapa "%s" do trabalho n.º %s',
                           a.valores_posteriores ->> 'nome', a.valores_posteriores ->> 'trabalho_id')
           WHEN a.entidade_afetada = 'etapa_trabalho' AND a.acao = 'UPDATE'
                AND a.valores_anteriores ->> 'data_inicio' IS NULL
                AND a.valores_posteriores ->> 'data_inicio' IS NOT NULL
               THEN format('Começou a etapa "%s" do trabalho n.º %s',
                           a.valores_posteriores ->> 'nome', a.valores_posteriores ->> 'trabalho_id')
           WHEN a.entidade_afetada = 'etapa_trabalho' AND a.acao = 'UPDATE'
                AND a.valores_anteriores ->> 'responsavel_id' IS DISTINCT FROM a.valores_posteriores ->> 'responsavel_id'
               THEN format('Atribuiu a etapa "%s" do trabalho n.º %s a %s',
                           a.valores_posteriores ->> 'nome', a.valores_posteriores ->> 'trabalho_id', ur.nome)

           -- contas
           WHEN a.entidade_afetada = 'utilizador' AND a.acao = 'INSERT'
               THEN format('Criou a conta de %s', a.valores_posteriores ->> 'nome')
           WHEN a.entidade_afetada = 'utilizador' AND a.acao = 'UPDATE'
                AND a.valores_posteriores ? 'password_alterada'
               THEN format('Mudou a palavra-passe de %s', a.valores_posteriores ->> 'nome')
           WHEN a.entidade_afetada = 'utilizador' AND a.acao = 'UPDATE'
                AND a.valores_anteriores ->> 'data_aprovacao' IS NULL
                AND a.valores_posteriores ->> 'data_aprovacao' IS NOT NULL
               THEN format('Aprovou a conta de %s', a.valores_posteriores ->> 'nome')
           WHEN a.entidade_afetada = 'utilizador' AND a.acao = 'UPDATE'
                AND a.valores_anteriores ->> 'ativo' <> a.valores_posteriores ->> 'ativo'
               THEN format('%s a conta de %s',
                           CASE WHEN (a.valores_posteriores ->> 'ativo')::boolean THEN 'Reativou' ELSE 'Desativou' END,
                           a.valores_posteriores ->> 'nome')

           -- clínicas
           WHEN a.entidade_afetada = 'cliente' AND a.acao = 'INSERT'
               THEN format('Criou a clínica %s', a.valores_posteriores ->> 'nome')
           WHEN a.entidade_afetada = 'cliente' AND a.acao = 'UPDATE'
                AND a.valores_anteriores ->> 'ativo' <> a.valores_posteriores ->> 'ativo'
               THEN format('%s a clínica %s',
                           CASE WHEN (a.valores_posteriores ->> 'ativo')::boolean THEN 'Reativou' ELSE 'Suspendeu' END,
                           a.valores_posteriores ->> 'nome')

           -- ficheiros
           WHEN a.entidade_afetada = 'ficheiro' AND a.acao = 'INSERT'
               THEN format('Enviou o ficheiro "%s"', a.valores_posteriores ->> 'nome')

           -- as outras alterações: descrição geral
           ELSE format('%s %s n.º %s',
                       CASE a.acao WHEN 'INSERT' THEN 'Criou' WHEN 'UPDATE' THEN 'Alterou' ELSE 'Apagou' END,
                       CASE a.entidade_afetada
                           WHEN 'ordem_trabalho'    THEN 'a ordem'
                           WHEN 'trabalho'          THEN 'o trabalho'
                           WHEN 'etapa_trabalho'    THEN 'a etapa'
                           WHEN 'cliente'           THEN 'a clínica'
                           WHEN 'utilizador'        THEN 'a conta'
                           WHEN 'cargo'             THEN 'o cargo'
                           WHEN 'tipo_trabalho'     THEN 'o tipo de trabalho'
                           WHEN 'estado_ordem'      THEN 'o estado'
                           WHEN 'alteracao_cliente' THEN 'o pedido de alteração'
                           WHEN 'ficheiro'          THEN 'o ficheiro'
                           ELSE a.entidade_afetada
                       END,
                       a.id_entidade_afetada)
       END AS descricao,
       a.valores_anteriores, a.valores_posteriores
FROM registo_auditoria a
LEFT JOIN utilizador u    ON u.id = a.utilizador_id
LEFT JOIN cargo c         ON c.id = u.cargo_id
-- estados da ordem antes e depois (para "passou de ... para ...")
LEFT JOIN estado_ordem ea ON ea.id = (a.valores_anteriores ->> 'estado_ordem_id')::bigint
LEFT JOIN estado_ordem ep ON ep.id = (a.valores_posteriores ->> 'estado_ordem_id')::bigint
-- responsável de uma etapa (para "atribuiu ... a ...")
LEFT JOIN utilizador ur   ON ur.id = (a.valores_posteriores ->> 'responsavel_id')::bigint;
