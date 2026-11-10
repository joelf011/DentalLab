# Junta os ficheiros 01 a 06 num só: script_completo.sql (é o que se entrega).
# Sempre que mudarem um dos ficheiros numerados, voltem a correr:
#   python sql/juntar.py
from pathlib import Path

PASTA = Path(__file__).parent

PARTES = [
    "01_tabelas.sql",
    "02_vistas.sql",
    "03_funcoes.sql",
    "04_procedimentos.sql",
    "05_triggers.sql",
    "06_dados_iniciais.sql",
]

CABECALHO = """-- =====================================================================
-- ABD — Lab CD (DentalLab) — Script completo de criação da base de dados
-- Tabelas, vistas, funções, procedimentos, triggers e dados iniciais.
--
-- GERADO AUTOMATICAMENTE por sql/juntar.py: não editar aqui,
-- editar os ficheiros 01 a 06 e voltar a correr o juntar.py.
--
-- Como usar (PostgreSQL 12 ou mais recente):
--   1. No pgAdmin, criar uma base de dados vazia: abd_lab_cd
--   2. Abrir o Query Tool nessa base de dados, abrir este ficheiro e correr tudo (F5).
-- Corre numa só transação: se alguma coisa falhar, não fica nada criado.
-- =====================================================================

BEGIN;
"""

texto = CABECALHO
for nome in PARTES:
    texto += f"\n\n-- #####################################################################\n"
    texto += f"-- {nome}\n"
    texto += f"-- #####################################################################\n\n"
    texto += (PASTA / nome).read_text(encoding="utf-8").strip() + "\n"
texto += "\nCOMMIT;\n"

(PASTA / "script_completo.sql").write_text(texto, encoding="utf-8")
print("script_completo.sql criado com", texto.count("\n"), "linhas")
