# PROMPT MAESTRO — "INGENIUM TRACKER"

> Uso recomendado: guarda este archivo como `.github/copilot-instructions.md` en el repo vacío y abre Copilot Chat en modo agente con Claude Sonnet. Primer mensaje: *"Lee `.github/copilot-instructions.md` y ejecuta la FASE 0 y la FASE 1. No avances de fase sin mostrarme los criterios de aceptación cumplidos."*

---

## 0. ROL Y ENCARGO

Actúa como arquitecto de software senior especializado en humanidades digitales, con experiencia en pipelines de recuperación documental, NLP multilingüe (latín, español, francés, alemán, inglés, italiano) y visualización cartográfica de conocimiento.

Vas a construir **INGENIUM TRACKER**: un sistema que rastrea el concepto de *ingenium* en la literatura filosófica y técnica accesible en repositorios abiertos, extrae cada mención con su contexto, determina **qué se afirma sobre el ingenium y por qué se lo afirma** (función argumentativa, interlocutor, tradición), lo geolocaliza (lugar de escritura, publicación o afiliación del autor) y lo exporta como **bóveda de Obsidian** navegable.

Trabaja de forma incremental, en fases, con commits atómicos y mensajes convencionales. Al final de cada fase, ejecuta las pruebas y muéstrame la salida real, no una descripción de la salida.

---

## 1. RESTRICCIONES NO NEGOCIABLES

1. **No inventes datos.** Ninguna cita, autor, año, DOI, coordenada o fragmento puede ser generado por el modelo. Todo dato debe tener trazabilidad a un `source_id`, una URL, un número de página y un offset de carácter. Si un campo no se puede establecer con evidencia, va `NULL` y se registra en `extraction_gaps` con el motivo.
2. **"Toda la web" no es alcanzable ni legal.** Implementa en su lugar una **cobertura federada** sobre APIs abiertas y repositorios de acceso libre (lista en §4), más un crawler dirigido que respeta `robots.txt`, `Crawl-delay`, cabeceras `429/503` y un límite configurable de peticiones por dominio. Nunca eludas paywalls, captchas ni muros de sesión. Documenta explícitamente la cobertura lograda y sus sesgos en `docs/COBERTURA.md`.
3. **Derecho de cita.** En la base de datos y en la interfaz se almacenan y muestran fragmentos breves (máximo 300 caracteres por mención) con atribución completa, más el offset para que el usuario vaya a la fuente. No se almacena ni se sirve el texto íntegro de obras protegidas: el PDF completo se procesa en memoria o en un directorio temporal y se descarta, conservando solo metadatos, offsets y el fragmento citado. Marca cada documento con su licencia detectada (`public_domain`, `cc_by`, `cc_by_nc`, `unknown`, `restricted`) y bloquea la exportación de fragmentos de `restricted`.
4. **Multilingüismo obligatorio.** El concepto no aparece solo como "ingenium": debe rastrearse su flexión latina y sus vecinos vernáculos y conceptuales (§5.1). Un rastreo monolingüe se considera fallo de implementación.
5. **Todo secreto va en `.env`** y en `.env.example` sin valores. Nunca hardcodees claves de Supabase, Groq, OpenAI ni Semantic Scholar.
6. **Idempotencia.** Reejecutar cualquier etapa del pipeline no debe duplicar filas: usa hashes de contenido (`sha256` del texto normalizado) y claves únicas.

---

## 2. STACK

Backend: Python 3.11, FastAPI, Pydantic v2, `httpx` async, `tenacity` para reintentos, `apscheduler` o Celery + Redis para trabajos largos, `structlog` para logs JSON.

Extracción documental: `pymupdf` (PDF), `python-docx` (DOCX), `odfpy` (ODT), `ebooklib` + `beautifulsoup4` (EPUB), `trafilatura` (HTML), `ocrmypdf` + Tesseract con paquetes de idioma `lat spa eng fra deu ita` como fallback cuando la capa de texto tiene menos de 100 caracteres por página.

