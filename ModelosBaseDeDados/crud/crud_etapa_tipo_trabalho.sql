-- Etapas configuradas para cada tipo de trabalho.
CREATE OR REPLACE VIEW vw_etapa_tipo_trabalho AS
SELECT ett.tipo_trabalho_id, ett.ordem, ett.etapa_id, e.nome
FROM etapa_tipo_trabalho ett
JOIN etapa e ON e.id = ett.etapa_id
ORDER BY ett.tipo_trabalho_id, ett.ordem;

-- Substitui a lista inteira; um array vazio remove a configuração.
-- A mesma etapa pode aparecer mais do que uma vez.
CREATE OR REPLACE FUNCTION public.fn_definir_etapas_tipo_trabalho(
    p_tipo_trabalho_id bigint,
    p_etapas          bigint[])
RETURNS bigint
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_etapa_id bigint;
    v_ordem    integer := 0;
    n          integer;
BEGIN
    -- Impede duas substituições simultâneas da configuração do mesmo tipo.
    PERFORM id FROM tipo_trabalho
    WHERE id = p_tipo_trabalho_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'O tipo de trabalho % não existe', p_tipo_trabalho_id;
    END IF;

    IF p_etapas IS NULL THEN
        RAISE EXCEPTION 'Tem de indicar a lista de etapas';
    END IF;

    IF array_ndims(p_etapas) > 1 THEN
        RAISE EXCEPTION 'As etapas têm de ser indicadas numa lista simples';
    END IF;

    -- A coluna ordem é SMALLINT, com o limite de 32767.
    IF cardinality(p_etapas) > 32767 THEN
        RAISE EXCEPTION 'A lista não pode ter mais de 32767 etapas';
    END IF;

    -- Valida toda a lista antes de substituir a configuração anterior.
    FOREACH v_etapa_id IN ARRAY p_etapas LOOP
        IF v_etapa_id IS NULL THEN
            RAISE EXCEPTION 'A lista não pode conter etapas sem identificação';
        END IF;

        SELECT count(*) INTO n FROM etapa
        WHERE id = v_etapa_id AND ativa;
        IF n = 0 THEN
            RAISE EXCEPTION 'A etapa % não existe ou está desativada', v_etapa_id;
        END IF;
    END LOOP;

    DELETE FROM etapa_tipo_trabalho
    WHERE tipo_trabalho_id = p_tipo_trabalho_id;

    FOREACH v_etapa_id IN ARRAY p_etapas LOOP
        v_ordem := v_ordem + 1;
        INSERT INTO etapa_tipo_trabalho(tipo_trabalho_id, ordem, etapa_id)
        VALUES (p_tipo_trabalho_id, v_ordem, v_etapa_id);
    END LOOP;

    RETURN p_tipo_trabalho_id;
END;
$BODY$;
