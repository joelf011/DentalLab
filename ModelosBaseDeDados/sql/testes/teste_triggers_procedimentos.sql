-- Teste dos procedimentos (04_procedimentos.sql) e dos triggers (05_triggers.sql).
--
-- Como usar: abrir no Query Tool da BD abd_lab_cd e correr tudo (F5).
-- Os resultados aparecem no separador "Messages" (é isto que se mostra no relatório).
-- No fim, tudo é desfeito (ROLLBACK): a BD fica exatamente como estava.
-- Não precisa dos dados de exemplo: cria os seus próprios dados.

-- Desfaz alguma transação que tenha ficado a meio neste separador (se não houver, só dá um aviso).
ROLLBACK;

BEGIN;

DO $$
DECLARE
    v_admin    bigint;
    v_colab    bigint;
    v_cliente  bigint;
    v_clinica  bigint;
    v_tipo     bigint;
    v_ordem    bigint;
    v_trabalho bigint;
    v_etapa    record;
    v_ordem_l  record;
    v_coment   bigint;
    v_data     timestamptz;
    v_etapas   bigint[];
    n          integer;
BEGIN
    -- 0. Preparação: administrador, colaborador, clínica aprovada e um tipo de trabalho com 3 etapas
    SELECT id INTO v_admin FROM utilizador WHERE email = 'admin@dentallab.local';
    CALL pr_definir_utilizador(v_admin);

    v_colab := fn_utilizador_crud(
        p_operacao => 'CREATE', p_id => NULL,
        p_cargo_id => (SELECT id FROM cargo WHERE designacao = 'Colaborador'),
        p_nome => 'Colaborador Teste', p_email => 'colab@teste.pt', p_password_hash => 'HASH',
        p_aprovado_por => v_admin);

    v_cliente := fn_registar_clinica('Clínica Teste', '509990101', 'Rua A, Viseu', NULL, 'teste@clinica.pt', 'HASH');
    SELECT id INTO v_clinica FROM utilizador WHERE cliente_id = v_cliente;
    PERFORM fn_aprovar_utilizador(v_clinica, v_admin);

    INSERT INTO etapa(nome) VALUES ('Etapa A'), ('Etapa B'), ('Etapa C');
    v_tipo := fn_tipo_trabalho_crud('CREATE', NULL, 'Tipo Teste');
    -- o CALL não aceita subconsultas nos argumentos: a lista vai primeiro para uma variável
    v_etapas := ARRAY(SELECT id FROM etapa WHERE nome IN ('Etapa A', 'Etapa B', 'Etapa C') ORDER BY nome);
    CALL pr_definir_etapas_tipo_trabalho(v_tipo, v_etapas);
    RAISE NOTICE '0. Preparação feita (admin %, colaborador %, clínica %, tipo %)', v_admin, v_colab, v_clinica, v_tipo;

    -- 1. [T4] A clínica cria uma ordem: o administrador recebe uma notificação
    CALL pr_definir_utilizador(v_clinica);
    v_ordem := fn_ordem_trabalho_crud(p_operacao => 'CREATE', p_id => NULL,
        p_cliente_id => v_cliente, p_criado_por => v_clinica,
        p_nome_medico_responsavel => 'Dr. Teste', p_nome_paciente => 'Paciente Teste');
    SELECT count(*) INTO n FROM notificacao WHERE ordem_trabalho_id = v_ordem AND utilizador_id = v_admin;
    RAISE NOTICE '1. [T4] Ordem % criada. Notificações para o admin: % (esperado: 1)', v_ordem, n;

    -- 2. Trabalho na ordem: as 3 etapas do tipo são copiadas
    v_trabalho := fn_trabalho_crud('CREATE', NULL, v_ordem, v_tipo, 'FISICO', 'A2', ARRAY[11]::smallint[]);
    SELECT count(*) INTO n FROM etapa_trabalho WHERE trabalho_id = v_trabalho;
    RAISE NOTICE '2. Trabalho % criado com % etapas (esperado: 3)', v_trabalho, n;

    -- 2b. [T6] Começar uma etapa antes de a ordem ser aceite: tem de dar erro
    SELECT * INTO v_etapa FROM etapa_trabalho WHERE trabalho_id = v_trabalho AND ordem = 1;
    BEGIN
        CALL pr_iniciar_etapa(v_etapa.id, v_colab);
        RAISE NOTICE '2b. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '2b. [T6] Erro esperado: %', SQLERRM;
    END;

    -- 3. [pr_aceitar_ordem] Prazo no passado: tem de dar erro
    BEGIN
        CALL pr_aceitar_ordem(v_ordem, v_admin, current_date - 1);
        RAISE NOTICE '3. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '3. Erro esperado: %', SQLERRM;
    END;

    -- 4. [pr_aceitar_ordem + T3] Aceitar: fica "Por iniciar" e a clínica é avisada
    CALL pr_aceitar_ordem(v_ordem, v_admin, current_date + 7);
    SELECT * INTO v_ordem_l FROM vw_ordem_trabalho WHERE id = v_ordem;
    SELECT count(*) INTO n FROM notificacao WHERE ordem_trabalho_id = v_ordem AND utilizador_id = v_clinica;
    RAISE NOTICE '4. [T3] Estado: "%", prazo %. Notificações para a clínica: % (esperado: 1)', v_ordem_l.estado, v_ordem_l.prazo_entrega, n;

    -- 5. [T6] Começar a 2.ª etapa antes da 1.ª: tem de dar erro
    SELECT * INTO v_etapa FROM etapa_trabalho WHERE trabalho_id = v_trabalho AND ordem = 2;
    BEGIN
        CALL pr_iniciar_etapa(v_etapa.id, v_colab);
        RAISE NOTICE '5. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '5. [T6] Erro esperado: %', SQLERRM;
    END;

    -- 6. [pr_iniciar_etapa + T7 + T2] Começar a 1.ª etapa: a ordem passa a "Em processamento" e ganha data de início
    SELECT * INTO v_etapa FROM etapa_trabalho WHERE trabalho_id = v_trabalho AND ordem = 1;
    CALL pr_iniciar_etapa(v_etapa.id, v_colab);
    SELECT * INTO v_ordem_l FROM vw_ordem_trabalho WHERE id = v_ordem;
    RAISE NOTICE '6. [T7/T2] Estado: "%", data de início preenchida: % (esperado: true)', v_ordem_l.estado, v_ordem_l.data_inicio IS NOT NULL;

    -- 7. [pr_concluir_etapa] Concluir uma etapa que ainda não começou: tem de dar erro
    SELECT * INTO v_etapa FROM etapa_trabalho WHERE trabalho_id = v_trabalho AND ordem = 3;
    BEGIN
        CALL pr_concluir_etapa(v_etapa.id, v_colab);
        RAISE NOTICE '7. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '7. Erro esperado: %', SQLERRM;
    END;

    -- 8. [T7 + T2] Fazer as 3 etapas: no fim a ordem passa a "Concluído" sozinha
    FOR v_etapa IN SELECT * FROM etapa_trabalho WHERE trabalho_id = v_trabalho ORDER BY ordem LOOP
        IF v_etapa.data_inicio IS NULL THEN
            CALL pr_iniciar_etapa(v_etapa.id, v_colab);
        END IF;
        CALL pr_concluir_etapa(v_etapa.id, v_colab);
    END LOOP;
    SELECT * INTO v_ordem_l FROM vw_ordem_trabalho WHERE id = v_ordem;
    RAISE NOTICE '8. [T7/T2] Estado: "%" (esperado: Concluído), data de conclusão preenchida: %', v_ordem_l.estado, v_ordem_l.data_conclusao IS NOT NULL;

    -- 9. [T5] Juntar um trabalho a uma ordem concluída: tem de dar erro
    BEGIN
        PERFORM fn_trabalho_crud('CREATE', NULL, v_ordem, v_tipo, 'FISICO', NULL, ARRAY[21]::smallint[]);
        RAISE NOTICE '9. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '9. [T5] Erro esperado: %', SQLERRM;
    END;

    -- 10. [pr_mudar_estado_ordem] "Em espera" sem motivo: tem de dar erro
    BEGIN
        CALL pr_mudar_estado_ordem(v_ordem, v_admin, 'Em espera');
        RAISE NOTICE '10. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '10. Erro esperado: %', SQLERRM;
    END;

    -- 11. [pr_mudar_estado_ordem + T2] Entregar: a data de entrega é preenchida
    CALL pr_mudar_estado_ordem(v_ordem, v_admin, 'Entregue');
    SELECT * INTO v_ordem_l FROM vw_ordem_trabalho WHERE id = v_ordem;
    RAISE NOTICE '11. [T2] Estado: "%", data de entrega preenchida: % (esperado: true)', v_ordem_l.estado, v_ordem_l.data_entrega IS NOT NULL;

    -- 12. [T1] Auditoria: as alterações à ordem ficaram registadas, com quem as fez
    SELECT count(*) INTO n FROM registo_auditoria
    WHERE entidade_afetada = 'ordem_trabalho' AND id_entidade_afetada = v_ordem;
    RAISE NOTICE '12. [T1] Registos de auditoria da ordem: % (esperado: 5 = criação + 4 mudanças de estado)', n;
    SELECT count(*) INTO n FROM registo_auditoria
    WHERE entidade_afetada = 'utilizador' AND valores_posteriores ? 'password_hash';
    RAISE NOTICE '    [T1] Registos com password_hash: % (esperado: 0)', n;

    -- 13. [T8] Editar um comentário preenche a data de edição
    INSERT INTO comentario(ordem_trabalho_id, utilizador_id, conteudo)
    VALUES (v_ordem, v_clinica, 'Primeira versão') RETURNING id INTO v_coment;
    UPDATE comentario SET conteudo = 'Texto corrigido' WHERE id = v_coment;
    SELECT data_edicao INTO v_data FROM comentario WHERE id = v_coment;
    RAISE NOTICE '13. [T8] Data de edição preenchida: % (esperado: true)', v_data IS NOT NULL;

    -- 14. [pr_marcar_notificacoes_lidas] A clínica lê todas as notificações
    CALL pr_marcar_notificacoes_lidas(v_clinica);
    SELECT count(*) INTO n FROM notificacao WHERE utilizador_id = v_clinica AND data_leitura IS NULL;
    RAISE NOTICE '14. Notificações por ler da clínica: % (esperado: 0)', n;

    RAISE NOTICE 'Teste terminado sem problemas.';
END
$$;

-- Desfaz tudo o que o teste criou.
ROLLBACK;
