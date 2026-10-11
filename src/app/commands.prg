/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/app/commands.prg
   Rust origen: src/command.rs (CadCommand/CmdResult) +
                src/modules/registry.rs + src/modules/mod.rs +
                src/app/command_driver/* + src/app/alias.rs +
                src/app/shortcuts.rs
   Registro de comandos bilingüe (ES/EN) + despachador + clase base.
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "hbclass.ch"

STATIC s_aReg := NIL   // { cNombreES, cAliasEN, bFactory, cGrupo, cAyuda }

//--- Clase base de comando interactivo (Rust: trait CadCommand) ---------------
CLASS TCmdBase
   DATA oView
   DATA oDoc
   DATA cName    INIT ""
   DATA nStep    INIT 0
   DATA aPts     INIT {}
   DATA lDone    INIT .F.
   METHOD New( cName ) CONSTRUCTOR
   METHOD Start( oView )
   METHOD OnPick( aPt, nFlags ) VIRTUAL
   METHOD OnText( cText ) VIRTUAL
   METHOD OnNum( nVal ) VIRTUAL
   METHOD Preview( hDC, oView ) VIRTUAL
   METHOD OnHover( aPtW, oView ) VIRTUAL
   METHOD Prompt()
   METHOD Finish()
   METHOD Cancel()
ENDCLASS

METHOD New( cName ) CLASS TCmdBase
   ::cName := cName
RETURN Self

METHOD Start( oView ) CLASS TCmdBase
   ::oView := oView
   ::oDoc := oView:oDoc
   oView:oCmd := Self
   oView:bOnPick := { | aPt, nF | ::OnPick( aPt, nF ) }
   ::nStep := 0
   ::aPts := {}
   ::lDone := .F.
   OHB_CmdPrompt( ::Prompt() )
RETURN Self

METHOD Prompt() CLASS TCmdBase
RETURN ::cName + ":"

METHOD Finish() CLASS TCmdBase
   ::lDone := .T.
   ::oView:oCmd := NIL
   ::oView:bOnPick := NIL
   ::oView:Refresh()
   OHB_CmdPrompt( "*" + ::cName + " terminado. (" + ;
      LTrim( Str( ::oDoc:Count(), 0 ) ) + " entidades)" )
   OHB_PropRefresh()
RETURN OHB_CMD_OK

METHOD Cancel() CLASS TCmdBase
   ::lDone := .T.
   ::oView:oCmd := NIL
   ::oView:bOnPick := NIL
   ::oView:Refresh()
   OHB_CmdPrompt( "*" + ::cName + " cancelado." )
RETURN OHB_CMD_CANCEL

//--- Registro ------------------------------------------------------------------
STATIC PROCEDURE reg_init()
   IF s_aReg != NIL
      RETURN
   ENDIF
   s_aReg := {}
   // dibujo (Rust: modules/draw/draw/*)
   AAdd( s_aReg, { "LINEA",    "LINE",    { || TCmdLine2():New() },    "DIBUJO", "Segmentos" } )
   AAdd( s_aReg, { "CIRCULO",  "CIRCLE",  { || TCmdCircle():New() },   "DIBUJO", "Centro+radio" } )
   AAdd( s_aReg, { "ARCO",     "ARC",     { || TCmdArc():New() },      "DIBUJO", "3 puntos" } )
   AAdd( s_aReg, { "POL",      "PLINE",   { || TCmdPline():New() },    "DIBUJO", "Polilínea" } )
   AAdd( s_aReg, { "PUNTO",    "POINT",   { || TCmdPoint():New() },    "DIBUJO", "Punto" } )
   AAdd( s_aReg, { "TEXTO",    "TEXT",    { || TCmdText():New() },     "DIBUJO", "Texto" } )
   AAdd( s_aReg, { "RAYO",     "RAY",     { || TCmdRay():New() },      "DIBUJO", "Rayo" } )
   AAdd( s_aReg, { "LINEAX",   "XLINE",   { || TCmdXline():New() },    "DIBUJO", "Línea aux." } )
   AAdd( s_aReg, { "ELIPSE",   "ELLIPSE", { || TCmdEllipse():New() },  "DIBUJO", "Elipse" } )
   AAdd( s_aReg, { "SOMBREADO","HATCH",   { || TCmdHatch():New() },    "DIBUJO", "Sombreado" } )
   AAdd( s_aReg, { "COTLIN",   "DIMLIN",  { || TCmdDimLin():New() },   "COTA",   "Cota lineal" } )
   // modificación (Rust: modules/draw/modify/*)
   AAdd( s_aReg, { "BORRA",    "ERASE",   { || TCmdErase():New() },    "MODIF", "Borra selección" } )
   AAdd( s_aReg, { "MUEVE",    "MOVE",    { || TCmdMove():New() },     "MODIF", "Mueve selección" } )
   AAdd( s_aReg, { "COPIA",    "COPY",    { || TCmdCopy():New() },     "MODIF", "Copia selección" } )
   AAdd( s_aReg, { "GIRA",     "ROTATE",  { || TCmdRotate():New() },   "MODIF", "Gira selección" } )
   AAdd( s_aReg, { "ESCALA",   "SCALE",   { || TCmdScale():New() },    "MODIF", "Escala selección" } )
   AAdd( s_aReg, { "SIMETRIA", "MIRROR",  { || TCmdMirror():New() },   "MODIF", "Simetría" } )
   AAdd( s_aReg, { "DESFASE",  "OFFSET",  { || TCmdOffset():New() },   "MODIF", "Paralela" } )
   AAdd( s_aReg, { "EMPALME",  "FILLET",  { || TCmdFillet():New() },   "MODIF", "Empalme" } )
   AAdd( s_aReg, { "RECORTA",  "TRIM",    { || TCmdTrim():New() },     "MODIF", "Recorta" } )
   AAdd( s_aReg, { "MATRIZ",   "ARRAY",   { || TCmdArray():New() },    "MODIF", "Matriz" } )
   AAdd( s_aReg, { "IGUALA",   "MATCHPROP",{|| TCmdMatch():New() },    "MODIF", "Iguala prop." } )
   // consulta (Rust: modules/draw/inquiry/*)
   AAdd( s_aReg, { "DIST",     "DIST",    { || TCmdDist():New() },     "CONSULTA", "Distancia" } )
   AAdd( s_aReg, { "AREA",     "AREA",    { || TCmdArea():New() },     "CONSULTA", "Área" } )
   AAdd( s_aReg, { "ID",       "ID",      { || TCmdId():New() },       "CONSULTA", "Coords punto" } )
   // capas / vista (Rust: modules/draw/layers/*, modules/view/*)
   AAdd( s_aReg, { "CAPA",     "LAYER",   { || TCmdLayer():New() },    "CAPAS", "Gestor capas" } )
   AAdd( s_aReg, { "ZOOM",     "ZOOM",    { || TCmdZoom():New() },     "VISTA", "Zoom" } )
   AAdd( s_aReg, { "ENCUADRE", "PAN",     { || TCmdPan():New() },      "VISTA", "Encuadre" } )
   // archivo (Rust: io/*, app/recent.rs)
   AAdd( s_aReg, { "ABRE",     "OPEN",    { || TCmdOpen():New() },     "ARCHIVO", "Abre DXF" } )
   AAdd( s_aReg, { "GUARDA",   "SAVE",    { || TCmdSave():New() },     "ARCHIVO", "Guarda DXF" } )
   AAdd( s_aReg, { "NUEVO",    "NEW",     { || TCmdNew():New() },      "ARCHIVO", "Dibujo nuevo" } )
   AAdd( s_aReg, { "DESHACER", "UNDO",    { || TCmdUndo():New() },     "ARCHIVO", "Deshacer" } )
RETURN

FUNCTION OHB_CmdList()
   reg_init()
RETURN AClone( s_aReg )

FUNCTION OHB_CmdFind( cName )
   LOCAL i
   reg_init()
   cName := Upper( AllTrim( cName ) )
   FOR i := 1 TO Len( s_aReg )
      IF s_aReg[ i ][ 1 ] == cName .OR. s_aReg[ i ][ 2 ] == cName
         RETURN s_aReg[ i ]
      ENDIF
   NEXT
RETURN NIL

// cName o alias, oMain = ventana principal (para ABRE/GUARDA/NUEVO/CAPA)
FUNCTION OHB_RunCmd( cName, oView, oMain )
   LOCAL aR := OHB_CmdFind( cName ), oCmd
   IF aR == NIL
      OHB_CmdPrompt( "Comando desconocido: " + cName )
      RETURN NIL
   ENDIF
   IF oView:oCmd != NIL
      oView:oCmd:Cancel()
   ENDIF
   oCmd := Eval( aR[ 3 ] )
   IF __objHasData( oCmd, "OMAIN" )
      oCmd:oMain := oMain
   ENDIF
   oCmd:Start( oView )
RETURN oCmd
