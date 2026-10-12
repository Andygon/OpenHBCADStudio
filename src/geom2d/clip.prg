/* Port de opencadkernel/src/geom2d/clip.rs (442 lineas, 14 tests ported 1:1). UTF-8.
   Span = { nFrom, nTo }; Tolerance = numero. Prefijo Cp_. */
#include "ocx.ch"

STATIC FUNCTION Cp_Dedup( a, nMerge )
   LOCAL r := {}, x
   FOR EACH x IN a
      IF Len( r ) == 0 .OR. ! ( Abs( x - ATail( r ) ) <= nMerge )
         AAdd( r, x )
      ENDIF
   NEXT
RETURN r

FUNCTION Cp_BreakSpans( c, nFirst, nSecond, nTol )
   LOCAL a, b, nSpeed, nEps, aSp, nLo, nHi, nRem, lClosed
   IF Cv_Extent( c ) != EXT_BOUNDED .OR. ! OCX_ISFINITE( nFirst ) .OR. ! OCX_ISFINITE( nSecond ) ; RETURN NIL ; ENDIF
   a := Max( 0.0, Min( 1.0, nFirst ) )
   b := Max( 0.0, Min( 1.0, nSecond ) )
   nSpeed := Max( V2_Length( Cv_TangentAt( c, a ) ), V2_Length( Cv_TangentAt( c, b ) ) )
   IF ! OCX_ISFINITE( nSpeed ) .OR. nSpeed <= 0.0 ; RETURN NIL ; ENDIF
   nEps := Min( nTol / nSpeed, 1.0 )
   lClosed := Cv_IsClosed( c )
   IF lClosed
      IF c[ CV_KIND ] == CV_POLYLINE .AND. Abs( a - b ) <= nEps
         aSp := {}
         IF a > nEps ; AAdd( aSp, { 0.0, a } ) ; ENDIF
         IF 1.0 - a > nEps ; AAdd( aSp, { a, 1.0 } ) ; ENDIF
         RETURN aSp
      ENDIF
      nRem := OCX_REMEUCLID( b - a, 1.0 )
      IF nRem <= nEps .OR. 1.0 - nRem <= nEps ; RETURN NIL ; ENDIF
      RETURN { { b, b + 1.0 - nRem } }
   ENDIF
   IF a <= b ; nLo := a ; nHi := b ; ELSE ; nLo := b ; nHi := a ; ENDIF
   aSp := {}
   IF nLo > nEps ; AAdd( aSp, { 0.0, nLo } ) ; ENDIF
   IF 1.0 - nHi > nEps ; AAdd( aSp, { nHi, 1.0 } ) ; ENDIF
RETURN aSp

FUNCTION Cp_TrimSpans( c, aCuts, nPicked, nTol )
   LOCAL nExt := Cv_Extent( c ), nFirst, nLast, nSpeed, nMerge, aB, x, i, nRemoved := 0, aKept
   IF ! OCX_ISFINITE( nPicked ) ; RETURN {} ; ENDIF
   DO CASE
   CASE nExt == EXT_BOUNDED  ; nFirst := 0.0 ; nLast := 1.0
   CASE nExt == EXT_FORWARD  ; nFirst := 0.0 ; nLast := OCX_INF()
   OTHERWISE                 ; nFirst := -OCX_INF() ; nLast := OCX_INF()
   ENDCASE
   DO CASE
   CASE nExt == EXT_BOUNDED ; nPicked := Max( 0.0, Min( 1.0, nPicked ) )
   CASE nExt == EXT_FORWARD ; nPicked := Max( nPicked, 0.0 )
   ENDCASE
   nSpeed := V2_Length( Cv_TangentAt( c, nPicked ) )
   nMerge := IIf( nSpeed > 0.0, Min( nTol / nSpeed, 1.0 ), nTol )
   aB := { nFirst }
   FOR EACH x IN aCuts
      IF OCX_ISFINITE( x ) .AND. Ext_Holds( nExt, x )
         DO CASE
         CASE nExt == EXT_BOUNDED ; AAdd( aB, Max( 0.0, Min( 1.0, x ) ) )
         CASE nExt == EXT_FORWARD ; AAdd( aB, Max( x, 0.0 ) )
         OTHERWISE                ; AAdd( aB, x )
         ENDCASE
      ENDIF
   NEXT
   AAdd( aB, nLast )
   ASort( aB )
   aB := Cp_Dedup( aB, nMerge )
   FOR i := 1 TO Len( aB ) - 1
      IF nPicked >= aB[ i ] - nMerge .AND. nPicked <= aB[ i + 1 ] + nMerge
         nRemoved := i ; EXIT
      ENDIF
   NEXT
   IF nRemoved == 0 ; RETURN {} ; ENDIF
   aKept := {}
   IF aB[ nRemoved ] - nFirst > nMerge ; AAdd( aKept, { nFirst, aB[ nRemoved ] } ) ; ENDIF
   IF nLast - aB[ nRemoved + 1 ] > nMerge ; AAdd( aKept, { aB[ nRemoved + 1 ], nLast } ) ; ENDIF
RETURN aKept

FUNCTION Cp_InsideSpans( aBoundary, c, nTol )
   LOCAL aCuts := {}, e, cr, nSpeed, nMerge, aSp := {}, i, nMid, aPrev
   IF Len( aBoundary ) == 0 ; RETURN {} ; ENDIF
   FOR EACH e IN aBoundary
      FOR EACH cr IN Cx_Intersect( c, e, nTol )
         AAdd( aCuts, cr[ CR_TA ] )
      NEXT
   NEXT
   IF Len( aCuts ) == 0
      IF Cv_Extent( c ) == EXT_BOUNDED .AND. Co_Contains( aBoundary, Cv_PointAt( c, 0.5 ), nTol )
         RETURN { { 0.0, 1.0 } }
      ENDIF
      RETURN {}
   ENDIF
   IF Cv_Extent( c ) == EXT_BOUNDED
      AAdd( aCuts, 0.0 ) ; AAdd( aCuts, 1.0 )
   ENDIF
   ASort( aCuts )
   nSpeed := V2_Length( Cv_TangentAt( c, 0.5 ) )
   nMerge := IIf( nSpeed > 0.0, nTol / nSpeed, nTol )
   aCuts := Cp_Dedup( aCuts, nMerge )
   FOR i := 1 TO Len( aCuts ) - 1
      nMid := 0.5 * ( aCuts[ i ] + aCuts[ i + 1 ] )
      IF ! Co_Contains( aBoundary, Cv_PointAt( c, nMid ), nTol ) ; LOOP ; ENDIF
      IF Len( aSp ) > 0 .AND. Abs( ATail( aSp )[ 2 ] - aCuts[ i ] ) <= nMerge
         aPrev := ATail( aSp )
         aPrev[ 2 ] := aCuts[ i + 1 ]
      ELSE
         AAdd( aSp, { aCuts[ i ], aCuts[ i + 1 ] } )
      ENDIF
   NEXT
RETURN aSp

FUNCTION Cp_InsidePieces( aBoundary, c, nTol )
   LOCAL aOut := {}, s
   FOR EACH s IN Cp_InsideSpans( aBoundary, c, nTol )
      AAdd( aOut, { Cv_PointAt( c, s[1] ), Cv_PointAt( c, s[2] ) } )
   NEXT
RETURN aOut
