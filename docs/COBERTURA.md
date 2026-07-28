# Cobertura de fuentes y sesgos conocidos

> Este documento se actualiza en cada fase a medida que se integran adaptadores reales
> (§4 del prompt maestro). No contiene datos inventados: cada afirmación aquí debe poder
> verificarse contra `sources`, `documents` y `crawl_events` en la base de datos.

## Estado actual (FASE 0 / FASE 1)

Aún no se ha ejecutado ninguna ingesta real. Las tablas `sources` contienen únicamente el
catálogo de proveedores previstos (seed de FASE 1), con `enabled = false` hasta que su adaptador
esté implementado y probado (FASE 2 en adelante).

## Fuentes previstas (prioridad 1 — APIs)

OpenAlex, Crossref, Semantic Scholar, CORE, DOAJ, Zenodo, arXiv, OAI-PMH genérico, Internet
Archive, HathiTrust (solo metadatos), Google Books (solo metadatos/snippets), Wikisource, Perseus
Digital Library, The Latin Library, Gallica, Europeana, Biblioteca Digital Hispánica, SciELO,
Redalyc, y repositorios institucionales colombianos vía OAI-PMH.

## Fuentes previstas (prioridad 2 — crawler dirigido)

PhilPapers, Monoskop, dominios `.edu`/`.ac.*` en la lista blanca de `config/domains.yaml`.

## Sesgos conocidos y esperables

- **Cobertura desigual por idioma**: las APIs de prioridad 1 indexan mucho mejor producción
  académica en inglés y francés que en alemán, italiano o portugués; el corpus latino depende
  casi enteramente de Perseus y The Latin Library.
- **Sesgo hacia acceso abierto reciente**: OpenAlex/Crossref/Zenodo/arXiv favorecen publicaciones
  posteriores a 2000; el material de dominio público anterior depende de Internet Archive,
  HathiTrust, Gallica y Wikisource, con OCR de calidad variable.
- **Cobertura iberoamericana limitada** a lo indexado por SciELO/Redalyc y a los repositorios
  institucionales que exponen OAI-PMH correctamente.
- **El crawler dirigido nunca elude `robots.txt`, `Crawl-delay` ni muros de sesión**: cualquier
  dominio que los imponga queda fuera de la cobertura, no se documenta como "no accesible por
  restricción técnica", no como ausencia de interés.

Este documento se ampliará con cifras reales (documentos por fuente, por licencia, por idioma)
cuando exista al menos una ingesta ejecutada (FASE 2), y se enlazará con
`GET /api/v1/stats/coverage`.
