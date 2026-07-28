"""Validación del léxico multilingüe de FASE 1 (§5.1 del prompt maestro).

Estas pruebas no dependen de la base de datos: verifican que `config/lexicon.yaml`
es válido, que cada término trae una expresión regular que compila y que los
grupos marcados como ambiguos declaran `disambiguation_required`.
"""
import re
from pathlib import Path

import pytest
import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
LEXICON_PATH = REPO_ROOT / "config" / "lexicon.yaml"


@pytest.fixture(scope="module")
def lexicon() -> dict:
    with open(LEXICON_PATH, encoding="utf-8") as f:
        return yaml.safe_load(f)


def test_lexicon_file_exists():
    assert LEXICON_PATH.exists(), f"No se encontró {LEXICON_PATH}"


def test_lexicon_has_groups(lexicon):
    assert "groups" in lexicon
    assert len(lexicon["groups"]) > 0


def test_every_term_regex_compiles(lexicon):
    for group in lexicon["groups"]:
        for term in group["terms"]:
            re.compile(term["regex"])  # levanta re.error si es inválida


def test_nucleo_latino_covers_spec_forms(lexicon):
    expected = {
        "ingenium", "ingenii", "ingenio", "ingeniis",
        "ingenia", "ingeniorum", "ingeniosus", "ingeniosa", "ingeniose",
    }
    group = next(g for g in lexicon["groups"] if g["id"] == "nucleo_latino")
    forms = {t["form"] for t in group["terms"]}
    assert expected == forms


def test_ambiguous_vernacular_groups_require_disambiguation(lexicon):
    for group_id in ("romance_es", "romance_fr", "romance_pt"):
        group = next(g for g in lexicon["groups"] if g["id"] == group_id)
        assert group["disambiguation_required"] is True


def test_conceptual_neighbors_present(lexicon):
    group = next(g for g in lexicon["groups"] if g["id"] == "vecinos_conceptuales")
    forms = {t["form"] for t in group["terms"]}
    expected = {"ratio", "methodus", "iudicium", "memoria", "ars", "techne", "phronesis", "genius"}
    assert expected == forms
