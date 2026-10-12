/* Port de opencadkernel/src/geom2d/arc_fit.rs (152 lineas, 3 tests ported 1:1). UTF-8.
   ArcFitVertex = { aPoint, nBulge, nSource(base 0), nFraction, lInserted }. */
#include "ocx.ch"
#define AF_POINT 1
#define AF_BULGE 2
#define AF_SOURCE 3
#define AF_FRACTION 4
#define AF_INSERTED 5

STATIC FUNCTION AF_Unit( d )
   LOCAL nLen := V2_Length( d )
   IF OCX_ISFINITE( nLen ) .AND. nLen > 0.000000000001 ; RETURN V2_Div( d, nLen ) ; ENDIF
RETURN NIL

// -> { nBulge, nLength } o NIL
STATIC FUNCTION AF_ArcPiece( aStart, aTan, aEnd )
   LOCAL aChord := V2_Sub( aEnd, aStart ), nLen := V2_Length( aChord ), aArc, nSweep, nSign, nBulge
   IF ! OCX_ISFINITE( nLen ) .OR. nLen <= 0.000000000001 ; RETURN NIL ; ENDIF
   IF Abs( V2_Cross( aTan, aChord ) ) <= nLen * 0.000000000001
      IF V2_Dot( aTan, aChord ) > 0.0 ; RETURN { 0.0, nLen } ; ENDIF
      RETURN NIL
   ENDIF
   aArc := Cs_ArcFromStartTangent( aStart, aTan, aEnd, .F. )
   IF aArc == NIL ; RETURN NIL ; ENDIF
   nSweep := Ar_Sweep( aArc )
   nSign := OCX_SIGNUM( V2_Cross( aTan, aChord ) )
   nBulge := nSign * OCX_TAN( nSweep * 0.25 )
   nLen := aArc[ AR_RADIUS ] * nSweep
   IF OCX_ISFINITE( nBulge ) .AND. OCX_ISFINITE( nLen ) .AND. nLen > 0.0
      RETURN { nBulge, nLen }
   ENDIF
RETURN NIL

