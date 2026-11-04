-- Teste da fn_aprovar_utilizador (crud/crud_cargo_utilizador.sql).
--
-- Como usar: abrir no Query Tool da BD dentallab e correr tudo (F5).
-- Os resultados aparecem no separador "Messages".
-- No fim, tudo é desfeito (ROLLBACK): a BD fica exatamente como estava.

-- Desfaz alguma transação que tenha ficado a meio neste separador (se não houver, só dá um aviso).
ROLLBACK;

BEGIN;

DO $$
DECLARE
    v_cliente bigint;
    v_conta   record;
    v_admin   bigint;
BEGIN
    -- 1. Clínica que se registou sozinha: a conta fica por aprovar
    v_cliente := fn_registar_clinica('Clínica Teste', '509990101', 'Rua A, Viseu', NULL, 'teste@clinica.pt', 'HASH');
    SELECT * INTO v_conta FROM vw_utilizador WHERE cliente_id = v_cliente;
    SELECT id INTO v_admin FROM vw_utilizador WHERE cargo = 'Administrador' AND ativo ORDER BY id LIMIT 1;
    RAISE NOTICE '1. Conta % criada. Aprovada em: % (esperado: vazio)', v_conta.id, v_conta.data_aprovacao;

    -- 2. A própria clínica tenta aprovar-se: tem de dar erro
    BEGIN
        PERFORM fn_aprovar_utilizador(v_conta.id, v_conta.id);
        RAISE NOTICE '2. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '2. Erro esperado: %', SQLERRM;
    END;

    -- 3. O administrador aprova
    PERFORM fn_aprovar_utilizador(v_conta.id, v_admin);
    SELECT * INTO v_conta FROM vw_utilizador WHERE cliente_id = v_cliente;
    RAISE NOTICE '3. Aprovada por % em %', v_conta.aprovado_por, v_conta.data_aprovacao;

    -- 4. Aprovar outra vez: tem de dar erro
    BEGIN
        PERFORM fn_aprovar_utilizador(v_conta.id, v_admin);
        RAISE NOTICE '4. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '4. Erro esperado: %', SQLERRM;
    END;

    -- 5. Conta desativada (registo recusado): não se pode aprovar
    v_cliente := fn_registar_clinica('Clínica Recusada', '509990102', NULL, NULL, 'recusada@clinica.pt', 'HASH');
    SELECT * INTO v_conta FROM vw_utilizador WHERE cliente_id = v_cliente;
    PERFORM fn_utilizador_crud('DELETE', v_conta.id);
    BEGIN
        PERFORM fn_aprovar_utilizador(v_conta.id, v_admin);
        RAISE NOTICE '5. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '5. Erro esperado: %', SQLERRM;
    END;

    RAISE NOTICE 'Teste terminado sem problemas.';
END
$$;

-- Desfaz tudo o que o teste criou.
ROLLBACK;
