/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/angle.prg
   Origen Rust: opencadkernel/src/geom2d/angle.rs (150 lineas)
   Estado: TRADUCIDO (tests portados en tests/t_angle.prg)
   Nota: Rust `%` en f64 = fmod; se usa OCX_FMOD (C), no el % de Harbour.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define ANGULAR_EPSILON 0.000000001   // 1e-9

FUNCTION NormalizeAngle( nAngle )
RETURN OCX_FMOD( OCX_FMOD( nAngle, OCX_TAU ) + OCX_TAU, OCX_TAU )

FUNCTION ArcSpan( nStart, nEnd )
   LOCAL nSpan := NormalizeAngle( nEnd ) - NormalizeAngle( nStart )
   IF nSpan <= 0.0
      RETURN nSpan + OCX_TAU
   ENDIF
RETURN nSpan

FUNCTION AngleWithinArc( nAngle, nStart, nEnd )
   LOCAL nSweep
   nAngle := NormalizeAngle( nAngle )
   nStart := NormalizeAngle( nStart )
   nEnd   := NormalizeAngle( nEnd )
   nSweep := nEnd - nStart
   IF Abs( nSweep ) < ANGULAR_EPSILON .OR. Abs( nSweep - OCX_TAU ) < ANGULAR_EPSILON
      RETURN .T.
   ENDIF
   IF nStart <= nEnd
      RETURN nAngle >= nStart - ANGULAR_EPSILON .AND. nAngle <= nEnd + ANGULAR_EPSILON
   ENDIF
   // el arco cruza cero: la parte interior es la union de dos tramos
RETURN nAngle >= nStart - ANGULAR_EPSILON .OR. nAngle <= nEnd + ANGULAR_EPSILON

FUNCTION ArcParameter( nAngle, nStart, nEnd )
   LOCAL nSpan := ArcSpan( nStart, nEnd )
   LOCAL nTravelled
   IF nSpan < 0.000000000001   // 1e-12
      RETURN 0.0
   ENDIF
   nTravelled := OCX_REMEUCLID( NormalizeAngle( nAngle ) - NormalizeAngle( nStart ), OCX_TAU )
   IF nTravelled <= nSpan
      RETURN Max( 0.0, Min( 1.0, nTravelled / nSpan ) )
   ELSEIF nTravelled - nSpan <= ( OCX_TAU - nSpan ) * 0.5
      RETURN 1.0
   ENDIF
RETURN 0.0
