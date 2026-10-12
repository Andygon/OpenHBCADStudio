/* Port de opencadkernel/src/geom2d/dimension.rs (142 lineas, 2 tests ported 1:1). UTF-8.
   Line = { aStart, aEnd }. Devuelve { Line, lUnderText } o NIL. */
#include "ocx.ch"

FUNCTION Dm_LinearLeader( aMeasured, aDef, aAxis, aText, aHalf, nRot )
   LOCAL v, aFr, nFirst, nSecond, nAlong, nMin, nMax, aTA, nHalf, aS, aE, lUnder
   FOR EACH v IN { aMeasured[1], aMeasured[2], aDef, aAxis, aText, aHalf }
      IF ! OCX_ISFINITE( v[1] ) .OR. ! OCX_ISFINITE( v[2] ) ; RETURN NIL ; ENDIF
   NEXT
   IF ! OCX_ISFINITE( nRot ) .OR. aHalf[1] < 0.0 .OR. aHalf[2] < 0.0 ; RETURN NIL ; ENDIF
   aAxis := V2_Normalize( aAxis )
   IF aAxis == NIL ; RETURN NIL ; ENDIF
   aFr := Frame_At( { aDef[1], aDef[2], 0.0 } )
   nFirst := V2_Dot( Frame_Lift2D( aFr, aMeasured[1] ), aAxis )
   nSecond := V2_Dot( Frame_Lift2D( aFr, aMeasured[2] ), aAxis )
   aText := Frame_Lift2D( aFr, aText )
   nAlong := V2_Dot( aText, aAxis )
   nMin := Min( nFirst, nSecond ) ; nMax := Max( nFirst, nSecond )
   aTA := { OCX_COS( nRot ), OCX_SIN( nRot ) }
   nHalf := aHalf[1] * Abs( V2_Dot( aAxis, aTA ) ) + aHalf[2] * Abs( V2_Dot( aAxis, V2_Perpendicular( aTA ) ) )
   DO CASE
   CASE nAlong > nMax
      aS := V2_Mul( aAxis, nMax ) ; aE := V2_Mul( aAxis, nAlong + nHalf ) ; lUnder := .T.
   CASE nAlong < nMin
      aS := V2_Mul( aAxis, nMin ) ; aE := V2_Mul( aAxis, nAlong - nHalf ) ; lUnder := .T.
   OTHERWISE
      aS := V2_Mul( aAxis, nAlong ) ; aE := aText ; lUnder := .F.
   ENDCASE
RETURN { { Frame_Lower2D( aFr, aS ), Frame_Lower2D( aFr, aE ) }, lUnder }
