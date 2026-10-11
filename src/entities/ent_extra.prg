/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/entities/ent_extra.prg
   Rust origen: src/entities/hatch.rs + insert.rs + dimension.rs +
                leader.rs + multileader.rs + ray.rs + solid.rs +
                mline.rs + raster_image.rs + underlay.rs + table.rs +
                tolerance.rs + attribute.rs + solid3d.rs (envoltura 2D)
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "FiveWin.ch"

//=========================== SOMBREADO ===========================================
CLASS TEntHatch FROM TEntBase
   DATA cPat   INIT "ANSI31"
   DATA nAng   INIT 0.0
   DATA nScale INIT 1.0
   DATA aLoop  INIT {}     // pol??gono contorno { {x,y}... }
   DATA lAssoc INIT .T.
   METHOD New() CONSTRUCTOR
   METHOD BBox()
   METHOD Draw( hDC, oView )
   METHOD ToDxf( nHnd )
ENDCLASS

METHOD New() CLASS TEntHatch
   ::super:New( OHB_ENT_HATCH )
RETURN Self

METHOD BBox() CLASS TEntHatch
   IF Empty( ::aLoop )
      RETURN { 0, 0, 0, 0 }
   ENDIF
RETURN OC_BBoxPts( ::aLoop )

METHOD Draw( hDC, oView ) CLASS TEntHatch
   // Relleno diagonal ANSI31 + contorno (Rust: hatch_model.rs simplificado)
   LOCAL i, n := Len( ::aLoop ), x, y, x0, y0, x1, y1, k
   LOCAL aB := ::BBox()
   IF n < 3
      RETURN NIL
   ENDIF
   FOR i := 1 TO n
      x := oView:W2SX( ::aLoop[ i ][ 1 ] )
      y := oView:W2SY( ::aLoop[ i ][ 2 ] )
      IF i == 1
         MoveTo( hDC, x, y )
      ELSE
         LineTo( hDC, x, y )
      ENDIF
   NEXT
   LineTo( hDC, oView:W2SX( ::aLoop[ 1 ][ 1 ] ), ;
                oView:W2SY( ::aLoop[ 1 ][ 2 ] ) )
   // tramado: l??neas a 45?? separadas 6 px, recortadas al bbox
   x0 := oView:W2SX( aB[ 1 ] ); y0 := oView:W2SY( aB[ 2 ] )
   x1 := oView:W2SX( aB[ 3 ] ); y1 := oView:W2SY( aB[ 4 ] )
   k := 0
   DO WHILE k < ( x1 - x0 ) + ( y0 - y1 )
      MoveTo( hDC, x0 + k, y0 )
      LineTo( hDC, x0 + k - ( y0 - y1 ), y1 )
      k += 6
   ENDDO
RETURN NIL

METHOD ToDxf( nHnd ) CLASS TEntHatch
   LOCAL a := { { 0, "HATCH" }, { 5, LTrim( Str( nHnd, 0 ) ) }, ;
      { 8, ::cLayer }, { 2, ::cPat }, { 70, 0 }, { 71, 0 }, ;
      { 91, 1 }, { 92, 1 }, { 93, Len( ::aLoop ) }, { 72, 0 } }
   LOCAL i
   FOR i := 1 TO Len( ::aLoop )
      AAdd( a, { 10, ::aLoop[ i ][ 1 ] } )
      AAdd( a, { 20, ::aLoop[ i ][ 2 ] } )
   NEXT
RETURN a

//=========================== INSERT (bloque) ======================================
CLASS TEntInsert FROM TEntBase
   DATA cBlock INIT ""
   DATA aPt    INIT { 0, 0 }
   DATA nSx    INIT 1.0
   DATA nSy    INIT 1.0
   DATA nRot   INIT 0.0
   METHOD New() CONSTRUCTOR
   METHOD BBox()
   METHOD Draw( hDC, oView )
   METHOD ToDxf( nHnd )
ENDCLASS

METHOD New() CLASS TEntInsert
   ::super:New( OHB_ENT_INSERT )
RETURN Self

