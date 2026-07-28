-- FASE 1: índices de soporte. Postgres no indexa automáticamente las columnas de FK,
-- y las búsquedas por similitud (dedupe de títulos, semántica sobre embeddings) necesitan
-- índices especializados.

-- Foreign keys más consultadas
CREATE INDEX idx_documents_source_id ON documents (source_id);
CREATE INDEX idx_document_authors_author_id ON document_authors (author_id);
CREATE INDEX idx_document_places_place_id ON document_places (place_id);
CREATE INDEX idx_mentions_document_id ON mentions (document_id);
CREATE INDEX idx_interpretations_mention_id ON interpretations (mention_id);
CREATE INDEX idx_concept_edges_concept_a ON concept_edges (concept_a_id);
CREATE INDEX idx_concept_edges_concept_b ON concept_edges (concept_b_id);
CREATE INDEX idx_crawl_events_job_id ON crawl_events (crawl_job_id);
CREATE INDEX idx_extraction_gaps_entity ON extraction_gaps (entity_type, entity_id);

-- Filtros habituales de la API (§6)
CREATE INDEX idx_documents_pub_year ON documents (pub_year);
CREATE INDEX idx_documents_license ON documents (license);
CREATE INDEX idx_mentions_lemma_group ON mentions (lemma_group);
CREATE INDEX idx_mentions_sense ON mentions (sense);
CREATE INDEX idx_mentions_lang ON mentions (lang);
CREATE INDEX idx_interpretations_role ON interpretations (argumentative_role);
CREATE INDEX idx_interpretations_needs_review ON interpretations (needs_review);

-- Deduplicación de documentos por similitud de título (§4: umbral pg_trgm > 0.92)
CREATE INDEX idx_documents_title_trgm ON documents USING gin (title gin_trgm_ops);
CREATE INDEX idx_authors_normalized_name_trgm ON authors USING gin (normalized_name gin_trgm_ops);

-- Búsqueda semántica sobre embeddings (§6: GET /api/v1/mentions?q=...)
-- HNSW no requiere un mínimo de filas para construirse (a diferencia de ivfflat),
-- lo cual es importante porque en FASE 1 la tabla está vacía.
CREATE INDEX idx_mentions_embedding_hnsw
    ON mentions USING hnsw (embedding vector_cosine_ops);
