-- FASE 1: esquema de datos completo (§3 del prompt maestro).
-- Cada tabla incluye los campos mínimos exigidos, restricciones únicas para idempotencia
-- (hashes/claves compuestas) y CHECK constraints para los vocabularios cerrados descritos
-- en el encargo. Los campos "abiertos" (p. ej. authors.tradition) se dejan como texto libre
-- a propósito: el prompt maestro los describe como "enum abierto".

-- ============================================================
-- sources
-- ============================================================
CREATE TABLE sources (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name             text NOT NULL UNIQUE,
    kind             text NOT NULL CHECK (kind IN ('api', 'oai_pmh', 'crawl')),
    base_url         text,
    license_default  text CHECK (license_default IN ('public_domain', 'cc_by', 'cc_by_nc', 'unknown', 'restricted')),
    robots_ok        boolean NOT NULL DEFAULT true,
    rate_limit_rpm   integer NOT NULL DEFAULT 10,
    enabled          boolean NOT NULL DEFAULT false,
    created_at       timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- authors
-- ============================================================
CREATE TABLE authors (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name     text NOT NULL,
    normalized_name  text NOT NULL UNIQUE,
    birth_year       integer,
    death_year       integer,
    viaf_id          text,
    wikidata_qid     text,
    tradition        text,  -- enum abierto, ver docstring del archivo
    notes            text,
    confidence       numeric(3, 2) CHECK (confidence BETWEEN 0 AND 1),
    created_at       timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- documents
-- ============================================================
CREATE TABLE documents (
    id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id                uuid NOT NULL REFERENCES sources(id) ON DELETE RESTRICT,
    external_id              text NOT NULL,
    doi                      text,
    title                    text NOT NULL,
    subtitle                 text,
    lang                     text,
    pub_year                 integer,
    pub_year_precision       text NOT NULL DEFAULT 'unknown'
                             CHECK (pub_year_precision IN ('exact', 'decade', 'century', 'unknown')),
    work_type                text CHECK (work_type IN ('libro', 'artículo', 'tesis', 'capítulo', 'manuscrito', 'informe')),
    publisher                text,
    url                      text,
    file_url                 text,
    mime                     text,
    sha256                   text,
    page_count               integer,
    license                  text NOT NULL DEFAULT 'unknown'
                             CHECK (license IN ('public_domain', 'cc_by', 'cc_by_nc', 'unknown', 'restricted')),
    full_text_available      boolean NOT NULL DEFAULT false,
    ingested_at              timestamptz NOT NULL DEFAULT now(),
    original_language_note   text,
    UNIQUE (source_id, external_id),
    UNIQUE (sha256)
);

-- ============================================================
-- document_authors
-- ============================================================
CREATE TABLE document_authors (
    document_id  uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    author_id    uuid NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
    role         text NOT NULL CHECK (role IN ('autor', 'editor', 'traductor', 'comentarista')),
    position     integer,
    PRIMARY KEY (document_id, author_id, role)
);

-- ============================================================
-- places
-- ============================================================
CREATE TABLE places (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name          text NOT NULL,
    country_code  text,
    lat           numeric(9, 6),
    lon           numeric(9, 6),
    geonames_id   text,
    precision     text CHECK (precision IN ('ciudad', 'región', 'país', 'desconocido')),
    resolver      text CHECK (resolver IN ('geonames', 'nominatim', 'manual')),
    created_at    timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- document_places
-- ============================================================
CREATE TABLE document_places (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id  uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    place_id     uuid NOT NULL REFERENCES places(id) ON DELETE CASCADE,
    relation     text NOT NULL CHECK (relation IN (
                     'lugar_de_escritura', 'lugar_de_publicación',
                     'afiliación_autor', 'lugar_de_custodia_del_manuscrito'
                 )),
    evidence     text,
    confidence   numeric(3, 2) CHECK (confidence BETWEEN 0 AND 1),
    UNIQUE (document_id, place_id, relation)
);

-- ============================================================
-- mentions
-- ============================================================
CREATE TABLE mentions (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id     uuid NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    page            integer,
    char_start      integer NOT NULL,
    char_end        integer NOT NULL CHECK (char_end >= char_start),
    matched_form    text NOT NULL,
    lemma_group     text NOT NULL,
    sense           text CHECK (sense IN ('facultad', 'artefacto', 'topónimo', 'ambiguo')),
    snippet         text NOT NULL CHECK (char_length(snippet) <= 300),
    context_before  text CHECK (context_before IS NULL OR char_length(context_before) <= 200),
    context_after   text CHECK (context_after IS NULL OR char_length(context_after) <= 200),
    lang            text,
    embedding       vector(1024),
    sha256_snippet  text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    UNIQUE (document_id, char_start, char_end)
);

-- ============================================================
-- interpretations
-- (una fila por (mención, prompt_version): permite reprocesar sin duplicar)
-- ============================================================
CREATE TABLE interpretations (
    id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mention_id            uuid NOT NULL REFERENCES mentions(id) ON DELETE CASCADE,
    claim                 text,
    argumentative_role    text CHECK (argumentative_role IN (
                              'define', 'distingue', 'critica', 'apropia',
                              'historiza', 'traduce', 'ejemplifica', 'opone'
                          )),
    opposed_to            text[] NOT NULL DEFAULT '{}',
    interlocutor          text,
    why                   text,
    evidence_quote        text,
    tradition_inferred    text,
    confidence            numeric(3, 2) CHECK (confidence BETWEEN 0 AND 1),
    insufficient_evidence boolean NOT NULL DEFAULT false,
    needs_review          boolean GENERATED ALWAYS AS (confidence IS NULL OR confidence < 0.55) STORED,
    model                 text,
    prompt_version        text NOT NULL,
    created_at            timestamptz NOT NULL DEFAULT now(),
    UNIQUE (mention_id, prompt_version)
);

-- ============================================================
-- concepts / concept_edges
-- ============================================================
CREATE TABLE concepts (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug         text NOT NULL UNIQUE,
    label        text NOT NULL,
    lang         text,
    description  text,
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE concept_edges (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    concept_a_id   uuid NOT NULL REFERENCES concepts(id) ON DELETE CASCADE,
    concept_b_id   uuid NOT NULL REFERENCES concepts(id) ON DELETE CASCADE,
    weight         numeric NOT NULL DEFAULT 1,
    edge_type      text NOT NULL CHECK (edge_type IN ('coocurrencia', 'oposición_explícita', 'sinonimia_declarada')),
    created_at     timestamptz NOT NULL DEFAULT now(),
    CHECK (concept_a_id <> concept_b_id),
    UNIQUE (concept_a_id, concept_b_id, edge_type)
);

-- ============================================================
-- crawl_jobs / crawl_events
-- ============================================================
CREATE TABLE crawl_jobs (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id        uuid REFERENCES sources(id) ON DELETE SET NULL,
    status           text NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled')),
    query            text,
    pages_count      integer NOT NULL DEFAULT 0,
    errors_count     integer NOT NULL DEFAULT 0,
    robots_snapshot  jsonb,
    started_at       timestamptz,
    finished_at      timestamptz,
    created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE crawl_events (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    crawl_job_id  uuid NOT NULL REFERENCES crawl_jobs(id) ON DELETE CASCADE,
    event_type    text NOT NULL,
    url           text,
    status_code   integer,
    message       text,
    created_at    timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- extraction_gaps
-- Garantía de honestidad: todo lo que no se pudo establecer con evidencia queda aquí.
-- Polimórfica a propósito (entity_type + entity_id): puede referirse a document,
-- author, mention, interpretation, place, etc. sin una FK rígida.
-- ============================================================
CREATE TABLE extraction_gaps (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type  text NOT NULL,
    entity_id    uuid,
    field        text NOT NULL,
    reason       text NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);
