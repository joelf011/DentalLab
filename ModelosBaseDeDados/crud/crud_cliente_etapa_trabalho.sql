-- Vistas e funções CRUD das entidades cliente e etapa_trabalho

-- cliente

CREATE OR REPLACE VIEW vw_cliente AS
SELECT c.id, c.nome, c.nif, c.morada_faturacao, c.email, c.telefone, c.ativo, c.criado_em
FROM cliente c;


-- CREATE, UPDATE e DELETE; devolve o id do registo afetado.
-- Em UPDATE, os parâmetros a NULL mantêm o valor atual.
-- DELETE desativa o cliente (ativo = FALSE); UPDATE com p_ativo = TRUE reativa-o.
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
        v_id := p_id;

    ELSIF v_operacao = 'DELETE' THEN
        -- o cliente mantém-se por causa do histórico de ordens
        UPDATE cliente SET ativo = FALSE WHERE id = p_id;
        v_id := p_id;

    ELSE
        RAISE EXCEPTION 'Operação inválida: % (use CREATE, UPDATE ou DELETE)', p_operacao;
    END IF;

    RETURN v_id;
END;
$BODY$;


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