NLP: `spacy` (modelos multilingües), `cltk` o al menos un lematizador latino para las flexiones de *ingenium*, `sentence-transformers` con `BAAI/bge-m3` para embeddings multilingües (o `nomic-embed-text` vía Ollama si se prefiere local).

Análisis interpretativo: LLM vía API (Claude o Groq) con salida JSON estricta validada por Pydantic y `temperature=0`. Prompt de extracción en `backend/prompts/interpretation.md`, versionado, y el `prompt_version` se guarda en cada fila para poder reprocesar.

Base de datos: Supabase (Postgres 15) con extensiones `pgvector`, `pg_trgm`, `unaccent`, `postgis` si está disponible (si no, columnas `lat`/`lon` en `numeric`). Migraciones en `supabase/migrations/*.sql`. RLS activo desde el inicio.

Frontend: React 18 + TypeScript + Vite, TanStack Query, Zustand, Tailwind con tokens propios (§7.1), MapLibre GL JS con tiles vectoriales de un proveedor sin token o raster de OpenStreetMap con atribución visible, `d3-force` para el grafo conceptual, `visx` o D3 puro para la línea de tiempo.

Testing: `pytest` + `pytest-asyncio` + `respx` para mockear HTTP; Vitest + Testing Library en frontend. Cobertura mínima 70% en `backend/app/services`.

---

## 3. MODELO DE DATOS

Genera las migraciones SQL completas. Esquema mínimo:

`sources` — catálogo de proveedores: `id`, `name`, `kind` (api, oai_pmh, crawl), `base_url`, `license_default`, `robots_ok`, `rate_limit_rpm`, `enabled`.

`documents` — `id`, `source_id`, `external_id`, `doi`, `title`, `subtitle`, `lang`, `pub_year`, `pub_year_precision` (exact, decade, century, unknown), `work_type` (libro, artículo, tesis, capítulo, manuscrito, informe), `publisher`, `url`, `file_url`, `mime`, `sha256`, `page_count`, `license`, `full_text_available`, `ingested_at`, `original_language_note`. Único: (`source_id`, `external_id`) y `sha256`.

`authors` — `id`, `display_name`, `normalized_name`, `birth_year`, `death_year`, `viaf_id`, `wikidata_qid`, `tradition` (enum abierto: retórica latina, escolástica, humanismo, barroco, ilustración, idealismo, fenomenología, filosofía de la técnica, teoría de medios, otra), `notes`, `confidence`.

`document_authors` — `document_id`, `author_id`, `role` (autor, editor, traductor, comentarista), `position`.

`places` — `id`, `name`, `country_code`, `lat`, `lon`, `geonames_id`, `precision` (ciudad, región, país, desconocido), `resolver` (geonames, nominatim, manual).

`document_places` — `document_id`, `place_id`, `relation` (lugar_de_escritura, lugar_de_publicación, afiliación_autor, lugar_de_custodia_del_manuscrito), `evidence`, `confidence`. Esta tabla es la que alimenta el mapa: una mención puede aparecer en varios puntos y la interfaz debe dejar claro **qué relación** representa cada punto.

`mentions` — `id`, `document_id`, `page`, `char_start`, `char_end`, `matched_form` (la forma exacta hallada), `lemma_group` (§5.1), `snippet` (máx. 300 caracteres), `context_before`, `context_after` (200 caracteres cada uno, no expuestos por API si la licencia es restringida), `lang`, `embedding vector(1024)`, `sha256_snippet`.