FUNCTION AF_FitArcChain( aPts, lClosed, aDirs )
   LOCAL n := Len( aPts ), nSpans, aChords, aTan, i, j, p, aD, aV
   LOCAL p0, p1, t0, t1, d, s0, s1, a, nDisc, aKnee, nReach, r0, r1, c0, c1, aArc, aNormal, aFrom, aTo, nDet, nRad
   LOCAL aFirst, aRev, nTot, nFrac, u
   IF n < 2 .OR. Len( aDirs ) != n ; RETURN NIL ; ENDIF
   FOR EACH p IN aPts
      IF ! OCX_ISFINITE( p[1] ) .OR. ! OCX_ISFINITE( p[2] ) ; RETURN NIL ; ENDIF
   NEXT
   nSpans := IIf( lClosed, n, n - 1 )
   aChords := Array( nSpans )
   FOR i := 0 TO nSpans - 1
      u := AF_Unit( V2_Sub( aPts[ ( i + 1 ) % n + 1 ], aPts[ i + 1 ] ) )
      IF u == NIL ; RETURN NIL ; ENDIF
      aChords[ i + 1 ] := u
   NEXT
   aTan := Array( n )
   AFill( aTan, { 0.0, 0.0 } )
   FOR i := 0 TO n - 1
      IF ! lClosed .AND. ( i == 0 .OR. i + 1 == n ) ; LOOP ; ENDIF
      u := V2_Normalize( V2_Add( aChords[ ( i + nSpans - 1 ) % nSpans + 1 ], aChords[ i % nSpans + 1 ] ) )
      aTan[ i + 1 ] := IIf( u == NIL, aChords[ i % nSpans + 1 ], u )
   NEXT
   IF ! lClosed .AND. n == 2
      aTan[1] := aChords[1] ; aTan[2] := aChords[1]
   ELSEIF ! lClosed
      aTan[1] := V2_Sub( V2_Mul( aChords[1], 2.0 * V2_Dot( aChords[1], aTan[2] ) ), aTan[2] )
      aTan[n] := V2_Sub( V2_Mul( aChords[n-1], 2.0 * V2_Dot( aChords[n-1], aTan[n-1] ) ), aTan[n-1] )
   ENDIF
   FOR i := 1 TO n
      aD := aDirs[ i ]
      IF aD != NIL
         IF ! OCX_ISFINITE( aD[1] ) .OR. ! OCX_ISFINITE( aD[2] ) ; RETURN NIL ; ENDIF
         u := AF_Unit( aD )
         IF u == NIL ; RETURN NIL ; ENDIF
         aTan[ i ] := u
      ENDIF
   NEXT
   aV := {}
   FOR i := 0 TO nSpans - 1
      j := ( i + 1 ) % n
      p0 := aPts[ i + 1 ] ; p1 := aPts[ j + 1 ] ; t0 := aTan[ i + 1 ] ; t1 := aTan[ j + 1 ]
      d := V2_Sub( p1, p0 )
      IF V2_LengthSquared( V2_Sub( aChords[ i + 1 ], t0 ) ) < 0.000000000000000000000001 .AND. ;
         V2_LengthSquared( V2_Sub( aChords[ i + 1 ], t1 ) ) < 0.000000000000000000000001
         AAdd( aV, { p0, 0.0, i, 0.0, .F. } )
         LOOP
      ENDIF
      s0 := V2_Cross( aChords[ i + 1 ], t0 )
      s1 := V2_Cross( aChords[ i + 1 ], t1 )
      IF Abs( s0 ) <= 0.000000000001 .OR. Abs( s1 ) <= 0.000000000001
         AAdd( aV, { p0, 0.0, i, 0.0, .F. } )
         LOOP
      ENDIF
      a := -2.0 * ( 1.0 - Max( -1.0, Min( 1.0, V2_Dot( t0, t1 ) ) ) ) / ( s0 * s1 )
      nDisc := 16.0 - 4.0 * a
      IF nDisc >= -0.000000000001
         nReach := V2_Length( d ) * 2.0 / ( 4.0 + Sqrt( Max( nDisc, 0.0 ) ) )
         r0 := -nReach / s0
         r1 := nReach / s1
         c0 := V2_Add( p0, V2_Mul( V2_Perpendicular( t0 ), r0 ) )
         c1 := V2_Add( p1, V2_Mul( V2_Perpendicular( t1 ), r1 ) )
         IF Abs( r0 - r1 ) <= 0.000000000001 * Max( Max( Abs( r0 ), Abs( r1 ) ), 1.0 )
            aArc := Cs_ArcFromStartTangent( p0, t0, p1, .F. )
            IF aArc == NIL ; RETURN NIL ; ENDIF
            aKnee := Cv_PointAt( Cv_Arc( aArc[1], aArc[2], aArc[3], aArc[4] ), 0.5 )
         ELSE
            aKnee := V2_Div( V2_Sub( V2_Mul( c1, r0 ), V2_Mul( c0, r1 ) ), r0 - r1 )
         ENDIF
      ELSE
         aNormal := V2_Perpendicular( aChords[ i + 1 ] )
         aFrom := V2_Sub( V2_Perpendicular( t0 ), aNormal )
         aTo := V2_Sub( aNormal, V2_Perpendicular( t1 ) )
         nDet := V2_Cross( aFrom, aTo )
         IF Abs( nDet ) <= 0.000000000001 ; RETURN NIL ; ENDIF
         nRad := V2_Cross( d, aTo ) / nDet
         aKnee := V2_Add( p0, V2_Mul( aFrom, nRad ) )
      ENDIF
      IF ! OCX_ISFINITE( aKnee[1] ) .OR. ! OCX_ISFINITE( aKnee[2] ) ; RETURN NIL ; ENDIF
      aFirst := AF_ArcPiece( p0, t0, aKnee )
      IF aFirst == NIL ; RETURN NIL ; ENDIF
      aRev := AF_ArcPiece( p1, V2_Neg( t1 ), aKnee )
      IF aRev == NIL ; RETURN NIL ; ENDIF
      nTot := aFirst[2] + aRev[2]
      IF ! OCX_ISFINITE( nTot ) .OR. nTot <= 0.0 ; RETURN NIL ; ENDIF
      nFrac := aFirst[2] / nTot
      AAdd( aV, { p0, aFirst[1], i, 0.0, .F. } )
      AAdd( aV, { aKnee, -aRev[1], i, nFrac, .T. } )
   NEXT
   IF ! lClosed
      AAdd( aV, { aPts[n], 0.0, n - 1, 0.0, .F. } )
   ENDIF
RETURN aV
