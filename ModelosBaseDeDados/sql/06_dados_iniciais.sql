-- =====================================================================
-- ABD — Lab CD (DentalLab) — 06. Dados iniciais
-- Origem: modelofisico.sql. Corre depois dos triggers, por isso a criação
-- do administrador já fica no registo de auditoria.
-- =====================================================================


INSERT INTO cargo (designacao) VALUES
    ('Administrador'),
    ('Colaborador'),
    ('Cliente');

-- Estados visíveis pela clínica (sugeridos pela cliente)
INSERT INTO estado_ordem (designacao) VALUES
    ('Em avaliação'),
    ('Rejeitado'),
    ('Por iniciar'),
    ('Em processamento'),
    ('Em espera'),
    ('Em prova'),
    ('Concluído'),
    ('Entregue');

INSERT INTO tipo_ficheiro (designacao) VALUES
    ('STL'),
    ('Fotografia'),
    ('Documento'),
    ('Outro');

-- Administrador pré-configurado (único utilizador criado pelo script).
-- Password provisória: Admin#2026 (hash bcrypt), a alterar no primeiro login.
-- Como não há quem o aprove, fica aprovado por si próprio.
INSERT INTO utilizador (cargo_id, nome, email, password_hash, password_temporaria)
SELECT c.id, 'Administrador', 'admin@dentallab.local',
       '$2a$12$VAqXKiYsU6rR5iw1ehHsvOvic9icZwiAWc7.BPIrkquswaOaC4a6O', TRUE
FROM cargo c
WHERE c.designacao = 'Administrador';

UPDATE utilizador
SET aprovado_por = id, data_aprovacao = now()
WHERE lower(email) = 'admin@dentallab.local';