METHOD BBox() CLASS TEntInsert
RETURN { ::aPt[ 1 ] - 1, ::aPt[ 2 ] - 1, ::aPt[ 1 ] + 1, ::aPt[ 2 ] + 1 }

METHOD Draw( hDC, oView ) CLASS TEntInsert
   LOCAL x := oView:W2SX( ::aPt[ 1 ] ), y := oView:W2SY( ::aPt[ 2 ] )
   MoveTo( hDC, x - 5, y - 5 )
   LineTo( hDC, x + 5, y + 5 )
   MoveTo( hDC, x - 5, y + 5 )
   LineTo( hDC, x + 5, y - 5 )
   TextOut( hDC, y + 6, x + 6, ::cBlock )
RETURN NIL

METHOD ToDxf( nHnd ) CLASS TEntInsert
RETURN { { 0, "INSERT" }, { 5, LTrim( Str( nHnd, 0 ) ) }, ;
   { 8, ::cLayer }, { 2, ::cBlock }, { 10, ::aPt[ 1 ] }, ;
   { 20, ::aPt[ 2 ] }, { 41, ::nSx }, { 42, ::nSy }, ;
   { 50, OC_Rad2Deg( ::nRot ) } }

//=========================== COTA ================================================
CLASS TEntDim FROM TEntBase
   DATA nKind  INIT 0   // 0 lineal, 1 alineada, 2 radio, 3 di??metro, 4 angular
   DATA aP1    INIT { 0, 0 }
   DATA aP2    INIT { 0, 0 }
   DATA aPl    INIT { 0, 0 }  // posici??n l??nea de cota / punto
   DATA cText  INIT ""
   METHOD New() CONSTRUCTOR
   METHOD BBox()
   METHOD Draw( hDC, oView )
   METHOD ToDxf( nHnd )
   METHOD Measure()
ENDCLASS

METHOD New() CLASS TEntDim
   ::super:New( OHB_ENT_DIM )
RETURN Self

METHOD Measure() CLASS TEntDim
   DO CASE
   CASE ::nKind == 0 ; RETURN Abs( ::aP2[ 1 ] - ::aP1[ 1 ] )
   CASE ::nKind == 1 ; RETURN OC_Dist2D( ::aP1, ::aP2 )
   CASE ::nKind == 2 ; RETURN OC_Dist2D( ::aP1, ::aP2 )
   CASE ::nKind == 3 ; RETURN 2 * OC_Dist2D( ::aP1, ::aP2 )
   ENDCASE
RETURN OC_Dist2D( ::aP1, ::aP2 )

METHOD BBox() CLASS TEntDim
   LOCAL a := { AClone( ::aP1 ), AClone( ::aP2 ), AClone( ::aPl ) }
RETURN OC_BBoxPts( a )

METHOD Draw( hDC, oView ) CLASS TEntDim
   LOCAL x1 := oView:W2SX( ::aP1[ 1 ] ), y1 := oView:W2SY( ::aP1[ 2 ] )
   LOCAL x2 := oView:W2SX( ::aP2[ 1 ] ), y2 := oView:W2SY( ::aP2[ 2 ] )
   LOCAL cT := If( Empty( ::cText ), LTrim( Str( ::Measure(), 0, 2 ) ), ::cText )
   MoveTo( hDC, x1, y1 )
   LineTo( hDC, x2, y2 )
   TextOut( hDC, ( y1 + y2 ) / 2 - 14, ( x1 + x2 ) / 2, cT )
RETURN NIL

METHOD ToDxf( nHnd ) CLASS TEntDim
RETURN { { 0, "DIMENSION" }, { 5, LTrim( Str( nHnd, 0 ) ) }, ;
   { 8, ::cLayer }, { 10, ::aPl[ 1 ] }, { 20, ::aPl[ 2 ] }, ;
   { 13, ::aP1[ 1 ] }, { 23, ::aP1[ 2 ] }, { 14, ::aP2[ 1 ] }, ;
   { 24, ::aP2[ 2 ] }, { 70, ::nKind }, { 1, ::cText } }

