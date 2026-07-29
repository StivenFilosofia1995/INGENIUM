-- ============================================================================
-- ATLAS DEL INGENIUM — esquema independiente para cartografia_del_ingenium_1.html
-- ============================================================================
-- Este esquema NO es el de FASE 1 (sources/documents/mentions/interpretations).
-- Es deliberadamente aparte: el atlas del ingenium es un instrumento curado a
-- mano por Stive Arteaga y Andrés Vélez Posada, no el resultado del pipeline
-- automático de ingesta. Estas tablas guardan SOLO los aportes que se agreguen
-- en vivo desde el HTML publicado — nunca los 143 nodos curados originales,
-- que siguen viviendo en el propio archivo HTML (NODES / VELEZ_NODES).
--
-- El HTML, al cargar, hace merge de: (a) su dataset curado embebido + (b) lo
-- que lea de estas tablas. Por eso las columnas source/target de atlas_links
-- NO tienen foreign key contra atlas_nodes: un enlace aportado por un visitante
-- puede perfectamente apuntar a un nodo curado (p. ej. "huarte") que nunca
-- existirá como fila en atlas_nodes. La integridad referencial se resuelve del
-- lado del cliente (igual que ya hace el propio HTML con rebuildGlobeLinks/
-- byId), no en la base de datos.
-- ============================================================================

create table if not exists public.atlas_nodes (
  id          text primary key,
  n           text not null check (char_length(n) between 1 and 200),
  k           text not null check (k in ('persona','obra','artefacto','practica','institucion','concepto')),
  y           integer not null,
  r0          integer,
  r1          integer,
  la          double precision not null check (la between -90 and 90),
  lo          double precision not null check (lo between -180 and 180),
  pl          text,
  rg          text,
  tr          text,
  ax          text[] not null default '{}',
  d           text not null check (char_length(d) between 1 and 3000),
  s           text[] default '{}',
  fu          text,
  fo          text,
  q           text,
  contributor text check (char_length(contributor) <= 120),
  created_at  timestamptz not null default now()
);

create table if not exists public.atlas_links (
  id          bigint generated always as identity primary key,
  source      text not null check (char_length(source) between 1 and 100),
  target      text not null check (char_length(target) between 1 and 100),
  type        text not null check (type in ('inf','tra','opo','ins','rei','par','anl')),
  label       text not null check (char_length(label) between 1 and 300),
  contributor text check (char_length(contributor) <= 120),
  created_at  timestamptz not null default now()
);

comment on table public.atlas_nodes is 'Nodos aportados en vivo al atlas del ingenium (cartografia_del_ingenium_1.html). No incluye el dataset curado, que vive embebido en el HTML.';
comment on table public.atlas_links is 'Relaciones aportadas en vivo al atlas del ingenium. source/target pueden apuntar a nodos curados del HTML o a filas de atlas_nodes.';

alter table public.atlas_nodes enable row level security;
alter table public.atlas_links enable row level security;

-- Lectura pública: cualquiera que abra el atlas ve los aportes de todos.
create policy "atlas_nodes_public_read" on public.atlas_nodes
  for select using (true);

create policy "atlas_links_public_read" on public.atlas_links
  for select using (true);

-- Escritura abierta (modelo "wiki"): cualquiera puede añadir nodos y enlaces.
create policy "atlas_nodes_public_insert" on public.atlas_nodes
  for insert with check (true);

create policy "atlas_links_public_insert" on public.atlas_links
  for insert with check (true);

-- Deliberadamente NO hay políticas de update/delete para anon/authenticated:
-- sin una política permisiva, RLS las bloquea por defecto. Modificar o borrar
-- una fila ya aportada requiere la service_role_key (uso administrativo desde
-- el SQL editor de Supabase o un script propio), nunca desde el HTML público.
-- Esto evita que un visitante borre o altere aportes de otra persona.
