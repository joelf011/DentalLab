-- Vistas e funções CRUD das entidades estado_ordem e ordem_trabalho

-- estado_ordem

CREATE OR REPLACE VIEW vw_estado_ordem AS
SELECT e.id, e.designacao
FROM estado_ordem e;


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
