-- =====================================================================
-- Alteração 001: tabela alteracao_cliente
--
-- Pedidos de alteração dos dados de uma clínica, feitos pela própria clínica.
-- Os dados novos só passam para a tabela cliente quando o Administrador aprova
-- (funções em crud/crud_alteracao_cliente.sql).
--
-- Corre-se UMA SÓ VEZ, depois do modelofisico.sql. Para desfazer: DROP TABLE alteracao_cliente;
-- =====================================================================

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
