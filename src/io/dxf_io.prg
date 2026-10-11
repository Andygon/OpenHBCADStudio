/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/io/dxf_io.prg
   Rust origen: opencadcodec (lectura DWG/DXF) + src/io/mod.rs +
                src/io/thumbnail.rs (vista previa: aqu?? BMP v??a FiveWin) +
                src/scene/convert/*.rs (conversi??n: aqu?? DXF<->entidades).
   Lector/escritor DXF ASCII R12/R2000. R??pido: escaneo C (OC_DXFSCAN).
----------------------------------------------------------------------------*/
#include "ohbcad.ch"

STATIC s_nHnd := 0

//--- Escritura ---------------------------------------------------------------
FUNCTION OC_DxfNum( n )
   LOCAL c := AllTrim( Str( n, 24, 8 ) )
   DO WHILE Right( c, 1 ) == "0" .AND. "." $ c
      c := Left( c, Len( c ) - 1 )
   ENDDO
   IF Right( c, 1 ) == "."
      c := Left( c, Len( c ) - 1 )
   ENDIF
   IF c == "-0"
      c := "0"
   ENDIF
RETURN c

STATIC PROCEDURE dxf_pair( h, nCode, xVal )
   LOCAL cV
   DO CASE
   CASE ValType( xVal ) == "N" ; cV := OC_DxfNum( xVal )
   CASE ValType( xVal ) == "C" ; cV := xVal
   OTHERWISE                   ; cV := ""
   ENDCASE
   FWrite( h, PadL( LTrim( Str( nCode, 0 ) ), 3 ) + hb_eol() + cV + hb_eol() )
RETURN

FUNCTION OC_DxfSave( oDoc, cFile )
   LOCAL h, oL, oE, aP, i, j
   h := FCreate( cFile )
   IF h == -1
      RETURN .F.
   ENDIF
   // HEADER
   dxf_pair( h, 0, "SECTION" )
   dxf_pair( h, 2, "HEADER" )
   dxf_pair( h, 9, "$ACADVER" )
   dxf_pair( h, 1, "AC1009" )
   dxf_pair( h, 9, "$INSUNITS" )
   dxf_pair( h, 70, oDoc:nInsUnits )
   dxf_pair( h, 9, "$LTSCALE" )
   dxf_pair( h, 40, oDoc:nLtscale )
   dxf_pair( h, 0, "ENDSEC" )
   // TABLES: LTYPE m??nima + LAYER
   dxf_pair( h, 0, "SECTION" )
   dxf_pair( h, 2, "TABLES" )
   dxf_pair( h, 0, "TABLE" )
   dxf_pair( h, 2, "LTYPE" )
   dxf_pair( h, 70, 1 )
   dxf_pair( h, 0, "LTYPE" )
   dxf_pair( h, 2, "Continuous" )
   dxf_pair( h, 70, 0 )
   dxf_pair( h, 3, "Solid line" )
   dxf_pair( h, 72, 65 )
   dxf_pair( h, 73, 0 )
   dxf_pair( h, 40, 0.0 )
   dxf_pair( h, 0, "ENDTAB" )
   dxf_pair( h, 0, "TABLE" )
   dxf_pair( h, 2, "LAYER" )
   dxf_pair( h, 70, Len( oDoc:aLayers ) )
   FOR EACH oL IN oDoc:aLayers
      dxf_pair( h, 0, "LAYER" )
      dxf_pair( h, 2, oL:cName )
      dxf_pair( h, 70, 0 )
      dxf_pair( h, 62, oL:nColor )
      dxf_pair( h, 6, oL:cLtype )
   NEXT
   dxf_pair( h, 0, "ENDTAB" )
   dxf_pair( h, 0, "ENDSEC" )
   // BLOCKS vac??a
   dxf_pair( h, 0, "SECTION" )
   dxf_pair( h, 2, "BLOCKS" )
   dxf_pair( h, 0, "ENDSEC" )
   // ENTITIES
   dxf_pair( h, 0, "SECTION" )
   dxf_pair( h, 2, "ENTITIES" )
   s_nHnd := 0
   FOR EACH oE IN oDoc:aEnts
      IF oE:lErased
         LOOP
      ENDIF
      s_nHnd++
      aP := oE:ToDxf( s_nHnd )
      IF aP != NIL
         FOR i := 1 TO Len( aP )
            IF aP[ i ] != NIL
               dxf_pair( h, aP[ i ][ 1 ], aP[ i ][ 2 ] )
            ENDIF
         NEXT
      ENDIF
   NEXT
   dxf_pair( h, 0, "ENDSEC" )
   dxf_pair( h, 0, "EOF" )
   FClose( h )
   oDoc:cFile := cFile
   oDoc:lDirty := .F.
