# PORTING — Rust → Harbour/FiveWin64/MSVC22

Documento de trazabilidad de la traducción de OpenCADStudio (Rust,
659 ficheros, ~21 MB) a OpenHBCADStudio (Harbour + FiveWin64 + C/MSVC22).

## 1. Decisiones de arquitectura

| Rust (origen) | Harbour (destino) | Motivo |
|---|---|---|
| `wgpu` + shaders WGSL (`src/shaders/*.wgsl`, `scene/pipeline/*`) | GDI clásico (`MoveTo/LineTo/Ellipse/TextOut`) en `cad_canvas.prg` | FiveWin64 es GDI; no hay binding wgpu. Teselado de arcos/elipses por polilíneas como en `tess.rs`. |
| `iced` + `iced_aw` (`src/ui/*`, ribbon, dock, overlays) | Ventana MDI + `ButtonBar` + menús + diálogos modales (`mainwin.prg`, `cmdline.prg`) | Patrón clásico FiveWin (`samples/test/testmdi.prg`). Sin WebGPU ni iced. |
| `glam::DVec3`, `lyon`, `kurbo` | `csrc/ocad_geom.c` (MSVC22 `-O2`) + `geom.prg` | Aceleración C donde la pidió el proyecto: distancias, ángulos, intersecciones, punto-segmento, afines, longitud/área, teselado, bbox, paralelas. Prefijo `OCX_` (Harbour es insensible a mayúsculas y colisionaría con los envoltorios `OC_*`). |
| `opencadcodec` DWG binario + `io/*` | `csrc/ocad_dxf.c` (escáner C) + `dxf_io.prg` (DXF R12/R2000 R/W) | El DWG es formato propietario: intercambio nativo vía DXF ASCII (Lee/Escribe LINE, POINT, CIRCLE, ARC, ELLIPSE, LWPOLYLINE, POLYLINE+VERTEX, SPLINE, TEXT, MTEXT, HATCH, INSERT, DIMENSION, RAY, XLINE, SOLID, TRACE, capas, $INSUNITS). DWG directo: vía ODA File Converter externo o librería Teigha (fase 2). |
| `Scene` (`scene/mod.rs`, 14k líneas) + `app/document.rs` | `TDocDrawing` (`doc.prg`): entidades, capas, bloques, selección, undo (add/del, 200 niveles) | Subconjunto operativo; redo completo y `mspace/paperspace` en fase 2. |
| `CadCommand` (`command.rs`) + `modules/registry.rs` | `TCmdBase` + tabla bilingüe ES/EN (`commands.prg`) | 30 comandos implementados (dibujo, edición, consulta, capas, vista, archivo). |
| `iced_test` + `tests/integration.rs` | `tests/smoke.prg` (16 checks, consola) | Verificado: `smoke.exe` → `SMOKE-ALL-OK` (MSVC22 x64). |
| `build.rs` (winresource) + Cargo | `build64.bat` + `SOURCES.lst` + `resources/OpenHBCADStudio.rc` | Receta `buildh64.bat` FiveTech: `harbour /d__64__`, `cl -O2 -D_WIN64`, `link /subsystem:windows` con `FiveH64.lib`/`FiveHC64.lib`. |
| `std::f64` notación `1e-12` | literales decimales (`0.000000000001`) | Harbour no acepta `1e-12` sin punto decimal. |
| `hb_IIf()` (xhb) | `If()` del núcleo | Evita dependencia de `xhb.lib` en el código propio. |
| `main.rs` → `main.prg` | `ohbcad.prg` | Harbour genera el arranque implícito con el nombre del módulo: fichero `main.prg` + `FUNCTION Main()` colisionan (E0002). |
| `src/main.rs` (espejo) | `src/main.prg` (stub) | El espejo 1:1 se conserva; el ejecutable arranca en `ohbcad.prg`. |

## 2. Cobertura por módulo (fase 1)

