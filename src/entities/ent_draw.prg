/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/entities/ent_draw.prg
   Rust origen: src/entities/line.rs + circle.rs + arc.rs + point.rs +
                text.rs + mtext.rs + lwpolyline.rs + polyline.rs +
                ellipse.rs
   Entidades b??sicas de dibujo con Draw GDI, DXF y grips.
   oView: objeto canvas con W2SX(nX), W2SY(nY), W2SL(n) y nTolPx.
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "FiveWin.ch"

//=========================== LINEA ============================================
CLASS TEntLine FROM TEntBase
   DATA aP1 INIT { 0, 0 }
   DATA aP2 INIT { 0, 0 }
   METHOD New() CONSTRUCTOR
   METHOD Transform( aM )
   METHOD BBox()
   METHOD GripPoints()
   METHOD Draw( hDC, oView )
   METHOD HitTest( aPt, nTol, oView )
   METHOD ToDxf( nHnd )
   METHOD Props()
ENDCLASS

METHOD New() CLASS TEntLine
   ::super:New( OHB_ENT_LINE )
RETURN Self

METHOD Transform( aM ) CLASS TEntLine
   ::aP1 := OC_XfPt( ::aP1, aM )
   ::aP2 := OC_XfPt( ::aP2, aM )
RETURN Self

METHOD BBox() CLASS TEntLine
RETURN { Min( ::aP1[ 1 ], ::aP2[ 1 ] ), Min( ::aP1[ 2 ], ::aP2[ 2 ] ), ;
         Max( ::aP1[ 1 ], ::aP2[ 1 ] ), Max( ::aP1[ 2 ], ::aP2[ 2 ] ) }

METHOD GripPoints() CLASS TEntLine
RETURN { AClone( ::aP1 ), OC_Mid2D( ::aP1, ::aP2 ), AClone( ::aP2 ) }

METHOD Draw( hDC, oView ) CLASS TEntLine
   MoveTo( hDC, oView:W2SX( ::aP1[ 1 ] ), oView:W2SY( ::aP1[ 2 ] ) )
   LineTo( hDC, oView:W2SX( ::aP2[ 1 ] ), oView:W2SY( ::aP2[ 2 ] ) )
RETURN NIL

METHOD HitTest( aPt, nTol, oView ) CLASS TEntLine
   LOCAL a := OC_PtSeg( aPt, ::aP1, ::aP2 )
RETURN a[ 1 ] <= nTol

METHOD ToDxf( nHnd ) CLASS TEntLine
RETURN { { 0, "LINE" }, { 5, LTrim( Str( nHnd, 0 ) ) }, ;
   { 8, ::cLayer }, { 10, ::aP1[ 1 ] }, { 20, ::aP1[ 2 ] }, ;
   { 11, ::aP2[ 1 ] }, { 21, ::aP2[ 2 ] }, ;
   If( ::nColor == OHB_BYLAYER, NIL, { 62, ::nColor } ) }

METHOD Props() CLASS TEntLine
RETURN { { "Tipo", "LINEA" }, { "Capa", ::cLayer }, ;
   { "X1", ::aP1[ 1 ] }, { "Y1", ::aP1[ 2 ] }, ;
   { "X2", ::aP2[ 1 ] }, { "Y2", ::aP2[ 2 ] }, ;
   { "Longitud", OC_Dist2D( ::aP1, ::aP2 ) } }

//=========================== PUNTO ============================================
CLASS TEntPoint FROM TEntBase
   DATA aPt INIT { 0, 0 }
   METHOD New() CONSTRUCTOR
   METHOD Transform( aM )
   METHOD BBox()
   METHOD GripPoints()
   METHOD Draw( hDC, oView )
   METHOD HitTest( aPt, nTol, oView )
   METHOD ToDxf( nHnd )
ENDCLASS

METHOD New() CLASS TEntPoint
   ::super:New( OHB_ENT_POINT )
RETURN Self

METHOD Transform( aM ) CLASS TEntPoint
   ::aPt := OC_XfPt( ::aPt, aM )
RETURN Self

METHOD BBox() CLASS TEntPoint
RETURN { ::aPt[ 1 ], ::aPt[ 2 ], ::aPt[ 1 ], ::aPt[ 2 ] }

METHOD GripPoints() CLASS TEntPoint
RETURN { AClone( ::aPt ) }

METHOD Draw( hDC, oView ) CLASS TEntPoint
   LOCAL x := oView:W2SX( ::aPt[ 1 ] ), y := oView:W2SY( ::aPt[ 2 ] )
   MoveTo( hDC, x - 3, y )
   LineTo( hDC, x + 4, y )
   MoveTo( hDC, x, y - 3 )
   LineTo( hDC, x, y + 4 )