RETURN .T.

//--- Lectura ------------------------------------------------------------------
FUNCTION OC_DxfLoad( cFile )
   LOCAL aPairs := OCX_DXFSCAN( cFile )
   LOCAL oDoc := TDocDrawing():New()
   LOCAL i := 1, n, cSec := "", cEnt := ""
   LOCAL aCur, aVtx, cLayer := "0"
   IF aPairs == NIL
      RETURN NIL
   ENDIF
   n := Len( aPairs )
   oDoc:cFile := cFile
   DO WHILE i <= n
      IF aPairs[ i ][ 1 ] == 0
         cEnt := Upper( AllTrim( aPairs[ i ][ 2 ] ) )
         DO CASE
         CASE cEnt == "SECTION"
            i++
            IF i <= n .AND. aPairs[ i ][ 1 ] == 2
               cSec := Upper( AllTrim( aPairs[ i ][ 2 ] ) )
            ENDIF
         CASE cEnt == "ENDSEC" .OR. cEnt == "EOF"
            cSec := ""
         CASE cSec == "ENTITIES" .AND. Left( cEnt, 4 ) != "SEQE"
            aCur := dxf_read_ent( aPairs, @i, cEnt )
            IF aCur != NIL
               oDoc:AddEnt( aCur )
               // AddEnt registra undo: limpiar (carga no es operable)
               ASize( oDoc:aUndo, 0 )
            ENDIF
            LOOP
         CASE cSec == "TABLES" .AND. cEnt == "LAYER"
            cLayer := dxf_read_layer( aPairs, @i, oDoc )
            LOOP
         ENDCASE
      ELSEIF cSec == "HEADER" .AND. aPairs[ i ][ 1 ] == 9
         IF Upper( AllTrim( aPairs[ i ][ 2 ] ) ) == "$INSUNITS" ;
               .AND. i + 1 <= n
            oDoc:nInsUnits := Val( aPairs[ i + 1 ][ 2 ] )
         ENDIF
      ENDIF
      i++
   ENDDO
   oDoc:lDirty := .F.
RETURN oDoc

STATIC FUNCTION dxf_read_layer( aPairs, nI, oDoc )
   LOCAL n := Len( aPairs ), cName := "0", nColor := 7, cLt := "Continuous"
   LOCAL i := nI + 1   // tras el par {0,LAYER}; si no, bucle infinito
   DO WHILE i <= n .AND. !( aPairs[ i ][ 1 ] == 0 )
      DO CASE
      CASE aPairs[ i ][ 1 ] == 2  ; cName := Upper( AllTrim( aPairs[ i ][ 2 ] ) )
      CASE aPairs[ i ][ 1 ] == 62 ; nColor := Val( aPairs[ i ][ 2 ] )
      CASE aPairs[ i ][ 1 ] == 6  ; cLt := AllTrim( aPairs[ i ][ 2 ] )
      ENDCASE
      i++
   ENDDO
   nI := i - 1
   IF oDoc:Layer( cName ) == NIL
      oDoc:AddLayer( cName, nColor )
      ASize( oDoc:aUndo, 0 )
   ENDIF
RETURN cName

STATIC FUNCTION dxf_val( aPairs, nI, nCode )
   IF aPairs[ nI ][ 1 ] == nCode
      RETURN Val( aPairs[ nI ][ 2 ] )
   ENDIF
RETURN NIL

