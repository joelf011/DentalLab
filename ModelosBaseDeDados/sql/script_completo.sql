-- =====================================================================
-- ABD — Lab CD (DentalLab) — Script completo de criação da base de dados
-- Tabelas, vistas, funções, procedimentos, triggers e dados iniciais.
--
-- GERADO AUTOMATICAMENTE por sql/juntar.py: não editar aqui,
-- editar os ficheiros 01 a 06 e voltar a correr o juntar.py.
--
-- Como usar (PostgreSQL 12 ou mais recente):
--   1. No pgAdmin, criar uma base de dados vazia: abd_lab_cd
--   2. Abrir o Query Tool nessa base de dados, abrir este ficheiro e correr tudo (F5).
-- Corre numa só transação: se alguma coisa falhar, não fica nada criado.
-- =====================================================================

BEGIN;


-- #####################################################################
-- 01_tabelas.sql
-- #####################################################################

-- =====================================================================
-- ABD — Lab CD (DentalLab) — 01. Tabelas e índices
-- Laboratório de Prótese Dentária Catarina Domingos
--
-- Origem: DentalLab/ModelosBaseDeDados/modelofisico.sql
--         + alteracoes/001_alteracao_cliente.sql
--
-- Convenções:
--   * snake_case, nomes de tabela no singular
--   * chaves primárias BIGINT GENERATED ALWAYS AS IDENTITY
--   * datas/horas em TIMESTAMPTZ
--   * nunca se apaga: catálogos e utilizadores usam "ativo";
--     dados operacionais usam "eliminado_em" (soft delete).
--     Todas as FK usam ON DELETE RESTRICT (comportamento por omissão).
-- =====================================================================

-- ---------------------------------------------------------------------
-- Tabelas de referência (lookup)
-- ---------------------------------------------------------------------

