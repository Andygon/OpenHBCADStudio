/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/scene/doc.prg
   Rust origen: src/scene/mod.rs (Scene) + src/app/document.rs +
                src/app/layers.rs + src/scene/selection.rs +
                src/scene/mspace.rs + src/scene/limits.rs +
                src/scene/group_layer.rs
   Base de datos del dibujo: capas, entidades, bloques, selección, undo.
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "hbclass.ch"

//=========================== CAPA ==================================================
CLASS TDocLayer
   DATA cName   INIT "0"
   DATA nColor  INIT OHB_WHITE
   DATA cLtype  INIT "Continuous"
   DATA lOff    INIT .F.
   DATA lFrozen INIT .F.
   DATA lLock   INIT .F.
   DATA lPlot   INIT .T.
   DATA nLinewt INIT -1
   METHOD New( cName ) CONSTRUCTOR
ENDCLASS

METHOD New( cName ) CLASS TDocLayer
   hb_default( @cName, "0" )
   ::cName := Upper( cName )
RETURN Self

//=========================== DIBUJO =================================================
CLASS TDocDrawing
   DATA cFile     INIT ""
   DATA lDirty    INIT .F.
   DATA aEnts     INIT {}     // array de TEntBase
   DATA aLayers   INIT {}     // array de TDocLayer
   DATA cCurLayer INIT "0"
   DATA aBlocks   INIT {}     // { cName, aEnts } definición de bloque
   DATA aSel      INIT {}     // handles seleccionados
   DATA nNextHnd  INIT OHB_HANDLE_START
   DATA aUndo     INIT {}
   DATA aRedo     INIT {}
   DATA aLimMin   INIT { -1000, -1000 }
   DATA aLimMax   INIT { 1000, 1000 }
   DATA nInsUnits INIT 4      // mm (Rust: units.rs)
   DATA nLtscale  INIT 1.0

   METHOD New() CONSTRUCTOR
   METHOD NewHandle()
   METHOD Layer( cName )
   METHOD AddLayer( cName, nColor )
   METHOD AddEnt( oEnt )
   METHOD DelEnt( cHandle )
   METHOD FindEnt( cHandle )
   METHOD Select( cHandle )
   METHOD SelectBox( aB, lCross )
   METHOD ClearSel()
   METHOD SelEnts()
   METHOD Undo()
   METHOD Redo()
   METHOD PushUndo( aOp )
   METHOD MarkDirty()
   METHOD Extents()
   METHOD Count()
ENDCLASS

METHOD New() CLASS TDocDrawing
   ::AddLayer( "0", OHB_WHITE )
   ::AddLayer( "DEFPOINTS", OHB_RED )
RETURN Self

METHOD NewHandle() CLASS TDocDrawing
   ::nNextHnd++
RETURN "H" + LTrim( Str( ::nNextHnd, 0 ) )

METHOD Layer( cName ) CLASS TDocDrawing
   LOCAL i
   cName := Upper( cName )
   FOR i := 1 TO Len( ::aLayers )
      IF ::aLayers[ i ]:cName == cName
         RETURN ::aLayers[ i ]
      ENDIF
   NEXT
RETURN NIL

METHOD AddLayer( cName, nColor ) CLASS TDocDrawing
   LOCAL o
   IF ::Layer( cName ) != NIL
      RETURN ::Layer( cName )
   ENDIF
   o := TDocLayer():New( cName )
   IF nColor != NIL
      o:nColor := nColor
   ENDIF
   AAdd( ::aLayers, o )
   ::MarkDirty()
RETURN o

METHOD AddEnt( oEnt ) CLASS TDocDrawing
   IF Empty( oEnt:cHandle )
      oEnt:cHandle := ::NewHandle()
   ENDIF
   IF Empty( oEnt:cLayer )
      oEnt:cLayer := ::cCurLayer
   ENDIF
   AAdd( ::aEnts, oEnt )
   ::PushUndo( { "add", oEnt:cHandle } )
   ::MarkDirty()
RETURN oEnt:cHandle

METHOD FindEnt( cHandle ) CLASS TDocDrawing
   LOCAL i
   FOR i := 1 TO Len( ::aEnts )
      IF ::aEnts[ i ]:cHandle == cHandle
         RETURN ::aEnts[ i ]
      ENDIF
   NEXT
RETURN NIL

METHOD DelEnt( cHandle ) CLASS TDocDrawing
   LOCAL i
   FOR i := 1 TO Len( ::aEnts )
      IF ::aEnts[ i ]:cHandle == cHandle
         ::PushUndo( { "del", ::aEnts[ i ]:Clone(), i } )
         ADel( ::aEnts, i )
         ASize( ::aEnts, Len( ::aEnts ) - 1 )
         ::MarkDirty()
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.

