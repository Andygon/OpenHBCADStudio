/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/cross.prg
   Origen Rust: opencadkernel/src/geom2d/cross.rs (860 lineas)
   Estado: TRADUCIDO (tests portados en tests/t_cross.prg; los 2 tests que usan
   NurbsCurve::interpolate estan pendientes y sustituidos por [extra] con NC_New).
   Crossing = { aPoint, nTA, nTB }. Tolerance = numero (nLinear).
   sort_by/dedup_by de Rust: ordenacion ESTABLE (con desempate por indice) y
   dedup contra el ultimo retenido.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define CR_MAX_DEPTH 40

FUNCTION Cx_Intersect( a, b, nTol )
   LOCAL aAnch, aFrame, aOrigin, aShift, aLa, aLb, aCr, cr
   aAnch := { { Cv_PointAt( a, 0.0 )[1], Cv_PointAt( a, 0.0 )[2], 0.0 }, { Cv_PointAt( b, 0.0 )[1], Cv_PointAt( b, 0.0 )[2], 0.0 } }
   aFrame := Frame_Around( aAnch ) ; aOrigin := Frame_Origin( aFrame )
   IF Max( Abs( aOrigin[1] ), Abs( aOrigin[2] ) ) < 1000.0
      RETURN Cx_IntersectLocal( a, b, nTol )
   ENDIF
   aShift := Tr_Translation( { -aOrigin[1], -aOrigin[2] } )
   aLa := Cv_Transformed( a, aShift ) ; aLb := Cv_Transformed( b, aShift )
   IF aLa == NIL .OR. aLb == NIL
      RETURN Cx_IntersectLocal( a, b, nTol )
   ENDIF
   aCr := Cx_IntersectLocal( aLa, aLb, nTol )
   FOR EACH cr IN aCr
      cr[ CR_POINT ] := { cr[ CR_POINT ][1] + aOrigin[1], cr[ CR_POINT ][2] + aOrigin[2] }
   NEXT
RETURN aCr

STATIC FUNCTION Cx_IntersectLocal( a, b, nTol )
   LOCAL aCr := {}, aPt, nTA, nTB, aOut := {}, i
   FOR EACH aPt IN Cx_Candidates( a, b, nTol )
      nTA := Cx_OnCurve( a, aPt, nTol )
      IF nTA == NIL ; LOOP ; ENDIF
      nTB := Cx_OnCurve( b, aPt, nTol )
      IF nTB == NIL ; LOOP ; ENDIF
      AAdd( aCr, { aPt, nTA, nTB, Len( aCr ) } )
   NEXT
   // sort estable por t_a
   ASort( aCr,,, {| x, y | x[ CR_TA ] < y[ CR_TA ] .OR. ( x[ CR_TA ] == y[ CR_TA ] .AND. x[ 4 ] < y[ 4 ] ) } )
   // dedup_by( |x, y| dist(x, y) <= tol ): x actual, y ultimo retenido
   FOR i := 1 TO Len( aCr )
      IF Len( aOut ) > 0 .AND. V2_Distance( aCr[ i ][ CR_POINT ], ATail( aOut )[ CR_POINT ] ) <= nTol
         LOOP
      ENDIF
      AAdd( aOut, { aCr[ i ][ 1 ], aCr[ i ][ 2 ], aCr[ i ][ 3 ] } )
   NEXT
RETURN aOut

STATIC FUNCTION Cx_OnCurve( c, aPoint, nTol )
   LOCAL t := Cv_ParameterAt( c, aPoint )
   // un parametro fuera del extent: el cruce esta en la prolongacion
   IF ! Cv_IsClosed( c ) .AND. ! Ext_Holds( Cv_Extent( c ), t )
      RETURN NIL
   ENDIF
   // evaluar el parametro debe volver al punto de partida
   IF V2_Distance( Cv_PointAt( c, t ), aPoint ) > nTol
      RETURN NIL
   ENDIF
   IF Cv_Extent( c ) == EXT_BOUNDED
      RETURN Max( 0.0, Min( 1.0, t ) )
   ENDIF
RETURN t

STATIC FUNCTION Cx_Round( c ) ; RETURN c[ CV_KIND ] == CV_CIRCLE .OR. c[ CV_KIND ] == CV_ARC

