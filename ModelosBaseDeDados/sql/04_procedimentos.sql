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
