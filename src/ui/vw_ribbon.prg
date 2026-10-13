/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/ui/vw_ribbon.prg
   Fase 2 / B8b: cinta (ribbon) con TRibbonBar de FiveWin 26.03.
   Origen Rust: src/ui/ribbon (carpeta) y los mod.rs de src/modules (pestanas = modulos
   Draw/Insert/Annotate/View/Manage/Layout/Parametric/Model; grupos y
   botones). Cada boton ejecuta la misma linea de comandos del visor.
   Los botones sin comando todavia portado muestran "no portado aun".
   Solo se valida compilando y enlazando; la GUI no se ejecuta en Wine.
----------------------------------------------------------------------------*/
#include "FiveWin.ch"
#include "Ribbon.ch"

#define VWR_HEIGHT  145
#define VWR_BW      62
#define VWR_BH      72
/* tema oscuro del Rust (Oxocarbon), BGR: panel #262626, linea #393939, acento #00B4FF */
#define VWR_PANE    2500134
#define VWR_LINE    3750201
#define VWR_ACCENT  16757760

/* Tabla: { pestana, { { grupo, { { texto, comando }, ... } }, ... } }.
   Comando vacio = pendiente de portar. Prefijo @ = accion de la ventana. */
STATIC FUNCTION Vwr_Table()
RETURN { ;
 { "Inicio", { ;
   { "Dibujo", { { "Linea", "LINEA" }, { "Circulo", "CIRCULO" }, { "Arco", "ARCO" }, { "Polilinea", "PLINE" }, { "Punto", "PUNTO" } } }, ;
   { "Modificar", { { "Mover", "MOVER" }, { "Copiar", "COPIAR" }, { "Borrar", "BORRAR" }, { "Deshacer", "DESHACER" } } }, ;
   { "Capas", { { "Capas", "CAPAS" }, { "Capa actual", "CAPA" } } }, ;
   { "Seleccion", { { "Todo", "SELTODO" }, { "Quitar", "DESELECCIONAR" } } }, ;
   { "Archivo", { { "Abrir", "@ABRIR" }, { "Guardar", "GUARDAR" }, { "Guardar como", "@GUARDARCOMO" } } }, ;
   { "Anotacion", { { "Texto", "" }, { "Cotas", "" }, { "Directriz", "" } } } } }, ;
 { "Insertar", { ;
   { "Bloque", { { "Insertar", "" }, { "Crear", "" }, { "Editar", "" } } }, ;
   { "Referencia", { { "Adjuntar", "" }, { "PDF", "" } } }, ;
   { "Importar", { { "DXF", "@ABRIR" } } } } }, ;
 { "Anotar", { ;
   { "Texto", { { "Texto", "" }, { "Buscar", "" } } }, ;
   { "Cotas", { { "Lineal", "" }, { "Alineada", "" }, { "Angular", "" }, { "Radio", "" } } }, ;
   { "Directrices", { { "Directriz", "" }, { "Multidirectriz", "" } } }, ;
   { "Tablas", { { "Tabla", "" } } } } }, ;
 { "Vista", { ;
   { "Navegar", { { "Zoom ext.", "ZOOM E" }, { "Acercar", "@ZOOMIN" }, { "Alejar", "@ZOOMOUT" }, { "Regenerar", "REGEN" } } }, ;
   { "Vistas", { { "Planta", "VISTA SUP" }, { "Frontal", "VISTA FRONTAL" }, { "Posterior", "VISTA POSTERIOR" }, { "Derecha", "VISTA DERECHA" }, { "Izquierda", "VISTA IZQUIERDA" } } }, ;
   { "Isometricas", { { "ISO SO", "VISTA ISO-SO" }, { "ISO SE", "VISTA ISO-SE" }, { "ISO NE", "VISTA ISO-NE" }, { "ISO NO", "VISTA ISO-NO" }, { "3D", "3D" } } }, ;
   { "Ayudas", { { "Snap", "SNAP" }, { "Comandos", "AYUDA" } } } } }, ;
 { "Gestionar", { ;
   { "Limpieza", { { "Purgar", "" }, { "Auditar", "" } } }, ;
   { "Aplicacion", { { "Comandos", "AYUDA" }, { "Salir", "@SALIR" } } } } }, ;
 { "Layout", { ;
   { "Viewport", { { "Nuevo", "" }, { "Capas VP", "" } } }, ;
   { "Plot", { { "PDF", "" } } } } }, ;
 { "Parametrico", { ;
   { "Geometrico", { { "Coincidente", "" }, { "Horizontal", "" }, { "Vertical", "" } } }, ;
   { "Dimensional", { { "Lineal", "" } } } } }, ;
 { "Modelo", { ;
   { "Crear", { { "Caja", "" }, { "Cilindro", "" } } }, ;
   { "Editar", { { "Union", "" }, { "Seccion", "" } } } } } }

/* Crea la cinta en oWnd; oS es el TViewer (metodo Run). Devuelve la barra. */
FUNCTION Vwr_Build( oWnd, oS )
   LOCAL aT := Vwr_Table(), aTabs := {}, t, g, b, oRb, oGr, nOpt := 0, nCol, cC
   FOR EACH t IN aT
      AAdd( aTabs, t[ 1 ] )
   NEXT
   DEFINE RIBBONBAR oRb OF oWnd PROMPT "Inicio", "Insertar", "Anotar", "Vista", "Gestionar", "Layout", "Parametrico", "Modelo" ;
      HEIGHT VWR_HEIGHT COLOR VWR_PANE COLORBOX VWR_LINE, VWR_LINE COLORSEL VWR_ACCENT, VWR_ACCENT 2013
   FOR EACH t IN aT
      nOpt++
      FOR EACH g IN t[ 2 ]
         ADD GROUP oGr RIBBON oRb TO OPTION nOpt PROMPT g[ 1 ] WIDTH Max( 90, Len( g[ 2 ] ) * ( VWR_BW + 4 ) + 12 )
         nCol := 4
         FOR EACH b IN g[ 2 ]
            cC := b[ 2 ]
            @ 4, nCol ADD BUTTON PROMPT b[ 1 ] SIZE VWR_BW, VWR_BH ACTION oS:Run( cC ) OF oGr TOP TOOLTIP b[ 1 ]
            nCol += VWR_BW + 4
         NEXT
      NEXT
   NEXT
RETURN oRb

FUNCTION Vwr_Height()
RETURN VWR_HEIGHT