STATIC FUNCTION Cx_CircleOf( c )
   IF c[ CV_KIND ] == CV_CIRCLE
      RETURN { c[ CV_DATA ][ CI_CENTRE ], c[ CV_DATA ][ CI_RADIUS ] }
   ENDIF
RETURN { c[ CV_DATA ][ AR_CENTRE ], c[ CV_DATA ][ AR_RADIUS ] }

STATIC FUNCTION Cx_Candidates( a, b, nTol )
   LOCAL aPR, aQR, p, d, q, e, aHit, aCo, aOut := {}, t, aNear, aPiece, lKeep, ax, aLow, aHigh, aFrom, h
   LOCAL ka := a[ CV_KIND ], kb := b[ CV_KIND ], aC1, aC2
   IF Cv_IsStraight( a ) .AND. Cv_IsStraight( b )
      aPR := Cv_AsRay( a ) ; aQR := Cv_AsRay( b )
      p := aPR[1] ; d := aPR[2] ; q := aQR[1] ; e := aQR[2]
      aHit := Ix_LineLine( p, d, q, e )
      IF aHit == NIL ; RETURN {} ; ENDIF
      RETURN { { p[1] + aHit[1] * d[1], p[2] + aHit[1] * d[2] } }
   ENDIF
   IF Cv_IsStraight( a ) .AND. Cx_Round( b )
      aPR := Cv_AsRay( a ) ; p := aPR[1] ; d := aPR[2]
      aCo := Cx_CircleOf( b )
      FOR EACH t IN Ix_LineCircle( p, d, aCo[1], aCo[2] )
         AAdd( aOut, { p[1] + t * d[1], p[2] + t * d[2] } )
      NEXT
      RETURN aOut
   ENDIF
   IF Cx_Round( a ) .AND. Cv_IsStraight( b )
      RETURN Cx_Candidates( b, a, nTol )
   ENDIF
   IF kb == CV_ELLIPSE .AND. Cv_IsStraight( a )
      aPR := Cv_AsRay( a ) ; p := aPR[1] ; d := aPR[2]
      FOR EACH h IN Ix_LineEllipse( p, d, b[ CV_DATA ][ EA_ELLIPSE ] )
         AAdd( aOut, Ell_PointAt( b[ CV_DATA ][ EA_ELLIPSE ], h[2] ) )
      NEXT
      RETURN aOut
   ENDIF
   IF ka == CV_ELLIPSE .AND. Cv_IsStraight( b )
      RETURN Cx_Candidates( b, a, nTol )
   ENDIF
   IF Cx_Round( a ) .AND. Cx_Round( b )
      aC1 := Cx_CircleOf( a ) ; aC2 := Cx_CircleOf( b )
      RETURN Ix_CircleCirclePoints( aC1[1], aC1[2], aC2[1], aC2[2] )
   ENDIF
   IF ka == CV_ELLIPSE .AND. Cx_Round( b )
      aCo := Cx_CircleOf( b )
      FOR EACH h IN Ix_EllipseCircle( a[ CV_DATA ][ EA_ELLIPSE ], aCo[1], aCo[2] )
         AAdd( aOut, Ell_PointAt( a[ CV_DATA ][ EA_ELLIPSE ], h[2] ) )
      NEXT
      RETURN aOut
   ENDIF
   IF kb == CV_ELLIPSE .AND. Cx_Round( a )
      RETURN Cx_Candidates( b, a, nTol )
   ENDIF
   IF ka == CV_POLYLINE
      // se desarma la polilinea, pero solo las piezas cercanas a b
      aNear := AnalyticCurveBounds( { b } )
      FOR EACH aPiece IN Cv_Segments( a )
         lKeep := .T.
         aFrom := AnalyticCurveBounds( { aPiece } )
         IF aNear != NIL .AND. aFrom != NIL
            aLow := aNear[1] ; aHigh := aNear[2]
            FOR ax := 1 TO 2
               IF ! ( aFrom[1][ax] <= aHigh[ax] + nTol .AND. aFrom[2][ax] >= aLow[ax] - nTol )
                  lKeep := .F.
               ENDIF
            NEXT
         ENDIF
         IF lKeep
            FOR EACH h IN Cx_Candidates( aPiece, b, nTol ) ; AAdd( aOut, h ) ; NEXT
         ENDIF
      NEXT
      RETURN aOut
   ENDIF
   IF kb == CV_POLYLINE
      RETURN Cx_Candidates( b, a, nTol )
   ENDIF
