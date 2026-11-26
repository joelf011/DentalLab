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