RETURN NIL

METHOD HitTest( aPt, nTol, oView ) CLASS TEntPoint
RETURN OC_Dist2D( aPt, ::aPt ) <= nTol

METHOD ToDxf( nHnd ) CLASS TEntPoint
RETURN { { 0, "POINT" }, { 5, LTrim( Str( nHnd, 0 ) ) }, ;
   { 8, ::cLayer }, { 10, ::aPt[ 1 ] }, { 20, ::aPt[ 2 ] } }

//=========================== CIRCULO ===========================================
CLASS TEntCircle FROM TEntBase
   DATA aCen INIT { 0, 0 }
   DATA nRad INIT 1.0
   METHOD New() CONSTRUCTOR
   METHOD Transform( aM )
   METHOD BBox()
   METHOD GripPoints()
   METHOD Draw( hDC, oView )
   METHOD HitTest( aPt, nTol, oView )
   METHOD ToDxf( nHnd )
   METHOD Props()
ENDCLASS

METHOD New() CLASS TEntCircle
   ::super:New( OHB_ENT_CIRCLE )
RETURN Self

METHOD Transform( aM ) CLASS TEntCircle
   LOCAL aX := OC_XfPt( { ::aCen[ 1 ] + 1, ::aCen[ 2 ] }, aM )
   ::aCen := OC_XfPt( ::aCen, aM )
   ::nRad := OC_Dist2D( ::aCen, aX ) * ::nRad
RETURN Self

METHOD BBox() CLASS TEntCircle
RETURN { ::aCen[ 1 ] - ::nRad, ::aCen[ 2 ] - ::nRad, ;
         ::aCen[ 1 ] + ::nRad, ::aCen[ 2 ] + ::nRad }

METHOD GripPoints() CLASS TEntCircle
RETURN { AClone( ::aCen ), ;
   { ::aCen[ 1 ] + ::nRad, ::aCen[ 2 ] }, ;
   { ::aCen[ 1 ] - ::nRad, ::aCen[ 2 ] }, ;
   { ::aCen[ 1 ], ::aCen[ 2 ] + ::nRad }, ;
   { ::aCen[ 1 ], ::aCen[ 2 ] - ::nRad } }

METHOD Draw( hDC, oView ) CLASS TEntCircle
   LOCAL x := oView:W2SX( ::aCen[ 1 ] ), y := oView:W2SY( ::aCen[ 2 ] )
   LOCAL r := oView:W2SL( ::nRad )
   Ellipse( hDC, x - r, y - r, x + r, y + r )
RETURN NIL

METHOD HitTest( aPt, nTol, oView ) CLASS TEntCircle
RETURN Abs( OC_Dist2D( aPt, ::aCen ) - ::nRad ) <= nTol

METHOD ToDxf( nHnd ) CLASS TEntCircle
RETURN { { 0, "CIRCLE" }, { 5, LTrim( Str( nHnd, 0 ) ) }, ;
   { 8, ::cLayer }, { 10, ::aCen[ 1 ] }, { 20, ::aCen[ 2 ] }, ;
   { 40, ::nRad } }

METHOD Props() CLASS TEntCircle
RETURN { { "Tipo", "CIRCULO" }, { "Capa", ::cLayer }, ;
   { "Centro X", ::aCen[ 1 ] }, { "Centro Y", ::aCen[ 2 ] }, ;
   { "Radio", ::nRad }, { "Area", 4 * ATan( 1 ) * ::nRad * ::nRad } }

//=========================== ARCO ==============================================
CLASS TEntArc FROM TEntBase
   DATA aCen  INIT { 0, 0 }
   DATA nRad  INIT 1.0
   DATA nA0   INIT 0.0
   DATA nA1   INIT 1.5707963267948966
   METHOD New() CONSTRUCTOR
   METHOD Transform( aM )
   METHOD BBox()
   METHOD GripPoints()
   METHOD Draw( hDC, oView )
   METHOD HitTest( aPt, nTol, oView )
   METHOD ToDxf( nHnd )
ENDCLASS

METHOD New() CLASS TEntArc
   ::super:New( OHB_ENT_ARC )
RETURN Self

METHOD Transform( aM ) CLASS TEntArc
   LOCAL aX := OC_XfPt( { ::aCen[ 1 ] + 1, ::aCen[ 2 ] }, aM )
   LOCAL nS := OC_Dist2D( ::aCen, aX )
   LOCAL nRot := OC_Ang2D( ::aCen, aX )
   ::aCen := OC_XfPt( ::aCen, aM )
   ::nRad *= nS
   ::nA0 := OC_NormAng( ::nA0 + nRot )
   ::nA1 := OC_NormAng( ::nA1 + nRot )
