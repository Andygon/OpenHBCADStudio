/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/entities/ent_base.prg
   Rust origen: src/entities/mod.rs + common.rs + traits.rs + names.rs +
                object_data.rs + match_props.rs
   Clase base de entidad + factoría + registro de tipos.
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "FiveWin.ch"

//--- Clase base ----------------------------------------------------------------
CLASS TEntBase
   DATA nType      INIT 0
   DATA cHandle    INIT ""
   DATA cLayer     INIT "0"
   DATA nColor     INIT OHB_BYLAYER
   DATA cLtype     INIT "BYLAYER"
   DATA nLtscale   INIT 1.0
   DATA nLinewt    INIT -1
   DATA lErased    INIT .F.
   DATA nSpace     INIT OHB_SPACE_MODEL

   METHOD New( nType ) CONSTRUCTOR
   METHOD TypeName() INLINE OHB_EntTypeName( ::nType )
   METHOD Clone()
   METHOD Transform( aM ) VIRTUAL
   METHOD MoveBy( aFrom, aTo )
   METHOD BBox() VIRTUAL
   METHOD GripPoints() VIRTUAL
   METHOD Draw( hDC, oView ) VIRTUAL
   METHOD Props() VIRTUAL
   METHOD ToDxf( nHnd ) VIRTUAL
   METHOD HitTest( aPt, nTol, oView ) VIRTUAL
ENDCLASS

METHOD New( nType ) CLASS TEntBase
   hb_default( @nType, 0 )
   ::nType := nType
RETURN Self

METHOD Clone() CLASS TEntBase
   LOCAL o := __clsInst( ::ClassH )
   o:nType    := ::nType
   o:cHandle  := ::cHandle
   o:cLayer   := ::cLayer
   o:nColor   := ::nColor
   o:cLtype   := ::cLtype
   o:nLtscale := ::nLtscale
   o:nLinewt  := ::nLinewt
   o:lErased  := ::lErased
   o:nSpace   := ::nSpace
RETURN o

METHOD MoveBy( aFrom, aTo ) CLASS TEntBase
RETURN ::Transform( OC_MoveM( aTo[ 1 ] - aFrom[ 1 ], aTo[ 2 ] - aFrom[ 2 ] ) )

//--- Nombres de tipo (Rust: entities/names.rs) ----------------------------------
FUNCTION OHB_EntTypeName( nType )
   LOCAL cName := "DESCONOCIDA"
   DO CASE
   CASE nType == OHB_ENT_LINE       ; cName := "LINEA"
   CASE nType == OHB_ENT_POINT      ; cName := "PUNTO"
   CASE nType == OHB_ENT_CIRCLE     ; cName := "CIRCULO"
   CASE nType == OHB_ENT_ARC        ; cName := "ARCO"
   CASE nType == OHB_ENT_ELLIPSE    ; cName := "ELIPSE"
   CASE nType == OHB_ENT_LWPOLYLINE ; cName := "POLILINEA"
   CASE nType == OHB_ENT_POLYLINE   ; cName := "POLILINEA3D"
   CASE nType == OHB_ENT_SPLINE     ; cName := "SPLINE"
   CASE nType == OHB_ENT_TEXT       ; cName := "TEXTO"
   CASE nType == OHB_ENT_MTEXT      ; cName := "TEXTOM"
   CASE nType == OHB_ENT_HATCH      ; cName := "SOMBREADO"
   CASE nType == OHB_ENT_INSERT     ; cName := "INSERT"
   CASE nType == OHB_ENT_DIM        ; cName := "COTA"
   CASE nType == OHB_ENT_LEADER     ; cName := "DIRECTRIZ"
   CASE nType == OHB_ENT_MLEADER    ; cName := "DIRECTRIZM"
   CASE nType == OHB_ENT_TABLE      ; cName := "TABLA"
   CASE nType == OHB_ENT_SOLID      ; cName := "SOLIDO"
   CASE nType == OHB_ENT_TRACE      ; cName := "TRAZO"
   CASE nType == OHB_ENT_SHAPE      ; cName := "FORMA"
   CASE nType == OHB_ENT_RAY        ; cName := "RAYO"
   CASE nType == OHB_ENT_XLINE      ; cName := "LINEAX"
   CASE nType == OHB_ENT_VIEWPORT   ; cName := "VENTANA"
   CASE nType == OHB_ENT_RASTER     ; cName := "IMAGEN"
   CASE nType == OHB_ENT_UNDERLAY   ; cName := "SUBYACENTE"
   CASE nType == OHB_ENT_MLINE      ; cName := "LINEAM"
   CASE nType == OHB_ENT_WIPEOUT    ; cName := "BORRADO"
   CASE nType == OHB_ENT_SOLID3D    ; cName := "SOLIDO3D"
   CASE nType == OHB_ENT_BODY       ; cName := "CUERPO"
   CASE nType == OHB_ENT_REGION     ; cName := "REGION"
   CASE nType == OHB_ENT_TOLERANCE  ; cName := "TOLERANCIA"
   CASE nType == OHB_ENT_ATTDEF     ; cName := "ATRIBDEF"
   CASE nType == OHB_ENT_ATTRIB     ; cName := "ATRIBUTO"
   ENDCASE
