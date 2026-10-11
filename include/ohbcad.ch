/*----------------------------------------------------------------------------
   OpenHBCADStudio - include/ohbcad.ch
   Port Harbour/FiveWin64 (MSVC22) de OpenCADStudio (Rust).
   Constantes globales: tipos de entidad, colores ACI, resultados de comando.
   Rust origen: src/entities/names.rs, src/entities/common.rs,
                src/command.rs, src/scene/mod.rs (parcial).
----------------------------------------------------------------------------*/

// --- Versión (Rust: Cargo.toml [package] version) ---
#define OHB_VERSION_MAJOR  2026
#define OHB_VERSION_MINOR  40
#define OHB_VERSION_PATCH  1
#define OHB_VERSION_STR    "2026.40.1-hb1"

// --- Tipos de entidad (Rust: codec::EntityType / entities/names.rs) ---
#define OHB_ENT_LINE        1
#define OHB_ENT_POINT       2
#define OHB_ENT_CIRCLE      3
#define OHB_ENT_ARC         4
#define OHB_ENT_ELLIPSE     5
#define OHB_ENT_LWPOLYLINE  6
#define OHB_ENT_POLYLINE    7
#define OHB_ENT_SPLINE      8
#define OHB_ENT_TEXT        9
#define OHB_ENT_MTEXT      10
#define OHB_ENT_HATCH      11
#define OHB_ENT_INSERT     12
#define OHB_ENT_DIM        13
#define OHB_ENT_LEADER     14
#define OHB_ENT_MLEADER    15
#define OHB_ENT_TABLE      16
#define OHB_ENT_SOLID      17
#define OHB_ENT_TRACE      18
#define OHB_ENT_SHAPE      19
#define OHB_ENT_RAY        20
#define OHB_ENT_XLINE      21
#define OHB_ENT_VIEWPORT   22
#define OHB_ENT_RASTER     23
#define OHB_ENT_UNDERLAY   24
#define OHB_ENT_MLINE      25
#define OHB_ENT_WIPEOUT    26
#define OHB_ENT_SOLID3D    27
#define OHB_ENT_BODY       28
#define OHB_ENT_REGION     29
#define OHB_ENT_TOLERANCE  30
#define OHB_ENT_ATTDEF     31
#define OHB_ENT_ATTRIB     32
#define OHB_ENT_SEQEND     33

// --- Colores ACI (AutoCAD Color Index) ---
#define OHB_BYLAYER    256
#define OHB_BYBLOCK      0
#define OHB_RED          1
#define OHB_YELLOW       2
#define OHB_GREEN        3
#define OHB_CYAN         4
#define OHB_BLUE         5
#define OHB_MAGENTA      6
#define OHB_WHITE        7

// --- Resultado de comando interactivo (Rust: src/command.rs CmdResult) ---
#define OHB_CMD_OK          0
#define OHB_CMD_CANCEL      1
#define OHB_CMD_NEED_POINT  2
#define OHB_CMD_NEED_TEXT   3
#define OHB_CMD_NEED_NUMBER 4
#define OHB_CMD_NEED_SELECT 5
#define OHB_CMD_ERROR       9

// --- Modos de snap (Rust: src/snap.rs + app/drafting_settings.rs) ---
#define OHB_SNAP_OFF      0
#define OHB_SNAP_END      1
#define OHB_SNAP_MID      2
#define OHB_SNAP_INT      4
#define OHB_SNAP_CEN      8
#define OHB_SNAP_QUA     16
#define OHB_SNAP_TAN     32
#define OHB_SNAP_PERP    64
#define OHB_SNAP_NOD    128

// --- Espacios de dibujo ---
#define OHB_SPACE_MODEL   0
#define OHB_SPACE_PAPER   1

// --- Zoom ---
#define OHB_ZOOM_MIN_FACTOR  0.001
#define OHB_ZOOM_MAX_FACTOR  1000.0

// --- Handles ---
#define OHB_HANDLE_START  1000