//=========================== RAYO / LINEAX ========================================
CLASS TEntRay FROM TEntBase
   DATA aPt   INIT { 0, 0 }
   DATA aDir  INIT { 1, 0 }
   DATA lXline INIT .F.
   METHOD New() CONSTRUCTOR
   METHOD Draw( hDC, oView )
   METHOD ToDxf( nHnd )
ENDCLASS

METHOD New() CLASS TEntRay
   ::super:New( OHB_ENT_RAY )
RETURN Self

METHOD Draw( hDC, oView ) CLASS TEntRay
   LOCAL L := 100000, x0, y0, x1, y1
   IF ::lXline
      x0 := ::aPt[ 1 ] - ::aDir[ 1 ] * L
      y0 := ::aPt[ 2 ] - ::aDir[ 2 ] * L
   ELSE
      x0 := ::aPt[ 1 ]; y0 := ::aPt[ 2 ]
   ENDIF
   x1 := ::aPt[ 1 ] + ::aDir[ 1 ] * L
   y1 := ::aPt[ 2 ] + ::aDir[ 2 ] * L
   MoveTo( hDC, oView:W2SX( x0 ), oView:W2SY( y0 ) )
   LineTo( hDC, oView:W2SX( x1 ), oView:W2SY( y1 ) )
RETURN NIL

METHOD ToDxf( nHnd ) CLASS TEntRay
RETURN { { 0, If( ::lXline, "XLINE", "RAY" ) }, ;
   { 5, LTrim( Str( nHnd, 0 ) ) }, { 8, ::cLayer }, ;
   { 10, ::aPt[ 1 ] }, { 20, ::aPt[ 2 ] }, ;
   { 11, ::aDir[ 1 ] }, { 21, ::aDir[ 2 ] } }

//=========================== SOLIDO / TRAZO ========================================
CLASS TEntSolid FROM TEntBase
   DATA aPts INIT {}   // 3-4 v??rtices
   METHOD New() CONSTRUCTOR
   METHOD BBox()
   METHOD Draw( hDC, oView )
   METHOD ToDxf( nHnd )
ENDCLASS

METHOD New() CLASS TEntSolid
   ::super:New( OHB_ENT_SOLID )
RETURN Self

METHOD BBox() CLASS TEntSolid
   IF Empty( ::aPts )
      RETURN { 0, 0, 0, 0 }
   ENDIF
RETURN OC_BBoxPts( ::aPts )

METHOD Draw( hDC, oView ) CLASS TEntSolid
   LOCAL i, x, y
   FOR i := 1 TO Len( ::aPts )
      x := oView:W2SX( ::aPts[ i ][ 1 ] )
      y := oView:W2SY( ::aPts[ i ][ 2 ] )
      IF i == 1
         MoveTo( hDC, x, y )
      ELSE
         LineTo( hDC, x, y )
      ENDIF
   NEXT
   IF Len( ::aPts ) > 2
      LineTo( hDC, oView:W2SX( ::aPts[ 1 ][ 1 ] ), ;
                   oView:W2SY( ::aPts[ 1 ][ 2 ] ) )
   ENDIF
RETURN NIL

METHOD ToDxf( nHnd ) CLASS TEntSolid
   LOCAL a := { { 0, "SOLID" }, { 5, LTrim( Str( nHnd, 0 ) ) }, ;
      { 8, ::cLayer } }
   LOCAL i
   FOR i := 1 TO Min( Len( ::aPts ), 4 )
      AAdd( a, { 10 + i - 1, ::aPts[ i ][ 1 ] } )
      AAdd( a, { 20 + i - 1, ::aPts[ i ][ 2 ] } )
   NEXT
RETURN a

//=========================== LINEAM ===============================================
CLASS TEntMLine FROM TEntPoly
   DATA nStyle INIT 1
   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS TEntMLine
   ::super:New()
   ::nType := OHB_ENT_MLINE
RETURN Self

//=========================== BORRADO (wipeout) =====================================
CLASS TEntWipeout FROM TEntSolid
   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS TEntWipeout
   ::super:New()
   ::nType := OHB_ENT_WIPEOUT
RETURN Self

