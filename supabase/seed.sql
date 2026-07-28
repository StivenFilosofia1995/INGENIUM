-- FASE 1: datos semilla (§9, criterio de aceptación de FASE 1).
-- Este archivo lo ejecuta `supabase db reset` automáticamente después de las migraciones.
--
-- Nota de honestidad de datos: para las fuentes de las que no tengo verificado con certeza
-- un endpoint base estable (HathiTrust, Perseus, Gallica, Biblioteca Digital Hispánica,
-- SciELO, Redalyc, OAI-PMH institucionales, PhilPapers, Monoskop), dejo `base_url` en NULL
-- en vez de inventar una URL plausible. Se completará cuando se implemente y verifique
-- cada adaptador (FASE 2 y FASE 6), siguiendo la restricción no negociable §1.1 de no
-- inventar datos. Todas las fuentes entran `enabled = false` hasta tener un adaptador
-- real probado con `respx` (ver docs/COBERTURA.md).

INSERT INTO sources (name, kind, base_url, license_default, robots_ok, rate_limit_rpm, enabled) VALUES
    ('OpenAlex',                         'api',     'https://api.openalex.org',                 'unknown', true, 60, false),
    ('Crossref',                         'api',     'https://api.crossref.org',                 'unknown', true, 60, false),
    ('Semantic Scholar',                 'api',     'https://api.semanticscholar.org/graph/v1',  'unknown', true, 60, false),
    ('CORE',                             'api',     'https://api.core.ac.uk/v3',                 'unknown', true, 60, false),
    ('DOAJ',                             'api',     'https://doaj.org/api',                      'unknown', true, 60, false),
    ('Zenodo',                           'api',     'https://zenodo.org/api',                    'unknown', true, 60, false),
    ('arXiv',                            'api',     'http://export.arxiv.org/api/query',         'unknown', true, 60, false),
    ('OAI-PMH genérico institucional',   'oai_pmh', NULL,                                        'unknown', true, 30, false),
    ('Internet Archive',                 'api',     'https://archive.org/advancedsearch.php',     'public_domain', true, 60, false),
    ('HathiTrust',                       'api',     NULL,                                        'public_domain', true, 30, false),
    ('Google Books',                     'api',     'https://www.googleapis.com/books/v1',        'unknown', true, 60, false),
    ('Wikisource',                       'api',     'https://www.wikisource.org/w/api.php',        'public_domain', true, 60, false),
    ('Perseus Digital Library',          'api',     NULL,                                        'public_domain', true, 30, false),
    ('The Latin Library',                'crawl',   'https://www.thelatinlibrary.com',            'public_domain', true, 6, false),
    ('Gallica (BnF)',                    'api',     NULL,                                        'unknown', true, 30, false),
    ('Europeana',                        'api',     'https://api.europeana.eu/record/v2',         'unknown', true, 60, false),
    ('Biblioteca Digital Hispánica',     'oai_pmh', NULL,                                        'unknown', true, 30, false),
    ('SciELO',                           'api',     NULL,                                        'unknown', true, 30, false),
    ('Redalyc',                          'crawl',   NULL,                                        'unknown', true, 6, false),
    ('Repositorio institucional EAFIT',  'oai_pmh', NULL,                                        'unknown', true, 30, false),
    ('PhilPapers',                       'crawl',   NULL,                                        'unknown', true, 6, false),
    ('Monoskop',                         'crawl',   NULL,                                        'unknown', true, 6, false);

-- ------------------------------------------------------------------
-- concepts (§3 y §5.1): nodo central "ingenium" más sus vecinos conceptuales
-- (oposición) y vernáculos (traducción/equivalencia declarada).
-- Descripciones deliberadamente lexicales/mínimas: no son afirmaciones filosóficas
-- del sistema, solo etiquetas para el grafo (§7.2).
-- ------------------------------------------------------------------
INSERT INTO concepts (slug, label, lang, description) VALUES
    ('ingenium',    'ingenium',    'la',  'Concepto nuclear rastreado por el sistema.'),
    ('ratio',       'ratio',       'la',  'Vecino conceptual que activa el análisis de oposición (§5.1).'),
    ('methodus',    'methodus',    'la',  'Vecino conceptual que activa el análisis de oposición (§5.1).'),
    ('iudicium',    'iudicium',    'la',  'Vecino conceptual que activa el análisis de oposición (§5.1).'),
    ('memoria',     'memoria',     'la',  'Vecino conceptual que activa el análisis de oposición (§5.1).'),
    ('ars',         'ars',         'la',  'Vecino conceptual que activa el análisis de oposición (§5.1).'),
    ('genius',      'genius',      'la',  'Vecino conceptual que activa el análisis de oposición (§5.1).'),
    ('techne',      'technē',      'grc', 'Vecino conceptual griego que activa el análisis de oposición (§5.1).'),
    ('phronesis',   'phronesis',   'grc', 'Vecino conceptual griego que activa el análisis de oposición (§5.1).'),
    ('witz',        'Witz',        'de',  'Equivalente vernáculo germánico de ingenium (§5.1).'),
    ('esprit',      'esprit',      'fr',  'Equivalente vernáculo francés de ingenium, con desambiguación de contexto (§5.1).'),
    ('genio',       'genio',       NULL,  'Equivalente vernáculo romance (español/italiano) de ingenium (§5.1).'),
    ('organologia', 'organología', 'es',  'Concepto de la filosofía de la técnica / teoría de medios (§3).'),
    ('pharmakon',   'pharmakon',   'grc', 'Concepto de la filosofía de la técnica / teoría de medios (§3).');
