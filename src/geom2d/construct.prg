/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/construct.prg
   Origen Rust: opencadkernel/src/geom2d/construct.rs (195 lineas)
   Estado: TRADUCIDO. El original NO tiene tests: tests/t_construct.prg son [extra].
   Arc = { aCentre, nRadius, nStartAngle, nEndAngle } (como Cv_Arc data).
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define CS_ANGLE_EPS 0.000000001

FUNCTION Cs_BoundedArc( aCentre, nRadius, nStart, nEnd )
   LOCAL nSweep
   IF ! ( OCX_ISFINITE( nRadius ) .AND. OCX_ISFINITE( nStart ) .AND. OCX_ISFINITE( nEnd ) )
      RETURN NIL
   ENDIF
   nSweep := OCX_REMEUCLID( nEnd - nStart, OCX_TAU )
   IF nRadius <= CS_ANGLE_EPS .OR. nSweep <= CS_ANGLE_EPS ; RETURN NIL ; ENDIF
RETURN { aCentre, nRadius, nStart, nEnd }

STATIC FUNCTION Cs_StoredArc( aStart, aEnd, nBulge )
   LOCAL ba := BA_FromBulge( aStart, aEnd, nBulge ), nS, nE
   IF ba == NIL ; RETURN NIL ; ENDIF
   IF ba[ BA_SWEEP ] > 0.0
      nS := ba[ BA_START ] ; nE := ba[ BA_END ]
   ELSE
      nS := ba[ BA_END ] ; nE := ba[ BA_START ]
   ENDIF
RETURN { ba[ BA_CENTER ], ba[ BA_RADIUS ], nS, nE }

FUNCTION Cs_ArcFromEndpointsAngle( aStart, aEnd, nIncluded )
   LOCAL nSweep
   IF ! OCX_ISFINITE( nIncluded ) ; RETURN NIL ; ENDIF
   nSweep := Abs( nIncluded )
   IF nSweep <= CS_ANGLE_EPS .OR. nSweep >= OCX_TAU - CS_ANGLE_EPS ; RETURN NIL ; ENDIF
RETURN Cs_StoredArc( aStart, aEnd, OCX_TAN( nIncluded * 0.25 ) )

FUNCTION Cs_ArcFromEndpointsRadius( aStart, aEnd, nSignedRadius )
   LOCAL nChord := V2_Distance( aStart, aEnd ), nRadius := Abs( nSignedRadius ), nSignedChord, nSweep
   IF ! OCX_ISFINITE( nRadius ) .OR. nRadius <= CS_ANGLE_EPS .OR. nChord > 2.0 * nRadius ; RETURN NIL ; ENDIF
   nSignedChord := IIF( nSignedRadius < 0.0, -nChord, nChord )
   nSweep := Cs_ArcSweepFromChord( nRadius, nSignedChord )
   IF nSweep == NIL ; RETURN NIL ; ENDIF
RETURN Cs_ArcFromEndpointsAngle( aStart, aEnd, nSweep )

FUNCTION Cs_ArcFromSagitta( aStart, aEnd, nSagitta )
   LOCAL nChord := V2_Distance( aStart, aEnd )
   IF ! OCX_ISFINITE( nSagitta ) .OR. nChord <= CS_ANGLE_EPS ; RETURN NIL ; ENDIF
RETURN Cs_StoredArc( aStart, aEnd, -2.0 * nSagitta / nChord )

FUNCTION Cs_ArcFromStartTangent( aStart, aTangent, aEnd, lFlip )
   LOCAL aT := V2_Normalize( aTangent ), aChord, nChSq, aNormal, nDen, aCentre, nRadius, nSA, nEA, aCcw, lForward
   IF aT == NIL ; RETURN NIL ; ENDIF
   aChord := V2_Sub( aEnd, aStart ) ; nChSq := V2_LengthSquared( aChord )
   IF nChSq <= CS_ANGLE_EPS * CS_ANGLE_EPS ; RETURN NIL ; ENDIF
   aNormal := V2_Perpendicular( aT )
   nDen := V2_Dot( aNormal, aChord )
   IF Abs( nDen ) <= V2_Length( aChord ) * CS_ANGLE_EPS ; RETURN NIL ; ENDIF
   aCentre := V2_Add( aStart, V2_Mul( aNormal, nChSq / ( 2.0 * nDen ) ) )
   nRadius := V2_Distance( aCentre, aStart )
   nSA := V2_Angle( V2_Sub( aStart, aCentre ) ) ; nEA := V2_Angle( V2_Sub( aEnd, aCentre ) )
   aCcw := V2_Perpendicular( V2_Sub( aStart, aCentre ) )
   lForward := V2_Dot( aCcw, aT ) >= 0.0
   IF lForward != lFlip     // forward ^ flip
      RETURN { aCentre, nRadius, nSA, nEA }
   ENDIF
RETURN { aCentre, nRadius, nEA, nSA }

FUNCTION Cs_ArcThroughPoints( aStart, aMiddle, aEnd )
   LOCAL u := V2_Sub( aMiddle, aStart ), v := V2_Sub( aEnd, aStart ), nScaleSq, nDet, aCentre, nRadius
   LOCAL nSA, nMA, nEA, nSweep, nToMid
   nScaleSq := Max( Max( V2_LengthSquared( u ), V2_LengthSquared( v ) ), V2_LengthSquared( V2_Sub( aEnd, aMiddle ) ) )
   nDet := 2.0 * V2_Cross( u, v )
   IF nScaleSq <= CS_ANGLE_EPS * CS_ANGLE_EPS .OR. Abs( nDet ) <= nScaleSq * 0.000000000001 ; RETURN NIL ; ENDIF
   aCentre := V2_Add( aStart, { ( V2_LengthSquared( u ) * v[2] - V2_LengthSquared( v ) * u[2] ) / nDet, ;
                                ( u[1] * V2_LengthSquared( v ) - v[1] * V2_LengthSquared( u ) ) / nDet } )
   nRadius := V2_Distance( aCentre, aStart )
   nSA := V2_Angle( V2_Sub( aStart, aCentre ) ) ; nMA := V2_Angle( V2_Sub( aMiddle, aCentre ) ) ; nEA := V2_Angle( V2_Sub( aEnd, aCentre ) )
   nSweep := OCX_REMEUCLID( nEA - nSA, OCX_TAU )
   nToMid := OCX_REMEUCLID( nMA - nSA, OCX_TAU )
   IF nToMid <= nSweep + CS_ANGLE_EPS
      RETURN { aCentre, nRadius, nSA, nEA }
   ENDIF
RETURN { aCentre, nRadius, nEA, nSA }

FUNCTION Cs_ArcSweepFromChord( nRadius, nSignedChord )
   LOCAL nChord, nMinor
   IF ! OCX_ISFINITE( nRadius ) .OR. ! OCX_ISFINITE( nSignedChord ); RETURN NIL ; ENDIF
   nChord := Abs( nSignedChord )
   IF nRadius <= CS_ANGLE_EPS .OR. nChord <= CS_ANGLE_EPS .OR. nChord > 2.0 * nRadius ; RETURN NIL ; ENDIF
   nMinor := 2.0 * OCX_ASIN( Max( 0.0, Min( 1.0, nChord / ( 2.0 * nRadius ) ) ) )
RETURN IIF( nSignedChord > 0.0, nMinor, OCX_TAU - nMinor )
