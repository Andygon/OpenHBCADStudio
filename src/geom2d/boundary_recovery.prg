/* Port de opencadkernel/src/geom2d/boundary_recovery.rs (284 lineas, 2 tests ported 1:1). UTF-8.
   curves -> codeblock {|| aCurves }; project -> codeblock {|p| p'}. Presupuestos por referencia: arrays de 1 elemento. */
#include "ocx.ch"
#define MAX_RECOVERY_POINTS 512
#define MAX_EXTRA_POINTS 128
#define MAX_PASSES 16
#define MAX_INTERSECTION_CHECKS 1000000

STATIC FUNCTION BR_D2( a, b ) ; RETURN ( a[1] - b[1] ) ^ 2 + ( a[2] - b[2] ) ^ 2

STATIC FUNCTION BR_Sample( c, aRem )
   LOCAL aPts, nMinX := OCX_INF(), nMaxX := -OCX_INF(), nMinY := OCX_INF(), nMaxY := -OCX_INF(), p, nTol
   IF c[ CV_KIND ] != CV_NURBS
      aPts := Cv_TessellateAngle( c, Tess_DefaultAngle() )
      IF aRem[1] < Len( aPts ) ; RETURN NIL ; ENDIF
      aRem[1] -= Len( aPts )
      RETURN aPts
   ENDIF
   FOR EACH p IN NC_ControlPoints( c[ CV_DATA ] )
      nMinX := Min( nMinX, p[1] ) ; nMaxX := Max( nMaxX, p[1] )
      nMinY := Min( nMinY, p[2] ) ; nMaxY := Max( nMaxY, p[2] )
   NEXT
   nTol := OCX_HYPOT( nMaxX - nMinX, nMaxY - nMinY ) * ( 1.0 - OCX_COS( Tess_DefaultAngle() * 0.5 ) )
   IF ! OCX_ISFINITE( nTol ) .OR. nTol <= 0.0 ; RETURN NIL ; ENDIF
   aPts := Cv_TessellateWithin( c, nTol )
   IF aRem[1] < Len( aPts ) ; RETURN NIL ; ENDIF
   aRem[1] -= Len( aPts )
RETURN aPts

STATIC FUNCTION BR_Chain( aSamples )
   LOCAL aS := {}, x, aChain, aHead, aTail, aBest, i, aPts, aStart, aEnd, aCand, nIdx, lRev, lFront, aNew, k, aFirst
   FOR EACH x IN aSamples
      IF Len( x ) > 0 ; AAdd( aS, x ) ; ENDIF
   NEXT
   IF Len( aS ) == 0 ; RETURN NIL ; ENDIF
   aChain := AClone( ATail( aS ) ) ; ASize( aS, Len( aS ) - 1 )
   DO WHILE Len( aS ) > 0
      aHead := aChain[1] ; aTail := ATail( aChain )
      aBest := { 1.7976931348623157 * OCX_POW( 10.0, 308.0 ), 0, .F., .F. }
      FOR i := 1 TO Len( aS )
         aStart := aS[i][1] ; aEnd := ATail( aS[i] )
         FOR EACH aCand IN { { BR_D2( aTail, aStart ), i, .F., .F. }, { BR_D2( aTail, aEnd ), i, .T., .F. }, ;
                             { BR_D2( aHead, aEnd ), i, .F., .T. }, { BR_D2( aHead, aStart ), i, .T., .T. } }
            IF aCand[1] < aBest[1] ; aBest := aCand ; ENDIF
         NEXT
      NEXT
      nIdx := aBest[2] ; lRev := aBest[3] ; lFront := aBest[4]
      aPts := AClone( aS[ nIdx ] )
      aS[ nIdx ] := ATail( aS ) ; ASize( aS, Len( aS ) - 1 )     // swap_remove
      IF lRev
         aNew := {}
         FOR k := Len( aPts ) TO 1 STEP -1 ; AAdd( aNew, aPts[k] ) ; NEXT
         aPts := aNew
      ENDIF
      IF lFront
         IF BR_D2( ATail( aPts ), aHead ) < 0.000000000000000001
            ASize( aPts, Len( aPts ) - 1 )
         ENDIF
         aNew := {}
         FOR EACH x IN aPts ; AAdd( aNew, x ) ; NEXT
         FOR EACH x IN aChain ; AAdd( aNew, x ) ; NEXT
         aChain := aNew
      ELSE
         k := 1
         IF Len( aPts ) > 0
            aFirst := aPts[1] ; k := 2
            IF BR_D2( aFirst, aTail ) >= 0.000000000000000001 ; AAdd( aChain, aFirst ) ; ENDIF
         ENDIF
         DO WHILE k <= Len( aPts )
            AAdd( aChain, aPts[k] ) ; k++
         ENDDO
      ENDIF
   ENDDO