STATIC FUNCTION dxf_read_ent( aPairs, nI, cEnt )
   // nI apunta al par {0,cEnt}; devuelve entidad y deja nI en ??ltimo par suyo
   LOCAL n := Len( aPairs ), i := nI + 1
   LOCAL h := {}, o := NIL, cLayer := "0", nColor := 256
   LOCAL aV := {}, aP := NIL
   DO WHILE i <= n .AND. !( aPairs[ i ][ 1 ] == 0 )
      AAdd( h, { aPairs[ i ][ 1 ], AllTrim( aPairs[ i ][ 2 ] ) } )
      i++
   ENDDO
   nI := i - 1
   // comunes 8 (capa) / 62 (color)
   FOR i := 1 TO Len( h )
      IF h[ i ][ 1 ] == 8
         cLayer := Upper( h[ i ][ 2 ] )
      ELSEIF h[ i ][ 1 ] == 62
         nColor := Val( h[ i ][ 2 ] )
      ENDIF
   NEXT
   DO CASE
   CASE cEnt == "LINE"
      o := TEntLine():New()
      o:aP1 := { dxf_g( h, 10 ), dxf_g( h, 20 ) }
      o:aP2 := { dxf_g( h, 11 ), dxf_g( h, 21 ) }
   CASE cEnt == "POINT"
      o := TEntPoint():New()
      o:aPt := { dxf_g( h, 10 ), dxf_g( h, 20 ) }
   CASE cEnt == "CIRCLE"
      o := TEntCircle():New()
      o:aCen := { dxf_g( h, 10 ), dxf_g( h, 20 ) }
      o:nRad := dxf_g( h, 40 )
   CASE cEnt == "ARC"
      o := TEntArc():New()
      o:aCen := { dxf_g( h, 10 ), dxf_g( h, 20 ) }
      o:nRad := dxf_g( h, 40 )
      o:nA0 := OC_Deg2Rad( dxf_g( h, 50 ) )
      o:nA1 := OC_Deg2Rad( dxf_g( h, 51 ) )
   CASE cEnt == "ELLIPSE"
      o := TEntEllipse():New()
      o:aCen := { dxf_g( h, 10 ), dxf_g( h, 20 ) }
      o:aAxis := { dxf_g( h, 11 ), dxf_g( h, 21 ) }
      o:nRatio := dxf_g( h, 40 )
   CASE cEnt == "LWPOLYLINE" .OR. cEnt == "POLYLINE"
      o := TEntPoly():New()
      IF cEnt == "POLYLINE"
         // v??rtices VERTEX...SEQEND: recolectar del flujo principal
         aV := dxf_read_vertexes( aPairs, @nI )
      ELSE
         aV := dxf_collect_xy( h, 10, 20 )
      ENDIF
      o:aVerts := aV
      o:lClosed := ( dxf_g( h, 70 ) % 2 ) == 1
   CASE cEnt == "SPLINE"
      o := TEntSpline():New()
      o:aVerts := dxf_collect_xy( h, 10, 20 )
   CASE cEnt == "TEXT" .OR. cEnt == "ATTRIB" .OR. cEnt == "ATTDEF"
      DO CASE
      CASE cEnt == "ATTRIB" ; o := TEntAttrib():New()
      CASE cEnt == "ATTDEF" ; o := TEntAttDef():New()
      OTHERWISE             ; o := TEntText():New()
      ENDCASE
      o:aPt := { dxf_g( h, 10 ), dxf_g( h, 20 ) }
      o:cText := dxf_s( h, 1 )
      o:nH := dxf_g( h, 40 )
      IF o:nH == 0
         o:nH := 2.5
      ENDIF
      o:nRot := OC_Deg2Rad( dxf_g( h, 50 ) )
   CASE cEnt == "MTEXT"
      o := TEntMText():New()
      o:aPt := { dxf_g( h, 10 ), dxf_g( h, 20 ) }
      o:cText := StrTran( dxf_s( h, 1 ), "\P", " " )
      o:nH := dxf_g( h, 40 )
   CASE cEnt == "HATCH"
      o := TEntHatch():New()
      o:cPat := dxf_s( h, 2 )
      o:aLoop := dxf_collect_xy( h, 10, 20 )
   CASE cEnt == "INSERT"
      o := TEntInsert():New()
      o:cBlock := dxf_s( h, 2 )
      o:aPt := { dxf_g( h, 10 ), dxf_g( h, 20 ) }
      o:nSx := dxf_gdef( h, 41, 1 )
      o:nSy := dxf_gdef( h, 42, 1 )
      o:nRot := OC_Deg2Rad( dxf_gdef( h, 50, 0 ) )
   CASE cEnt == "DIMENSION"
      o := TEntDim():New()
      o:aPl := { dxf_g( h, 10 ), dxf_g( h, 20 ) }
      o:aP1 := { dxf_g( h, 13 ), dxf_g( h, 23 ) }
      o:aP2 := { dxf_g( h, 14 ), dxf_g( h, 24 ) }
      o:cText := dxf_s( h, 1 )
   CASE cEnt == "RAY" .OR. cEnt == "XLINE"
      o := TEntRay():New()
      o:lXline := ( cEnt == "XLINE" )
      o:aPt := { dxf_g( h, 10 ), dxf_g( h, 20 ) }
      o:aDir := { dxf_gdef( h, 11, 1 ), dxf_gdef( h, 21, 0 ) }
   CASE cEnt == "SOLID" .OR. cEnt == "TRACE"
      o := TEntSolid():New()
      o:aPts := dxf_collect_xy4( h )
   ENDCASE
   IF o != NIL
      o:cLayer := cLayer
      o:nColor := nColor
   ENDIF
