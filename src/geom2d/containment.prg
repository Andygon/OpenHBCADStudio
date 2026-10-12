/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/containment.prg
   Origen Rust: opencadkernel/src/geom2d/containment.rs (396 lineas)
   Estado: TRADUCIDO (tests en tests/t_containment.prg).
   Closest = { nT, aPoint, nDistance }; nearest_of devuelve { nIndex(base 0), Closest } o NIL.
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION Co_At( c, t, aTo )
   LOCAL aP := Cv_PointAt( c, t )
RETURN { t, aP, V2_Distance( aP, aTo ) }

FUNCTION Co_ClosestPoint( c, aTo )
   LOCAL nRaw := Cv_ParameterAt( c, aTo ), nExt := Cv_Extent( c ), aBest, aNext
   DO CASE
   CASE nExt == EXT_INFINITE ; RETURN Co_At( c, nRaw, aTo )
   CASE nExt == EXT_FORWARD  ; RETURN Co_At( c, Max( nRaw, 0.0 ), aTo )
   ENDCASE
   // interior, inicio y fin; se queda con el primero de menor distancia
   aBest := Co_At( c, Max( 0.0, Min( 1.0, nRaw ) ), aTo )
   FOR EACH aNext IN { Co_At( c, 0.0, aTo ), Co_At( c, 1.0, aTo ) }
      IF aNext[ CL_D ] < aBest[ CL_D ] ; aBest := aNext ; ENDIF
   NEXT
RETURN aBest

FUNCTION Co_DistanceTo( c, aPoint ) ; RETURN Co_ClosestPoint( c, aPoint )[ CL_D ]

FUNCTION Co_NearestOf( aCurves, aPoint )
   LOCAL aBest := NIL, i, aCl
   FOR i := 1 TO Len( aCurves )
      aCl := Co_ClosestPoint( aCurves[ i ], aPoint )
      IF aBest == NIL .OR. aCl[ CL_D ] < aBest[ 2 ][ CL_D ]
         aBest := { i - 1, aCl }
      ENDIF
   NEXT
RETURN aBest

STATIC FUNCTION Co_Directions()
RETURN { { 1.0, 0.0 }, { 0.52347, 0.85204 }, { -0.7071067811865475, 0.7071067811865475 }, { 0.31737, -0.94831 } }

FUNCTION Co_Contains( aBoundary, aPoint, nTol )
   LOCAL c, aDir, lInside
   IF Len( aBoundary ) == 0 ; RETURN .F. ; ENDIF
   FOR EACH c IN aBoundary
      IF Co_DistanceTo( c, aPoint ) <= nTol ; RETURN .T. ; ENDIF
   NEXT
   FOR EACH aDir IN Co_Directions()
      lInside := Co_Cast( aBoundary, aPoint, aDir, nTol )
      IF lInside != NIL ; RETURN lInside ; ENDIF
   NEXT
RETURN .F.

// Option<bool>: NIL = direccion degenerada
STATIC FUNCTION Co_Cast( aBoundary, aPoint, aDir, nTol )
   LOCAL aRay := Cv_Ray( aPoint, aDir ), aHits := {}, c, aPieces, p, aAlong, aOff, cr, lAtEnd, aTan, aUnique := {}, h, aKept, lDup
   FOR EACH c IN aBoundary
      IF c[ CV_KIND ] == CV_POLYLINE
         aPieces := Cv_Segments( c )
      ELSE
         aPieces := { c }
      ENDIF
      FOR EACH p IN aPieces
         IF p[ CV_KIND ] == CV_LINE
            aAlong := V2_Sub( p[ CV_DATA ][ LN_END ], p[ CV_DATA ][ LN_START ] )
            aOff := V2_Sub( p[ CV_DATA ][ LN_START ], aPoint )
            IF Abs( V2_Cross( aAlong, aDir ) ) <= 0.000000000001 * V2_Length( aAlong ) .AND. Abs( V2_Cross( aOff, aDir ) ) <= nTol
               RETURN NIL
            ENDIF
         ENDIF
         FOR EACH cr IN Cx_Intersect( aRay, p, nTol )
            lAtEnd := cr[ CR_TB ] <= 0.000001 .OR. cr[ CR_TB ] >= 1.0 - 0.000001
            aTan := Cv_TangentAt( p, cr[ CR_TB ] )
            IF ( lAtEnd .AND. ! Cv_IsClosed( p ) ) .OR. Abs( V2_Cross( aTan, aDir ) ) <= 0.0000000001 * V2_Length( aTan )
               RETURN NIL
            ENDIF
            AAdd( aHits, cr[ CR_POINT ] )
         NEXT
      NEXT
   NEXT
   FOR EACH h IN aHits
      lDup := .F.
      FOR EACH aKept IN aUnique
         IF V2_Distance( aKept, h ) <= nTol ; lDup := .T. ; ENDIF
      NEXT
      IF lDup ; RETURN NIL ; ENDIF
      AAdd( aUnique, h )
   NEXT
RETURN Len( aUnique ) % 2 == 1
