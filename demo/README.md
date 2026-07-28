# Demo de mapa (prototipo visual)

`map-demo.html` es un prototipo **independiente**, sin Node/npm ni paso de build: usa
MapLibre GL JS y tiles raster gratuitos de OpenStreetMap vía CDN (`unpkg.com`), pensado
para esta máquina de desarrollo que no puede instalar Node.js.

## Cómo verlo

Ábrelo directamente con doble clic o:

```powershell
start demo\map-demo.html
```

Requiere conexión a internet (carga MapLibre GL JS y los tiles desde CDN públicos). No
requiere clave ni token de ningún proveedor.

## Qué demuestra

- La dirección visual "cartografía filológica" (§7.1): tokens de color, retícula, tipografías.
- El **cajón de marginalia**: al hacer clic en un punto se desliza un panel con textura de
  vellum y un hilo SVG que lo conecta con el punto en el mapa.
- El conmutador de relación geográfica (escritura / publicación / afiliación / custodia).
- La leyenda de tradición, clicable y funcional (oculta/muestra puntos).
- Accesibilidad básica: marcadores como `<button>` navegables por teclado, cierre con
  `Escape`, `aria-live` para el estado, respeto de `prefers-reduced-motion`.

## Importante

Todos los puntos están marcados **`FIXTURE_*`** y con textos "[Texto de ejemplo]": no son
citas, autores ni interpretaciones reales (§10 del prompt maestro — "no inventes datos").
Las coordenadas de las ciudades sí son reales (dato geográfico verificable), pero el resto
del contenido es un marcador de posición para probar el diseño antes de construir el
componente React real de FASE 5, que consumirá `GET /api/v1/map/points` con datos
verdaderos.
