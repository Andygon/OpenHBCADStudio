/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/area.prg
   Origen Rust: opencadkernel/src/geom2d/area.rs (557 lineas)
   Estado: TRADUCIDO (tests en tests/t_area.prg).
   Los metodos de `impl Curve` pasan a Cv_*. Momentos = { nArea, nFirstX, nFirstY }.
   Gauss-Legendre de 5 nodos x 16 paneles, igual que Rust.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define AREA_PANELS 16

STATIC FUNCTION Ar_Nodes()
RETURN { { -0.906179845938664, 0.236926885056189 }, ;
         { -0.538469310105683, 0.478628670499366 }, ;
         {  0.0,               0.568888888888889 }, ;
         {  0.538469310105683, 0.478628670499366 }, ;
         {  0.906179845938664, 0.236926885056189 } }

FUNCTION Cv_EnclosedArea( c )
   LOCAL d := c[ CV_DATA ], nStart
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE
      RETURN 0.5 * V2_Cross( d[ LN_START ], d[ LN_END ] )
   CASE c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE
      RETURN 0.0
   CASE c[ CV_KIND ] == CV_CIRCLE
      RETURN CircularArea( d[ CI_CENTRE ], d[ CI_RADIUS ], 0.0, OCX_TAU )
   CASE c[ CV_KIND ] == CV_ARC
      nStart := NormalizeAngle( d[ AR_START ] )
      RETURN CircularArea( d[ AR_CENTRE ], d[ AR_RADIUS ], nStart, nStart + Ar_Sweep( d ) )
   CASE c[ CV_KIND ] == CV_ELLIPSE .OR. c[ CV_KIND ] == CV_NURBS
      RETURN Cv_IntegratedArea( c )
   ENDCASE
RETURN PolylineArea( d )

FUNCTION Cv_ChainArea( c )
   LOCAL aV, aFirst, aLast
   IF c[ CV_KIND ] == CV_POLYLINE .AND. ! c[ CV_DATA ][ PL_CLOSED ] .AND. Len( c[ CV_DATA ][ PL_VERTS ] ) >= 2
      aV := c[ CV_DATA ][ PL_VERTS ]
      aFirst := aV[ 1 ][ PV_POS ] ; aLast := aV[ Len( aV ) ][ PV_POS ]
      RETURN PolylineArea( c[ CV_DATA ] ) - 0.5 * V2_Cross( aLast, aFirst )
   ENDIF
RETURN Cv_EnclosedArea( c )

FUNCTION Cv_ChordClosedArea( c )
   LOCAL aStart, aEnd
   IF c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE ; RETURN NIL ; ENDIF
   aStart := Cv_PointAt( c, 0.0 ) ; aEnd := Cv_PointAt( c, 1.0 )
RETURN Cv_EnclosedArea( c ) + LineMoments( aEnd, aStart )[ 1 ]

FUNCTION Cv_EnclosedCentroid( c )
   LOCAL aOrigin, aLocal, aM
   IF c[ CV_KIND ] == CV_POLYLINE
      IF Len( c[ CV_DATA ][ PL_VERTS ] ) < 2 ; RETURN NIL ; ENDIF
   ELSEIF ! Cv_IsClosed( c )
      RETURN NIL
   ENDIF
   aOrigin := Cv_PointAt( c, 0.0 )
   aLocal := Cv_Transformed( c, Tr_Translation( { -aOrigin[1], -aOrigin[2] } ) )
   IF aLocal == NIL ; RETURN NIL ; ENDIF
   aM := Cv_EnclosedMoments( aLocal )
RETURN Ar_Centroid( aOrigin, aM )

FUNCTION Cv_ChordClosedCentroid( c )
   LOCAL aOrigin, aLocal, aStart, aEnd, aM
   IF c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE ; RETURN NIL ; ENDIF
   aOrigin := Cv_PointAt( c, 0.0 )
   aLocal := Cv_Transformed( c, Tr_Translation( { -aOrigin[1], -aOrigin[2] } ) )
   IF aLocal == NIL ; RETURN NIL ; ENDIF
   aStart := Cv_PointAt( aLocal, 0.0 ) ; aEnd := Cv_PointAt( aLocal, 1.0 )
   aM := AddMoments( Cv_EnclosedMoments( aLocal ), LineMoments( aEnd, aStart ) )
RETURN Ar_Centroid( aOrigin, aM )

STATIC FUNCTION Ar_Centroid( aOrigin, aM )
   IF OCX_ISFINITE( aM[1] ) .AND. aM[1] != 0.0 .AND. OCX_ISFINITE( aM[2] ) .AND. OCX_ISFINITE( aM[3] )
      RETURN { aOrigin[1] + aM[2] / aM[1], aOrigin[2] + aM[3] / aM[1] }
   ENDIF
RETURN NIL

FUNCTION Cv_EnclosedMoments( c )
   LOCAL aF
   IF c[ CV_KIND ] == CV_POLYLINE ; RETURN PolylineMoments( c[ CV_DATA ] ) ; ENDIF
   aF := IntegratedFirstMoments( {| t | Cv_PointAt( c, t ) }, {| t | Cv_TangentAt( c, t ) } )
RETURN { Cv_EnclosedArea( c ), aF[1], aF[2] }

STATIC FUNCTION Cv_IntegratedArea( c )
   LOCAL nWidth := 1.0 / AREA_PANELS, nPanel, nFrom, nHalf, nMiddle, nInner, nOuter := 0.0, aNode, t, aPoint, aStep
   FOR nPanel := 0 TO AREA_PANELS - 1
      nFrom := nWidth * nPanel
      nHalf := 0.5 * nWidth
      nMiddle := nFrom + nHalf
      nInner := 0.0
      FOR EACH aNode IN Ar_Nodes()
         t := nMiddle + nHalf * aNode[1]
         aPoint := Cv_PointAt( c, t ) ; aStep := Cv_TangentAt( c, t )
         nInner += aNode[2] * V2_Cross( aPoint, aStep )
      NEXT
      nOuter += nHalf * nInner
   NEXT