RETURN Self

METHOD BBox() CLASS TEntArc
   LOCAL aT := OC_TessArc( ::aCen, ::nRad, ::nA0, ::nA1, ::nRad * 0.02 )
RETURN OC_BBoxPts( aT )

METHOD GripPoints() CLASS TEntArc
RETURN { AClone( ::aCen ), OC_Polar2D( ::aCen, ::nA0, ::nRad ), ;
   OC_Polar2D( ::aCen, ::nA1, ::nRad ) }

METHOD Draw( hDC, oView ) CLASS TEntArc
   // Teselado poligonal (igual que Rust tess.rs; evita Arc() GDI)
   LOCAL aT := OC_TessArc( ::aCen, ::nRad, ::nA0, ::nA1, ::nRad * 0.02 )
   LOCAL i
   FOR i := 1 TO Len( aT )
      IF i == 1
         MoveTo( hDC, oView:W2SX( aT[ i ][ 1 ] ), oView:W2SY( aT[ i ][ 2 ] ) )
      ELSE
         LineTo( hDC, oView:W2SX( aT[ i ][ 1 ] ), oView:W2SY( aT[ i ][ 2 ] ) )
      ENDIF
   NEXT
RETURN NIL

METHOD HitTest( aPt, nTol, oView ) CLASS TEntArc
   LOCAL nA
   IF Abs( OC_Dist2D( aPt, ::aCen ) - ::nRad ) > nTol
      RETURN .F.
   ENDIF
   nA := OC_NormAng( OC_Ang2D( ::aCen, aPt ) )
   IF ::nA1 >= ::nA0
      RETURN nA >= ::nA0 - 0.001 .AND. nA <= ::nA1 + 0.001
   ENDIF
RETURN nA >= ::nA0 - 0.001 .OR. nA <= ::nA1 + 0.001

METHOD ToDxf( nHnd ) CLASS TEntArc
RETURN { { 0, "ARC" }, { 5, LTrim( Str( nHnd, 0 ) ) }, ;
   { 8, ::cLayer }, { 10, ::aCen[ 1 ] }, { 20, ::aCen[ 2 ] }, ;
   { 40, ::nRad }, { 50, OC_Rad2Deg( ::nA0 ) }, { 51, OC_Rad2Deg( ::nA1 ) } }

//=========================== ELIPSE ============================================
CLASS TEntEllipse FROM TEntBase
   DATA aCen  INIT { 0, 0 }
   DATA aAxis INIT { 1, 0 }   // semieje mayor (vector)
   DATA nRatio INIT 0.5       // eje menor / eje mayor
   DATA nA0   INIT 0.0
   DATA nA1   INIT 6.283185307179586
   METHOD New() CONSTRUCTOR
   METHOD BBox()
   METHOD Draw( hDC, oView )
   METHOD ToDxf( nHnd )
ENDCLASS

METHOD New() CLASS TEntEllipse
   ::super:New( OHB_ENT_ELLIPSE )
RETURN Self

METHOD BBox() CLASS TEntEllipse
   LOCAL L := OC_Dist2D( { 0, 0 }, ::aAxis )
   LOCAL b := L * ::nRatio
RETURN { ::aCen[ 1 ] - L, ::aCen[ 2 ] - b, ::aCen[ 1 ] + L, ::aCen[ 2 ] + b }

METHOD Draw( hDC, oView ) CLASS TEntEllipse
   // Aproximaci??n poligonal (teselado como en Rust tess.rs)
   LOCAL aT, i, x, y
   LOCAL L := OC_Dist2D( { 0, 0 }, ::aAxis )
   LOCAL nRot := OC_Ang2D( { 0, 0 }, ::aAxis )
   LOCAL b := L * ::nRatio
   aT := OCX_TESSARC( 0, 0, 1, ::nA0, ::nA1, ;
        OCX_ARCN( 0, 0, 1, ::nA0, ::nA1, 0.02 ) )
   FOR i := 1 TO Len( aT )
      x := ::aCen[ 1 ] + aT[ i ][ 1 ] * L * Cos( nRot ) - ;
           aT[ i ][ 2 ] * b * Sin( nRot )
      y := ::aCen[ 2 ] + aT[ i ][ 1 ] * L * Sin( nRot ) + ;
           aT[ i ][ 2 ] * b * Cos( nRot )
      IF i == 1
         MoveTo( hDC, oView:W2SX( x ), oView:W2SY( y ) )
      ELSE
         LineTo( hDC, oView:W2SX( x ), oView:W2SY( y ) )
      ENDIF
   NEXT
