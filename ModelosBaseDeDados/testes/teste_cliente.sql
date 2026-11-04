-- Teste da fn_cliente_crud (crud/crud_cliente_etapa_trabalho.sql):
-- ao desativar ou reativar uma clínica, as contas de acesso dela acompanham.
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
BEGIN
    -- 1. Clínica de teste, com a sua conta
    v_cliente := fn_registar_clinica('Clínica Teste', '509990101', 'Rua A, Viseu', NULL, 'teste@clinica.pt', 'HASH');
    SELECT * INTO v_conta FROM vw_utilizador WHERE cliente_id = v_cliente;
    RAISE NOTICE '1. Clínica % criada. Conta ativa: %', v_cliente, v_conta.ativo;

    -- 2. O administrador desativa a clínica (DELETE): a conta também fica desativada
    PERFORM fn_cliente_crud('DELETE', v_cliente);
    SELECT * INTO v_conta FROM vw_utilizador WHERE cliente_id = v_cliente;
    RAISE NOTICE '2. Clínica desativada. Conta ativa: % (esperado: false)', v_conta.ativo;

    -- 3. O administrador reativa a clínica (UPDATE com p_ativo = TRUE): a conta volta a ficar ativa
    PERFORM fn_cliente_crud(p_operacao => 'UPDATE', p_id => v_cliente, p_ativo => TRUE);
    SELECT * INTO v_conta FROM vw_utilizador WHERE cliente_id = v_cliente;
    RAISE NOTICE '3. Clínica reativada. Conta ativa: % (esperado: true)', v_conta.ativo;

    -- 4. Alterar só o telefone (p_ativo a NULL): a conta não muda
    PERFORM fn_cliente_crud(p_operacao => 'UPDATE', p_id => v_cliente, p_telefone => '232000000');
    SELECT * INTO v_conta FROM vw_utilizador WHERE cliente_id = v_cliente;
    RAISE NOTICE '4. Telefone alterado. Conta ativa: % (esperado: true)', v_conta.ativo;

    -- 5. NIF com letras: tem de dar erro (regra ck_cliente_nif da tabela)
    BEGIN
        PERFORM fn_cliente_crud(p_operacao => 'UPDATE', p_id => v_cliente, p_nif => '50123456A');
        RAISE NOTICE '5. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '5. Erro esperado: %', SQLERRM;
    END;

    RAISE NOTICE 'Teste terminado sem problemas.';
END
$$;

-- Desfaz tudo o que o teste criou.
ROLLBACK;
