# OpenHBCADStudio

Port a **Harbour + FiveWin64 + MSVC22 (x64)** de
[OpenCADStudio](../OpenCADStudio/) (Rust + iced/wgpu).

Versión: `2026.40.1-hb1` (sigue a OpenCADStudio 2026.40.1).

## Requisitos (rutas fijas del proyecto)

| Componente | Ruta |
|---|---|
| Harbour 3.2 64-bit MSVC22 | `C:\PRG\HB\HB_64_MSVC22\` |
| FiveWin64 26.x | `C:\PRG\FWH\fwh2605\fwh64\` |
| MSVC 2022 (cl/link x64) | Visual Studio 2022 Community instalado |
| Fuentes Rust originales | `C:\PRG\XDCODE\PRJ\AUTOCAD\OpenCADStudio\` |

No se necesita ningún compilador adicional (todo va con MSVC22 +
`hbmk2`/receta FiveWin). No se instaló nada en `/prg/comp` porque no hizo
falta; si en el futuro se requiere alguna utilidad, irá en `C:\PRG\`.

## Construcción

Desde la raíz del repo, en una consola con MSVC x64 (o dejando que `build.bat` llame a `vcvarsall`):

```bat
build.bat USE_FW=1 norun   :: compila y enlaza la GUI -> OpenHBCADStudio.exe (raíz del repo)
build.bat                  :: compila y ejecuta los tests de consola (t_ocx.exe, esperado 0 fallos / OCX-ALL-OK)
build.bat clean            :: limpia obj_t, obj_a y los ejecutables
```

Ajusta `HBROOT` (Harbour msvc64) y `FWH_DIR` (fwh64) al principio de `build.bat` o como variables de entorno. Instalación de MSVC: `docs/instalar-msvc.md`. Si falla, envía `comp_one.log` y `cl_one.log`.
`build64.bat` es el script antiguo del esqueleto previo y ya no es el camino soportado.

## Uso

```bat
OpenHBCADStudio.exe [dibujo.dxf]
```

Comandos (ES/EN): `LINEA/LINE`, `CIRCULO/CIRCLE`, `ARCO/ARC`, `POL/PLINE`,
`PUNTO/POINT`, `TEXTO/TEXT`, `RAYO/RAY`, `LINEAX/XLINE`, `ELIPSE/ELLIPSE`,
`SOMBREADO/HATCH`, `COTLIN/DIMLIN`, `BORRA/ERASE`, `MUEVE/MOVE`,
`COPIA/COPY`, `GIRA/ROTATE`, `ESCALA/SCALE`, `SIMETRIA/MIRROR`,
`DESFASE/OFFSET`, `EMPALME/FILLET`, `RECORTA/TRIM`, `MATRIZ/ARRAY`,
`IGUALA/MATCHPROP`, `DIST`, `AREA`, `ID`, `CAPA/LAYER`, `ZOOM`,
`ENCUADRE/PAN`, `ABRE/OPEN`, `GUARDA/SAVE`, `NUEVO/NEW`, `DESHACER/UNDO`.
Atajos: `L`, `C`, `Supr`, `Esc`, `Ctrl+Z`, `Ctrl+S`.

## Estructura (espejo 1:1 del Rust)

Cada `*.rs` de OpenCADStudio tiene su `*.prg` homólogo en la misma ruta
relativa (`src/`, `crates/`). Los 15 ficheros del núcleo funcional más
`csrc/*.c` llevan la implementación real; el resto son espejos documentados
con el estado de port y el fichero equivalente (ver `docs/PORTING.md`).

| Fichero | Origen Rust |
|---|---|
| `ohbcad.prg` | `src/main.rs` + `src/cli.rs` |
| `include/ohbcad.ch` | `entities/names.rs`, `common.rs`, `command.rs` |
| `csrc/ocad_geom.c` | `glam::DVec3`, `tess*.rs`, `hit_test.rs`, `offset/fillet/trim.rs` |
| `csrc/ocad_dxf.c` | `opencadcodec` (escáner DXF rápido) |
| `src/sys_core.prg` | `main/lib/sys/sysinfo/config.rs`, `app/startup.rs` |
| `src/geom.prg` | envoltorios Harbour del núcleo C |
| `src/entities/ent_*.prg` | `src/entities/*.rs` (21 clases) |
| `src/scene/doc.prg` | `scene/mod.rs`, `app/document.rs`, `layers.rs`, `selection.rs` |
| `src/io/dxf_io.prg` | `opencadcodec` + `io/*.rs` (DXF R12 R/W) |
| `src/ui/cad_canvas.prg` | `scene/view/*`, `pipeline/*`, `pick/*`, `snap.rs`, `input/*` |
| `src/ui/cmdline.prg` | `ui/command_line.rs`, `modal.rs`, `properties.rs`, `statusbar` |
| `src/ui/mainwin.prg` | `app.rs`, `ui/ribbon/*`, `ui/window/*`, `dock.rs` |
| `src/app/commands.prg` | `command.rs`, `modules/registry.rs`, `alias.rs` |
| `src/modules/draw/draw_cmds.prg` | `modules/draw/draw/*`, `annotate/dim*` |
| `src/modules/draw/modify_cmds.prg` | `modules/draw/modify/*` |
| `src/modules/draw/inquiry_cmds.prg` | `modules/draw/inquiry/*`, `view/zoom*`, `layers/*` |
| `tests/smoke.prg` | `tests/integration.rs` (equivalente funcional) |

## Notas de traducción

Ver `docs/PORTING.md`: tabla de adaptaciones (wgpu→GDI, iced→FiveWin,
DWG binario→DXF, wasm→n/a, etc.) y roadmap fase 2.
