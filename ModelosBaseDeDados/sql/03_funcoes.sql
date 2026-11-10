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
