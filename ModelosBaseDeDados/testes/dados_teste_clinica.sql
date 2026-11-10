-- Dados de teste: uma clínica com conta de acesso JÁ APROVADA, para experimentar a API.
--
-- ATENÇÃO: ao contrário dos outros ficheiros desta pasta, este NÃO desfaz nada: a clínica fica na BD.
-- Pode correr-se várias vezes (se a conta já existir, não faz nada).
--
-- Login da clínica de teste:
--   email:    clinica.teste@dentallab.local
--   password: Clinica#2026
--
-- Como usar: abrir no Query Tool da BD dentallab e correr tudo (F5). O resultado aparece em "Messages".

DO $$
DECLARE
    v_cliente bigint;
    v_conta   bigint;
    v_admin   bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM vw_utilizador WHERE email = 'clinica.teste@dentallab.local') THEN
        RAISE NOTICE 'A clínica de teste já existe. Nada a fazer.';
        RETURN;
    END IF;

    -- regista a clínica (fica por aprovar), com o hash bcrypt de "Clinica#2026"
    v_cliente := fn_registar_clinica(
        'Clínica de Teste', '509990010', 'Rua de Teste 1, Viseu', '232000000',
        'clinica.teste@dentallab.local',
        '$2b$12$dUE1itVp/hrHPoqlDIMIpexj2nFpt2RvqLtlN0f9H5iiigkWRHiv.');

    -- o primeiro administrador aprova a conta
    SELECT id INTO v_conta FROM vw_utilizador WHERE cliente_id = v_cliente;
    SELECT id INTO v_admin FROM vw_utilizador WHERE cargo = 'Administrador' AND ativo ORDER BY id LIMIT 1;
    PERFORM fn_utilizador_crud(p_operacao => 'UPDATE', p_id => v_conta, p_aprovado_por => v_admin);

    RAISE NOTICE 'Clínica de teste criada (cliente %, conta %) e aprovada.', v_cliente, v_conta;
END
$$;