`interpretations` — una fila por mención analizada: `id`, `mention_id`, `claim` (qué se afirma del ingenium, en una oración), `argumentative_role` (enum: define, distingue, critica, apropia, historiza, traduce, ejemplifica, opone), `opposed_to` (texto libre normalizado: ratio, methodus, iudicium, técnica, algoritmo, memoria, cálculo…), `interlocutor` (autor o corriente contra la que se argumenta, si consta), `why` (la razón que el propio texto da, no la razón que el modelo suponga), `evidence_quote` (subcadena literal del snippet), `tradition_inferred`, `confidence` (0–1), `model`, `prompt_version`, `created_at`. Restricción: si `confidence < 0.55` la fila se marca `needs_review = true` y no se muestra en el mapa sin etiqueta de baja confianza.

`concepts` y `concept_edges` — nodos conceptuales (`ingenium`, `ratio`, `methodus`, `Witz`, `esprit`, `genio`, `techne`, `organología`, `pharmakon`…) y aristas con `weight` derivado de coocurrencia dentro de una ventana de 1.000 caracteres, más `edge_type` (coocurrencia, oposición_explícita, sinonimia_declarada).

`crawl_jobs` y `crawl_events` — para trazabilidad operativa: estado, contador de páginas, errores, `robots_snapshot`.

`extraction_gaps` — `entity_type`, `entity_id`, `field`, `reason`. Esta tabla es la garantía de honestidad del sistema: lo que no se sabe queda escrito.

Vistas materializadas: `mv_map_points` (mención + lugar + autor + año + color de tradición), `mv_timeline` (conteos por década y tradición), `mv_author_summary`.

RLS: lectura pública solo sobre las vistas materializadas y sobre `documents` con `license <> 'restricted'`; escritura solo con `service_role`.

---

## 4. FUENTES A INTEGRAR

Implementa un conector por fuente, todos con la misma interfaz `SourceAdapter` (`search(query, since, until) -> AsyncIterator[DocumentCandidate]`, `fetch_file(candidate) -> bytes | None`), registro en `sources` y pruebas con `respx`.

Prioridad 1 (APIs con búsqueda de texto completo o metadatos ricos): OpenAlex, Crossref, Semantic Scholar, CORE, DOAJ, Zenodo, arXiv, OAI-PMH genérico para repositorios institucionales, Internet Archive, HathiTrust (solo metadatos y dominio público), Google Books API (solo metadatos y snippets permitidos), Wikisource, Perseus Digital Library y The Latin Library para el corpus latino, Gallica (BnF), Europeana, Biblioteca Digital Hispánica, SciELO y Redalyc para el ámbito iberoamericano, y el repositorio institucional de EAFIT y de las universidades colombianas vía OAI-PMH.

Prioridad 2 (crawler dirigido, `robots.txt` primero): PhilPapers, Monoskop, dominios `.edu` y `.ac.*` con documentos abiertos, y una lista blanca configurable en `config/domains.yaml` que yo pueda editar.

Cada candidato entra en una cola con deduplicación por DOI, luego por `sha256`, luego por similitud de título con `pg_trgm` mayor a 0.92.

---

## 5. DETECCIÓN E INTERPRETACIÓN

### 5.1 Grupos de búsqueda

Define en `config/lexicon.yaml` los grupos siguientes, cada uno con su expresión regular sensible a flexión y su idioma:

Núcleo latino: `ingenium`, `ingenii`, `ingenio`, `ingeniis`, `ingenia`, `ingeniorum`, `ingeniosus`, `ingeniosa`, `ingeniose`.
Romance: español `ingenio`, `ingeniosidad`, `ingenioso`; italiano `ingegno`; francés `engin`, `esprit` (solo con desambiguación de contexto), `génie`; portugués `engenho`.
Germánico e inglés: `Witz`, `Scharfsinn`, `wit`, `ingenuity`, `wittiness`.
Vecinos conceptuales que activan el análisis de oposición: `ratio`, `methodus`, `iudicium`, `memoria`, `ars`, `techne`, `technē`, `phronesis`, `genius`.

Advertencia de precisión: `ingenio` en español y `engenho` en portugués también significan máquina, artificio e ingenio azucarero. Implementa un clasificador de desambiguación (reglas de contexto + un paso LLM barato) y guarda el resultado en `mentions.lemma_group` con un campo `sense` (`facultad`, `artefacto`, `topónimo`, `ambiguo`). El mapa filtra por `sense = facultad` de forma predeterminada, con conmutador visible.

