-- =====================================================================
-- ABD — Lab CD (DentalLab) — 07. Dados de exemplo (opcional)
--
-- Dados para experimentar a aplicação Django e ver os triggers a funcionar.
-- Não faz parte do script de criação: corre-se à parte, depois do script_completo.sql.
-- Pode correr-se mais do que uma vez (se os dados já existirem, não faz nada).
--
-- Contas criadas (além do administrador do 06_dados_iniciais.sql):
--   ana@dentallab.local            colaboradora   password: Admin#2026
--   clinica.teste@dentallab.local  clínica        password: Clinica#2026
-- =====================================================================

DO $$
DECLARE
    v_admin     bigint;
    v_colab     bigint;
    v_cliente   bigint;
    v_clinica   bigint;   -- conta de acesso da clínica
    v_coroa     bigint;
    v_protese   bigint;
    v_ordem1    bigint;
    v_ordem2    bigint;
    e_modelos   bigint;
    e_cad       bigint;
    e_fresagem  bigint;
    e_prova     bigint;
    e_acabam    bigint;
    e_controlo  bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM utilizador WHERE email = 'ana@dentallab.local') THEN
        RAISE NOTICE 'Os dados de exemplo já existem. Nada a fazer.';
        RETURN;
    END IF;

    SELECT id INTO v_admin FROM utilizador WHERE email = 'admin@dentallab.local';
    -- tudo o que se segue fica na auditoria como feito pelo administrador
    CALL pr_definir_utilizador(v_admin);

    -- 1. Catálogo de etapas (não tem função CRUD: insere-se diretamente)
    INSERT INTO etapa(nome) VALUES ('Modelos em gesso')      RETURNING id INTO e_modelos;
    INSERT INTO etapa(nome) VALUES ('Desenho digital (CAD)') RETURNING id INTO e_cad;
    INSERT INTO etapa(nome) VALUES ('Fresagem (CAM)')        RETURNING id INTO e_fresagem;
    INSERT INTO etapa(nome) VALUES ('Prova')                 RETURNING id INTO e_prova;
    INSERT INTO etapa(nome) VALUES ('Acabamento')            RETURNING id INTO e_acabam;
    INSERT INTO etapa(nome) VALUES ('Controlo de qualidade') RETURNING id INTO e_controlo;

    -- 2. Tipos de trabalho e as suas etapas (procedimento novo)
    v_coroa   := fn_tipo_trabalho_crud('CREATE', NULL, 'Coroa em zircónia', 'Coroa unitária fresada');
    v_protese := fn_tipo_trabalho_crud('CREATE', NULL, 'Prótese parcial removível', NULL);

    CALL pr_definir_etapas_tipo_trabalho(v_coroa,
        ARRAY[e_modelos, e_cad, e_fresagem, e_acabam, e_controlo]);
    CALL pr_definir_etapas_tipo_trabalho(v_protese,
        ARRAY[e_modelos, e_prova, e_acabam, e_prova, e_controlo]);

    -- 3. Uma colaboradora do laboratório (mesma password provisória do administrador)
    v_colab := fn_utilizador_crud(
        p_operacao      => 'CREATE',
        p_id            => NULL,
        p_cargo_id      => (SELECT id FROM cargo WHERE designacao = 'Colaborador'),
        p_nome          => 'Ana Colaboradora',
        p_email         => 'ana@dentallab.local',
        p_password_hash => '$2a$12$VAqXKiYsU6rR5iw1ehHsvOvic9icZwiAWc7.BPIrkquswaOaC4a6O',
        p_aprovado_por  => v_admin);

    -- 4. Uma clínica que se registou sozinha e foi aprovada (hash bcrypt de "Clinica#2026")
    v_cliente := fn_registar_clinica(
        'Clínica de Teste', '509990010', 'Rua de Teste 1, Viseu', '232000000',
        'clinica.teste@dentallab.local',
        '$2b$12$dUE1itVp/hrHPoqlDIMIpexj2nFpt2RvqLtlN0f9H5iiigkWRHiv.');
    SELECT id INTO v_clinica FROM utilizador WHERE cliente_id = v_cliente;
    PERFORM fn_aprovar_utilizador(v_clinica, v_admin);

    -- 5. A clínica faz duas ordens (o trigger T4 avisa o administrador)
    CALL pr_definir_utilizador(v_clinica);

    v_ordem1 := fn_ordem_trabalho_crud(
        p_operacao                => 'CREATE',
        p_id                      => NULL,
        p_cliente_id              => v_cliente,
        p_criado_por              => v_clinica,
        p_nome_medico_responsavel => 'Dr. João Silva',
        p_nome_paciente           => 'Maria Santos',
        p_sexo_paciente           => 'F',
        p_idade_paciente          => 54::smallint);
    PERFORM fn_trabalho_crud('CREATE', NULL, v_ordem1, v_coroa, 'FISICO', 'A2', ARRAY[11, 21]::smallint[]);

    v_ordem2 := fn_ordem_trabalho_crud(
        p_operacao                => 'CREATE',
        p_id                      => NULL,
        p_cliente_id              => v_cliente,
        p_criado_por              => v_clinica,
        p_nome_medico_responsavel => 'Dra. Rita Costa',
        p_nome_paciente           => 'Carlos Pereira',
        p_sexo_paciente           => 'M',
        p_idade_paciente          => 67::smallint);
    PERFORM fn_trabalho_crud('CREATE', NULL, v_ordem2, v_protese, 'FISICO', NULL, ARRAY[36, 37]::smallint[]);

    -- 6. O administrador aceita a primeira ordem (o trigger T3 avisa a clínica)
    CALL pr_aceitar_ordem(v_ordem1, v_admin, current_date + 10);

    RAISE NOTICE 'Dados de exemplo criados: ordens % (aceite) e % (em avaliação).', v_ordem1, v_ordem2;
END
$$;