RETURN aChain

// -> aMarked (array de logicos por arista) o NIL
STATIC FUNCTION BR_Crossings( aEdges, bProject, aWork )
   LOCAL aMarked := Array( Len( aEdges ) ), lProj, aSegs, e, i, j, pr, a, b, c, d, nRight, nOther, aO
   AFill( aMarked, .F. )
   FOR EACH lProj IN { .F., .T. }
      aSegs := {}
      FOR e := 1 TO Len( aEdges )
         pr := aEdges[ e ]
         FOR i := 1 TO Len( pr ) - 1
            a := pr[ i ] ; b := pr[ i + 1 ]
            IF lProj ; a := Eval( bProject, a ) ; b := Eval( bProject, b ) ; ENDIF
            IF ! OCX_ISFINITE( a[1] ) .OR. ! OCX_ISFINITE( a[2] ) .OR. ! OCX_ISFINITE( b[1] ) .OR. ! OCX_ISFINITE( b[2] ) ; RETURN NIL ; ENDIF
            AAdd( aSegs, { Min( a[1], b[1] ), Max( a[1], b[1] ), e, a, b } )
         NEXT
      NEXT
      ASort( aSegs,,, {| x, y | x[1] < y[1] } )
      FOR i := 1 TO Len( aSegs )
         nRight := aSegs[i][2] ; e := aSegs[i][3] ; a := aSegs[i][4] ; b := aSegs[i][5]
         FOR j := i + 1 TO Len( aSegs )
            aO := aSegs[j]
            IF aO[1] > nRight ; EXIT ; ENDIF
            IF aWork[1] == 0 ; RETURN NIL ; ENDIF
            aWork[1]--
            nOther := aO[3] ; c := aO[4] ; d := aO[5]
            IF Max( a[2], b[2] ) < Min( c[2], d[2] ) .OR. Max( c[2], d[2] ) < Min( a[2], b[2] ) ; LOOP ; ENDIF
            IF ( BR_Opp( BR_Cr( a, b, c ), BR_Cr( a, b, d ) ) .AND. BR_Opp( BR_Cr( c, d, a ), BR_Cr( c, d, b ) ) ) .OR. ;
               BR_Inside( a, c, d ) .OR. BR_Inside( b, c, d ) .OR. BR_Inside( c, a, b ) .OR. BR_Inside( d, a, b ) .OR. ;
               ( ! BR_Eq( a, b ) .AND. ( ( BR_Eq( a, c ) .AND. BR_Eq( b, d ) ) .OR. ( BR_Eq( a, d ) .AND. BR_Eq( b, c ) ) ) )
               aMarked[ e ] := .T. ; aMarked[ nOther ] := .T.
            ENDIF
         NEXT
      NEXT
   NEXT
RETURN aMarked

STATIC FUNCTION BR_Eq( a, b ) ; RETURN a[1] == b[1] .AND. a[2] == b[2]
STATIC FUNCTION BR_Cr( a, b, c ) ; RETURN ( b[1] - a[1] ) * ( c[2] - a[2] ) - ( b[2] - a[2] ) * ( c[1] - a[1] )
STATIC FUNCTION BR_Opp( a, b ) ; RETURN ( a < 0.0 .AND. b > 0.0 ) .OR. ( a > 0.0 .AND. b < 0.0 )
STATIC FUNCTION BR_Inside( p, a, b )
   LOCAL ax
   IF BR_Cr( a, b, p ) != 0.0 ; RETURN .F. ; ENDIF
   FOR ax := 1 TO 2
      IF p[ax] > Min( a[ax], b[ax] ) .AND. p[ax] < Max( a[ax], b[ax] ) ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.

