-- Teste das funções da comunicação (03_funcoes.sql): comentários, ficheiros e notificações.
--
-- Como usar: abrir no Query Tool da BD abd_lab_cd e correr tudo (F5).
-- Os resultados aparecem no separador "Messages".
-- No fim, tudo é desfeito (ROLLBACK): a BD fica exatamente como estava.
-- Precisa dos dados de exemplo (07_dados_exemplo.sql): usa a primeira ordem e o primeiro trabalho.

-- Desfaz alguma transação que tenha ficado a meio neste separador (se não houver, só dá um aviso).
ROLLBACK;

BEGIN;

DO $$
DECLARE
    v_admin    bigint;
    v_ordem    bigint;
    v_trabalho bigint;
    v_id       bigint;
    v_tipo     bigint;
    n          integer;
BEGIN
    SELECT id INTO v_admin FROM vw_utilizador WHERE cargo = 'Administrador' AND ativo ORDER BY id LIMIT 1;
    SELECT id INTO v_ordem FROM vw_ordem_trabalho ORDER BY id LIMIT 1;
    SELECT id INTO v_trabalho FROM vw_trabalho WHERE ordem_trabalho_id = v_ordem ORDER BY id LIMIT 1;

    -- 1. Comentário da ordem (a clínica vê-o) e nota interna do trabalho
    v_id := fn_comentario_crud('CREATE', NULL, p_ordem_trabalho_id => v_ordem,
                               p_utilizador_id => v_admin, p_conteudo => 'A cor fica A2.');
    RAISE NOTICE '1. Comentário % na ordem %', v_id, v_ordem;
    v_id := fn_comentario_crud('CREATE', NULL, p_trabalho_id => v_trabalho,
                               p_utilizador_id => v_admin, p_conteudo => 'Rever a margem.');
    RAISE NOTICE '1. Nota % no trabalho %', v_id, v_trabalho;

    -- 2. Na ordem e no trabalho ao mesmo tempo: tem de dar erro
    BEGIN
        PERFORM fn_comentario_crud('CREATE', NULL, p_ordem_trabalho_id => v_ordem, p_trabalho_id => v_trabalho,
                                   p_utilizador_id => v_admin, p_conteudo => 'x');
        RAISE NOTICE '2. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '2. Erro esperado: %', SQLERRM;
    END;

    -- 3. Comentário vazio: tem de dar erro
    BEGIN
        PERFORM fn_comentario_crud('CREATE', NULL, p_ordem_trabalho_id => v_ordem,
                                   p_utilizador_id => v_admin, p_conteudo => '   ');
        RAISE NOTICE '3. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '3. Erro esperado: %', SQLERRM;
    END;

    -- 4. Editar preenche data_edicao (trigger); eliminar esconde-o da vista
    PERFORM fn_comentario_crud('UPDATE', v_id, p_conteudo => 'Rever a margem distal.');
    SELECT count(*) INTO n FROM vw_comentario WHERE id = v_id AND data_edicao IS NOT NULL;
    RAISE NOTICE '4. Editado com data_edicao: % (esperado: 1)', n;
    PERFORM fn_comentario_crud('DELETE', v_id);
    SELECT count(*) INTO n FROM vw_comentario WHERE id = v_id;
    RAISE NOTICE '4. Depois de eliminado, na vista: % (esperado: 0)', n;

    -- 5. Ficheiro de uma ordem, e eliminar
    SELECT id INTO v_tipo FROM vw_tipo_ficheiro WHERE designacao = 'Fotografia';
    v_id := fn_ficheiro_crud('CREATE', NULL, p_tipo_ficheiro_id => v_tipo, p_ordem_trabalho_id => v_ordem,
                             p_carregado_por => v_admin, p_nome => 'sorriso.jpg', p_localizacao => 'abc.jpg');
    SELECT count(*) INTO n FROM vw_ficheiro WHERE id = v_id AND tipo = 'Fotografia';
    RAISE NOTICE '5. Ficheiro % na vista: % (esperado: 1)', v_id, n;
    PERFORM fn_ficheiro_crud('DELETE', v_id);
    SELECT count(*) INTO n FROM vw_ficheiro WHERE id = v_id;
    RAISE NOTICE '5. Depois de eliminado, na vista: % (esperado: 0)', n;

    -- 6. Ficheiro sem ordem nem trabalho: tem de dar erro
    BEGIN
        PERFORM fn_ficheiro_crud('CREATE', NULL, p_tipo_ficheiro_id => v_tipo,
                                 p_carregado_por => v_admin, p_nome => 'x.pdf', p_localizacao => 'x.pdf');
        RAISE NOTICE '6. FALHOU: devia ter dado erro';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '6. Erro esperado: %', SQLERRM;
    END;

    -- 7. Notificações: marcar todas as do administrador como lidas
    CALL pr_marcar_notificacoes_lidas(v_admin);
    SELECT count(*) INTO n FROM vw_notificacao WHERE utilizador_id = v_admin AND NOT lida;
    RAISE NOTICE '7. Notificações por ler do administrador: % (esperado: 0)', n;

    RAISE NOTICE 'Teste terminado sem problemas.';
END
$$;

-- Desfaz tudo o que o teste criou.
ROLLBACK;