- `entities/*` (43 rs) → `ent_base/ent_draw/ent_extra.prg`: 21 clases con Draw/Grips/BBox/DXF/Transform/HitTest. Sólidos 3D, mallas, nubes de puntos, GDI/WMF/EMF, PDF/DWF/DGN: envolvente 2D o fase 2.
- `scene/*` → `doc.prg` + `cad_canvas.prg`: documento, extents, selección ventana/cruce, zoom/pan/rejilla/snap (END/MID/CEN…), grips. Sin `quadtree` (barrido lineal), sin GPU.
- `modules/draw/draw/*` (27 rs) → `draw_cmds.prg`: LINEA, CIRCULO, ARCO(3P), POL, PUNTO, TEXTO, RAYO, LINEAX, ELIPSE, SOMBREADO, COTLIN. Resto (donut, hélice, wipeout, sketch, shape…) fase 2.
- `modules/draw/modify/*` (34 rs) → `modify_cmds.prg`: BORRA, MUEVE, COPIA, GIRA, ESCALA, SIMETRIA, DESFASE (línea/círculo/arco/poli), EMPALME (línea-línea), RECORTA (línea/línea), MATRIZ (rect/polar), IGUALA. PEDIT/SPLINEDIT/OVERKILL/STRETCH/EXPLODE… fase 2.
- `modules/draw/inquiry/*` → `inquiry_cmds.prg`: DIST, AREA, ID + ZOOM, ENCUADRE, CAPA, ABRE, GUARDA, NUEVO, DESHACER.
- `ui/*` (60+ rs) → `mainwin/cmdline.prg`: menú completo, barra de botones, línea de comandos con historial, panel de propiedades (8 líneas), coordenadas, gestor de capas. Estilos de cota/texto/tablas, paletas, ribbon contextual: fase 2.
- `plugin/*` + `crates/ocs_plugin_api` → fase 2 (DLL Harbour con `HB_FUNC`).
- `input/*`, `cli.rs`, `mcp*.rs`, `rest*.rs`, `network.rs`, web/wasm (`Trunk.toml`, `web-app.html`) → n/a en desktop FiveWin (la CLI acepta `exe [dibujo.dxf]`).
- `parcialmente`: `parametric/*` (solver), `model/*` (ACIS), `insert/*` (XREF/PDF/DGN/point-cloud), `layout/*`, `manage/*`, `annotate/*` avanzado, `plot/print/pdf_export`, `i18n` (solo ES/EN en comandos).

## 3. Cómo continuar (fase 2)

1. XBrowse de capas/propiedades (sustituir SAYs), `TRibbon` FiveWin.
2. Presentaciones (paper space) + trazado (`TPrinter`, `TPDF`/HaruPDF incluido en FWH).
3. DWG vía ODA + miniaturas (`thumbnail.rs` → BMP del preview).
4. Redo, grupos, Portapapeles, PEDIT, STRETCH, EXPLODE, sombreados asociativos.
5. Solver paramétrico puro Harbour (ecuaciones `parametric_solve.rs` son portables).
6. Plugins DLL (`HB_FUNC`) con la API de `crates/ocs_plugin_api`.

## 4. Incidencias resueltas durante el port

1. `E0002 Redefinition of 'MAIN'`: renombrado a `ohbcad.prg`.
2. `F0029 hbclass.ch`: añadir include de Harbour (`-i`) y `hbclass.ch` en ficheros sin FiveWin.
3. `E0030 'ALWAYS'`: `ENDCLASS` sobrante tras métodos (corta/pega).
4. `1e-12`: Harbour exige punto decimal en notación científica.
5. `LNK2005 OC_*`: colisión C↔Harbour → prefijo `OCX_` en C.
6. `.bat` con LF: `cmd.exe` exige CRLF (fallos intermitentes de `call :etiqueta`).
7. Bucle infinito en `dxf_read_layer`: empezar en `nI+1` (como `dxf_read_ent`).
8. `hb_arraySetForward` + `hb_itemRelease`: usar patrón `hb_arraySet` + release.

## 5. Cierre de la fase 2: lo portado y lo que queda como N/A

Portado en la fase 2 (con tests en Linux; la GUI solo se ejecuta en Windows): visor/editor 2D (zoom, pan, capas, hatch, linea de comandos ES/EN, seleccion, grips, snap, menus, guardar), ribbon de 8 pestanas, comandos de dibujo y edicion, textos, MTEXT, cotas, INSERT, 3D alambre con orbita, lector SAT con descifrado, teselado de caras planas, cono/cilindro, esfera y toro (`vw_sattess.prg`), sombreado painter (`vw_shade.prg`, comando `SOMBREADO`, `OCX_FILLTRI` en `csrc/ocad_win.c`) y trazado a PDF vectorial (`vw_plot.prg`, comando `PLOT`/`EXPORTPDF`).

N/A (no portable a Harbour/FiveWin/GDI, o fuera de alcance de esta fase):

- Shaders GPU y backend wgpu (`src/shaders/*`, `gpu_backend.prg`): el render es GDI con algoritmo del pintor.
- Plugins (`src/plugin/*`), red y servicios web (`network.prg`, `rest.prg`, `mcp*.prg`, `patreon.prg`, `update_check`, `web_*`): dependen de librerias Rust y servicios externos.
- NURBS y blends ACIS, SAB binario, caras curvas recortadas con precision (se rellenan por el rango de sus bordes), esfera con lazos no circulares y toro parcial.
- ARRAYPATH, ELLIPSE_ARC, trim/extend de polilineas y splines.
- PDF: fuentes TrueType del dibujo, estilos CTB/STB, layouts y viewports multiples, imagenes.
- DWG nativo: se integrara desde el proyecto Harbour del usuario (fase posterior).
- Sin verificar en Windows real: enlace de `USE_FW=1` con los cambios de `OCX_FILLTRI` y `DrawShaded`.
