-- Teste das funções dos pedidos de alteração (crud/crud_alteracao_cliente.sql).
--
-- Como usar: abrir no Query Tool da BD dentallab e correr tudo (F5).
-- Os resultados aparecem no separador "Messages".
-- No fim, tudo é desfeito (ROLLBACK): a BD fica exatamente como estava.

-- Desfaz alguma transação que tenha ficado a meio neste separador.
-- Se não houver nenhuma, aparece só o aviso "there is no transaction in progress", que é normal.
ROLLBACK;

BEGIN;

-- Um bloco DO corre código plpgsql sem criar uma função.
DO $$
DECLARE
    v_cliente bigint;
    v_conta   bigint;
    v_admin   bigint;
    v_pedido  bigint;
    v_linha   record;
BEGIN
    -- 1. Clínica de teste, com a sua conta
    v_cliente := fn_registar_clinica('Clínica Teste', '501234567', 'Rua A, Viseu', '232000000', 'teste@clinica.pt', 'HASH');
    SELECT id INTO v_conta FROM vw_utilizador WHERE email = 'teste@clinica.pt';
    SELECT id INTO v_admin FROM vw_utilizador WHERE cargo = 'Administrador' AND ativo ORDER BY id LIMIT 1;
    RAISE NOTICE '1. Clínica % criada (conta %). Administrador: %', v_cliente, v_conta, v_admin;

    -- 2. A clínica pede nova morada e novo telefone
    v_pedido := fn_pedir_alteracao_cliente(v_cliente, v_conta, NULL, 'Rua B, Viseu', NULL, '232111111');
    SELECT * INTO v_linha FROM vw_alteracao_cliente WHERE id = v_pedido;
    RAISE NOTICE '2. Pedido % (%): morada "%" -> "%"', v_pedido, v_linha.estado, v_linha.morada_faturacao_atual, v_linha.morada_faturacao;

    -- 3. Segundo pedido enquanto o primeiro está à espera: tem de dar erro
    BEGIN
        PERFORM fn_pedir_alteracao_cliente(v_cliente, v_conta, 'Outro nome');
        RAISE NOTICE '3. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '3. Erro esperado: %', SQLERRM;
    END;

    -- 4. A clínica tenta decidir o próprio pedido: tem de dar erro
    BEGIN
        PERFORM fn_decidir_alteracao_cliente(v_pedido, v_conta, TRUE);
        RAISE NOTICE '4. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '4. Erro esperado: %', SQLERRM;
    END;

    -- 5. O administrador aprova: os dados passam para a clínica
    PERFORM fn_decidir_alteracao_cliente(v_pedido, v_admin, TRUE);
    SELECT * INTO v_linha FROM vw_cliente WHERE id = v_cliente;
    RAISE NOTICE '5. Aprovado. Clínica agora: morada "%", telefone "%", nome "%"', v_linha.morada_faturacao, v_linha.telefone, v_linha.nome;

    -- 6. Novo pedido (nome), rejeitado com motivo: o nome não muda
    v_pedido := fn_pedir_alteracao_cliente(v_cliente, v_conta, 'Clínica Teste Feliz');
    PERFORM fn_decidir_alteracao_cliente(v_pedido, v_admin, FALSE, 'O nome tem de ser o do registo comercial');
    SELECT * INTO v_linha FROM vw_alteracao_cliente WHERE id = v_pedido;
    RAISE NOTICE '6. Pedido % %: "%". Nome da clínica: "%"', v_pedido, v_linha.estado, v_linha.motivo_rejeicao, v_linha.nome_atual;

    RAISE NOTICE 'Teste terminado sem problemas.';
END
$$;

-- Desfaz tudo o que o teste criou.
ROLLBACK;