RETURN o

STATIC FUNCTION dxf_g( h, nCode )
   LOCAL i
   FOR i := 1 TO Len( h )
      IF h[ i ][ 1 ] == nCode
         RETURN Val( h[ i ][ 2 ] )
      ENDIF
   NEXT
RETURN 0

STATIC FUNCTION dxf_gdef( h, nCode, xDef )
   LOCAL i
   FOR i := 1 TO Len( h )
      IF h[ i ][ 1 ] == nCode
         RETURN Val( h[ i ][ 2 ] )
      ENDIF
   NEXT
RETURN xDef

STATIC FUNCTION dxf_s( h, nCode )
   LOCAL i
   FOR i := 1 TO Len( h )
      IF h[ i ][ 1 ] == nCode
         RETURN h[ i ][ 2 ]
      ENDIF
   NEXT
RETURN ""

STATIC FUNCTION dxf_collect_xy( h, nCX, nCY )
   // pares 10/20 repetidos (LWPOLYLINE, SPLINE puntos, HATCH contorno simple)
   LOCAL a := {}, i, j, x
   FOR i := 1 TO Len( h )
      IF h[ i ][ 1 ] == nCX
         x := Val( h[ i ][ 2 ] )
         FOR j := i + 1 TO Len( h )
            IF h[ j ][ 1 ] == nCY
               AAdd( a, { x, Val( h[ j ][ 2 ] ) } )
               EXIT
            ENDIF
         NEXT
      ENDIF
   NEXT
RETURN a

STATIC FUNCTION dxf_collect_xy4( h )
   // SOLID/TRACE: c??digos 10..13 / 20..23
   LOCAL a := {}, k
   FOR k := 0 TO 3
      AAdd( a, { dxf_gdef( h, 10 + k, 0 ), dxf_gdef( h, 20 + k, 0 ) } )
   NEXT
RETURN a

STATIC FUNCTION dxf_read_vertexes( aPairs, nI )
   // POLYLINE 2D: lee VERTEX hasta SEQEND; avanza nI
   LOCAL n := Len( aPairs ), a := {}, i := nI + 1, x := 0, y := 0
   DO WHILE i <= n
      IF aPairs[ i ][ 1 ] == 0
         IF Upper( AllTrim( aPairs[ i ][ 2 ] ) ) == "SEQEND"
            nI := i
            EXIT
         ENDIF
         IF Upper( AllTrim( aPairs[ i ][ 2 ] ) ) == "VERTEX" .AND. x != NIL
            // vuelca v??rtice anterior si exist??a
         ENDIF
      ELSEIF aPairs[ i ][ 1 ] == 10
         IF Len( a ) > 0 .OR. i > nI + 2
            // nada
         ENDIF
         x := Val( aPairs[ i ][ 2 ] )
         IF i + 1 <= n .AND. aPairs[ i + 1 ][ 1 ] == 20
            y := Val( aPairs[ i + 1 ][ 2 ] )
            AAdd( a, { x, y } )
         ENDIF
      ENDIF
      i++
   ENDDO
RETURN a