RETURN cName

//--- Factoría (Rust: codec EntityType -> entities) -------------------------------
FUNCTION OHB_EntCreate( nType )
   LOCAL o := NIL
   DO CASE
   CASE nType == OHB_ENT_LINE       ; o := TEntLine():New()
   CASE nType == OHB_ENT_POINT      ; o := TEntPoint():New()
   CASE nType == OHB_ENT_CIRCLE     ; o := TEntCircle():New()
   CASE nType == OHB_ENT_ARC        ; o := TEntArc():New()
   CASE nType == OHB_ENT_ELLIPSE    ; o := TEntEllipse():New()
   CASE nType == OHB_ENT_LWPOLYLINE ; o := TEntPoly():New()
   CASE nType == OHB_ENT_POLYLINE   ; o := TEntPoly():New()
   CASE nType == OHB_ENT_SPLINE     ; o := TEntSpline():New()
   CASE nType == OHB_ENT_TEXT       ; o := TEntText():New()
   CASE nType == OHB_ENT_MTEXT      ; o := TEntMText():New()
   CASE nType == OHB_ENT_HATCH      ; o := TEntHatch():New()
   CASE nType == OHB_ENT_INSERT     ; o := TEntInsert():New()
   CASE nType == OHB_ENT_DIM        ; o := TEntDim():New()
   CASE nType == OHB_ENT_RAY        ; o := TEntRay():New()
   CASE nType == OHB_ENT_XLINE      ; o := TEntRay():New()
   CASE nType == OHB_ENT_SOLID      ; o := TEntSolid():New()
   CASE nType == OHB_ENT_TRACE      ; o := TEntSolid():New()
   CASE nType == OHB_ENT_RASTER     ; o := TEntRaster():New()
   CASE nType == OHB_ENT_MLINE      ; o := TEntMLine():New()
   CASE nType == OHB_ENT_WIPEOUT    ; o := TEntWipeout():New()
   CASE nType == OHB_ENT_LEADER     ; o := TEntLeader():New()
   CASE nType == OHB_ENT_TOLERANCE  ; o := TEntTolerance():New()
   CASE nType == OHB_ENT_ATTDEF     ; o := TEntAttDef():New()
   CASE nType == OHB_ENT_ATTRIB     ; o := TEntAttrib():New()
   CASE nType == OHB_ENT_TABLE      ; o := TEntTable():New()
   ENDCASE
RETURN o

//--- Igualar propiedades (Rust: entities/match_props.rs, modify match_prop) -----
PROCEDURE OHB_MatchProps( oDst, oSrc )
   oDst:cLayer   := oSrc:cLayer
   oDst:nColor   := oSrc:nColor
   oDst:cLtype   := oSrc:cLtype
   oDst:nLtscale := oSrc:nLtscale
   oDst:nLinewt  := oSrc:nLinewt
RETURN

//--- Color efectivo --------------------------------------------------------------
FUNCTION OHB_EffColor( oEnt, oDoc )
   LOCAL oLay
   IF oEnt:nColor != OHB_BYLAYER
      RETURN oEnt:nColor
   ENDIF
   oLay := oDoc:Layer( oEnt:cLayer )
   IF oLay != NIL
      RETURN oLay:nColor
   ENDIF
RETURN OHB_WHITE
