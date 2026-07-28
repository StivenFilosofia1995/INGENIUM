-- FASE 1: vistas materializadas de lectura pública (§3, §6).
-- Son la única superficie de lectura pública además de `documents` (ver migración de RLS):
-- se calculan aquí, no en el frontend, para no repetir lógica de negocio en TypeScript.

-- ------------------------------------------------------------------
-- mv_map_points: alimenta GET /api/v1/map/points.
-- Una fila por (mención, lugar, relación): un mismo punto puede representar
-- "lugar de escritura", "de publicación", "afiliación" o "custodia" y la interfaz
-- debe distinguirlo (§7.2), por eso no se colapsa en una sola fila por mención.
-- ------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_map_points AS
WITH latest_interpretation AS (
    SELECT DISTINCT ON (mention_id)
        mention_id, argumentative_role, confidence, needs_review, tradition_inferred
    FROM interpretations
    ORDER BY mention_id, created_at DESC
),
mention_authors AS (
    SELECT
        da.document_id,
        string_agg(DISTINCT a.display_name, '; ' ORDER BY a.display_name) AS authors,
        -- Tradición dominante: heurística simple y transparente (primer autor no nulo
        -- por orden alfabético). No pretende ser un cómputo estadístico sofisticado.
        (array_agg(a.tradition ORDER BY a.display_name) FILTER (WHERE a.tradition IS NOT NULL))[1]
            AS author_tradition
    FROM document_authors da
    JOIN authors a ON a.id = da.author_id
    GROUP BY da.document_id
)
SELECT
    m.id AS mention_id,
    d.id AS document_id,
    dp.place_id,
    p.name AS place_name,
    p.lat,
    p.lon,
    dp.relation,
    ma.authors,
    d.pub_year,
    d.pub_year_precision,
    COALESCE(li.tradition_inferred, ma.author_tradition) AS tradition,
    -- Mapea a las 6 claves de color categóricas de §7.1; una tradición no listada allí
    -- (p. ej. "escolástica" u "otra") no tiene color asignado a propósito: se dibuja
    -- en --vellum-dim con contorno punteado en el frontend.
    CASE COALESCE(li.tradition_inferred, ma.author_tradition)
        WHEN 'retórica latina' THEN 'amber'
        WHEN 'humanismo' THEN 'vermilion'
        WHEN 'barroco' THEN 'vermilion'
        WHEN 'ilustración' THEN 'jade'
        WHEN 'idealismo' THEN 'lilac'
        WHEN 'fenomenología' THEN 'sky'
        WHEN 'filosofía de la técnica' THEN 'magenta'
        WHEN 'teoría de medios' THEN 'magenta'
        ELSE NULL
    END AS tradition_color_key,
    li.argumentative_role,
    li.confidence,
    COALESCE(li.needs_review, true) AS needs_review,
    m.sense,
    m.matched_form,
    m.lang
FROM mentions m
JOIN documents d ON d.id = m.document_id
JOIN document_places dp ON dp.document_id = d.id
JOIN places p ON p.id = dp.place_id
LEFT JOIN mention_authors ma ON ma.document_id = d.id
LEFT JOIN latest_interpretation li ON li.mention_id = m.id;

CREATE UNIQUE INDEX idx_mv_map_points_pk ON mv_map_points (mention_id, place_id, relation);
CREATE INDEX idx_mv_map_points_tradition ON mv_map_points (tradition);
CREATE INDEX idx_mv_map_points_sense ON mv_map_points (sense);

-- ------------------------------------------------------------------
-- mv_timeline: alimenta GET /api/v1/timeline (histograma por década y tradición).
-- ------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_timeline AS
WITH latest_interpretation AS (
    SELECT DISTINCT ON (mention_id) mention_id, tradition_inferred
    FROM interpretations
    ORDER BY mention_id, created_at DESC
),
mention_authors AS (
    SELECT
        da.document_id,
        (array_agg(a.tradition ORDER BY a.display_name) FILTER (WHERE a.tradition IS NOT NULL))[1]
            AS author_tradition
    FROM document_authors da
    JOIN authors a ON a.id = da.author_id
    GROUP BY da.document_id
),
mention_tradition AS (
    SELECT
        m.id AS mention_id,
        d.pub_year,
        d.pub_year_precision,
        COALESCE(li.tradition_inferred, ma.author_tradition) AS tradition
    FROM mentions m
    JOIN documents d ON d.id = m.document_id
    LEFT JOIN latest_interpretation li ON li.mention_id = m.id
    LEFT JOIN mention_authors ma ON ma.document_id = d.id
    WHERE d.pub_year IS NOT NULL
)
SELECT
    (floor(pub_year / 10.0) * 10)::int AS decade,
    tradition,
    count(*) AS mention_count,
    bool_or(pub_year_precision <> 'exact') AS has_imprecise_year
FROM mention_tradition
GROUP BY decade, tradition;

CREATE UNIQUE INDEX idx_mv_timeline_pk ON mv_timeline (decade, tradition);

-- ------------------------------------------------------------------
-- mv_author_summary: alimenta GET /api/v1/authors.
-- ------------------------------------------------------------------
CREATE MATERIALIZED VIEW mv_author_summary AS
SELECT
    a.id AS author_id,
    a.display_name,
    a.tradition,
    count(DISTINCT da.document_id) AS documents_count,
    count(DISTINCT m.id) AS mentions_count,
    min(d.pub_year) AS earliest_pub_year,
    max(d.pub_year) AS latest_pub_year
FROM authors a
LEFT JOIN document_authors da ON da.author_id = a.id
LEFT JOIN documents d ON d.id = da.document_id
LEFT JOIN mentions m ON m.document_id = d.id
GROUP BY a.id, a.display_name, a.tradition;

CREATE UNIQUE INDEX idx_mv_author_summary_pk ON mv_author_summary (author_id);
