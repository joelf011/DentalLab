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
