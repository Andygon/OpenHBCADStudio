/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/ui/vw_ribbon.prg
   Fase 2 / B8b: cinta (ribbon) con TRibbonBar de FiveWin 26.03.
   Origen Rust: src/ui/ribbon (carpeta) y los mod.rs de src/modules: pestanas
   en el orden de src/modules/registry.rs, grupos y botones como el original
   (nombres en ingles, iconos de assets/icons convertidos a BMP en vw_icons*.prg).
   Boton grande = icono + texto; pequeno = solo icono (columnas de 3);
   desplegable = SPLITPOPUP (clic = accion por defecto, flecha = menu).
   Cada boton ejecuta la linea de comandos del visor (TViewer:Run); los que
   aun no estan portados avisan "Aun no portado". La tabla se genero leyendo
   las fuentes Rust; faltan los combos (capa, estilos) y la logica de colapso.
   Solo se valida compilando y enlazando; la GUI no se ejecuta en Wine.
----------------------------------------------------------------------------*/
#include "FiveWin.ch"
#include "Ribbon.ch"

#define VWR_HEIGHT  150
#define VWR_BW      62
#define VWR_BH      76
#define VWR_SW      28
#define VWR_SH      24
/* tema oscuro del Rust (Oxocarbon), BGR: panel #262626, linea #393939, acento #00B4FF */
#define VWR_PANE    2500134
#define VWR_LINE    3750201
#define VWR_ACCENT  16757760

/* Tabla: { pestana, { { grupo, { { tipo, id, texto, icono, comando, { { id, texto, comando }, ... } }, ... } }, ... } }
   tipo "large" o "small"; comando vacio = pendiente de portar; @ = accion de la ventana. */
