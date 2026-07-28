-- FASE 1: Row Level Security (§3: "lectura pública solo sobre las vistas materializadas
-- y sobre documents con license <> 'restricted'; escritura solo con service_role").
--
-- Nota de diseño: las vistas materializadas de Postgres NO admiten políticas RLS
-- (ALTER MATERIALIZED VIEW ... ENABLE ROW LEVEL SECURITY no existe); su lectura pública
-- se controla con GRANT SELECT directo. `service_role` en Supabase tiene el atributo
-- BYPASSRLS, así que no necesita políticas de escritura explícitas: basta con no
-- concedérselas a `anon`/`authenticated`.
--
-- Los roles anon/authenticated/service_role ya existen en cualquier proyecto Supabase.
-- Para que esta misma migración sea válida también contra un Postgres plano (como el
-- usado en el job de CI que valida FASE 1 sin Docker/Supabase CLI locales), se crean
-- aquí de forma condicional si todavía no existen.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN BYPASSRLS;
    END IF;
END $$;

GRANT USAGE ON SCHEMA public TO anon, authenticated;

ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentions ENABLE ROW LEVEL SECURITY;
ALTER TABLE interpretations ENABLE ROW LEVEL SECURITY;
ALTER TABLE concepts ENABLE ROW LEVEL SECURITY;
ALTER TABLE concept_edges ENABLE ROW LEVEL SECURITY;
ALTER TABLE crawl_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE crawl_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE extraction_gaps ENABLE ROW LEVEL SECURITY;

-- Única política de lectura pública sobre una tabla base: documents, y solo si su
-- licencia no es 'restricted'. El resto de tablas quedan con RLS activo y SIN políticas
-- para anon/authenticated, lo que en Postgres significa denegación por defecto.
CREATE POLICY documents_public_read ON documents
    FOR SELECT
    TO anon, authenticated
    USING (license <> 'restricted');

-- Lectura pública de las vistas materializadas agregadas (no son tablas base, no llevan RLS).
GRANT SELECT ON mv_map_points TO anon, authenticated;
GRANT SELECT ON mv_timeline TO anon, authenticated;
GRANT SELECT ON mv_author_summary TO anon, authenticated;