RETURN Cx_Subdivided( a, b, nTol )

// ---- Piece = { nFrom, nTo, aStart, aEnd, aLow, aHigh, nBow } -----------------
#define PC_FROM  1
#define PC_TO    2
#define PC_START 3
#define PC_END   4
#define PC_LOW   5
#define PC_HIGH  6
#define PC_BOW   7

STATIC FUNCTION Pc_Of( c, nFrom, nTo )
   LOCAL aS := Cv_PointAt( c, nFrom ), aE := Cv_PointAt( c, nTo ), nBow := 0.0, aLow, aHigh, nStep, aP
   aLow := { Min( aS[1], aE[1] ), Min( aS[2], aE[2] ) }
   aHigh := { Max( aS[1], aE[1] ), Max( aS[2], aE[2] ) }
   FOR nStep := 1 TO 3
      aP := Cv_PointAt( c, nFrom + ( nTo - nFrom ) * nStep / 4.0 )
      nBow := Max( nBow, V2_DistanceToSegment( aP, aS, aE ) )
      aLow := { Min( aLow[1], aP[1] ), Min( aLow[2], aP[2] ) }
      aHigh := { Max( aHigh[1], aP[1] ), Max( aHigh[2], aP[2] ) }
   NEXT
RETURN { nFrom, nTo, aS, aE, { aLow[1] - nBow, aLow[2] - nBow }, { aHigh[1] + nBow, aHigh[2] + nBow }, nBow }

STATIC FUNCTION Pc_Overlaps( p, o )
RETURN p[PC_LOW][1] <= o[PC_HIGH][1] .AND. o[PC_LOW][1] <= p[PC_HIGH][1] .AND. p[PC_LOW][2] <= o[PC_HIGH][2] .AND. o[PC_LOW][2] <= p[PC_HIGH][2]

STATIC FUNCTION Pc_Middle( p ) ; RETURN ( p[PC_FROM] + p[PC_TO] ) * 0.5

STATIC FUNCTION Cx_Subdivided( a, b, nTol )
   LOCAL aOut := {}, aR
   aR := Cv_AsRay( a )
   IF aR != NIL
      Cx_AgainstStraight( aR[1], aR[2], b, Pc_Of( b, 0.0, 1.0 ), a, nTol, 0, aOut )
      RETURN aOut
   ENDIF
   aR := Cv_AsRay( b )
   IF aR != NIL
      Cx_AgainstStraight( aR[1], aR[2], a, Pc_Of( a, 0.0, 1.0 ), b, nTol, 0, aOut )
      RETURN aOut
   ENDIF
   Cx_Descend( a, Pc_Of( a, 0.0, 1.0 ), b, Pc_Of( b, 0.0, 1.0 ), nTol, 0, aOut )
RETURN aOut

STATIC FUNCTION Cx_Side( aOrigin, aDir, aP )
RETURN V2_Cross( aDir, V2_Sub( aP, aOrigin ) )

STATIC FUNCTION Cx_AgainstStraight( aOrigin, aDir, c, piece, straight, nTol, nDepth, aOut )
   LOCAL aCorners, aChord, aHit, nU, nGuess, aPt, nMid, nSlack := 0.000000001, lPos, lNeg, s
   aCorners := { Cx_Side( aOrigin, aDir, { piece[PC_LOW][1], piece[PC_LOW][2] } ), ;
                 Cx_Side( aOrigin, aDir, { piece[PC_HIGH][1], piece[PC_LOW][2] } ), ;
                 Cx_Side( aOrigin, aDir, { piece[PC_LOW][1], piece[PC_HIGH][2] } ), ;
                 Cx_Side( aOrigin, aDir, { piece[PC_HIGH][1], piece[PC_HIGH][2] } ) }
   lPos := .T. ; lNeg := .T.
   FOR EACH s IN aCorners
      IF ! ( s > 0.0 ) ; lPos := .F. ; ENDIF
      IF ! ( s < 0.0 ) ; lNeg := .F. ; ENDIF
   NEXT
   IF lPos .OR. lNeg ; RETURN NIL ; ENDIF
   IF nDepth >= CR_MAX_DEPTH .OR. piece[PC_BOW] <= nTol
      aChord := V2_Sub( piece[PC_END], piece[PC_START] )
      aHit := Ix_LineLine( aOrigin, aDir, piece[PC_START], aChord )
      IF aHit == NIL ; RETURN NIL ; ENDIF
      nU := aHit[2]
      IF ! ( nU >= -nSlack .AND. nU <= 1.0 + nSlack ) ; RETURN NIL ; ENDIF
      nGuess := piece[PC_FROM] + nU * ( piece[PC_TO] - piece[PC_FROM] )
      aPt := Cx_Refine( c, straight, nGuess, nTol )
      IF aPt != NIL ; AAdd( aOut, aPt ) ; ENDIF
      RETURN NIL
   ENDIF
   nMid := Pc_Middle( piece )
   Cx_AgainstStraight( aOrigin, aDir, c, Pc_Of( c, piece[PC_FROM], nMid ), straight, nTol, nDepth + 1, aOut )
   Cx_AgainstStraight( aOrigin, aDir, c, Pc_Of( c, nMid, piece[PC_TO] ), straight, nTol, nDepth + 1, aOut )
