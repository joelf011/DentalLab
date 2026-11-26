-- Teste da auditoria das mudanças de palavra-passe (fn_trg_auditoria, 05_triggers.sql).
--
-- Como usar: abrir no Query Tool da BD abd_lab_cd e correr tudo (F5).
-- Os resultados aparecem no separador "Messages".
-- No fim, tudo é desfeito (ROLLBACK): a BD fica exatamente como estava.

-- Desfaz alguma transação que tenha ficado a meio neste separador (se não houver, só dá um aviso).
ROLLBACK;

BEGIN;

DO $$
DECLARE
    v_admin    bigint;
    v_conta    bigint;
    v_registo  registo_auditoria%ROWTYPE;
BEGIN
    SELECT id INTO v_admin FROM vw_utilizador WHERE cargo = 'Administrador' AND ativo ORDER BY id LIMIT 1;
    -- quem faz as alterações (é o que a API faz antes de cada escrita)
    CALL pr_definir_utilizador(v_admin);

    -- Uma conta de teste, já com a palavra-passe definitiva (password_temporaria = FALSE)
    v_conta := fn_utilizador_crud('CREATE', NULL,
        p_cargo_id            => (SELECT id FROM cargo WHERE designacao = 'Colaborador'),
        p_nome                => 'Conta Teste Auditoria',
        p_email               => 'auditoria@teste.pt',
        p_password_hash       => 'HASH-1',
        p_password_temporaria => FALSE,
        p_aprovado_por        => v_admin);

    -- 1. Muda só a palavra-passe: tem de ficar registado
    PERFORM fn_utilizador_crud('UPDATE', v_conta, p_password_hash => 'HASH-2');
    SELECT * INTO v_registo FROM registo_auditoria
     WHERE entidade_afetada = 'utilizador' AND id_entidade_afetada = v_conta AND acao = 'UPDATE'
     ORDER BY id DESC LIMIT 1;
    IF NOT FOUND THEN
        RAISE NOTICE '1. FALHOU: a mudança da palavra-passe não ficou registada';
    ELSE
        RAISE NOTICE '1. Registado por % em %: password_alterada = % (esperado: true)',
            v_registo.utilizador_id, v_registo.data_hora, v_registo.valores_posteriores ->> 'password_alterada';
    END IF;

    -- 2. O hash nunca vai para a auditoria
    IF v_registo.valores_anteriores ? 'password_hash' OR v_registo.valores_posteriores ? 'password_hash' THEN
        RAISE NOTICE '2. FALHOU: o hash aparece na auditoria';
    ELSE
        RAISE NOTICE '2. O hash não aparece na auditoria';
    END IF;

    -- 3. Mudar outro campo (sem mexer na palavra-passe) não marca password_alterada
    PERFORM fn_utilizador_crud('UPDATE', v_conta, p_nome => 'Conta Teste Auditoria 2');
    SELECT * INTO v_registo FROM registo_auditoria
     WHERE entidade_afetada = 'utilizador' AND id_entidade_afetada = v_conta AND acao = 'UPDATE'
     ORDER BY id DESC LIMIT 1;
    RAISE NOTICE '3. Mudou o nome: password_alterada = % (esperado: vazio)',
        v_registo.valores_posteriores ->> 'password_alterada';

    RAISE NOTICE 'Teste terminado sem problemas.';
END
$$;

-- Desfaz tudo o que o teste criou.
ROLLBACK;
