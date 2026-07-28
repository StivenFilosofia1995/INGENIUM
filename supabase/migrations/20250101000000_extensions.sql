-- FASE 1: extensiones necesarias para el modelo de datos.
-- pgvector (embeddings), pg_trgm (similitud de títulos/dedupe), unaccent (normalización
-- de texto multilingüe). postgis es opcional: el modelo de datos usa columnas lat/lon
-- numeric como especifica el prompt maestro, así que si postgis no está disponible en el
-- entorno (p. ej. Postgres plano de CI) la migración no debe fallar por eso.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

DO $$
BEGIN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS postgis;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'postgis no disponible en este entorno; se usan columnas lat/lon numeric (fallback previsto en el prompt maestro §2).';
  END;
END $$;