### 5.2 Extracción del "por qué"

Para cada mención con `sense = facultad`, envía al LLM el snippet más 1.200 caracteres de contexto y pide **exclusivamente** este JSON:

```
{
  "claim": "",
  "argumentative_role": "define|distingue|critica|apropia|historiza|traduce|ejemplifica|opone",
  "opposed_to": [],
  "interlocutor": null,
  "why": "",
  "evidence_quote": "",
  "tradition_inferred": null,
  "confidence": 0.0,
  "insufficient_evidence": false
}
```

Reglas del prompt de interpretación, escríbelas literalmente en el archivo: `evidence_quote` debe ser una subcadena exacta del texto recibido, y el backend lo verifica programáticamente; si no lo es, la fila se descarta y se registra en `extraction_gaps`. `why` recoge la razón que el texto da, y si el texto no da razón, `insufficient_evidence = true` y `why = ""`. Prohibido completar con conocimiento general sobre el autor.

---

## 6. API FASTAPI

Estructura: `backend/app/{main.py,api/v1/,services/,adapters/,models/,schemas/,db/,prompts/,workers/}`.

Endpoints de lectura: `GET /api/v1/mentions` con filtros por `year_from`, `year_to`, `tradition`, `lang`, `role`, `sense`, `author_id`, `place_id`, `q` (búsqueda semántica sobre embeddings, `min_confidence`, paginación por cursor. `GET /api/v1/mentions/{id}` devuelve la mención con su interpretación, su documento, sus autores, sus lugares y su cadena de procedencia completa. `GET /api/v1/map/points` sirve GeoJSON `FeatureCollection` ya agregado por lugar con `count`, `tradition_dominant` y `sample_mention_ids`. `GET /api/v1/timeline`, `GET /api/v1/graph`, `GET /api/v1/authors`, `GET /api/v1/documents/{id}`, `GET /api/v1/stats/coverage` (documentos por fuente, por licencia, por idioma, y menciones sin interpretación).

Endpoints de operación, protegidos por cabecera `X-Admin-Token`: `POST /api/v1/crawl/jobs`, `GET /api/v1/crawl/jobs/{id}`, `POST /api/v1/ingest/file` (subida manual de PDF o DOCX propio), `POST /api/v1/reprocess/interpretations?prompt_version=`, `POST /api/v1/export/obsidian`.

Todo con OpenAPI documentado, `response_model` explícito, y errores en formato problem-details con mensaje que dice qué pasó y qué hacer.

---

## 7. FRONTEND: LA VISTA INTERACTIVA

### 7.1 Dirección visual

No uses el aspecto genérico de dashboard oscuro con acento verde ácido, ni el de fondo crema con serif y terracota. La dirección es **cartografía filológica**: la pantalla se comporta como una carta náutica anotada al margen.

Tokens de color, escríbelos en `src/styles/tokens.css` como variables CSS y consúmelos desde Tailwind:

```
--ink:        #0E1A1F   /* fondo base, azul-tinta profundo */
--ink-2:      #142530   /* paneles */
--rule:       #294049   /* hairlines, retícula del mapa */
--vellum:     #E8E1D1   /* texto principal, papel */
--vellum-dim: #8FA3AB   /* texto secundario */
--amber:      #F2B33D   /* retórica latina */
--vermilion:  #E85D4A   /* humanismo y barroco */
--jade:       #4FC1A6   /* ilustración */
--lilac:      #A78BFA   /* idealismo y romanticismo */
--sky:        #5BA8F5   /* fenomenología */
--magenta:    #EC6EC0   /* filosofía de la técnica y teoría de medios */
```

Los seis colores categóricos **codifican tradición intelectual**, no decoran: la leyenda es funcional y clicable, y un punto sin tradición determinada se dibuja en `--vellum-dim` con contorno punteado, porque la ignorancia también se representa. Verifica contraste AA sobre `--ink`.

Tipografía en tres roles: display `Fraunces` (eje wonk activo, usada solo en títulos de sección y en el número de menciones), lectura `Literata` para citas y párrafos largos, utilitaria `IBM Plex Mono` para metadatos, offsets, años y etiquetas de eje. Escala tipográfica definida en tokens, no valores sueltos.

**Elemento firma: el cajón de marginalia.** Al seleccionar un punto del mapa, no se abre un modal centrado: se desliza desde el borde derecho un panel con textura de vellum (`--vellum` sobre `--ink`) que muestra la cita, el rol argumentativo como sello tipográfico, el "por qué" y la procedencia; y desde el panel se dibuja con SVG un hilo de un píxel que permanece anclado al punto del mapa mientras el usuario navega. Ese hilo es la metáfora de la trazabilidad y es lo único que se anima con generosidad. Respeta `prefers-reduced-motion`.

### 7.2 Vistas

Vista Mapa, principal: MapLibre con estilo oscuro propio y retícula en `--rule`, clústeres proporcionales al número de menciones, color por tradición dominante, y conmutador de la relación geográfica representada (escritura, publicación, afiliación, custodia), porque un punto significa cosas distintas según la relación. Al hacer hover, tooltip con autor, año y forma hallada. Al hacer clic, el cajón de marginalia.

Barra temporal inferior, siempre visible: histograma por década, arrastrable, que filtra el mapa en tiempo real. Marca visualmente las décadas con `pub_year_precision <> 'exact'` con trama diagonal para no fingir precisión.

Vista Grafo: `d3-force` con `ingenium` en el centro y aristas cuyo grosor es la coocurrencia y cuyo estilo distingue oposición explícita de simple coocurrencia.

Vista Autores: tabla densa ordenable, con búsqueda, que enlaza a mapa y a grafo.

Panel de cobertura: qué se buscó, en qué fuentes, cuántos documentos por licencia e idioma, y cuántas menciones esperan revisión. Sin este panel la aplicación no está terminada.

Buscador semántico: campo único que acepta una frase en cualquier idioma y devuelve menciones por similitud de embedding, mostrando la distancia como dato, no como porcentaje inventado de "relevancia".

Estados vacíos y de error redactados en voz activa, que dicen qué pasó y cuál es el siguiente paso. Accesibilidad: navegación por teclado en mapa y cajón, foco visible, `aria-live` para los resultados del filtro.

---

## 8. EXPORTACIÓN A OBSIDIAN

`POST /api/v1/export/obsidian` genera un directorio `vault/` con esta estructura y lo entrega en `.zip`:

`00 - MOC/` con `MOC Ingenium.md` como índice maestro, más MOCs por tradición y por siglo. `10 - Conceptos/` con una nota por concepto. `20 - Autores/` con una nota por autor. `30 - Obras/` con una nota por documento. `40 - Menciones/` con una nota por mención, nombrada `{apellido}-{año}-p{página}-{n}.md`. `90 - Meta/` con `Cobertura.md`, `Vacíos.md` (volcado de `extraction_gaps`) y `Registro de procesamiento.md`.

Cada nota de mención lleva frontmatter YAML con `author`, `year`, `place`, `lat`, `lon`, `lang`, `matched_form`, `sense`, `argumentative_role`, `opposed_to`, `confidence`, `source_url`, `page`, `char_start`, `char_end`, `license`, `tags`. El cuerpo trae la cita en blockquote, el "por qué" como párrafo, enlaces `[[wikilink]]` al autor, a la obra, a la tradición y a los conceptos opuestos, y una línea de procedencia con la URL. Añade consultas Dataview listas para usar en los MOC y un `Ingenium.canvas` con los nodos principales. La exportación es idempotente: reejecutar sobre la misma bóveda actualiza, no duplica.

---

## 9. ENTREGA POR FASES CON CRITERIOS DE ACEPTACIÓN

FASE 0 — Repo, `docker-compose` con Postgres local para pruebas, `.env.example`, CI de GitHub Actions con lint y tests, `README.md` con arranque en menos de cinco comandos. Aceptación: `make dev` levanta backend y frontend y `pytest` pasa en verde.

FASE 1 — Migraciones Supabase completas, RLS, vistas materializadas y seeds de `sources`, `concepts` y `lexicon`. Aceptación: `supabase db reset` reconstruye todo sin errores y una consulta de ejemplo devuelve filas de los seeds.

FASE 2 — Dos adaptadores reales (OpenAlex y Zenodo) más ingesta manual de archivo, extracción de texto con OCR de respaldo y detección de menciones con desambiguación de sentido. Aceptación: al ingerir tres PDF que yo suba, el sistema muestra las menciones halladas con página y offsets verificables abriendo el PDF.

FASE 3 — Capa de interpretación con verificación programática de `evidence_quote`, embeddings y poblado de `extraction_gaps`. Aceptación: en una muestra de veinte menciones, cien por ciento de las `evidence_quote` son subcadenas exactas del texto fuente.

FASE 4 — API completa y documentada. Aceptación: `/docs` operativo y todos los endpoints de lectura respondiendo con datos reales.

FASE 5 — Frontend con mapa, línea de tiempo, cajón de marginalia y panel de cobertura. Aceptación: navegable con teclado, responsive a 390 píxeles de ancho, y sin ningún dato que no provenga de la API.

FASE 6 — Resto de adaptadores, grafo, buscador semántico y exportación a Obsidian. Aceptación: bóveda que abre en Obsidian con Dataview funcionando y sin enlaces rotos.

---

## 10. QUÉ NO HACER

No generes datos de ejemplo que parezcan reales: si necesitas fixtures, ponlos en `tests/fixtures/` y nómbralos con prefijo `FIXTURE_`. No uses `localStorage` para estado que deba persistir de verdad. No pongas la clave de servicio de Supabase en el frontend, solo la `anon`. No escribas resúmenes extensos de las obras rastreadas ni reproduzcas capítulos completos. No entregues código que no hayas ejecutado. Cuando una decisión técnica tenga dos caminos razonables, detente, expón las dos opciones en una línea cada una y pregúntame antes de seguir.

---

## 11. NOTA DE ENTORNO DE DESARROLLO (agregada tras iniciar el proyecto)

El entorno local de trabajo **no tiene Docker ni Node.js/npm instalados, y no se pueden instalar**
(restricción del equipo del usuario). Sí están disponibles Git y Python 3.11 (vía `py -3.11`).

Adaptación de la estrategia de validación, sin relajar ningún criterio de aceptación del enunciado:

- El backend se desarrolla y se prueba localmente con un entorno virtual de Python 3.11 y `pytest`
  (usando `respx` para HTTP y, cuando se requiera Postgres real, mocks o SQLite en memoria para
  pruebas unitarias; las pruebas de integración con Postgres/pgvector corren en CI).
- El frontend se escribe completo (React/TS/Vite) pero **no se ejecuta ni se compila localmente**.
  Se valida mediante GitHub Actions (los runners sí traen Node) y se despliega en Railway para
  visualización real tras cada `git push`.
- `docker-compose.yml` y `make dev` se mantienen en el repo tal como pide el enunciado, pensados
  para correr en CI, en Railway o en cualquier máquina del usuario que sí tenga Docker; no se
  ejecutan en esta máquina de desarrollo.
- Cada fase se da por aceptada cuando: (a) las pruebas de backend ejecutables localmente pasan en
  verde y se muestra la salida real, y (b) el pipeline de GitHub Actions (lint + tests + build)
  pasa en verde tras el push, lo que constituye la evidencia equivalente a `make dev`/`supabase db
  reset` en esta configuración.
