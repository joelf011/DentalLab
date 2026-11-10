-- Vista e função CRUD das etapas do catálogo.

CREATE OR REPLACE VIEW vw_etapa AS
SELECT e.id, e.nome, e.descricao, e.ativa
FROM etapa e;

-- Em UPDATE, os parâmetros a NULL mantêm o valor atual.
-- DELETE desativa a etapa; UPDATE com p_ativa = TRUE reativa-a.
CREATE OR REPLACE FUNCTION public.fn_etapa_crud(
    p_operacao  character varying,
    p_id        bigint,
    p_nome      character varying DEFAULT NULL,
    p_descricao text              DEFAULT NULL,
    p_ativa     boolean           DEFAULT NULL)
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_operacao character varying := upper(p_operacao);
    v_id       bigint;
    n          integer;
BEGIN
    IF v_operacao IN ('UPDATE', 'DELETE') THEN
        SELECT count(*) INTO n FROM etapa WHERE id = p_id;
        IF n = 0 THEN
            RAISE EXCEPTION 'A etapa % não existe', p_id;
        END IF;
    END IF;

    IF v_operacao IN ('CREATE', 'UPDATE') THEN
        IF (v_operacao = 'CREATE' AND p_nome IS NULL)
           OR (p_nome IS NOT NULL AND trim(p_nome) = '') THEN
            RAISE EXCEPTION 'Tem de indicar o nome da etapa';
        END IF;

        IF p_nome IS NOT NULL THEN
            SELECT count(*) INTO n FROM etapa
            WHERE nome = p_nome
              AND (v_operacao = 'CREATE' OR id IS DISTINCT FROM p_id);
            IF n > 0 THEN
                RAISE EXCEPTION 'Já existe uma etapa com o nome %', p_nome;
            END IF;
        END IF;
    END IF;

    IF v_operacao = 'CREATE' THEN
        INSERT INTO etapa(nome, descricao) VALUES (p_nome, p_descricao)
        RETURNING id INTO v_id;

    ELSIF v_operacao = 'UPDATE' THEN
        UPDATE etapa
        SET nome      = COALESCE(p_nome, nome),
            descricao = COALESCE(p_descricao, descricao),
            ativa     = COALESCE(p_ativa, ativa)
        WHERE id = p_id;
        v_id := p_id;

    ELSIF v_operacao = 'DELETE' THEN
        UPDATE etapa SET ativa = FALSE WHERE id = p_id;
        v_id := p_id;

    ELSE
        RAISE EXCEPTION 'Operação inválida: % (use CREATE, UPDATE ou DELETE)', p_operacao;
    END IF;

    RETURN v_id;
END;
$BODY$;