CREATE TABLE cargo (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    designacao  VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE estado_ordem (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    designacao  VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE tipo_ficheiro (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    designacao  VARCHAR(50) NOT NULL UNIQUE
);

-- ---------------------------------------------------------------------
-- Clientes e utilizadores
-- ---------------------------------------------------------------------

-- Entidade faturada (clínica, médico dentista ou grupo de clínicas).
-- nif guarda o NIPC (empresa) ou o NIF (consultório em nome individual):
-- ambos têm 9 dígitos.
CREATE TABLE cliente (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome              VARCHAR(150) NOT NULL,
    nif               CHAR(9)      NOT NULL UNIQUE,
    morada_faturacao  VARCHAR(255),
    email             VARCHAR(254),
    telefone          VARCHAR(20),
    ativo             BOOLEAN      NOT NULL DEFAULT TRUE,
    criado_em         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ck_cliente_nif CHECK (nif ~ '^[0-9]{9}$')
);

-- Admin e Colaborador: cliente_id NULL (internos do laboratório).
-- Cliente: cada clínica é um utilizador ligado ao respetivo cliente.
-- Contas criadas pela própria clínica ficam pendentes (data_aprovacao NULL)
-- até o Admin as aprovar; contas criadas pelo Admin são aprovadas logo.
-- Uma conta recusada ou desativada fica com ativo = FALSE e pode ser
-- reativada pelo Admin (o email continua reservado para essa conta).
CREATE TABLE utilizador (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cargo_id        BIGINT       NOT NULL REFERENCES cargo (id),
    cliente_id      BIGINT       REFERENCES cliente (id),
    nome            VARCHAR(150) NOT NULL,
    email           VARCHAR(254) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    -- obriga a definir nova password no próximo login
    password_temporaria  BOOLEAN NOT NULL DEFAULT FALSE,
    ativo           BOOLEAN      NOT NULL DEFAULT TRUE,
    aprovado_por    BIGINT       REFERENCES utilizador (id),
    data_aprovacao  TIMESTAMPTZ,
    criado_em       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT ck_utilizador_aprovacao CHECK (
        (aprovado_por IS NULL) = (data_aprovacao IS NULL)
    )
);

CREATE UNIQUE INDEX uq_utilizador_email ON utilizador (lower(email));
CREATE INDEX ix_utilizador_cargo        ON utilizador (cargo_id);
CREATE INDEX ix_utilizador_cliente      ON utilizador (cliente_id);
CREATE INDEX ix_utilizador_aprovado_por ON utilizador (aprovado_por);
-- contas à espera de aprovação do Admin
CREATE INDEX ix_utilizador_pendente     ON utilizador (criado_em)
    WHERE data_aprovacao IS NULL AND ativo;

-- ---------------------------------------------------------------------
-- Modelos de trabalho (geridos pelo Admin)
-- ---------------------------------------------------------------------

CREATE TABLE tipo_trabalho (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome       VARCHAR(100) NOT NULL UNIQUE,
    descricao  TEXT,
    ativo      BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE etapa (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome       VARCHAR(100) NOT NULL UNIQUE,
    descricao  TEXT,
    ativa      BOOLEAN      NOT NULL DEFAULT TRUE
);

-- Lista ordenada de etapas de cada tipo de trabalho (modelo gerido pelo Admin).
-- A mesma etapa pode repetir-se (ex.: duas provas).
-- Exceção ao soft delete: é configuração, não histórico. Ao editar, o backend
-- substitui a lista inteira numa transação; os trabalhos já criados guardam
-- a sua cópia em etapa_trabalho e a alteração fica em registo_auditoria.
CREATE TABLE etapa_tipo_trabalho (
    tipo_trabalho_id  BIGINT   NOT NULL REFERENCES tipo_trabalho (id),
    ordem             SMALLINT NOT NULL CHECK (ordem > 0),
    etapa_id          BIGINT   NOT NULL REFERENCES etapa (id),
    -- DEFERRABLE para o Admin poder reordenar etapas numa só transação
    CONSTRAINT pk_etapa_tipo_trabalho PRIMARY KEY (tipo_trabalho_id, ordem)
        DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX ix_etapa_tipo_trabalho_etapa ON etapa_tipo_trabalho (etapa_id);

-- ---------------------------------------------------------------------
-- Ordens de trabalho (encomendas)
-- ---------------------------------------------------------------------

CREATE TABLE ordem_trabalho (
    id                       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id               BIGINT       NOT NULL REFERENCES cliente (id),
    criado_por               BIGINT       NOT NULL REFERENCES utilizador (id),
    aceite_por               BIGINT       REFERENCES utilizador (id),
    estado_ordem_id          BIGINT       NOT NULL REFERENCES estado_ordem (id),
    nome_medico_responsavel  VARCHAR(150) NOT NULL,
    nome_paciente            VARCHAR(150),
    sexo_paciente            CHAR(1),
    idade_paciente           SMALLINT,
    data_proxima_consulta    DATE,
    observacoes              TEXT,
    prazo_entrega            DATE,
    data_criacao             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    data_aceitacao           TIMESTAMPTZ,
    data_inicio              TIMESTAMPTZ,
    data_conclusao           TIMESTAMPTZ,
    data_entrega             TIMESTAMPTZ,
    -- obrigatório (validado no backend) quando o estado é "Em espera"
    motivo_espera            TEXT,
    motivo_rejeicao          TEXT,
    eliminado_em             TIMESTAMPTZ,
    CONSTRAINT ck_ordem_sexo  CHECK (sexo_paciente IN ('M', 'F')),
    CONSTRAINT ck_ordem_idade CHECK (idade_paciente BETWEEN 0 AND 130),
    -- na aceitação é obrigatório o prazo e quem aceitou
    CONSTRAINT ck_ordem_aceitacao CHECK (
        data_aceitacao IS NULL
        OR (aceite_por IS NOT NULL AND prazo_entrega IS NOT NULL)
    )
);

CREATE INDEX ix_ordem_cliente     ON ordem_trabalho (cliente_id);
CREATE INDEX ix_ordem_criado_por  ON ordem_trabalho (criado_por);
CREATE INDEX ix_ordem_aceite_por  ON ordem_trabalho (aceite_por);
CREATE INDEX ix_ordem_estado      ON ordem_trabalho (estado_ordem_id);
-- listagem de trabalhos a executar ordenada por data limite
CREATE INDEX ix_ordem_prazo       ON ordem_trabalho (prazo_entrega)
    WHERE eliminado_em IS NULL;

-- Material que a clínica envia para o laboratório (ex.: molde em gesso)
CREATE TABLE material_recebido (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ordem_trabalho_id  BIGINT      NOT NULL REFERENCES ordem_trabalho (id),
    descricao          TEXT        NOT NULL,
    observacoes        TEXT,
    data_registo       TIMESTAMPTZ NOT NULL DEFAULT now(),
    data_rececao       TIMESTAMPTZ,
    eliminado_em       TIMESTAMPTZ
);

CREATE INDEX ix_material_recebido_ordem ON material_recebido (ordem_trabalho_id);

-- ---------------------------------------------------------------------
-- Trabalhos
-- ---------------------------------------------------------------------

-- As datas de início e fim pertencem à ordem; o progresso interno de cada
-- trabalho é dado pelas suas etapas (etapa_trabalho).
CREATE TABLE trabalho (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ordem_trabalho_id  BIGINT      NOT NULL REFERENCES ordem_trabalho (id),
    tipo_trabalho_id   BIGINT      NOT NULL REFERENCES tipo_trabalho (id),
    natureza           VARCHAR(10) NOT NULL,
    -- escala VITA (ex.: A1, A3.5, D4) ou 3D-Master (ex.: 2M2); lista sugerida na app
    cor                VARCHAR(10),
    eliminado_em       TIMESTAMPTZ,
    CONSTRAINT ck_trabalho_natureza CHECK (natureza IN ('FISICO', 'DIGITAL'))
);

CREATE INDEX ix_trabalho_ordem ON trabalho (ordem_trabalho_id);
CREATE INDEX ix_trabalho_tipo  ON trabalho (tipo_trabalho_id);

-- Odontograma: dentes intervencionados em cada trabalho (numeração FDI:
-- permanentes 11–48, decíduos 51–85)
CREATE TABLE trabalho_dente (
    trabalho_id  BIGINT   NOT NULL REFERENCES trabalho (id),
    numero_fdi   SMALLINT NOT NULL,
    PRIMARY KEY (trabalho_id, numero_fdi),
    CONSTRAINT ck_trabalho_dente_fdi CHECK (
        (numero_fdi / 10 BETWEEN 1 AND 4 AND numero_fdi % 10 BETWEEN 1 AND 8)
     OR (numero_fdi / 10 BETWEEN 5 AND 8 AND numero_fdi % 10 BETWEEN 1 AND 5)
    )
);

-- Cópia das etapas do tipo de trabalho no momento da criação do trabalho.
-- Alterações posteriores ao modelo (etapa_tipo_trabalho) não afetam
-- trabalhos já criados. Etapa atual = primeira etapa por concluir.
CREATE TABLE etapa_trabalho (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trabalho_id     BIGINT       NOT NULL REFERENCES trabalho (id),
    etapa_id        BIGINT       REFERENCES etapa (id),
    nome            VARCHAR(100) NOT NULL,
    ordem           SMALLINT     NOT NULL CHECK (ordem > 0),
    responsavel_id  BIGINT       REFERENCES utilizador (id),
    data_inicio     TIMESTAMPTZ,
    data_conclusao  TIMESTAMPTZ,
    CONSTRAINT uq_etapa_trabalho_ordem UNIQUE (trabalho_id, ordem),
    CONSTRAINT ck_etapa_trabalho_inicio CHECK (
        data_inicio IS NULL OR responsavel_id IS NOT NULL
    ),
    CONSTRAINT ck_etapa_trabalho_conclusao CHECK (
        data_conclusao IS NULL OR data_inicio IS NOT NULL
    )
);

CREATE INDEX ix_etapa_trabalho_etapa       ON etapa_trabalho (etapa_id);
CREATE INDEX ix_etapa_trabalho_responsavel ON etapa_trabalho (responsavel_id);
CREATE INDEX ix_etapa_trabalho_pendente    ON etapa_trabalho (trabalho_id, ordem)
    WHERE data_conclusao IS NULL;

-- ---------------------------------------------------------------------
-- Documentação e comunicação
-- Associado à ordem  -> partilhado entre clínica e laboratório
-- Associado ao trabalho -> interno do laboratório
-- ---------------------------------------------------------------------

CREATE TABLE ficheiro (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo_ficheiro_id   BIGINT       NOT NULL REFERENCES tipo_ficheiro (id),
    ordem_trabalho_id  BIGINT       REFERENCES ordem_trabalho (id),
    trabalho_id        BIGINT       REFERENCES trabalho (id),
    carregado_por      BIGINT       NOT NULL REFERENCES utilizador (id),
    nome               VARCHAR(255) NOT NULL,
    localizacao        TEXT         NOT NULL,
    data_carregamento  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    eliminado_em       TIMESTAMPTZ,
    CONSTRAINT ck_ficheiro_associacao CHECK (num_nonnulls(ordem_trabalho_id, trabalho_id) = 1)
);

CREATE INDEX ix_ficheiro_tipo          ON ficheiro (tipo_ficheiro_id);
CREATE INDEX ix_ficheiro_ordem         ON ficheiro (ordem_trabalho_id);
CREATE INDEX ix_ficheiro_trabalho      ON ficheiro (trabalho_id);
CREATE INDEX ix_ficheiro_carregado_por ON ficheiro (carregado_por);

CREATE TABLE comentario (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ordem_trabalho_id   BIGINT      REFERENCES ordem_trabalho (id),
    trabalho_id         BIGINT      REFERENCES trabalho (id),
    utilizador_id       BIGINT      NOT NULL REFERENCES utilizador (id),
    conteudo            TEXT        NOT NULL,
    data_criacao        TIMESTAMPTZ NOT NULL DEFAULT now(),
    data_edicao         TIMESTAMPTZ,
    eliminado_em        TIMESTAMPTZ,
    CONSTRAINT ck_comentario_associacao CHECK (num_nonnulls(ordem_trabalho_id, trabalho_id) = 1)
);

CREATE INDEX ix_comentario_ordem      ON comentario (ordem_trabalho_id);
CREATE INDEX ix_comentario_trabalho   ON comentario (trabalho_id);
CREATE INDEX ix_comentario_utilizador ON comentario (utilizador_id);

-- Notificações dentro do sistema (sininho), não push
CREATE TABLE notificacao (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    utilizador_id      BIGINT       NOT NULL REFERENCES utilizador (id),
    ordem_trabalho_id  BIGINT       REFERENCES ordem_trabalho (id),
    trabalho_id        BIGINT       REFERENCES trabalho (id),
    mensagem           VARCHAR(500) NOT NULL,
    data_criacao       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    data_leitura       TIMESTAMPTZ
);

CREATE INDEX ix_notificacao_ordem    ON notificacao (ordem_trabalho_id);
CREATE INDEX ix_notificacao_trabalho ON notificacao (trabalho_id);
-- contador e lista de notificações por ler de cada utilizador
CREATE INDEX ix_notificacao_por_ler  ON notificacao (utilizador_id, data_criacao DESC)
    WHERE data_leitura IS NULL;

-- ---------------------------------------------------------------------
-- Auditoria
-- ---------------------------------------------------------------------

CREATE TABLE registo_auditoria (
    id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    utilizador_id        BIGINT       REFERENCES utilizador (id),
    acao                 VARCHAR(50)  NOT NULL,
    entidade_afetada     VARCHAR(100) NOT NULL,
    id_entidade_afetada  BIGINT,
    data_hora            TIMESTAMPTZ  NOT NULL DEFAULT now(),
    valores_anteriores   JSONB,
    valores_posteriores  JSONB
);

CREATE INDEX ix_auditoria_utilizador ON registo_auditoria (utilizador_id);
CREATE INDEX ix_auditoria_entidade   ON registo_auditoria (entidade_afetada, id_entidade_afetada);
CREATE INDEX ix_auditoria_data       ON registo_auditoria (data_hora);


-- ---------------------------------------------------------------------
-- Pedidos de alteração dos dados de uma clínica (feitos pela própria clínica).
-- Os dados novos só passam para a tabela cliente quando o Administrador aprova.
-- ---------------------------------------------------------------------

-- Os campos a NULL ficam como estão. O NIF não faz parte do pedido:
-- é a identificação fiscal e só o Administrador o pode alterar.
CREATE TABLE alteracao_cliente (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id        BIGINT       NOT NULL REFERENCES cliente (id),
    pedido_por        BIGINT       NOT NULL REFERENCES utilizador (id),
    -- dados novos pedidos pela clínica
    nome              VARCHAR(150),
    morada_faturacao  VARCHAR(255),
    email             VARCHAR(254),
    telefone          VARCHAR(20),
    -- decisão do Administrador
    estado            VARCHAR(20)  NOT NULL DEFAULT 'pendente',
    data_pedido       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    decidido_por      BIGINT       REFERENCES utilizador (id),
    data_decisao      TIMESTAMPTZ,
    motivo_rejeicao   TEXT,
    CONSTRAINT ck_alteracao_cliente_estado CHECK (estado IN ('pendente', 'aprovado', 'rejeitado')),
    -- um pedido tem de pedir pelo menos uma alteração
    CONSTRAINT ck_alteracao_cliente_dados CHECK (num_nonnulls(nome, morada_faturacao, email, telefone) > 0),
    -- enquanto está pendente não tem decisão; depois de decidido tem quem decidiu e quando
    CONSTRAINT ck_alteracao_cliente_decisao CHECK (
        (estado = 'pendente') = (decidido_por IS NULL)
        AND (decidido_por IS NULL) = (data_decisao IS NULL)
    ),
    CONSTRAINT ck_alteracao_cliente_motivo CHECK (estado <> 'rejeitado' OR motivo_rejeicao IS NOT NULL)
);

CREATE INDEX ix_alteracao_cliente_cliente ON alteracao_cliente (cliente_id);
-- no máximo um pedido à espera de aprovação por clínica
CREATE UNIQUE INDEX uq_alteracao_cliente_pendente ON alteracao_cliente (cliente_id)
    WHERE estado = 'pendente';


-- #####################################################################
-- 02_vistas.sql
-- #####################################################################

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


-- #####################################################################
-- 03_funcoes.sql
-- #####################################################################

-- =====================================================================
-- ABD — Lab CD (DentalLab) — 03. Funções (PL/pgSQL)
-- Origem: pasta crud/ do DentalLab.
-- Cada entidade tem uma função fn_<entidade>_crud(p_operacao, p_id, ...)
-- que faz CREATE, UPDATE e DELETE e devolve o id do registo afetado.
-- Correr depois de 02_vistas.sql.
-- =====================================================================

-- (origem: crud/crud_cargo_utilizador.sql)
-- CREATE, UPDATE e DELETE; devolve o id do registo afetado.
-- Em UPDATE, os parâmetros a NULL mantêm o valor atual.
CREATE OR REPLACE FUNCTION public.fn_cargo_crud(
    p_operacao   character varying,
    p_id         bigint,
    p_designacao character varying DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_operacao character varying := upper(p_operacao);
    v_id       bigint;
    n          integer;
BEGIN
    IF v_operacao IN ('UPDATE', 'DELETE') THEN
        SELECT count(*) INTO n FROM cargo WHERE id = p_id;
        IF n = 0 THEN
            RAISE EXCEPTION 'O cargo % não existe', p_id;
        END IF;
    END IF;

    IF v_operacao = 'CREATE' THEN
        IF p_designacao IS NULL OR trim(p_designacao) = '' THEN
            RAISE EXCEPTION 'Tem de indicar a designação do cargo';
        END IF;

        SELECT count(*) INTO n FROM cargo WHERE designacao = p_designacao;
        IF n > 0 THEN
            RAISE EXCEPTION 'Já existe o cargo %', p_designacao;
        END IF;

        INSERT INTO cargo(designacao) VALUES (p_designacao)
        RETURNING id INTO v_id;

    ELSIF v_operacao = 'UPDATE' THEN
        UPDATE cargo
        SET designacao = COALESCE(p_designacao, designacao)
        WHERE id = p_id;
        v_id := p_id;

    ELSIF v_operacao = 'DELETE' THEN
        -- a tabela não tem ativo nem eliminado_em: só se apaga se não estiver em uso
        SELECT count(*) INTO n FROM utilizador WHERE cargo_id = p_id;
        IF n > 0 THEN
            RAISE EXCEPTION 'O cargo % tem utilizadores associados', p_id;
        END IF;

        DELETE FROM cargo WHERE id = p_id;
        v_id := p_id;

    ELSE
        RAISE EXCEPTION 'Operação inválida: % (use CREATE, UPDATE ou DELETE)', p_operacao;
    END IF;

    RETURN v_id;
END;
$BODY$;


-- (origem: crud/crud_cargo_utilizador.sql)
-- A password chega já em hash (gerado pela aplicação), nunca em texto simples.
-- p_aprovado_por aprova a conta. DELETE desativa a conta (ativo = FALSE);
-- UPDATE com p_ativo = TRUE reativa-a.
CREATE OR REPLACE FUNCTION public.fn_utilizador_crud(
    p_operacao            character varying,
    p_id                  bigint,
    p_cargo_id            bigint            DEFAULT NULL,
    p_cliente_id          bigint            DEFAULT NULL,
    p_nome                character varying DEFAULT NULL,
    p_email               character varying DEFAULT NULL,
    p_password_hash       character varying DEFAULT NULL,
    p_password_temporaria boolean           DEFAULT NULL,
    p_ativo               boolean           DEFAULT NULL,
    p_aprovado_por        bigint            DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_operacao character varying := upper(p_operacao);
    v_id       bigint;
    v_cargo    character varying;
    v_cliente  bigint;
    n          integer;
BEGIN
    IF v_operacao IN ('UPDATE', 'DELETE') THEN
        SELECT count(*) INTO n FROM utilizador WHERE id = p_id;
        IF n = 0 THEN
            RAISE EXCEPTION 'O utilizador % não existe', p_id;
        END IF;
    END IF;

    IF v_operacao IN ('CREATE', 'UPDATE') THEN
        IF p_email IS NOT NULL THEN
            SELECT count(*) INTO n FROM utilizador
            WHERE lower(email) = lower(p_email) AND id IS DISTINCT FROM p_id;
            IF n > 0 THEN
                RAISE EXCEPTION 'Já existe um utilizador com o email %', p_email;
            END IF;
        END IF;

        IF p_aprovado_por IS NOT NULL THEN
            SELECT count(*) INTO n
            FROM utilizador u
            JOIN cargo c ON c.id = u.cargo_id
            WHERE u.id = p_aprovado_por AND c.designacao = 'Administrador' AND u.ativo;
            IF n = 0 THEN
                RAISE EXCEPTION 'A conta só pode ser aprovada por um administrador ativo';
            END IF;
        END IF;
    END IF;

    IF v_operacao = 'CREATE' THEN
        IF p_cargo_id IS NULL OR p_nome IS NULL OR p_email IS NULL OR p_password_hash IS NULL THEN
            RAISE EXCEPTION 'Tem de indicar o cargo, o nome, o email e a password';
        END IF;

        -- contas aprovadas na criação ficam logo ativas; as restantes ficam pendentes
        INSERT INTO utilizador(cargo_id, cliente_id, nome, email, password_hash,
                               password_temporaria, aprovado_por, data_aprovacao)
        VALUES (p_cargo_id, p_cliente_id, p_nome, p_email, p_password_hash,
                COALESCE(p_password_temporaria, FALSE), p_aprovado_por,
                CASE WHEN p_aprovado_por IS NOT NULL THEN now() END)
        RETURNING id INTO v_id;

    ELSIF v_operacao = 'UPDATE' THEN
        UPDATE utilizador
        SET cargo_id            = COALESCE(p_cargo_id, cargo_id),
            cliente_id          = COALESCE(p_cliente_id, cliente_id),
            nome                = COALESCE(p_nome, nome),
            email               = COALESCE(p_email, email),
            password_hash       = COALESCE(p_password_hash, password_hash),
            password_temporaria = COALESCE(p_password_temporaria, password_temporaria),
            ativo               = COALESCE(p_ativo, ativo),
            aprovado_por        = COALESCE(p_aprovado_por, aprovado_por),
            data_aprovacao      = CASE WHEN p_aprovado_por IS NOT NULL THEN now()
                                       ELSE data_aprovacao END
        WHERE id = p_id;
        v_id := p_id;

    ELSIF v_operacao = 'DELETE' THEN
        UPDATE utilizador SET ativo = FALSE WHERE id = p_id;
        v_id := p_id;

    ELSE
        RAISE EXCEPTION 'Operação inválida: % (use CREATE, UPDATE ou DELETE)', p_operacao;
    END IF;

    -- Administrador e Colaborador são internos; só o cargo Cliente tem cliente associado.
    -- Se a regra falhar, a exceção desfaz a operação.
    IF v_operacao IN ('CREATE', 'UPDATE') THEN
        SELECT c.designacao, u.cliente_id INTO v_cargo, v_cliente
        FROM utilizador u
        JOIN cargo c ON c.id = u.cargo_id
        WHERE u.id = v_id;

        IF v_cargo = 'Cliente' AND v_cliente IS NULL THEN
            RAISE EXCEPTION 'Um utilizador com o cargo Cliente tem de ter um cliente associado';
        ELSIF v_cargo <> 'Cliente' AND v_cliente IS NOT NULL THEN
            RAISE EXCEPTION 'Só os utilizadores com o cargo Cliente podem ter cliente associado';
        END IF;
    END IF;

    RETURN v_id;
END;
$BODY$;


-- (origem: crud/crud_cargo_utilizador.sql)
-- login

-- Devolve os dados de que a API precisa para o login, incluindo o password_hash.
-- É a única forma de ler o password_hash (a vw_utilizador esconde-o de propósito).
-- O email não distingue maiúsculas de minúsculas. Se não existir, não devolve nenhuma linha.
-- A API compara a palavra-passe com o hash e depois decide pelo "ativo" e pelo "aprovado".
CREATE OR REPLACE FUNCTION public.fn_utilizador_login(
    p_email character varying)
RETURNS TABLE (
    id                  bigint,
    nome                character varying,
    email               character varying,
    cargo               character varying,
    cliente_id          bigint,
    password_hash       character varying,
    password_temporaria boolean,
    ativo               boolean,
    aprovado            boolean)
LANGUAGE 'sql'
AS $BODY$
    SELECT u.id, u.nome, u.email,
           c.designacao,
           u.cliente_id, u.password_hash, u.password_temporaria, u.ativo,
           u.data_aprovacao IS NOT NULL
    FROM utilizador u
    JOIN cargo c ON c.id = u.cargo_id
    WHERE lower(u.email) = lower(p_email);
$BODY$;


-- (origem: crud/crud_cargo_utilizador.sql)
-- registo de clínica

-- Registo feito pela própria clínica, na página pública de registo.
-- Cria o cliente e a conta de acesso (cargo Cliente) de uma só vez:
-- se uma das partes falhar (ex.: email já usado), não fica nada criado.
-- A conta usa o mesmo nome e email da clínica e fica por aprovar até o Administrador a aprovar.
-- A password chega já em hash (gerado pela API). Devolve o id do cliente criado.
CREATE OR REPLACE FUNCTION public.fn_registar_clinica(
    p_nome             character varying,
    p_nif              character varying,
    p_morada_faturacao character varying,
    p_telefone         character varying,
    p_email            character varying,
    p_password_hash    character varying)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_cargo_id   bigint;
    v_cliente_id bigint;
BEGIN
    IF p_email IS NULL OR trim(p_email) = '' THEN
        RAISE EXCEPTION 'Tem de indicar o email';
    END IF;

    SELECT id INTO v_cargo_id FROM cargo WHERE designacao = 'Cliente';

    -- as validações (nome, NIF repetido, email repetido...) são as das funções CRUD
    v_cliente_id := fn_cliente_crud(
        p_operacao         => 'CREATE',
        p_id               => NULL,
        p_nome             => p_nome,
        p_nif              => p_nif,
        p_morada_faturacao => p_morada_faturacao,
        p_email            => p_email,
        p_telefone         => p_telefone);

    -- sem p_aprovado_por: a conta fica por aprovar
    PERFORM fn_utilizador_crud(
        p_operacao      => 'CREATE',
        p_id            => NULL,
        p_cargo_id      => v_cargo_id,
        p_cliente_id    => v_cliente_id,
        p_nome          => p_nome,
        p_email         => p_email,
        p_password_hash => p_password_hash);

    RETURN v_cliente_id;
END;
$BODY$;


-- (origem: crud/crud_cargo_utilizador.sql)
-- aprovação de contas

-- O Administrador aprova uma conta que está à espera (ex.: uma clínica que se registou sozinha).
-- Só aprova contas ativas e ainda por aprovar. Devolve o id do utilizador.
-- Quem aprova tem de ser um administrador ativo (verificado pela fn_utilizador_crud).
-- Para recusar um registo, desativa-se a conta (fn_utilizador_crud com DELETE).
CREATE OR REPLACE FUNCTION public.fn_aprovar_utilizador(
    p_id           bigint,
    p_aprovado_por bigint)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_conta utilizador%ROWTYPE;
BEGIN
    SELECT * INTO v_conta FROM utilizador WHERE id = p_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'O utilizador % não existe', p_id;
    END IF;
    IF v_conta.data_aprovacao IS NOT NULL THEN
        RAISE EXCEPTION 'Esta conta já está aprovada';
    END IF;
    IF NOT v_conta.ativo THEN
        RAISE EXCEPTION 'Esta conta está desativada; reative-a antes de a aprovar';
    END IF;

    RETURN fn_utilizador_crud(p_operacao => 'UPDATE', p_id => p_id, p_aprovado_por => p_aprovado_por);
END;
$BODY$;


-- (origem: crud/crud_cliente_etapa_trabalho.sql)
-- CREATE, UPDATE e DELETE; devolve o id do registo afetado.
-- Em UPDATE, os parâmetros a NULL mantêm o valor atual.
-- DELETE desativa o cliente (ativo = FALSE); UPDATE com p_ativo = TRUE reativa-o.
-- As contas de acesso da clínica (utilizadores com este cliente_id) são desativadas
-- e reativadas ao mesmo tempo que a clínica.
CREATE OR REPLACE FUNCTION public.fn_cliente_crud(
    p_operacao         character varying,
    p_id               bigint,
    p_nome             character varying DEFAULT NULL,
    p_nif              character varying DEFAULT NULL,
    p_morada_faturacao character varying DEFAULT NULL,
    p_email            character varying DEFAULT NULL,
    p_telefone         character varying DEFAULT NULL,
    p_ativo            boolean           DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_operacao character varying := upper(p_operacao);
    v_id       bigint;
    n          integer;
BEGIN
    IF v_operacao IN ('UPDATE', 'DELETE') THEN
        SELECT count(*) INTO n FROM cliente WHERE id = p_id;
        IF n = 0 THEN
            RAISE EXCEPTION 'O cliente % não existe', p_id;
        END IF;
    END IF;

    IF v_operacao IN ('CREATE', 'UPDATE') AND p_nif IS NOT NULL THEN
        IF length(p_nif) <> 9 THEN
            RAISE EXCEPTION 'O NIF tem de ter 9 dígitos';
        END IF;

        SELECT count(*) INTO n FROM cliente WHERE nif = p_nif AND id IS DISTINCT FROM p_id;
        IF n > 0 THEN
            RAISE EXCEPTION 'Já existe um cliente com o NIF %', p_nif;
        END IF;
    END IF;

    IF v_operacao = 'CREATE' THEN
        IF p_nome IS NULL OR p_nif IS NULL THEN
            RAISE EXCEPTION 'Tem de indicar o nome e o NIF do cliente';
        END IF;

        INSERT INTO cliente(nome, nif, morada_faturacao, email, telefone)
        VALUES (p_nome, p_nif, p_morada_faturacao, p_email, p_telefone)
        RETURNING id INTO v_id;

    ELSIF v_operacao = 'UPDATE' THEN
        UPDATE cliente
        SET nome             = COALESCE(p_nome, nome),
            nif              = COALESCE(p_nif, nif),
            morada_faturacao = COALESCE(p_morada_faturacao, morada_faturacao),
            email            = COALESCE(p_email, email),
            telefone         = COALESCE(p_telefone, telefone),
            ativo            = COALESCE(p_ativo, ativo)
        WHERE id = p_id;
        -- ao desativar ou reativar a clínica, as contas de acesso dela acompanham
        IF p_ativo IS NOT NULL THEN
            UPDATE utilizador SET ativo = p_ativo WHERE cliente_id = p_id;
        END IF;
        v_id := p_id;

    ELSIF v_operacao = 'DELETE' THEN
        -- o cliente mantém-se por causa do histórico de ordens
        UPDATE cliente SET ativo = FALSE WHERE id = p_id;
        -- as contas de acesso da clínica deixam de poder entrar
        UPDATE utilizador SET ativo = FALSE WHERE cliente_id = p_id;
        v_id := p_id;

    ELSE
        RAISE EXCEPTION 'Operação inválida: % (use CREATE, UPDATE ou DELETE)', p_operacao;
    END IF;

    RETURN v_id;
END;
$BODY$;


-- (origem: crud/crud_cliente_etapa_trabalho.sql)
-- No CREATE, sem p_nome usa o nome da etapa do catálogo (p_etapa_id) e,
-- sem p_ordem, coloca a etapa a seguir à última do trabalho.
-- A tabela não tem eliminação lógica: DELETE apaga a etapa, mas só se ainda
-- não tiver sido iniciada.
CREATE OR REPLACE FUNCTION public.fn_etapa_trabalho_crud(
    p_operacao       character varying,
    p_id             bigint,
    p_trabalho_id    bigint            DEFAULT NULL,
    p_etapa_id       bigint            DEFAULT NULL,
    p_nome           character varying DEFAULT NULL,
    p_ordem          smallint          DEFAULT NULL,
    p_responsavel_id bigint            DEFAULT NULL,
    p_data_inicio    timestamptz       DEFAULT NULL,
    p_data_conclusao timestamptz       DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_operacao character varying := upper(p_operacao);
    v_id       bigint;
    v_nome     character varying;
    v_ordem    smallint;
    v_inicio   timestamptz;
    v_fim      timestamptz;
    n          integer;
BEGIN
    IF v_operacao IN ('UPDATE', 'DELETE') THEN
        SELECT count(*) INTO n FROM etapa_trabalho WHERE id = p_id;
        IF n = 0 THEN
            RAISE EXCEPTION 'A etapa de trabalho % não existe', p_id;
        END IF;
    END IF;

    IF v_operacao IN ('CREATE', 'UPDATE') AND p_responsavel_id IS NOT NULL THEN
        SELECT count(*) INTO n FROM utilizador
        WHERE id = p_responsavel_id AND ativo AND cliente_id IS NULL;
        IF n = 0 THEN
            RAISE EXCEPTION 'O responsável tem de ser um utilizador ativo do laboratório';
        END IF;
    END IF;

    IF v_operacao = 'CREATE' THEN
        SELECT count(*) INTO n FROM trabalho WHERE id = p_trabalho_id AND eliminado_em IS NULL;
        IF n = 0 THEN
            RAISE EXCEPTION 'O trabalho % não existe', p_trabalho_id;
        END IF;

        v_nome := p_nome;
        IF v_nome IS NULL AND p_etapa_id IS NOT NULL THEN
            SELECT nome INTO v_nome FROM etapa WHERE id = p_etapa_id;
        END IF;
        IF v_nome IS NULL THEN
            RAISE EXCEPTION 'Tem de indicar o nome da etapa ou uma etapa do catálogo';
        END IF;

        v_ordem := p_ordem;
        IF v_ordem IS NULL THEN
            SELECT COALESCE(max(ordem), 0) + 1 INTO v_ordem
            FROM etapa_trabalho WHERE trabalho_id = p_trabalho_id;
        END IF;

        INSERT INTO etapa_trabalho(trabalho_id, etapa_id, nome, ordem, responsavel_id,
                                   data_inicio, data_conclusao)
        VALUES (p_trabalho_id, p_etapa_id, v_nome, v_ordem, p_responsavel_id,
                p_data_inicio, p_data_conclusao)
        RETURNING id INTO v_id;

    ELSIF v_operacao = 'UPDATE' THEN
        UPDATE etapa_trabalho
        SET etapa_id       = COALESCE(p_etapa_id, etapa_id),
            nome           = COALESCE(p_nome, nome),
            ordem          = COALESCE(p_ordem, ordem),
            responsavel_id = COALESCE(p_responsavel_id, responsavel_id),
            data_inicio    = COALESCE(p_data_inicio, data_inicio),
            data_conclusao = COALESCE(p_data_conclusao, data_conclusao)
        WHERE id = p_id;
        v_id := p_id;

    ELSIF v_operacao = 'DELETE' THEN
        SELECT data_inicio INTO v_inicio FROM etapa_trabalho WHERE id = p_id;
        IF v_inicio IS NOT NULL THEN
            RAISE EXCEPTION 'Só é possível eliminar etapas que ainda não foram iniciadas';
        END IF;

        DELETE FROM etapa_trabalho WHERE id = p_id;
        v_id := p_id;

    ELSE
        RAISE EXCEPTION 'Operação inválida: % (use CREATE, UPDATE ou DELETE)', p_operacao;
    END IF;

    -- as regras de responsável e de início/conclusão são garantidas pelas
    -- restrições CHECK da tabela; falta a ordem das datas
    IF v_operacao IN ('CREATE', 'UPDATE') THEN
        SELECT data_inicio, data_conclusao INTO v_inicio, v_fim
        FROM etapa_trabalho WHERE id = v_id;
        IF v_fim < v_inicio THEN
            RAISE EXCEPTION 'A data de conclusão não pode ser anterior à data de início';
        END IF;
    END IF;

    RETURN v_id;
END;
$BODY$;


-- (origem: crud/crud_alteracao_cliente.sql)
-- A clínica pede para alterar os seus dados. Devolve o id do pedido.
-- Os parâmetros a NULL (ou vazios) ficam como estão.
CREATE OR REPLACE FUNCTION public.fn_pedir_alteracao_cliente(
    p_cliente_id       bigint,
    p_pedido_por       bigint,
    p_nome             character varying DEFAULT NULL,
    p_morada_faturacao character varying DEFAULT NULL,
    p_email            character varying DEFAULT NULL,
    p_telefone         character varying DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_nome     character varying := NULLIF(trim(p_nome), '');
    v_morada   character varying := NULLIF(trim(p_morada_faturacao), '');
    v_email    character varying := NULLIF(trim(p_email), '');
    v_telefone character varying := NULLIF(trim(p_telefone), '');
    v_id       bigint;
    n          integer;
BEGIN
    SELECT count(*) INTO n FROM cliente WHERE id = p_cliente_id AND ativo;
    IF n = 0 THEN
        RAISE EXCEPTION 'O cliente % não existe ou está inativo', p_cliente_id;
    END IF;

    -- só uma conta da própria clínica pode pedir alterações aos dados dela
    SELECT count(*) INTO n FROM utilizador
    WHERE id = p_pedido_por AND cliente_id = p_cliente_id AND ativo;
    IF n = 0 THEN
        RAISE EXCEPTION 'Só a própria clínica pode pedir alterações aos seus dados';
    END IF;

    IF v_nome IS NULL AND v_morada IS NULL AND v_email IS NULL AND v_telefone IS NULL THEN
        RAISE EXCEPTION 'Indique pelo menos um dado a alterar';
    END IF;

    SELECT count(*) INTO n FROM alteracao_cliente
    WHERE cliente_id = p_cliente_id AND estado = 'pendente';
    IF n > 0 THEN
        RAISE EXCEPTION 'Já existe um pedido de alteração à espera de aprovação';
    END IF;

    INSERT INTO alteracao_cliente(cliente_id, pedido_por, nome, morada_faturacao, email, telefone)
    VALUES (p_cliente_id, p_pedido_por, v_nome, v_morada, v_email, v_telefone)
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$BODY$;


-- (origem: crud/crud_alteracao_cliente.sql)
-- O Administrador aprova (p_aprovar = TRUE) ou rejeita (FALSE) um pedido. Devolve o id do pedido.
-- Ao aprovar, os dados novos passam para a tabela cliente através da fn_cliente_crud
-- (assim valem as mesmas validações). Ao rejeitar, o motivo é obrigatório.
CREATE OR REPLACE FUNCTION public.fn_decidir_alteracao_cliente(
    p_id              bigint,
    p_decidido_por    bigint,
    p_aprovar         boolean,
    p_motivo_rejeicao text DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_pedido alteracao_cliente%ROWTYPE;
    n        integer;
BEGIN
    SELECT * INTO v_pedido FROM alteracao_cliente WHERE id = p_id AND estado = 'pendente';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'O pedido de alteração % não existe ou já foi decidido', p_id;
    END IF;

    SELECT count(*) INTO n
    FROM utilizador u
    JOIN cargo c ON c.id = u.cargo_id
    WHERE u.id = p_decidido_por AND c.designacao = 'Administrador' AND u.ativo;
    IF n = 0 THEN
        RAISE EXCEPTION 'Só um administrador ativo pode decidir pedidos de alteração';
    END IF;

    IF p_aprovar IS NULL THEN
        RAISE EXCEPTION 'Indique se o pedido é aprovado ou rejeitado';

    ELSIF p_aprovar THEN
        -- os campos a NULL ficam como estão (COALESCE da fn_cliente_crud); o NIF não muda
        PERFORM fn_cliente_crud(
            p_operacao         => 'UPDATE',
            p_id               => v_pedido.cliente_id,
            p_nome             => v_pedido.nome,
            p_morada_faturacao => v_pedido.morada_faturacao,
            p_email            => v_pedido.email,
            p_telefone         => v_pedido.telefone);

        UPDATE alteracao_cliente
        SET estado = 'aprovado', decidido_por = p_decidido_por, data_decisao = now()
        WHERE id = p_id;

    ELSE
        IF p_motivo_rejeicao IS NULL OR trim(p_motivo_rejeicao) = '' THEN
            RAISE EXCEPTION 'Tem de indicar o motivo da rejeição';
        END IF;

        UPDATE alteracao_cliente
        SET estado = 'rejeitado', decidido_por = p_decidido_por, data_decisao = now(),
            motivo_rejeicao = p_motivo_rejeicao
        WHERE id = p_id;
    END IF;

    RETURN p_id;
END;
$BODY$;


-- (origem: crud/crud_estado_ordem_ordem_trabalho.sql)
-- CREATE, UPDATE e DELETE; devolve o id do registo afetado.
-- Em UPDATE, os parâmetros a NULL mantêm o valor atual.
CREATE OR REPLACE FUNCTION public.fn_estado_ordem_crud(
    p_operacao   character varying,
    p_id         bigint,
    p_designacao character varying DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_operacao character varying := upper(p_operacao);
    v_id       bigint;
    n          integer;
BEGIN
    IF v_operacao IN ('UPDATE', 'DELETE') THEN
        SELECT count(*) INTO n FROM estado_ordem WHERE id = p_id;
        IF n = 0 THEN
            RAISE EXCEPTION 'O estado % não existe', p_id;
        END IF;
    END IF;

    IF v_operacao = 'CREATE' THEN
        IF p_designacao IS NULL OR trim(p_designacao) = '' THEN
            RAISE EXCEPTION 'Tem de indicar a designação do estado';
        END IF;

        SELECT count(*) INTO n FROM estado_ordem WHERE designacao = p_designacao;
        IF n > 0 THEN
            RAISE EXCEPTION 'Já existe o estado %', p_designacao;
        END IF;

        INSERT INTO estado_ordem(designacao) VALUES (p_designacao)
        RETURNING id INTO v_id;

    ELSIF v_operacao = 'UPDATE' THEN
        UPDATE estado_ordem
        SET designacao = COALESCE(p_designacao, designacao)
        WHERE id = p_id;
        v_id := p_id;

    ELSIF v_operacao = 'DELETE' THEN
        -- a tabela não tem ativo nem eliminado_em: só se apaga se não estiver em uso
        SELECT count(*) INTO n FROM ordem_trabalho WHERE estado_ordem_id = p_id;
        IF n > 0 THEN
            RAISE EXCEPTION 'O estado % está atribuído a ordens de trabalho', p_id;
        END IF;

        DELETE FROM estado_ordem WHERE id = p_id;
        v_id := p_id;

    ELSE
        RAISE EXCEPTION 'Operação inválida: % (use CREATE, UPDATE ou DELETE)', p_operacao;
    END IF;

    RETURN v_id;
END;
$BODY$;


-- (origem: crud/crud_estado_ordem_ordem_trabalho.sql)
-- Sem estado indicado, a ordem é criada "Em avaliação".
-- Ao indicar p_aceite_por, a data de aceitação é preenchida automaticamente.
-- DELETE é lógico: preenche eliminado_em.
CREATE OR REPLACE FUNCTION public.fn_ordem_trabalho_crud(
    p_operacao                character varying,
    p_id                      bigint,
    p_cliente_id              bigint            DEFAULT NULL,
    p_criado_por              bigint            DEFAULT NULL,
    p_estado_ordem_id         bigint            DEFAULT NULL,
    p_aceite_por              bigint            DEFAULT NULL,
    p_nome_medico_responsavel character varying DEFAULT NULL,
    p_nome_paciente           character varying DEFAULT NULL,
    p_sexo_paciente           character         DEFAULT NULL,
    p_idade_paciente          smallint          DEFAULT NULL,
    p_data_proxima_consulta   date              DEFAULT NULL,
    p_observacoes             text              DEFAULT NULL,
    p_prazo_entrega           date              DEFAULT NULL,
    p_data_inicio             timestamptz       DEFAULT NULL,
    p_data_conclusao          timestamptz       DEFAULT NULL,
    p_data_entrega            timestamptz       DEFAULT NULL,
    p_motivo_espera           text              DEFAULT NULL,
    p_motivo_rejeicao         text              DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_operacao character varying := upper(p_operacao);
    v_id       bigint;
    v_estado   bigint;
    v_motivo   text;
    n          integer;
BEGIN
    IF v_operacao IN ('UPDATE', 'DELETE') THEN
        SELECT count(*) INTO n FROM ordem_trabalho WHERE id = p_id AND eliminado_em IS NULL;
        IF n = 0 THEN
            RAISE EXCEPTION 'A ordem de trabalho % não existe', p_id;
        END IF;
    END IF;

    IF v_operacao IN ('CREATE', 'UPDATE') AND p_aceite_por IS NOT NULL THEN
        SELECT count(*) INTO n FROM utilizador
        WHERE id = p_aceite_por AND ativo AND cliente_id IS NULL;
        IF n = 0 THEN
            RAISE EXCEPTION 'A ordem só pode ser aceite por um utilizador ativo do laboratório';
        END IF;
    END IF;

    IF v_operacao = 'CREATE' THEN
        IF p_cliente_id IS NULL OR p_criado_por IS NULL OR p_nome_medico_responsavel IS NULL THEN
            RAISE EXCEPTION 'Tem de indicar o cliente, quem cria a ordem e o médico responsável';
        END IF;

        SELECT count(*) INTO n FROM cliente WHERE id = p_cliente_id AND ativo;
        IF n = 0 THEN
            RAISE EXCEPTION 'O cliente % não existe ou está inativo', p_cliente_id;
        END IF;

        SELECT count(*) INTO n FROM utilizador WHERE id = p_criado_por AND ativo;
        IF n = 0 THEN
            RAISE EXCEPTION 'O utilizador % não existe ou está inativo', p_criado_por;
        END IF;

        IF p_estado_ordem_id IS NULL THEN
            SELECT id INTO v_estado FROM estado_ordem WHERE designacao = 'Em avaliação';
        ELSE
            v_estado := p_estado_ordem_id;
        END IF;

        INSERT INTO ordem_trabalho(cliente_id, criado_por, aceite_por, estado_ordem_id,
                                   nome_medico_responsavel, nome_paciente, sexo_paciente,
                                   idade_paciente, data_proxima_consulta, observacoes,
                                   prazo_entrega, data_aceitacao, data_inicio, data_conclusao,
                                   data_entrega, motivo_espera, motivo_rejeicao)
        VALUES (p_cliente_id, p_criado_por, p_aceite_por, v_estado,
                p_nome_medico_responsavel, p_nome_paciente, p_sexo_paciente,
                p_idade_paciente, p_data_proxima_consulta, p_observacoes,
                p_prazo_entrega, CASE WHEN p_aceite_por IS NOT NULL THEN now() END,
                p_data_inicio, p_data_conclusao, p_data_entrega, p_motivo_espera,
                p_motivo_rejeicao)
        RETURNING id INTO v_id;

    ELSIF v_operacao = 'UPDATE' THEN
        UPDATE ordem_trabalho
        SET estado_ordem_id         = COALESCE(p_estado_ordem_id, estado_ordem_id),
            aceite_por              = COALESCE(p_aceite_por, aceite_por),
            data_aceitacao          = CASE WHEN p_aceite_por IS NOT NULL
                                           THEN COALESCE(data_aceitacao, now())
                                           ELSE data_aceitacao END,
            nome_medico_responsavel = COALESCE(p_nome_medico_responsavel, nome_medico_responsavel),
            nome_paciente           = COALESCE(p_nome_paciente, nome_paciente),
            sexo_paciente           = COALESCE(p_sexo_paciente, sexo_paciente),
            idade_paciente          = COALESCE(p_idade_paciente, idade_paciente),
            data_proxima_consulta   = COALESCE(p_data_proxima_consulta, data_proxima_consulta),
            observacoes             = COALESCE(p_observacoes, observacoes),
            prazo_entrega           = COALESCE(p_prazo_entrega, prazo_entrega),
            data_inicio             = COALESCE(p_data_inicio, data_inicio),
            data_conclusao          = COALESCE(p_data_conclusao, data_conclusao),
            data_entrega            = COALESCE(p_data_entrega, data_entrega),
            motivo_espera           = COALESCE(p_motivo_espera, motivo_espera),
            motivo_rejeicao         = COALESCE(p_motivo_rejeicao, motivo_rejeicao)
        WHERE id = p_id;
        v_id := p_id;

    ELSIF v_operacao = 'DELETE' THEN
        UPDATE ordem_trabalho SET eliminado_em = now() WHERE id = p_id;
        v_id := p_id;

    ELSE
        RAISE EXCEPTION 'Operação inválida: % (use CREATE, UPDATE ou DELETE)', p_operacao;
    END IF;

    -- regra do modelo físico: no estado "Em espera" o motivo é obrigatório.
    -- Se falhar, a exceção desfaz a operação.
    IF v_operacao IN ('CREATE', 'UPDATE') THEN
        SELECT count(*) INTO n
        FROM ordem_trabalho o
        JOIN estado_ordem e ON e.id = o.estado_ordem_id
        WHERE o.id = v_id AND e.designacao = 'Em espera' AND o.motivo_espera IS NULL;
        IF n > 0 THEN
            RAISE EXCEPTION 'O motivo de espera é obrigatório no estado "Em espera"';
        END IF;
    END IF;

    RETURN v_id;
END;
$BODY$;


-- (origem: crud/crud_tipo_trabalho_trabalho.sql)
-- CREATE, UPDATE e DELETE; devolve o id do registo afetado.
-- Em UPDATE, os parâmetros a NULL mantêm o valor atual.
-- DELETE desativa o tipo (ativo = FALSE); UPDATE com p_ativo = TRUE reativa-o.
CREATE OR REPLACE FUNCTION public.fn_tipo_trabalho_crud(
    p_operacao  character varying,
    p_id        bigint,
    p_nome      character varying DEFAULT NULL,
    p_descricao text              DEFAULT NULL,
    p_ativo     boolean           DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_operacao character varying := upper(p_operacao);
    v_id       bigint;
    n          integer;
BEGIN
    IF v_operacao IN ('UPDATE', 'DELETE') THEN
        SELECT count(*) INTO n FROM tipo_trabalho WHERE id = p_id;
        IF n = 0 THEN
            RAISE EXCEPTION 'O tipo de trabalho % não existe', p_id;
        END IF;
    END IF;

    IF v_operacao IN ('CREATE', 'UPDATE') AND p_nome IS NOT NULL THEN
        SELECT count(*) INTO n FROM tipo_trabalho
        WHERE nome = p_nome AND id IS DISTINCT FROM p_id;
        IF n > 0 THEN
            RAISE EXCEPTION 'Já existe o tipo de trabalho %', p_nome;
        END IF;
    END IF;

    IF v_operacao = 'CREATE' THEN
        IF p_nome IS NULL OR trim(p_nome) = '' THEN
            RAISE EXCEPTION 'Tem de indicar o nome do tipo de trabalho';
        END IF;

        INSERT INTO tipo_trabalho(nome, descricao) VALUES (p_nome, p_descricao)
        RETURNING id INTO v_id;

    ELSIF v_operacao = 'UPDATE' THEN
        UPDATE tipo_trabalho
        SET nome      = COALESCE(p_nome, nome),
            descricao = COALESCE(p_descricao, descricao),
            ativo     = COALESCE(p_ativo, ativo)
        WHERE id = p_id;
        v_id := p_id;

    ELSIF v_operacao = 'DELETE' THEN
        UPDATE tipo_trabalho SET ativo = FALSE WHERE id = p_id;
        v_id := p_id;

    ELSE
        RAISE EXCEPTION 'Operação inválida: % (use CREATE, UPDATE ou DELETE)', p_operacao;
    END IF;

    RETURN v_id;
END;
$BODY$;


-- (origem: crud/crud_tipo_trabalho_trabalho.sql)
-- p_dentes é a lista de dentes (números FDI); em UPDATE substitui a lista anterior.
-- No CREATE são copiadas as etapas configuradas para o tipo de trabalho.
-- DELETE é lógico: preenche eliminado_em.
CREATE OR REPLACE FUNCTION public.fn_trabalho_crud(
    p_operacao          character varying,
    p_id                bigint,
    p_ordem_trabalho_id bigint            DEFAULT NULL,
    p_tipo_trabalho_id  bigint            DEFAULT NULL,
    p_natureza          character varying DEFAULT NULL,
    p_cor               character varying DEFAULT NULL,
    p_dentes            smallint[]        DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_operacao character varying := upper(p_operacao);
    v_id       bigint;
    n          integer;
    i          integer;
BEGIN
    IF v_operacao IN ('UPDATE', 'DELETE') THEN
        SELECT count(*) INTO n FROM trabalho WHERE id = p_id AND eliminado_em IS NULL;
        IF n = 0 THEN
            RAISE EXCEPTION 'O trabalho % não existe', p_id;
        END IF;
    END IF;

    IF v_operacao = 'CREATE' THEN
        IF p_ordem_trabalho_id IS NULL OR p_tipo_trabalho_id IS NULL OR p_natureza IS NULL THEN
            RAISE EXCEPTION 'Tem de indicar a ordem, o tipo de trabalho e a natureza';
        END IF;

        IF p_dentes IS NULL OR array_length(p_dentes, 1) IS NULL THEN
            RAISE EXCEPTION 'Tem de indicar pelo menos um dente';
        END IF;

        SELECT count(*) INTO n FROM ordem_trabalho
        WHERE id = p_ordem_trabalho_id AND eliminado_em IS NULL;
        IF n = 0 THEN
            RAISE EXCEPTION 'A ordem de trabalho % não existe', p_ordem_trabalho_id;
        END IF;

        SELECT count(*) INTO n FROM tipo_trabalho WHERE id = p_tipo_trabalho_id AND ativo;
        IF n = 0 THEN
            RAISE EXCEPTION 'O tipo de trabalho % não existe ou está inativo', p_tipo_trabalho_id;
        END IF;

        INSERT INTO trabalho(ordem_trabalho_id, tipo_trabalho_id, natureza, cor)
        VALUES (p_ordem_trabalho_id, p_tipo_trabalho_id, upper(p_natureza), p_cor)
        RETURNING id INTO v_id;

        -- cópia das etapas do tipo de trabalho (regra do modelo físico)
        INSERT INTO etapa_trabalho(trabalho_id, etapa_id, nome, ordem)
        SELECT v_id, e.id, e.nome, ett.ordem
        FROM etapa_tipo_trabalho ett
        JOIN etapa e ON e.id = ett.etapa_id
        WHERE ett.tipo_trabalho_id = p_tipo_trabalho_id;

    ELSIF v_operacao = 'UPDATE' THEN
        UPDATE trabalho
        SET natureza = COALESCE(upper(p_natureza), natureza),
            cor      = COALESCE(p_cor, cor)
        WHERE id = p_id;
        v_id := p_id;

        IF p_dentes IS NOT NULL THEN
            IF array_length(p_dentes, 1) IS NULL THEN
                RAISE EXCEPTION 'Tem de indicar pelo menos um dente';
            END IF;
            DELETE FROM trabalho_dente WHERE trabalho_id = v_id;
        END IF;

    ELSIF v_operacao = 'DELETE' THEN
        UPDATE trabalho SET eliminado_em = now() WHERE id = p_id;
        v_id := p_id;

    ELSE
        RAISE EXCEPTION 'Operação inválida: % (use CREATE, UPDATE ou DELETE)', p_operacao;
    END IF;

    -- gravação dos dentes, ignorando números repetidos
    IF v_operacao IN ('CREATE', 'UPDATE') AND p_dentes IS NOT NULL THEN
        FOR i IN 1..array_length(p_dentes, 1) LOOP
            SELECT count(*) INTO n FROM trabalho_dente
            WHERE trabalho_id = v_id AND numero_fdi = p_dentes[i];
            IF n = 0 THEN
                INSERT INTO trabalho_dente(trabalho_id, numero_fdi) VALUES (v_id, p_dentes[i]);
            END IF;
        END LOOP;
    END IF;

    RETURN v_id;
END;
$BODY$;


-- #####################################################################
-- 04_procedimentos.sql
-- #####################################################################

-- =====================================================================
-- ABD — Lab CD (DentalLab) — 04. Procedimentos (PL/pgSQL)
--
-- Diferença entre função e procedimento:
--   * uma FUNÇÃO devolve um valor e chama-se com SELECT (ex.: SELECT fn_cliente_crud(...));
--   * um PROCEDIMENTO não devolve nada e chama-se com CALL (ex.: CALL pr_aceitar_ordem(...)).
-- Os procedimentos abaixo são "ações" do dia a dia do laboratório. Por dentro
-- reaproveitam as funções CRUD (03_funcoes.sql), para valerem as mesmas validações.
--
-- Correr depois de 03_funcoes.sql.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Utilizador atual (usado pela auditoria)
-- ---------------------------------------------------------------------

-- Guarda quem está a fazer as alterações, para o trigger de auditoria
-- (05_triggers.sql) registar o utilizador em registo_auditoria.
-- O valor só dura até ao fim da transação (terceiro parâmetro do set_config = TRUE).
-- Exemplo:
--   BEGIN;
--   CALL pr_definir_utilizador(1);
--   SELECT fn_cliente_crud('DELETE', 3);   -- fica registado como feito pelo utilizador 1
--   COMMIT;
CREATE OR REPLACE PROCEDURE public.pr_definir_utilizador(
    p_utilizador_id bigint)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    PERFORM set_config('app.utilizador_id', COALESCE(p_utilizador_id::text, ''), TRUE);
END;
$BODY$;


-- ---------------------------------------------------------------------
-- Ordens de trabalho
-- ---------------------------------------------------------------------

-- Muda o estado de uma ordem, indicando o estado pelo nome (ex.: 'Em espera').
-- O motivo é obrigatório nos estados "Em espera" e "Rejeitado".
-- As datas (início, conclusão, entrega) e a notificação à clínica são tratadas
-- pelos triggers da tabela ordem_trabalho.
CREATE OR REPLACE PROCEDURE public.pr_mudar_estado_ordem(
    p_ordem_id      bigint,
    p_utilizador_id bigint,
    p_estado        character varying,
    p_motivo        text DEFAULT NULL)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_estado_id bigint;
BEGIN
    SELECT id INTO v_estado_id FROM estado_ordem WHERE designacao = p_estado;
    IF v_estado_id IS NULL THEN
        RAISE EXCEPTION 'O estado "%" não existe', p_estado;
    END IF;

    IF p_estado IN ('Em espera', 'Rejeitado') AND (p_motivo IS NULL OR trim(p_motivo) = '') THEN
        RAISE EXCEPTION 'Tem de indicar o motivo para o estado "%"', p_estado;
    END IF;

    CALL pr_definir_utilizador(p_utilizador_id);

    -- a fn_ordem_trabalho_crud confirma que a ordem existe e não foi eliminada
    PERFORM fn_ordem_trabalho_crud(
        p_operacao        => 'UPDATE',
        p_id              => p_ordem_id,
        p_estado_ordem_id => v_estado_id,
        p_motivo_espera   => CASE WHEN p_estado = 'Em espera' THEN p_motivo END,
        p_motivo_rejeicao => CASE WHEN p_estado = 'Rejeitado' THEN p_motivo END);
END;
$BODY$;


-- O laboratório aceita uma ordem que está "Em avaliação": fica "Por iniciar",
-- com o prazo de entrega e quem a aceitou (a data de aceitação é preenchida
-- pela fn_ordem_trabalho_crud).
CREATE OR REPLACE PROCEDURE public.pr_aceitar_ordem(
    p_ordem_id   bigint,
    p_aceite_por bigint,
    p_prazo      date)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_estado character varying;
BEGIN
    SELECT e.designacao INTO v_estado
    FROM ordem_trabalho o
    JOIN estado_ordem e ON e.id = o.estado_ordem_id
    WHERE o.id = p_ordem_id AND o.eliminado_em IS NULL;

    IF v_estado IS NULL THEN
        RAISE EXCEPTION 'A ordem de trabalho % não existe', p_ordem_id;
    END IF;
    IF v_estado <> 'Em avaliação' THEN
        RAISE EXCEPTION 'Só se aceitam ordens "Em avaliação" (esta está "%")', v_estado;
    END IF;
    IF p_prazo IS NULL OR p_prazo < current_date THEN
        RAISE EXCEPTION 'Tem de indicar um prazo de entrega a partir de hoje';
    END IF;

    CALL pr_definir_utilizador(p_aceite_por);

    -- a fn_ordem_trabalho_crud confirma que quem aceita é do laboratório e está ativo
    PERFORM fn_ordem_trabalho_crud(
        p_operacao        => 'UPDATE',
        p_id              => p_ordem_id,
        p_estado_ordem_id => (SELECT id FROM estado_ordem WHERE designacao = 'Por iniciar'),
        p_aceite_por      => p_aceite_por,
        p_prazo_entrega   => p_prazo);
END;
$BODY$;


-- ---------------------------------------------------------------------
-- Tipos de trabalho
-- ---------------------------------------------------------------------

-- Define (ou redefine) a lista ordenada de etapas de um tipo de trabalho.
-- p_etapas é a lista de ids da tabela etapa, pela ordem em que se fazem
-- (a mesma etapa pode repetir-se, ex.: duas provas).
-- A lista anterior é apagada e substituída. Os trabalhos já criados não mudam,
-- porque guardam a sua própria cópia em etapa_trabalho.
CREATE OR REPLACE PROCEDURE public.pr_definir_etapas_tipo_trabalho(
    p_tipo_trabalho_id bigint,
    p_etapas           bigint[])
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    n integer;
    i integer;
BEGIN
    SELECT count(*) INTO n FROM tipo_trabalho WHERE id = p_tipo_trabalho_id;
    IF n = 0 THEN
        RAISE EXCEPTION 'O tipo de trabalho % não existe', p_tipo_trabalho_id;
    END IF;

    IF p_etapas IS NULL OR array_length(p_etapas, 1) IS NULL THEN
        RAISE EXCEPTION 'Tem de indicar pelo menos uma etapa';
    END IF;

    DELETE FROM etapa_tipo_trabalho WHERE tipo_trabalho_id = p_tipo_trabalho_id;

    FOR i IN 1..array_length(p_etapas, 1) LOOP
        SELECT count(*) INTO n FROM etapa WHERE id = p_etapas[i] AND ativa;
        IF n = 0 THEN
            RAISE EXCEPTION 'A etapa % não existe ou está inativa', p_etapas[i];
        END IF;

        INSERT INTO etapa_tipo_trabalho(tipo_trabalho_id, ordem, etapa_id)
        VALUES (p_tipo_trabalho_id, i, p_etapas[i]);
    END LOOP;
END;
$BODY$;


-- ---------------------------------------------------------------------
-- Etapas de cada trabalho (produção)
-- ---------------------------------------------------------------------

-- Um colaborador começa uma etapa: fica responsável por ela e a data de início é agora.
-- O trigger trg_etapa_trabalho_validar_inicio impede começar uma etapa
-- antes de as anteriores estarem concluídas.
CREATE OR REPLACE PROCEDURE public.pr_iniciar_etapa(
    p_etapa_trabalho_id bigint,
    p_responsavel_id    bigint)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_inicio timestamptz;
    n        integer;
BEGIN
    SELECT count(*), max(data_inicio) INTO n, v_inicio
    FROM etapa_trabalho WHERE id = p_etapa_trabalho_id;
    IF n = 0 THEN
        RAISE EXCEPTION 'A etapa de trabalho % não existe', p_etapa_trabalho_id;
    END IF;
    IF v_inicio IS NOT NULL THEN
        RAISE EXCEPTION 'Esta etapa já foi iniciada';
    END IF;

    CALL pr_definir_utilizador(p_responsavel_id);

    -- a fn_etapa_trabalho_crud confirma que o responsável é do laboratório e está ativo
    PERFORM fn_etapa_trabalho_crud(
        p_operacao       => 'UPDATE',
        p_id             => p_etapa_trabalho_id,
        p_responsavel_id => p_responsavel_id,
        p_data_inicio    => now());
END;
$BODY$;


-- O responsável dá a etapa por concluída. Só se concluem etapas já iniciadas.
-- Se for a última etapa da ordem, o trigger trg_etapa_trabalho_atualizar_ordem
-- passa a ordem para "Concluído".
CREATE OR REPLACE PROCEDURE public.pr_concluir_etapa(
    p_etapa_trabalho_id bigint,
    p_utilizador_id     bigint)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_etapa etapa_trabalho%ROWTYPE;
BEGIN
    SELECT * INTO v_etapa FROM etapa_trabalho WHERE id = p_etapa_trabalho_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'A etapa de trabalho % não existe', p_etapa_trabalho_id;
    END IF;
    IF v_etapa.data_inicio IS NULL THEN
        RAISE EXCEPTION 'A etapa "%" ainda não foi iniciada', v_etapa.nome;
    END IF;
    IF v_etapa.data_conclusao IS NOT NULL THEN
        RAISE EXCEPTION 'A etapa "%" já está concluída', v_etapa.nome;
    END IF;

    CALL pr_definir_utilizador(p_utilizador_id);

    PERFORM fn_etapa_trabalho_crud(
        p_operacao       => 'UPDATE',
        p_id             => p_etapa_trabalho_id,
        p_data_conclusao => now());
END;
$BODY$;


-- ---------------------------------------------------------------------
-- Notificações
-- ---------------------------------------------------------------------

-- Marca como lidas as notificações de um utilizador.
-- Com p_notificacao_id marca só essa; sem ele (NULL) marca todas as que estão por ler.
CREATE OR REPLACE PROCEDURE public.pr_marcar_notificacoes_lidas(
    p_utilizador_id  bigint,
    p_notificacao_id bigint DEFAULT NULL)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    UPDATE notificacao
    SET data_leitura = now()
    WHERE utilizador_id = p_utilizador_id
      AND data_leitura IS NULL
      AND (p_notificacao_id IS NULL OR id = p_notificacao_id);
END;
$BODY$;


-- #####################################################################
-- 05_triggers.sql
-- #####################################################################

-- =====================================================================
-- ABD — Lab CD (DentalLab) — 05. Triggers
--
-- Em PostgreSQL um trigger tem duas partes:
--   1. uma FUNÇÃO DE TRIGGER (RETURNS trigger), com o código a executar;
--   2. o CREATE TRIGGER, que liga essa função a uma tabela e a um evento
--      (INSERT, UPDATE, DELETE), antes (BEFORE) ou depois (AFTER) da operação.
-- Dentro da função existem as variáveis NEW (linha nova) e OLD (linha antiga),
-- TG_OP ('INSERT', 'UPDATE' ou 'DELETE') e TG_TABLE_NAME (nome da tabela).
--
-- BEFORE: pode alterar NEW antes de gravar (ou cancelar com RAISE EXCEPTION).
-- AFTER : a linha já está gravada; serve para registar ou mexer noutras tabelas.
--
-- Lista:
--   T1 trg_<tabela>_auditoria                 auditoria de várias tabelas
--   T2 trg_ordem_trabalho_datas               datas automáticas pelo estado
--   T3 trg_ordem_trabalho_notificar_estado    avisa a clínica quando o estado muda
--   T4 trg_ordem_trabalho_notificar_nova      avisa os administradores de uma ordem nova
--   T5 trg_trabalho_validar_ordem             não deixa juntar trabalhos a ordens fechadas
--   T6 trg_etapa_trabalho_validar_inicio      etapas só em ordens aceites e pela ordem certa
--   T7 trg_etapa_trabalho_atualizar_ordem     o progresso das etapas muda o estado da ordem
--   T8 trg_comentario_data_edicao             data de edição dos comentários
--
-- Correr depois de 04_procedimentos.sql.
-- =====================================================================


-- ---------------------------------------------------------------------
-- T1. Auditoria
-- Cada INSERT, UPDATE ou DELETE nas tabelas principais fica guardado em
-- registo_auditoria, com os valores antes e depois (em JSON).
-- O utilizador vem de pr_definir_utilizador (04_procedimentos.sql);
-- se não tiver sido definido, fica NULL.
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_trg_auditoria()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_antes  jsonb;
    v_depois jsonb;
    v_id     bigint;
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        -- o hash da password nunca vai para a auditoria
        v_antes := to_jsonb(OLD) - 'password_hash';
    END IF;
    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        v_depois := to_jsonb(NEW) - 'password_hash';
    END IF;

    -- UPDATE que não mudou nada: não regista
    IF TG_OP = 'UPDATE' AND v_antes = v_depois THEN
        RETURN NULL;
    END IF;

    v_id := (COALESCE(v_depois, v_antes) ->> 'id')::bigint;

    INSERT INTO registo_auditoria(utilizador_id, acao, entidade_afetada, id_entidade_afetada,
                                  valores_anteriores, valores_posteriores)
    VALUES (NULLIF(current_setting('app.utilizador_id', TRUE), '')::bigint,
            TG_OP, TG_TABLE_NAME, v_id, v_antes, v_depois);

    -- num trigger AFTER o valor devolvido é ignorado
    RETURN NULL;
END;
$BODY$;

-- A mesma função serve para todas as tabelas (todas têm a coluna id).
CREATE TRIGGER trg_cargo_auditoria
    AFTER INSERT OR UPDATE OR DELETE ON cargo
    FOR EACH ROW EXECUTE FUNCTION fn_trg_auditoria();

CREATE TRIGGER trg_utilizador_auditoria
    AFTER INSERT OR UPDATE OR DELETE ON utilizador
    FOR EACH ROW EXECUTE FUNCTION fn_trg_auditoria();

CREATE TRIGGER trg_cliente_auditoria
    AFTER INSERT OR UPDATE OR DELETE ON cliente
    FOR EACH ROW EXECUTE FUNCTION fn_trg_auditoria();

CREATE TRIGGER trg_alteracao_cliente_auditoria
    AFTER INSERT OR UPDATE OR DELETE ON alteracao_cliente
    FOR EACH ROW EXECUTE FUNCTION fn_trg_auditoria();

CREATE TRIGGER trg_estado_ordem_auditoria
    AFTER INSERT OR UPDATE OR DELETE ON estado_ordem
    FOR EACH ROW EXECUTE FUNCTION fn_trg_auditoria();

CREATE TRIGGER trg_ordem_trabalho_auditoria
    AFTER INSERT OR UPDATE OR DELETE ON ordem_trabalho
    FOR EACH ROW EXECUTE FUNCTION fn_trg_auditoria();

CREATE TRIGGER trg_tipo_trabalho_auditoria
    AFTER INSERT OR UPDATE OR DELETE ON tipo_trabalho
    FOR EACH ROW EXECUTE FUNCTION fn_trg_auditoria();

CREATE TRIGGER trg_trabalho_auditoria
    AFTER INSERT OR UPDATE OR DELETE ON trabalho
    FOR EACH ROW EXECUTE FUNCTION fn_trg_auditoria();

CREATE TRIGGER trg_etapa_trabalho_auditoria
    AFTER INSERT OR UPDATE OR DELETE ON etapa_trabalho
    FOR EACH ROW EXECUTE FUNCTION fn_trg_auditoria();


-- ---------------------------------------------------------------------
-- T2. Datas automáticas da ordem
-- Quando o estado de uma ordem muda, preenche a data correspondente
-- (só se ainda estiver vazia, para não apagar a data original).
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_trg_ordem_trabalho_datas()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_estado character varying;
BEGIN
    SELECT designacao INTO v_estado FROM estado_ordem WHERE id = NEW.estado_ordem_id;

    IF v_estado = 'Em processamento' THEN
        NEW.data_inicio := COALESCE(NEW.data_inicio, now());
    ELSIF v_estado = 'Concluído' THEN
        NEW.data_conclusao := COALESCE(NEW.data_conclusao, now());
    ELSIF v_estado = 'Entregue' THEN
        NEW.data_conclusao := COALESCE(NEW.data_conclusao, now());
        NEW.data_entrega   := COALESCE(NEW.data_entrega, now());
    END IF;

    -- num trigger BEFORE, o que se devolve é o que fica gravado
    RETURN NEW;
END;
$BODY$;

CREATE TRIGGER trg_ordem_trabalho_datas
    BEFORE UPDATE OF estado_ordem_id ON ordem_trabalho
    FOR EACH ROW
    WHEN (OLD.estado_ordem_id IS DISTINCT FROM NEW.estado_ordem_id)
    EXECUTE FUNCTION fn_trg_ordem_trabalho_datas();


-- ---------------------------------------------------------------------
-- T3. Notificar a clínica quando o estado da ordem muda
-- Cria uma notificação (o "sininho") para cada conta ativa da clínica.
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_trg_ordem_trabalho_notificar_estado()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_estado character varying;
BEGIN
    SELECT designacao INTO v_estado FROM estado_ordem WHERE id = NEW.estado_ordem_id;

    INSERT INTO notificacao(utilizador_id, ordem_trabalho_id, mensagem)
    SELECT u.id, NEW.id,
           format('A ordem n.º %s passou para o estado "%s".', NEW.id, v_estado)
    FROM utilizador u
    WHERE u.cliente_id = NEW.cliente_id AND u.ativo;

    RETURN NULL;
END;
$BODY$;

CREATE TRIGGER trg_ordem_trabalho_notificar_estado
    AFTER UPDATE OF estado_ordem_id ON ordem_trabalho
    FOR EACH ROW
    WHEN (OLD.estado_ordem_id IS DISTINCT FROM NEW.estado_ordem_id)
    EXECUTE FUNCTION fn_trg_ordem_trabalho_notificar_estado();


-- ---------------------------------------------------------------------
-- T4. Notificar os administradores de uma ordem nova
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_trg_ordem_trabalho_notificar_nova()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_cliente character varying;
BEGIN
    SELECT nome INTO v_cliente FROM cliente WHERE id = NEW.cliente_id;

    INSERT INTO notificacao(utilizador_id, ordem_trabalho_id, mensagem)
    SELECT u.id, NEW.id,
           format('Nova ordem n.º %s de %s, para avaliar.', NEW.id, v_cliente)
    FROM utilizador u
    JOIN cargo c ON c.id = u.cargo_id
    WHERE c.designacao = 'Administrador' AND u.ativo;

    RETURN NULL;
END;
$BODY$;

CREATE TRIGGER trg_ordem_trabalho_notificar_nova
    AFTER INSERT ON ordem_trabalho
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_ordem_trabalho_notificar_nova();


-- ---------------------------------------------------------------------
-- T5. Não deixar juntar trabalhos a ordens fechadas
-- Uma ordem rejeitada, concluída ou entregue já não recebe trabalhos novos.
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_trg_trabalho_validar_ordem()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_estado character varying;
BEGIN
    SELECT e.designacao INTO v_estado
    FROM ordem_trabalho o
    JOIN estado_ordem e ON e.id = o.estado_ordem_id
    WHERE o.id = NEW.ordem_trabalho_id;

    IF v_estado IN ('Rejeitado', 'Concluído', 'Entregue') THEN
        RAISE EXCEPTION 'Não é possível juntar trabalhos a uma ordem no estado "%"', v_estado;
    END IF;

    RETURN NEW;
END;
$BODY$;

CREATE TRIGGER trg_trabalho_validar_ordem
    BEFORE INSERT ON trabalho
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_trabalho_validar_ordem();


-- ---------------------------------------------------------------------
-- T6. As etapas de um trabalho fazem-se por ordem
-- Uma etapa só pode começar se a ordem já tiver sido aceite (e ainda não
-- estiver fechada) e quando todas as etapas anteriores estiverem concluídas.
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_trg_etapa_trabalho_validar_inicio()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_estado   character varying;
    v_anterior character varying;
BEGIN
    -- estado da ordem a que pertence o trabalho
    SELECT e.designacao INTO v_estado
    FROM trabalho t
    JOIN ordem_trabalho o ON o.id = t.ordem_trabalho_id
    JOIN estado_ordem e   ON e.id = o.estado_ordem_id
    WHERE t.id = NEW.trabalho_id;

    IF v_estado NOT IN ('Por iniciar', 'Em processamento', 'Em prova') THEN
        RAISE EXCEPTION 'Não é possível começar etapas de uma ordem no estado "%"', v_estado;
    END IF;

    -- primeira etapa anterior que ainda não está concluída (se houver)
    SELECT nome INTO v_anterior
    FROM etapa_trabalho
    WHERE trabalho_id = NEW.trabalho_id
      AND ordem < NEW.ordem
      AND data_conclusao IS NULL
    ORDER BY ordem
    LIMIT 1;

    IF v_anterior IS NOT NULL THEN
        RAISE EXCEPTION 'Antes de começar "%" tem de concluir a etapa "%"', NEW.nome, v_anterior;
    END IF;

    RETURN NEW;
END;
$BODY$;

CREATE TRIGGER trg_etapa_trabalho_validar_inicio
    BEFORE UPDATE OF data_inicio ON etapa_trabalho
    FOR EACH ROW
    WHEN (OLD.data_inicio IS NULL AND NEW.data_inicio IS NOT NULL)
    EXECUTE FUNCTION fn_trg_etapa_trabalho_validar_inicio();


-- ---------------------------------------------------------------------
-- T7. O progresso das etapas muda o estado da ordem
--   * quando começa a primeira etapa, a ordem "Por iniciar" passa a "Em processamento";
--   * quando termina a última etapa de todos os trabalhos, a ordem passa a "Concluído".
-- Este UPDATE à ordem dispara, por sua vez, os triggers T1, T2 e T3.
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_trg_etapa_trabalho_atualizar_ordem()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_ordem_id bigint;
    v_estado   character varying;
    n          integer;
BEGIN
    SELECT o.id, e.designacao INTO v_ordem_id, v_estado
    FROM trabalho t
    JOIN ordem_trabalho o ON o.id = t.ordem_trabalho_id
    JOIN estado_ordem e   ON e.id = o.estado_ordem_id
    WHERE t.id = NEW.trabalho_id;

    -- uma etapa começou
    IF OLD.data_inicio IS NULL AND NEW.data_inicio IS NOT NULL AND v_estado = 'Por iniciar' THEN
        UPDATE ordem_trabalho
        SET estado_ordem_id = (SELECT id FROM estado_ordem WHERE designacao = 'Em processamento')
        WHERE id = v_ordem_id;
    END IF;

    -- uma etapa terminou: ainda há etapas por concluir nesta ordem?
    IF OLD.data_conclusao IS NULL AND NEW.data_conclusao IS NOT NULL THEN
        SELECT count(*) INTO n
        FROM etapa_trabalho et
        JOIN trabalho t ON t.id = et.trabalho_id
        WHERE t.ordem_trabalho_id = v_ordem_id
          AND t.eliminado_em IS NULL
          AND et.data_conclusao IS NULL;

        IF n = 0 THEN
            UPDATE ordem_trabalho
            SET estado_ordem_id = (SELECT id FROM estado_ordem WHERE designacao = 'Concluído')
            WHERE id = v_ordem_id;
        END IF;
    END IF;

    RETURN NULL;
END;
$BODY$;

CREATE TRIGGER trg_etapa_trabalho_atualizar_ordem
    AFTER UPDATE OF data_inicio, data_conclusao ON etapa_trabalho
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_etapa_trabalho_atualizar_ordem();


-- ---------------------------------------------------------------------
-- T8. Data de edição dos comentários
-- Sempre que o texto de um comentário muda, guarda a data da edição.
-- ---------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_trg_comentario_data_edicao()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    NEW.data_edicao := now();
    RETURN NEW;
END;
$BODY$;

CREATE TRIGGER trg_comentario_data_edicao
    BEFORE UPDATE OF conteudo ON comentario
    FOR EACH ROW
    WHEN (OLD.conteudo IS DISTINCT FROM NEW.conteudo)
    EXECUTE FUNCTION fn_trg_comentario_data_edicao();


-- #####################################################################
-- 06_dados_iniciais.sql
-- #####################################################################

-- =====================================================================
-- ABD — Lab CD (DentalLab) — 06. Dados iniciais
-- Origem: modelofisico.sql. Corre depois dos triggers, por isso a criação
-- do administrador já fica no registo de auditoria.
-- =====================================================================


INSERT INTO cargo (designacao) VALUES
    ('Administrador'),
    ('Colaborador'),
    ('Cliente');

-- Estados visíveis pela clínica (sugeridos pela cliente)
INSERT INTO estado_ordem (designacao) VALUES
    ('Em avaliação'),
    ('Rejeitado'),
    ('Por iniciar'),
    ('Em processamento'),
    ('Em espera'),
    ('Em prova'),
    ('Concluído'),
    ('Entregue');

INSERT INTO tipo_ficheiro (designacao) VALUES
    ('STL'),
    ('Fotografia'),
    ('Documento'),
    ('Outro');

-- Administrador pré-configurado (único utilizador criado pelo script).
-- Password provisória: Admin#2026 (hash bcrypt), a alterar no primeiro login.
-- Como não há quem o aprove, fica aprovado por si próprio.
INSERT INTO utilizador (cargo_id, nome, email, password_hash, password_temporaria)
SELECT c.id, 'Administrador', 'admin@dentallab.local',
       '$2a$12$VAqXKiYsU6rR5iw1ehHsvOvic9icZwiAWc7.BPIrkquswaOaC4a6O', TRUE
FROM cargo c
WHERE c.designacao = 'Administrador';

UPDATE utilizador
SET aprovado_por = id, data_aprovacao = now()
WHERE lower(email) = 'admin@dentallab.local';

COMMIT;