STATIC FUNCTION Vwr_Table()
RETURN { ;
 { "Draw", { ;
   { "Draw", { { "large", "LINE", "Line", "line_l", "LINEA", {  } }, { "large", "PLINE", "Polyline", "polyline_l", "PLINE", {  } }, { "large", "CIRCLE", "Circle", "circle_circle_cr_l", "CIRCULO", { { "CIRCLE", "Center, Radius", "CIRCULO" }, { "CIRCLE_CD", "Center, Diameter", "" }, { "CIRCLE_2P", "2-Point", "" }, { "CIRCLE_3P", "3-Point", "" }, { "CIRCLE_TTR", "Tan, Tan, Radius", "" }, { "CIRCLE_TTT", "Tan, Tan, Tan", "" } } }, { "large", "ARC", "Arc", "arc_arc_3p_l", "ARCO", { { "ARC_3P", "3-Point", "ARCO" }, { "ARC_SCE", "Start, Center, End", "" }, { "ARC_SCA", "Start, Center, Angle", "" }, { "ARC_SCL", "Start, Center, Length", "" }, { "ARC_SEA", "Start, End, Angle", "" }, { "ARC_SED", "Start, End, Direction", "" }, { "ARC_SER", "Start, End, Radius", "" }, { "ARC_CSE", "Center, Start, End", "" }, { "ARC_CSA", "Center, Start, Angle", "" }, { "ARC_CSL", "Center, Start, Length", "" }, { "ARC_CONT", "Continue", "" } } }, { "small", "SHAPES", "Shapes", "shapes_rect_s", "", { { "RECT", "Rectangle - Two Corners", "RECTANG" }, { "RECT_ROT", "Rectangle - Rotated", "" }, { "RECT_CEN", "Rectangle - Center", "" }, { "POLY", "Polygon - Inscribed", "POLIGONO" }, { "POLY_C", "Polygon - Circumscribed", "" }, { "POLY_E", "Polygon - Edge", "" } } }, { "small", "ELLIPSE", "Ellipse", "ellipse_ellipse_ctr_s", "", { { "ELLIPSE", "Center, Axes", "" }, { "ELLIPSE_AXIS", "Axis, End", "" }, { "ELLIPSE_ARC", "Ellipse Arc", "" } } }, { "small", "HATCH", "Hatch", "hatch_hatch_lines_s", "", { { "HATCH", "Hatch", "" }, { "GRADIENT", "Gradient", "" }, { "BOUNDARY", "Boundary", "" } } } } }, ;
   { "Modify", { { "small", "MOVE", "Move", "move_s", "MOVER", {  } }, { "small", "COPY", "Copy", "copy_s", "COPIAR", {  } }, { "small", "STRETCH", "Stretch", "stretch_s", "", {  } }, { "small", "ROTATE", "Rotate", "rotate_s", "ROTAR", {  } }, { "small", "MIRROR", "Mirror", "mirror_s", "SIMETRIA", {  } }, { "small", "SCALE", "Scale", "scale_s", "ESCALA", {  } }, { "small", "TRIM", "Trim", "trim_s", "TRIM", { { "TRIM", "Trim", "TRIM" }, { "EXTEND", "Extend", "EXTEND" } } }, { "small", "FILLET", "Fillet", "fillet_s", "FILLET", { { "FILLET", "Fillet", "FILLET" }, { "CHAMFER", "Chamfer", "CHAMFER" } } }, { "small", "ARRAY", "Array", "array_rect_s", "", { { "ARRAYRECT", "Rectangular Array", "" }, { "ARRAYPATH", "Path Array", "" }, { "ARRAYPOLAR", "Polar Array", "" } } }, { "small", "ERASE", "Delete", "erase_s", "BORRAR", {  } }, { "small", "EXPLODE", "Explode", "explode_s", "EXPLODE", {  } }, { "small", "OFFSET", "Offset", "offset_s", "OFFSET", {  } } } }, ;
   { "Annotation", { { "large", "ANNOTATION_TEXT", "Text", "text_l", "", { { "TEXT", "Text", "" }, { "MTEXT", "MText", "" } } }, { "large", "ANNOTATION_DIMENSIONS", "Dimensions", "dim_linear_l", "", { { "DIMLINEAR", "Linear", "" }, { "DIMRADIUS", "Radius", "" }, { "DIMANGULAR", "Angular", "" } } }, { "large", "ANNOTATION_LEADER", "Leader", "leader_l", "", { { "LEADER", "Leader", "" }, { "MLEADER", "MLeader", "" } } } } }, ;
   { "Layers", { { "large", "LAYERS", "Layers", "layers_panel_l", "CAPAS", {  } }, { "small", "LAYOFF", "Layer Off", "layers_layoff_s", "", {  } }, { "small", "LAYFRZ", "Layer Freeze", "layers_layfrz_s", "", {  } }, { "small", "LAYLCK", "Layer Lock", "layers_laylck_s", "", {  } }, { "small", "LAYMCUR", "Make Current", "layers_laymcur_s", "", {  } }, { "small", "LAYISO", "Isolate Layer", "layers_layiso_s", "", {  } }, { "small", "LAYON", "Turn All Layers On", "layers_layon_s", "", {  } }, { "small", "LAYTHW", "Thaw All Layers", "layers_laythw_s", "", {  } }, { "small", "LAYULK", "Layer Unlock", "layers_layulk_s", "", {  } }, { "small", "LAYMATCH", "Match Layer", "layers_laymatch_s", "", {  } }, { "small", "LAYUNISO", "Unisolate Layers", "layers_layuniso_s", "", {  } } } }, ;
   { "Block", { { "small", "BLOCK", "Create Block", "blocks_block_s", "", {  } }, { "small", "BEDIT", "Edit Block", "edit_block_s", "", {  } } } }, ;
   { "Properties", { { "large", "MATCHPROP", "Match", "match_prop_l", "", {  } } } }, ;
   { "Groups", { { "large", "GROUP", "Group", "group_l", "", {  } }, { "large", "UNGROUP", "Ungroup", "ungroup_l", "", {  } } } }, ;
   { "Clipboard", { { "large", "PASTE_MENU", "Paste", "paste_l", "", { { "COPYCLIP", "Copy", "" }, { "CUTCLIP", "Cut", "" } } } } }, ;
   { "Measure", { { "large", "MEASURE_MENU", "Measure", "measure_l", "", {  } } } } } }, ;
 { "Parametric", { ;
   { "Geometric", { { "small", "GCVISIBILITY", "Show/Hide", "", "", {  } } } }, ;
   { "Dimensional", { { "large", "DC_LINEAR_MENU", "Linear", "", "", {  } }, { "small", "DCVISIBILITY", "Show/Hide", "", "", {  } } } }, ;
   { "Manage", {  } } } }, ;
 { "Model", { ;
   { "Create", { { "large", "MODEL_PRIMITIVES", "Box", "", "", {  } }, { "large", "EXTRUDE", "Extrude", "", "", {  } }, { "large", "REVOLVE", "Revolve", "", "", {  } }, { "large", "LOFT", "Loft", "", "", {  } }, { "large", "SWEEP", "Sweep", "", "", {  } }, { "large", "PRESSPULL", "Presspull", "", "", {  } } } }, ;
   { "Boolean", { { "large", "UNION", "Union", "", "", {  } }, { "large", "SUBTRACT", "Subtract", "", "", {  } }, { "large", "INTERSECT", "Intersect", "", "", {  } } } }, ;
   { "Edges", { { "large", "FILLETEDGE", "Fillet Edge", "", "", {  } }, { "large", "CHAMFEREDGE", "Chamfer", "", "", {  } }, { "large", "SHELL", "Shell", "", "", {  } } } } } }, ;
 { "Insert", { ;
   { "Reference", { { "large", "XATTACH", "Attach XREF", "blocks_insert_l", "", {  } }, { "large", "UNDERLAY_ATTACH", "Attach Underlay", "", "", {  } }, { "large", "CLIP", "Clip", "xclip_l", "", {  } }, { "large", "ADJUST", "Adjust", "xadjust_l", "", {  } }, { "small", "UNDERLAYLAYERS", "UnderlayLayers", "underlay_layers_s", "", {  } }, { "small", "FRAMES_DROPDOWN", "", "", "", {  } }, { "small", "UOSNAP_DROPDOWN", "Snap to Underlays", "", "", {  } } } }, ;
   { "Block", { { "large", "BLOCKPALETTE", "BlockPalette", "blocks_insert_l", "", {  } }, { "small", "ATTEDIT_DROPDOWN", "Edit Attribute", "", "", {  } }, { "small", "ATTMODE_DROPDOWN", "", "", "", {  } } } }, ;
   { "Block Definition", { { "large", "BLOCK", "Create Block", "blocks_block_l", "", {  } }, { "large", "ATTMAN", "Manage", "attman_l", "", {  } }, { "large", "BEDIT", "Edit Block", "edit_block_l", "", {  } } } }, ;
   { "Import", { { "large", "OPEN", "Open", "import_obj_l", "@ABRIR", {  } }, { "large", "LANDXMLIMPORT", "LandXML", "landxml_l", "", {  } } } }, ;
   { "Content", { { "large", "CONTENTBROWSER", "ContentBrowser", "content_browser_l", "", {  } }, { "large", "ADCENTER", "DesignCenter", "design_center_l", "", {  } } } } } }, ;
 { "Annotate", { ;
   { "Text", { { "large", "ANNOTATE_TEXT", "Multiline Text", "", "", {  } }, { "small", "FIND", "Find", "find_s", "", {  } } } }, ;
   { "Dimensions", { { "large", "ANNOTATE_DIM", "Dimension", "", "", {  } } } }, ;
   { "Centerlines", { { "large", "CENTERMARK", "Center Mark", "line_l", "", {  } }, { "large", "CENTERLINE", "Center Line", "line_l", "", {  } } } }, ;
   { "Leaders", { { "large", "ANNOTATE_LEADER", "Multileader", "", "", {  } } } }, ;
   { "Tables", { { "large", "TABLE", "Table", "table_l", "", {  } } } }, ;
   { "Markup", { { "large", "WIPEOUT", "Wipeout", "wipeout_l", "", {  } }, { "large", "REVCLOUD", "Rev Cloud", "revcloud_l", "", {  } } } }, ;
   { "Annotation Scaling", { { "small", "ANNOTATION_CURRENT_SCALE", "Add Current Scale", "", "", {  } }, { "small", "SCALELISTEDIT", "Scale List", "scale_list_s", "", {  } }, { "small", "OBJECTSCALE", "Add/Delete Scales", "add_scale_s", "", {  } }, { "small", "ANNORESET", "Sync Scale Positions", "sync_s", "", {  } } } } } }, ;
 { "View", { ;
   { "Viewport Tools", { { "large", "UCSICON", "UCSIcon", "ucs_icon_l", "", {  } }, { "large", "NAVVCUBE", "ViewCube", "viewcube_l", "", {  } } } }, ;
   { "Navigate", { { "large", "ZOOM_EXT", "ZoomExtents", "zoom_ext_l", "ZOOM E", {  } }, { "small", "ZOOM_WINDOW", "Zoom Window", "zoom_window_s", "", {  } }, { "small", "ZOOM_IN", "Zoom In", "zoom_in_s", "@ZOOMIN", {  } }, { "small", "ZOOM_OUT", "Zoom Out", "zoom_out_s", "@ZOOMOUT", {  } }, { "small", "PAN", "Pan", "pan_s", "", {  } }, { "small", "3DORBIT", "3D Orbit", "orbit_s", "3D", {  } } } }, ;
   { "Model Viewports", { { "large", "VPORTS", "ViewportConfiguration", "vports_config_l", "", {  } }, { "small", "VPORTS_NAMED", "Named", "vports_named_s", "", {  } }, { "small", "VPJOIN", "Join", "vports_join_s", "", {  } }, { "small", "VPORTS_RESTORE", "Restore", "vports_restore_s", "", {  } } } }, ;
   { "Visual Style", { { "large", "VISUAL_STYLE", "Visual Style", "", "", {  } } } }, ;
   { "Projection", { { "large", "ORTHO", "Ortho", "ortho_l", "", {  } }, { "large", "PERSP", "Persp", "persp_l", "", {  } } } }, ;
   { "Preset", { { "small", "VIEW_TOP", "Top", "view_top_s", "VISTA SUP", {  } }, { "small", "VIEW_FRONT", "Front", "view_front_s", "VISTA FRONTAL", {  } }, { "small", "VIEW_RIGHT", "Right", "view_right_s", "VISTA DERECHA", {  } }, { "small", "VIEW_ISO", "Iso", "view_iso_s", "VISTA ISO", {  } } } }, ;
   { "Palettes", { { "large", "TOOLPALETTES", "ToolPalettes", "tool_palettes_l", "", {  } }, { "large", "PROPERTIES", "Properties", "properties_l", "", {  } }, { "large", "COUNTLIST", "Count", "data_extract_l", "", {  } }, { "large", "SHEETSET", "Sheet SetManager", "sheetset_l", "", {  } } } }, ;
   { "Interface", { { "large", "FILETAB", "FileTabs", "file_tabs_l", "", {  } }, { "large", "LAYOUTTAB", "LayoutTabs", "layout_tabs_l", "", {  } }, { "small", "HORIZONTAL", "TileHoriz.", "tile_horiz_s", "", {  } }, { "small", "VERTICAL", "TileVert.", "tile_vert_s", "", {  } }, { "small", "CASCADE", "Cascade", "cascade_s", "", {  } } } }, ;
   { "Plot", { { "small", "PAGESETUP", "Page Setup", "pagesetup_s", "", {  } } } } } }, ;
 { "Manage", { ;
   { "Customization", { { "large", "CUI", "UserInterface", "user_interface_l", "", {  } }, { "small", "TOOLPALETTES", "Tool Palettes", "tool_palettes_s", "", {  } }, { "small", "CUIIMPORT", "Import", "cui_import_s", "", {  } }, { "small", "CUIEXPORT", "Export", "cui_export_s", "", {  } } } }, ;
   { "Cleanup", { { "large", "FINDNONPURGEABLE", "Find Non-Purgeable Items", "find_nonpurgeable_l", "", {  } }, { "small", "PURGE", "Purge", "purge_s", "", {  } }, { "small", "AUDIT", "Audit", "audit_s", "", {  } } } }, ;
   { "Application", { { "large", "OPTIONS", "Options", "options_tool_l", "", {  } }, { "large", "ABOUT", "About", "about_l", "AYUDA", {  } } } } } }, ;
 { "Layout", { ;
   { "Viewport", { { "small", "MVIEW", "Viewport", "viewport_s", "", {  } } } }, ;
   { "Plot", { { "small", "PAGESETUP", "Page Setup", "pagesetup_s", "", {  } }, { "small", "PRINTALL", "Print All", "plot_s", "", {  } } } } } } }