RETURN NIL

METHOD ToDxf( nHnd ) CLASS TEntEllipse
RETURN { { 0, "ELLIPSE" }, { 5, LTrim( Str( nHnd, 0 ) ) }, ;
   { 8, ::cLayer }, { 10, ::aCen[ 1 ] }, { 20, ::aCen[ 2 ] }, ;
   { 11, ::aAxis[ 1 ] }, { 21, ::aAxis[ 2 ] }, ;
   { 40, ::nRatio }, { 41, ::nA0 }, { 42, ::nA1 } }

//=========================== POLILINEA ==========================================
CLASS TEntPoly FROM TEntBase
   DATA aVerts  INIT {}    // array de {x,y} (+ {x,y,bulge}? simple: {x,y})
   DATA lClosed INIT .F.
   METHOD New() CONSTRUCTOR
   METHOD Transform( aM )
   METHOD BBox()
   METHOD GripPoints()
   METHOD Draw( hDC, oView )
   METHOD HitTest( aPt, nTol, oView )
   METHOD ToDxf( nHnd )
   METHOD Length()
ENDCLASS

METHOD New() CLASS TEntPoly
   ::super:New( OHB_ENT_LWPOLYLINE )
RETURN Self

METHOD Transform( aM ) CLASS TEntPoly
   LOCAL i
   FOR i := 1 TO Len( ::aVerts )
      ::aVerts[ i ] := OC_XfPt( ::aVerts[ i ], aM )
   NEXT
RETURN Self

METHOD BBox() CLASS TEntPoly
   LOCAL a
   IF Empty( ::aVerts )
      RETURN { 0, 0, 0, 0 }
   ENDIF
   a := OC_BBoxPts( ::aVerts )
RETURN a

METHOD GripPoints() CLASS TEntPoly
   LOCAL a := {}
   AEval( ::aVerts, { | p | AAdd( a, AClone( p ) ) } )
RETURN a

METHOD Draw( hDC, oView ) CLASS TEntPoly
   LOCAL i, n := Len( ::aVerts ), x, y
   FOR i := 1 TO n
      x := oView:W2SX( ::aVerts[ i ][ 1 ] )
      y := oView:W2SY( ::aVerts[ i ][ 2 ] )
      IF i == 1
         MoveTo( hDC, x, y )
      ELSE
         LineTo( hDC, x, y )
      ENDIF
   NEXT
   IF ::lClosed .AND. n > 2
      LineTo( hDC, oView:W2SX( ::aVerts[ 1 ][ 1 ] ), ;
                   oView:W2SY( ::aVerts[ 1 ][ 2 ] ) )
   ENDIF
RETURN NIL

METHOD HitTest( aPt, nTol, oView ) CLASS TEntPoly
   LOCAL i, n := Len( ::aVerts )
   FOR i := 2 TO n
      IF OC_PtSeg( aPt, ::aVerts[ i - 1 ], ::aVerts[ i ] )[ 1 ] <= nTol
         RETURN .T.
      ENDIF
   NEXT
   IF ::lClosed .AND. n > 2
      IF OC_PtSeg( aPt, ATail( ::aVerts ), ::aVerts[ 1 ] )[ 1 ] <= nTol
         RETURN .T.
      ENDIF
   ENDIF
RETURN .F.

METHOD ToDxf( nHnd ) CLASS TEntPoly
   LOCAL a := { { 0, "LWPOLYLINE" }, { 5, LTrim( Str( nHnd, 0 ) ) }, ;
      { 8, ::cLayer }, { 90, Len( ::aVerts ) }, ;
      { 70, If( ::lClosed, 1, 0 ) } }
   LOCAL i
   FOR i := 1 TO Len( ::aVerts )
      AAdd( a, { 10, ::aVerts[ i ][ 1 ] } )
      AAdd( a, { 20, ::aVerts[ i ][ 2 ] } )
   NEXT
RETURN a

METHOD Length() CLASS TEntPoly
RETURN OC_PolyLen( ::aVerts, ::lClosed )

//=========================== TEXTO ==============================================
CLASS TEntText FROM TEntBase
   DATA aPt    INIT { 0, 0 }
   DATA cText  INIT ""
   DATA nH     INIT 2.5
   DATA nRot   INIT 0.0
   DATA nHAlign INIT 0
   DATA nVAlign INIT 0
   METHOD New() CONSTRUCTOR
   METHOD Transform( aM )
   METHOD BBox()
   METHOD Draw( hDC, oView )
   METHOD ToDxf( nHnd )
