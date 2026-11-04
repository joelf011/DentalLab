-- Vistas e funções CRUD das entidades tipo_trabalho e trabalho

-- tipo_trabalho

CREATE OR REPLACE VIEW vw_tipo_trabalho AS
SELECT t.id, t.nome, t.descricao, t.ativo
FROM tipo_trabalho t;


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