STATIC FUNCTION Vwr_Width( aItems )
   LOCAL it, nW := 8, nSlot := 0
   FOR EACH it IN aItems
      IF it[ 1 ] == "large"
         nW += VWR_BW + 4
         nSlot := 0
      ELSE
         IF nSlot == 0 .OR. nSlot >= 3
            nW += VWR_SW + 4
            nSlot := 0
         ENDIF
         nSlot++
      ENDIF
   NEXT
RETURN Max( 70, nW )

STATIC FUNCTION Vwr_Menu( oS, aSub )
   LOCAL oPop, s
   MENU oPop POPUP
      FOR EACH s IN aSub
         Vwr_Item( oS, s[ 2 ], s[ 3 ] )
      NEXT
   ENDMENU
RETURN oPop

STATIC PROCEDURE Vwr_Item( oS, cText, cCmd )
   MENUITEM cText ACTION oS:Run( cCmd )
RETURN

/* un boton; funcion aparte para que cada cierre tenga su propio cCmd */
STATIC PROCEDURE Vwr_Btn( oGr, oS, it, nRow, nCol )
   LOCAL cCmd := it[ 5 ], cBmp := Vwi_File( it[ 4 ] ), cTip := it[ 3 ], oPop := NIL
   IF Len( it[ 6 ] ) > 0
      oPop := Vwr_Menu( oS, it[ 6 ] )
      cCmd := If( Empty( cCmd ), it[ 6 ][ 1 ][ 3 ], cCmd )
   ENDIF
   IF it[ 1 ] == "large"
      IF oPop != NIL
         @ nRow, nCol ADD BUTTON PROMPT it[ 3 ] SIZE VWR_BW, VWR_BH BITMAP cBmp ACTION oS:Run( cCmd ) OF oGr TOP SPLITPOPUP MENU oPop TOOLTIP cTip
      ELSE
         @ nRow, nCol ADD BUTTON PROMPT it[ 3 ] SIZE VWR_BW, VWR_BH BITMAP cBmp ACTION oS:Run( cCmd ) OF oGr TOP TOOLTIP cTip
      ENDIF
   ELSE
      IF oPop != NIL
         @ nRow, nCol ADD BUTTON PROMPT "" SIZE VWR_SW, VWR_SH BITMAP cBmp ACTION oS:Run( cCmd ) OF oGr SPLITPOPUP MENU oPop TOOLTIP cTip
      ELSE
         @ nRow, nCol ADD BUTTON PROMPT "" SIZE VWR_SW, VWR_SH BITMAP cBmp ACTION oS:Run( cCmd ) OF oGr TOOLTIP cTip
      ENDIF
   ENDIF