ENDCLASS

METHOD New() CLASS TEntText
   ::super:New( OHB_ENT_TEXT )
RETURN Self

METHOD Transform( aM ) CLASS TEntText
   LOCAL aX := OC_XfPt( { ::aPt[ 1 ] + 1, ::aPt[ 2 ] }, aM )
   ::nRot := OC_NormAng( ::nRot + OC_Ang2D( ::aPt, aX ) )
   ::aPt := OC_XfPt( ::aPt, aM )
RETURN Self

METHOD BBox() CLASS TEntText
   LOCAL w := Len( ::cText ) * ::nH * 0.7
RETURN { ::aPt[ 1 ], ::aPt[ 2 ], ::aPt[ 1 ] + w, ::aPt[ 2 ] + ::nH }

METHOD Draw( hDC, oView ) CLASS TEntText
   TextOut( hDC, oView:W2SY( ::aPt[ 2 ] ), oView:W2SX( ::aPt[ 1 ] ), ::cText )
RETURN NIL

METHOD ToDxf( nHnd ) CLASS TEntText
RETURN { { 0, "TEXT" }, { 5, LTrim( Str( nHnd, 0 ) ) }, ;
   { 8, ::cLayer }, { 10, ::aPt[ 1 ] }, { 20, ::aPt[ 2 ] }, ;
   { 40, ::nH }, { 1, ::cText }, { 50, OC_Rad2Deg( ::nRot ) } }

//=========================== TEXTOM ==============================================
CLASS TEntMText FROM TEntText
   DATA nWidth INIT 0.0
   METHOD New() CONSTRUCTOR
   METHOD ToDxf( nHnd )
ENDCLASS

METHOD New() CLASS TEntMText
   ::super:New( OHB_ENT_TEXT )
   ::nType := OHB_ENT_MTEXT
RETURN Self

METHOD ToDxf( nHnd ) CLASS TEntMText
   LOCAL a := ::super:ToDxf( nHnd )
   a[ 1 ] := { 0, "MTEXT" }
RETURN a

//=========================== SPLINE ==============================================
CLASS TEntSpline FROM TEntPoly
   METHOD New() CONSTRUCTOR
   METHOD Draw( hDC, oView )
ENDCLASS

METHOD New() CLASS TEntSpline
   ::super:New()
   ::nType := OHB_ENT_SPLINE
RETURN Self

METHOD Draw( hDC, oView ) CLASS TEntSpline
   // Catmull-Rom por los puntos de control (aprox. NURBS de Rust spline.rs)
   LOCAL aP := ::aVerts, n := Len( aP ), i, t, p0, p1, p2, p3, x, y
   LOCAL lFirst := .T.
   IF n < 2
      RETURN NIL
   ENDIF
   FOR i := 1 TO n - 1
      p1 := aP[ i ]; p2 := aP[ i + 1 ]
      p0 := If( i > 1, aP[ i - 1 ], p1 )
      p3 := If( i + 2 <= n, aP[ i + 2 ], p2 )
      FOR t := If( lFirst, 0, 1 ) TO 8
         x := 0.5 * ( 2 * p1[ 1 ] + ( -p0[ 1 ] + p2[ 1 ] ) * t / 8 + ;
            ( 2 * p0[ 1 ] - 5 * p1[ 1 ] + 4 * p2[ 1 ] - p3[ 1 ] ) * ( t / 8 ) ^ 2 + ;
            ( -p0[ 1 ] + 3 * p1[ 1 ] - 3 * p2[ 1 ] + p3[ 1 ] ) * ( t / 8 ) ^ 3 )
         y := 0.5 * ( 2 * p1[ 2 ] + ( -p0[ 2 ] + p2[ 2 ] ) * t / 8 + ;
            ( 2 * p0[ 2 ] - 5 * p1[ 2 ] + 4 * p2[ 2 ] - p3[ 2 ] ) * ( t / 8 ) ^ 2 + ;
            ( -p0[ 2 ] + 3 * p1[ 2 ] - 3 * p2[ 2 ] + p3[ 2 ] ) * ( t / 8 ) ^ 3 )
         IF lFirst
            MoveTo( hDC, oView:W2SX( x ), oView:W2SY( y ) )
            lFirst := .F.
         ELSE
            LineTo( hDC, oView:W2SX( x ), oView:W2SY( y ) )
         ENDIF
      NEXT
   NEXT
RETURN NIL