RETURN nOuter * 0.5

STATIC FUNCTION AddMoments( a, b ) ; RETURN { a[1] + b[1], a[2] + b[2], a[3] + b[3] }

STATIC FUNCTION PolySegments( pl )
   LOCAL nV := Len( pl[ PL_VERTS ] )
   IF nV < 2 ; RETURN 0 ; ENDIF
RETURN IIF( pl[ PL_CLOSED ], nV, nV - 1 )

FUNCTION PolylineArea( pl )
   LOCAL nV := Len( pl[ PL_VERTS ] ), nSeg := PolySegments( pl ), nArea := 0.0, i, aStart, aEnd, aArc
   FOR i := 0 TO nSeg - 1
      aStart := pl[ PL_VERTS ][ i + 1 ][ PV_POS ]
      aEnd := pl[ PL_VERTS ][ ( i + 1 ) % nV + 1 ][ PV_POS ]
      aArc := PL_SegmentArc( pl, i )
      IF aArc != NIL
         nArea += CircularArea( aArc[ BA_CENTER ], aArc[ BA_RADIUS ], aArc[ BA_START ], aArc[ BA_START ] + aArc[ BA_SWEEP ] )
      ELSE
         nArea += 0.5 * V2_Cross( aStart, aEnd )
      ENDIF
   NEXT
   IF ! pl[ PL_CLOSED ] .AND. nV >= 2
      nArea += 0.5 * V2_Cross( pl[ PL_VERTS ][ nV ][ PV_POS ], pl[ PL_VERTS ][ 1 ][ PV_POS ] )
   ENDIF
RETURN nArea

STATIC FUNCTION PolylineMoments( pl )
   LOCAL nV := Len( pl[ PL_VERTS ] ), nSeg := PolySegments( pl ), aTotal := { 0.0, 0.0, 0.0 }, i, aStart, aEnd, aArc, aC
   FOR i := 0 TO nSeg - 1
      aStart := pl[ PL_VERTS ][ i + 1 ][ PV_POS ]
      aEnd := pl[ PL_VERTS ][ ( i + 1 ) % nV + 1 ][ PV_POS ]
      aArc := PL_SegmentArc( pl, i )
      aC := IIF( aArc != NIL, BulgeMoments( aArc ), LineMoments( aStart, aEnd ) )
      aTotal := AddMoments( aTotal, aC )
   NEXT
   IF ! pl[ PL_CLOSED ] .AND. nV >= 2
      aTotal := AddMoments( aTotal, LineMoments( pl[ PL_VERTS ][ nV ][ PV_POS ], pl[ PL_VERTS ][ 1 ][ PV_POS ] ) )
   ENDIF
RETURN aTotal

STATIC FUNCTION BulgeMoments( ba )
   LOCAL aF
   aF := IntegratedFirstMoments( {| t | BA_Sample( ba, t ) }, ;
      {| t | BulgeTangent( ba, t ) } )
RETURN { CircularArea( ba[ BA_CENTER ], ba[ BA_RADIUS ], ba[ BA_START ], ba[ BA_START ] + ba[ BA_SWEEP ] ), aF[1], aF[2] }

STATIC FUNCTION BulgeTangent( ba, t )
   LOCAL nAngle := ba[ BA_START ] + ba[ BA_SWEEP ] * t
RETURN { -ba[ BA_RADIUS ] * OCX_SIN( nAngle ) * ba[ BA_SWEEP ], ba[ BA_RADIUS ] * OCX_COS( nAngle ) * ba[ BA_SWEEP ] }

STATIC FUNCTION LineMoments( aStart, aEnd )
   LOCAL aStep := { aEnd[1] - aStart[1], aEnd[2] - aStart[2] }, aF
   aF := IntegratedFirstMoments( {| t | { aStart[1] + aStep[1] * t, aStart[2] + aStep[2] * t } }, {| t | HB_SYMBOL_UNUSED( t ), aStep } )
RETURN { 0.5 * V2_Cross( aStart, aEnd ), aF[1], aF[2] }

STATIC FUNCTION IntegratedFirstMoments( bPoint, bTangent )
   LOCAL nWidth := 1.0 / AREA_PANELS, nPanel, nHalf, nMiddle, aNode, t, aPoint, aStep, nAX := 0.0, nAY := 0.0
   FOR nPanel := 0 TO AREA_PANELS - 1
      nHalf := 0.5 * nWidth
      nMiddle := nWidth * nPanel + nHalf
      FOR EACH aNode IN Ar_Nodes()
         t := nMiddle + nHalf * aNode[1]
         aPoint := Eval( bPoint, t ) ; aStep := Eval( bTangent, t )
         nAX += nHalf * aNode[2] * 0.5 * aPoint[1] * aPoint[1] * aStep[2]
         nAY += -nHalf * aNode[2] * 0.5 * aPoint[2] * aPoint[2] * aStep[1]
      NEXT
   NEXT
RETURN { nAX, nAY }

FUNCTION CircularArea( aCentre, nRadius, nStart, nEnd )
   LOCAL nSweep := nEnd - nStart, nAlong
   nAlong := nRadius * ( aCentre[1] * ( OCX_SIN( nEnd ) - OCX_SIN( nStart ) ) - aCentre[2] * ( OCX_COS( nEnd ) - OCX_COS( nStart ) ) )
RETURN 0.5 * ( nAlong + nRadius * nRadius * nSweep )
