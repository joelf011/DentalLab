-- Vistas e funções CRUD das entidades cargo e utilizador

-- cargo

CREATE OR REPLACE VIEW vw_cargo AS
SELECT c.id, c.designacao
FROM cargo c;


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


-- utilizador

-- Não mostra o password_hash.
-- cargo_id e cliente_id estão no fim porque foram acrescentados depois
-- (o CREATE OR REPLACE VIEW só aceita colunas novas no fim).
CREATE OR REPLACE VIEW vw_utilizador AS
SELECT u.id, u.nome, u.email,
       c.designacao AS cargo,
       cl.nome      AS cliente,
       u.password_temporaria, u.ativo,
       u.aprovado_por, u.data_aprovacao, u.criado_em,
       u.cargo_id, u.cliente_id
FROM utilizador u
JOIN cargo c         ON c.id = u.cargo_id
LEFT JOIN cliente cl ON cl.id = u.cliente_id;


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