FUNCTION BR_RefineSplineBoundary( aRing, bCurves, bProject )
   LOCAL aWork := { MAX_INTERSECTION_CHECKS }, aM, aProjected, p, nLimit, aSpans := {}, c, aDom, nStart, nEnd, aKn, i, t, aRem, aPts := {}, nPass
   LOCAL aMarked, aNext, aSampled, lChanged, aSp, part, aRing2, k, sp
   IF Len( aRing ) > MAX_RECOVERY_POINTS ; RETURN NIL ; ENDIF
   aM := BR_Crossings( { aRing }, bProject, aWork )
   IF aM == NIL .OR. ! aM[1] ; RETURN NIL ; ENDIF
   aProjected := {}
   FOR EACH p IN aRing ; AAdd( aProjected, Eval( bProject, p ) ) ; NEXT
   IF Len( Tg_Rings( { aProjected } )[2] ) > 0 ; RETURN NIL ; ENDIF
   nLimit := Min( Len( aRing ) + MAX_EXTRA_POINTS, MAX_RECOVERY_POINTS )
   FOR EACH c IN Eval( bCurves )
      IF c[ CV_KIND ] == CV_NURBS
         sp := c[ CV_DATA ]
         aDom := NC_Domain( sp ) ; nStart := aDom[1] ; nEnd := aDom[2]
         IF nEnd <= nStart .OR. Len( NC_ControlPoints( sp ) ) > nLimit ; RETURN NIL ; ENDIF
         aKn := NC_Knots( sp )
         FOR i := 1 TO Len( aKn ) - 1
            IF aKn[i] >= nStart .AND. aKn[i+1] <= nEnd .AND. aKn[i] < aKn[i+1]
               t := NC_Trimmed( sp, ( aKn[i] - nStart ) / ( nEnd - nStart ), ( aKn[i+1] - nStart ) / ( nEnd - nStart ) )
               IF t == NIL ; RETURN NIL ; ENDIF
               AAdd( aSpans, Cv_Nurbs( t ) )
            ENDIF
         NEXT
      ELSE
         AAdd( aSpans, c )
      ENDIF
   NEXT
   aRem := { nLimit }
   FOR EACH c IN aSpans
      t := BR_Sample( c, aRem )
      IF t == NIL ; RETURN NIL ; ENDIF
      AAdd( aPts, t )
   NEXT
   FOR nPass := 1 TO MAX_PASSES
      aMarked := BR_Crossings( aPts, bProject, aWork )
      IF aMarked == NIL ; RETURN NIL ; ENDIF
      IF AScan( aMarked, {| x | x } ) == 0
         aRing2 := BR_Chain( aPts )
         IF aRing2 == NIL ; RETURN NIL ; ENDIF
         aProjected := {}
         FOR EACH p IN aRing2 ; AAdd( aProjected, Eval( bProject, p ) ) ; NEXT
         IF Len( Tg_Rings( { aProjected } )[2] ) > 0 ; RETURN aRing2 ; ENDIF
         RETURN NIL
      ENDIF
      aNext := {} ; aSampled := {} ; lChanged := .F. ; aRem := { nLimit }
      FOR k := 1 TO Len( aSpans )
         c := aSpans[k]
         IF aMarked[k] .AND. c[ CV_KIND ] == CV_NURBS
            aSp := NC_SplitAt( c[ CV_DATA ], 0.5 )
            IF aSp == NIL ; RETURN NIL ; ENDIF
            FOR EACH part IN { Cv_Nurbs( aSp[1] ), Cv_Nurbs( aSp[2] ) }
               t := BR_Sample( part, aRem )
               IF t == NIL ; RETURN NIL ; ENDIF
               AAdd( aSampled, t ) ; AAdd( aNext, part )
            NEXT
            lChanged := .T.
            LOOP
         ENDIF
         IF aRem[1] < Len( aPts[k] ) ; RETURN NIL ; ENDIF
         aRem[1] -= Len( aPts[k] )
         AAdd( aNext, c ) ; AAdd( aSampled, aPts[k] )
      NEXT
      IF ! lChanged ; RETURN NIL ; ENDIF
      aSpans := aNext ; aPts := aSampled
   NEXT
RETURN NIL