RETURN

/* Crea la cinta en oWnd; oS es el TViewer (metodo Run). Devuelve la barra. */
FUNCTION Vwr_Build( oWnd, oS )
   LOCAL aT := Vwr_Table(), t, g, it, oRb, oGr, nOpt := 0, nCol, nSlot
   DEFINE RIBBONBAR oRb OF oWnd PROMPT "Draw", "Parametric", "Model", "Insert", "Annotate", "View", "Manage", "Layout" ;
      HEIGHT VWR_HEIGHT COLOR VWR_PANE COLORBOX VWR_LINE, VWR_LINE COLORSEL VWR_ACCENT, VWR_ACCENT 2013
   FOR EACH t IN aT
      nOpt++
      FOR EACH g IN t[ 2 ]
         IF Len( g[ 2 ] ) == 0
            LOOP
         ENDIF
         ADD GROUP oGr RIBBON oRb TO OPTION nOpt PROMPT g[ 1 ] WIDTH Vwr_Width( g[ 2 ] )
         nCol := 4
         nSlot := 0
         FOR EACH it IN g[ 2 ]
            IF it[ 1 ] == "large"
               IF nSlot > 0
                  nCol += VWR_SW + 4
                  nSlot := 0
               ENDIF
               Vwr_Btn( oGr, oS, it, 3, nCol )
               nCol += VWR_BW + 4
            ELSE
               IF nSlot >= 3
                  nCol += VWR_SW + 4
                  nSlot := 0
               ENDIF
               Vwr_Btn( oGr, oS, it, 3 + nSlot * ( VWR_SH + 2 ), nCol )
               nSlot++
            ENDIF
         NEXT
      NEXT
   NEXT
RETURN oRb

FUNCTION Vwr_Height()
RETURN VWR_HEIGHT
