# INGENIUM TRACKER

Rastreo del concepto de *ingenium* (y sus flexiones latinas, romances y germánicas) en la
literatura filosófica y técnica de acceso abierto: cada mención se extrae con su contexto exacto,
se interpreta (qué se afirma y por qué), se geolocaliza y se exporta como bóveda de Obsidian
navegable. Ver el encargo completo en [.github/copilot-instructions.md](.github/copilot-instructions.md).

## Arranque rápido (con Docker)

```bash
git clone <url-del-repo>
cd INGENIUM
cp .env.example .env
make dev
```

Esto levanta Postgres (con `pgvector`), el backend en `http://localhost:8000` (docs en `/docs`) y
el frontend en `http://localhost:5173`.

## ⚠️ Nota sobre esta máquina de desarrollo

Esta máquina de desarrollo concreta **no tiene Docker ni Node.js/npm instalados** y no es posible
instalarlos (restricción del equipo). Por eso, aquí el flujo de trabajo real es:

1. El **backend** se desarrolla y se prueba con Python 3.11 en un entorno virtual local:
   ```bash
   cd backend
   py -3.11 -m venv .venv
   .venv\Scripts\pip install -r requirements-dev.txt
   .venv\Scripts\python -m pytest -v
   ```
2. El **frontend** se escribe completo pero no se ejecuta en esta máquina. Se valida mediante el
   pipeline de GitHub Actions ([.github/workflows/ci.yml](.github/workflows/ci.yml)), que sí corre
   en runners con Node.js.
3. Tras cada `git push`, el proyecto se despliega en **Railway** (backend y frontend como
   servicios separados, ver `backend/Dockerfile` y `frontend/Dockerfile`), donde se puede
   visualizar el resultado real.

`docker-compose.yml` y `make dev` quedan tal como pide el encargo original, listos para cualquier
máquina que sí tenga Docker.

## Estructura del repositorio

```
backend/    API FastAPI, adaptadores de fuentes, servicios de NLP/interpretación, tests
frontend/   React + TypeScript + Vite, mapa, grafo, línea de tiempo
supabase/   Migraciones SQL (Postgres + pgvector + RLS), seeds
config/     Léxico multilingüe de ingenium, lista blanca de dominios para el crawler
docs/       Documentación de cobertura y sesgos de las fuentes
```

## Pruebas

```bash
# backend
cd backend && python -m pytest -v

# frontend (requiere Node.js; se valida en CI si no está disponible localmente)
cd frontend && npm run test
```

## Variables de entorno

Copia `.env.example` a `.env` y completa las claves reales. Ninguna clave se hardcodea en el
código ni se sube al repositorio.

## Fases del proyecto

El desarrollo avanza en fases con criterios de aceptación explícitos, documentados en
[.github/copilot-instructions.md](.github/copilot-instructions.md#9-entrega-por-fases-con-criterios-de-aceptación).
Estado actual: **FASE 0 y FASE 1 completadas** (ver commits).