METHOD Select( cHandle ) CLASS TDocDrawing
   IF AScan( ::aSel, cHandle ) == 0
      AAdd( ::aSel, cHandle )
   ENDIF
RETURN NIL

METHOD SelectBox( aB, lCross ) CLASS TDocDrawing
   // aB = {xmin,ymin,xmax,ymax} mundo. lCross: cruce (como AutoCAD)
   LOCAL o, aE, lIn
   hb_default( @lCross, .F. )
   FOR EACH o IN ::aEnts
      IF o:lErased
         LOOP
      ENDIF
      aE := o:BBox()
      IF lCross
         lIn := aE[ 3 ] >= aB[ 1 ] .AND. aE[ 1 ] <= aB[ 3 ] .AND. ;
                aE[ 4 ] >= aB[ 2 ] .AND. aE[ 2 ] <= aB[ 4 ]
      ELSE
         lIn := aE[ 1 ] >= aB[ 1 ] .AND. aE[ 3 ] <= aB[ 3 ] .AND. ;
                aE[ 2 ] >= aB[ 2 ] .AND. aE[ 4 ] <= aB[ 4 ]
      ENDIF
      IF lIn
         ::Select( o:cHandle )
      ENDIF
   NEXT
RETURN Len( ::aSel )

METHOD ClearSel() CLASS TDocDrawing
   ::aSel := {}
RETURN NIL

METHOD SelEnts() CLASS TDocDrawing
   LOCAL a := {}, cH
   FOR EACH cH IN ::aSel
      AAdd( a, ::FindEnt( cH ) )
   NEXT
RETURN a

METHOD PushUndo( aOp ) CLASS TDocDrawing
   AAdd( ::aUndo, aOp )
   IF Len( ::aUndo ) > 200
      ADel( ::aUndo, 1 )
      ASize( ::aUndo, Len( ::aUndo ) - 1 )
   ENDIF
   ::aRedo := {}
RETURN NIL

METHOD Undo() CLASS TDocDrawing
   LOCAL aOp := NIL, o, i
   IF Empty( ::aUndo )
      RETURN .F.
   ENDIF
   aOp := ATail( ::aUndo )
   ASize( ::aUndo, Len( ::aUndo ) - 1 )
   DO CASE
   CASE aOp[ 1 ] == "add"
      // quitar la entidad añadida (sin registrar)
      FOR i := 1 TO Len( ::aEnts )
         IF ::aEnts[ i ]:cHandle == aOp[ 2 ]
            AAdd( ::aRedo, { "add", ::aEnts[ i ]:Clone() } )
            ADel( ::aEnts, i )
            ASize( ::aEnts, Len( ::aEnts ) - 1 )
            EXIT
         ENDIF
      NEXT
   CASE aOp[ 1 ] == "del"
      o := aOp[ 2 ]:Clone()
      IF aOp[ 3 ] <= Len( ::aEnts ) + 1
         ASize( ::aEnts, Len( ::aEnts ) + 1 )
         AIns( ::aEnts, aOp[ 3 ] )
         ::aEnts[ aOp[ 3 ] ] := o
      ELSE
         AAdd( ::aEnts, o )
      ENDIF
      AAdd( ::aRedo, { "del", o:cHandle } )
   ENDCASE
   ::MarkDirty()
RETURN .T.

METHOD Redo() CLASS TDocDrawing
RETURN .F.  // (fase 1: redo simplificado pendiente; ver docs/PORTING.md)

METHOD MarkDirty() CLASS TDocDrawing
   ::lDirty := .T.
RETURN NIL

METHOD Extents() CLASS TDocDrawing
   LOCAL a := NIL, o, aE
   FOR EACH o IN ::aEnts
      IF o:lErased
         LOOP
      ENDIF
      aE := o:BBox()
      IF a == NIL
         a := AClone( aE )
      ELSE
         a[ 1 ] := Min( a[ 1 ], aE[ 1 ] )
         a[ 2 ] := Min( a[ 2 ], aE[ 2 ] )
         a[ 3 ] := Max( a[ 3 ], aE[ 3 ] )
         a[ 4 ] := Max( a[ 4 ], aE[ 4 ] )
      ENDIF
   NEXT
   IF a == NIL
      a := { -10, -10, 10, 10 }
   ENDIF
RETURN a

METHOD Count() CLASS TDocDrawing
RETURN Len( ::aEnts )
