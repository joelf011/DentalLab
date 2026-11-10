-- Vista e funções dos pedidos de alteração dos dados de uma clínica (tabela alteracao_cliente).
-- Precisa da tabela criada por alteracoes/001_alteracao_cliente.sql.

-- Mostra cada pedido ao lado dos dados atuais da clínica, para o Administrador comparar.
CREATE OR REPLACE VIEW vw_alteracao_cliente AS
SELECT a.id, a.cliente_id,
       up.nome AS pedido_por,
       a.data_pedido,
       -- dados atuais
       c.nome             AS nome_atual,
       c.morada_faturacao AS morada_faturacao_atual,
       c.email            AS email_atual,
       c.telefone         AS telefone_atual,
       -- dados pedidos (NULL = não muda)
       a.nome, a.morada_faturacao, a.email, a.telefone,
       -- decisão
       a.estado,
       ud.nome AS decidido_por,
       a.data_decisao, a.motivo_rejeicao
FROM alteracao_cliente a
JOIN cliente c          ON c.id = a.cliente_id
JOIN utilizador up      ON up.id = a.pedido_por
LEFT JOIN utilizador ud ON ud.id = a.decidido_por;


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