//=========================== DIRECTRIZ ==============================================
CLASS TEntLeader FROM TEntPoly
   DATA cText INIT ""
   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS TEntLeader
   ::super:New()
   ::nType := OHB_ENT_LEADER
RETURN Self

//=========================== TOLERANCIA ==============================================
CLASS TEntTolerance FROM TEntText
   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS TEntTolerance
   ::super:New()
   ::nType := OHB_ENT_TOLERANCE
RETURN Self

//=========================== ATRIBUTO / ATRIBDEF =======================================
CLASS TEntAttDef FROM TEntText
   DATA cTag INIT ""
   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS TEntAttDef
   ::super:New()
   ::nType := OHB_ENT_ATTDEF
RETURN Self

CLASS TEntAttrib FROM TEntAttDef
   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS TEntAttrib
   ::super:New()
   ::nType := OHB_ENT_ATTRIB
RETURN Self

//=========================== TABLA ======================================================
CLASS TEntTable FROM TEntBase
   DATA aPt    INIT { 0, 0 }
   DATA aCells INIT {}   // array de filas: array de textos
   DATA nRowH  INIT 5.0
   DATA nColW  INIT 20.0
   METHOD New() CONSTRUCTOR
   METHOD BBox()
   METHOD Draw( hDC, oView )
ENDCLASS

METHOD New() CLASS TEntTable
   ::super:New( OHB_ENT_TABLE )
RETURN Self

METHOD BBox() CLASS TEntTable
   LOCAL nR := Len( ::aCells ), nC := 1, i
   FOR i := 1 TO nR
      nC := Max( nC, Len( ::aCells[ i ] ) )
   NEXT
RETURN { ::aPt[ 1 ], ::aPt[ 2 ] - nR * ::nRowH, ;
         ::aPt[ 1 ] + nC * ::nColW, ::aPt[ 2 ] }

METHOD Draw( hDC, oView ) CLASS TEntTable
   LOCAL i, j, x, y, nR := Len( ::aCells )
   FOR i := 1 TO nR
      FOR j := 1 TO Len( ::aCells[ i ] )
         x := oView:W2SX( ::aPt[ 1 ] + ( j - 1 ) * ::nColW )
         y := oView:W2SY( ::aPt[ 2 ] - ( i - 1 ) * ::nRowH )
         TextOut( hDC, y - 12, x + 2, ::aCells[ i ][ j ] )
      NEXT
   NEXT
RETURN NIL

//=========================== IMAGEN RASTER ===============================================
CLASS TEntRaster FROM TEntBase
   DATA aPt   INIT { 0, 0 }
   DATA cFile INIT ""
   DATA nW    INIT 100.0
   DATA nH    INIT 100.0
   METHOD New() CONSTRUCTOR
   METHOD BBox()
   METHOD Draw( hDC, oView )
ENDCLASS

METHOD New() CLASS TEntRaster
   ::super:New( OHB_ENT_RASTER )
RETURN Self

METHOD BBox() CLASS TEntRaster
RETURN { ::aPt[ 1 ], ::aPt[ 2 ], ::aPt[ 1 ] + ::nW, ::aPt[ 2 ] + ::nH }

METHOD Draw( hDC, oView ) CLASS TEntRaster
   LOCAL x0 := oView:W2SX( ::aPt[ 1 ] ), y0 := oView:W2SY( ::aPt[ 2 ] )
   LOCAL x1 := oView:W2SX( ::aPt[ 1 ] + ::nW )
   LOCAL y1 := oView:W2SY( ::aPt[ 2 ] + ::nH )
   // marco + cruz + nombre (la imagen real la pinta el canvas si existe)
   MoveTo( hDC, x0, y0 )
   LineTo( hDC, x1, y0 )
   LineTo( hDC, x1, y1 )
   LineTo( hDC, x0, y1 )
   LineTo( hDC, x0, y0 )
   MoveTo( hDC, x0, y0 )
   LineTo( hDC, x1, y1 )
   MoveTo( hDC, x1, y0 )
   LineTo( hDC, x0, y1 )
RETURN NIL