RETURN NIL

STATIC FUNCTION Cx_Descend( a, pa, b, pb, nTol, nDepth, aOut )
   LOCAL d, e, aHit, nSlack := 0.000000001, nGuess, aPt, nMid
   IF ! Pc_Overlaps( pa, pb ) ; RETURN NIL ; ENDIF
   IF nDepth >= CR_MAX_DEPTH .OR. ( pa[PC_BOW] <= nTol .AND. pb[PC_BOW] <= nTol )
      d := V2_Sub( pa[PC_END], pa[PC_START] ) ; e := V2_Sub( pb[PC_END], pb[PC_START] )
      aHit := Ix_LineLine( pa[PC_START], d, pb[PC_START], e )
      IF aHit == NIL ; RETURN NIL ; ENDIF
      IF ! ( aHit[1] >= -nSlack .AND. aHit[1] <= 1.0 + nSlack ) .OR. ! ( aHit[2] >= -nSlack .AND. aHit[2] <= 1.0 + nSlack )
         RETURN NIL
      ENDIF
      nGuess := pa[PC_FROM] + aHit[1] * ( pa[PC_TO] - pa[PC_FROM] )
      aPt := Cx_Refine( a, b, nGuess, nTol )
      IF aPt != NIL ; AAdd( aOut, aPt ) ; ENDIF
      RETURN NIL
   ENDIF
   // se parte la pieza que mas se curva
   IF pa[PC_BOW] >= pb[PC_BOW]
      nMid := Pc_Middle( pa )
      Cx_Descend( a, Pc_Of( a, pa[PC_FROM], nMid ), b, pb, nTol, nDepth + 1, aOut )
      Cx_Descend( a, Pc_Of( a, nMid, pa[PC_TO] ), b, pb, nTol, nDepth + 1, aOut )
   ELSE
      nMid := Pc_Middle( pb )
      Cx_Descend( a, pa, b, Pc_Of( b, pb[PC_FROM], nMid ), nTol, nDepth + 1, aOut )
      Cx_Descend( a, pa, b, Pc_Of( b, nMid, pb[PC_TO] ), nTol, nDepth + 1, aOut )
   ENDIF
RETURN NIL

STATIC FUNCTION Cx_Refine( a, b, nGuess, nTol )
   LOCAL aPoint := Cv_PointAt( a, nGuess ), i, aOnB, aOnA, nGap, nMoved
   FOR i := 1 TO 40
      aOnB := Cv_PointAt( b, Cv_ParameterAt( b, aPoint ) )
      aOnA := Cv_PointAt( a, Cv_ParameterAt( a, aOnB ) )
      nGap := V2_Distance( aOnA, aOnB )
      nMoved := V2_Distance( aOnA, aPoint )
      aPoint := aOnA
      IF nGap <= nTol ; RETURN aPoint ; ENDIF
      IF nMoved <= nTol * 0.001 ; RETURN NIL ; ENDIF
   NEXT
   IF V2_Distance( Cv_PointAt( a, Cv_ParameterAt( a, aPoint ) ), Cv_PointAt( b, Cv_ParameterAt( b, aPoint ) ) ) <= nTol
      RETURN aPoint
   ENDIF
RETURN NIL
