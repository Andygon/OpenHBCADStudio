/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/arclength.rs -> arclength.prg
   Origen Rust: opencadkernel/src/geom2d/arclength.rs (647 lineas)
   Estado: TRADUCIDO (tests portados en tests/t_arclength.prg)
   SegmentLengths = { aCumulative, nTotal }. binary_search_by replica el algoritmo de
   std (Rust >= 1.82): Ok(i) -> { .T., i }, Err(i) -> { .F., i }.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define PANELS 32

STATIC FUNCTION GLNodes()
RETURN { { -0.906179845938664, 0.236926885056189 }, ;
         { -0.538469310105683, 0.478628670499366 }, ;
         {  0.0,               0.568888888888889 }, ;
         {  0.538469310105683, 0.478628670499366 }, ;
         {  0.906179845938664, 0.236926885056189 } }

FUNCTION Cv_TangentAt( c, t )
   LOCAL d := c[ CV_DATA ], nAngle, nSweep, nParam, e, nx, ny, nAlong, nAcross, aSegs, nCount, nScaled, nIdx, aLocal
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE     ; RETURN Ln_Direction( d )
   CASE c[ CV_KIND ] == CV_RAY      ; RETURN d[ RY_DIR ]
   CASE c[ CV_KIND ] == CV_XLINE    ; RETURN d[ XL_DIR ]
   CASE c[ CV_KIND ] == CV_CIRCLE
      nAngle := t * OCX_TAU
      RETURN { -d[ CI_RADIUS ] * OCX_SIN( nAngle ) * OCX_TAU, d[ CI_RADIUS ] * OCX_COS( nAngle ) * OCX_TAU }
   CASE c[ CV_KIND ] == CV_ARC
      nSweep := Ar_Sweep( d )
      nAngle := NormalizeAngle( d[ AR_START ] ) + t * nSweep
      RETURN { -d[ AR_RADIUS ] * OCX_SIN( nAngle ) * nSweep, d[ AR_RADIUS ] * OCX_COS( nAngle ) * nSweep }
   CASE c[ CV_KIND ] == CV_ELLIPSE
      nSweep := EA_Sweep( d )
      nParam := d[ EA_START ] + t * nSweep
      e := d[ EA_ELLIPSE ]
      nx := e[ ELL_MAJOR_AXIS ][ 1 ] ; ny := e[ ELL_MAJOR_AXIS ][ 2 ]
      nAlong  := -e[ ELL_MAJOR_R ] * OCX_SIN( nParam ) * nSweep
      nAcross :=  e[ ELL_MINOR_R ] * OCX_COS( nParam ) * nSweep
      RETURN { nAlong * nx - nAcross * ny, nAlong * ny + nAcross * nx }
   CASE c[ CV_KIND ] == CV_POLYLINE
      aSegs := Cv_Segments( c ) ; nCount := Len( aSegs )
      IF nCount == 0 ; RETURN { 0.0, 0.0 } ; ENDIF
      // el parametro se reparte por igual entre segmentos: la tangente de cada uno se escala por su numero
      nScaled := Min( Max( 0.0, Min( 1.0, t ) ) * nCount, nCount - 0.000000000001 )
      nIdx := Min( Int( OCX_FLOOR( nScaled ) ), nCount - 1 )
      aLocal := Cv_TangentAt( aSegs[ nIdx + 1 ], nScaled - nIdx )
      RETURN { aLocal[ 1 ] * nCount, aLocal[ 2 ] * nCount }
   CASE c[ CV_KIND ] == CV_NURBS
      RETURN NC_DerivativeAt( d, t )
   ENDCASE
RETURN { 0.0, 0.0 }

FUNCTION Cv_Length( c )
   LOCAL d := c[ CV_DATA ]
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE     ; RETURN Ln_Length( d )
   CASE c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE ; RETURN OCX_INF()
   CASE c[ CV_KIND ] == CV_CIRCLE   ; RETURN Ci_Length( d )
   CASE c[ CV_KIND ] == CV_ARC      ; RETURN Ar_Length( d )
   CASE c[ CV_KIND ] == CV_ELLIPSE .OR. c[ CV_KIND ] == CV_NURBS ; RETURN Cv_LengthBetween( c, 0.0, 1.0 )
   CASE c[ CV_KIND ] == CV_POLYLINE ; RETURN PolyLengths( c )[ 2 ]
   ENDCASE
RETURN 0.0

FUNCTION Cv_LengthTo( c, t ) ; RETURN Cv_LengthBetween( c, 0.0, t )

FUNCTION Cv_LengthBetween( c, nFrom, nTo )
   LOCAL aTab, nSpan, nWidth, nSum := 0.0, nPanel, nLower
   IF nTo < nFrom
      RETURN -Cv_LengthBetween( c, nTo, nFrom )
   ENDIF
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE .OR. c[ CV_KIND ] == CV_CIRCLE .OR. c[ CV_KIND ] == CV_ARC .OR. c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE
      // casos proporcionales: una fraccion del parametro es la misma fraccion de la longitud
      IF Cv_Length( c ) == OCX_INF()
         // inf * 0 = NaN en IEEE, como en Rust
         IF ( nTo - nFrom ) == 0.0 ; RETURN OCX_NAN() ; ENDIF
      ENDIF
      RETURN Cv_Length( c ) * ( nTo - nFrom )
   CASE c[ CV_KIND ] == CV_POLYLINE
      aTab := PolyLengths( c )
      RETURN SL_At( aTab, nTo ) - SL_At( aTab, nFrom )
   ENDCASE
   // Ellipse | Nurbs
   nSpan := nTo - nFrom
   IF nSpan <= 0.0 ; RETURN 0.0 ; ENDIF
   nWidth := nSpan / PANELS
   FOR nPanel := 0 TO PANELS - 1
      nLower := nFrom + nWidth * nPanel
      nSum += IntegrateSpeed( c, nLower, nLower + nWidth )
   NEXT
RETURN nSum

FUNCTION Cv_ParameterAtDistance( c, nDist )
   LOCAL nTotal := Cv_Length( c ), nStep, nLow := 0.0, nHigh := 1.0, nMid, i
   IF OCX_ISNAN( nTotal ) .OR. nTotal <= 0.0 ; RETURN 0.0 ; ENDIF
   IF nDist <= 0.0 ; RETURN 0.0 ; ENDIF
   IF OCX_ISFINITE( nTotal ) .AND. nDist >= nTotal ; RETURN 1.0 ; ENDIF
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE .OR. c[ CV_KIND ] == CV_CIRCLE .OR. c[ CV_KIND ] == CV_ARC
      RETURN nDist / nTotal
   CASE c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE
      // no acotado: una unidad de parametro avanza la longitud del vector direccion
      nStep := V2_Length( Cv_TangentAt( c, 0.0 ) )
      RETURN IIF( nStep > 0.0, nDist / nStep, 0.0 )
   CASE c[ CV_KIND ] == CV_POLYLINE
      RETURN SL_ParameterAt( PolyLengths( c ), nDist )
   ENDCASE
   // Ellipse | Nurbs: biseccion sobre la longitud acumulada (no Newton: la velocidad cae a 0 en una cuspide)
   FOR i := 1 TO 60
      nMid := 0.5 * ( nLow + nHigh )
      IF Cv_LengthBetween( c, 0.0, nMid ) < nDist
         nLow := nMid
      ELSE
         nHigh := nMid
      ENDIF
   NEXT
RETURN 0.5 * ( nLow + nHigh )

FUNCTION Cv_PointAtDistance( c, nDist ) ; RETURN Cv_PointAt( c, Cv_ParameterAtDistance( c, nDist ) )

STATIC FUNCTION IntegrateSpeed( c, nFrom, nTo )
   LOCAL nHalf := 0.5 * ( nTo - nFrom ), nMid := 0.5 * ( nTo + nFrom ), nSum := 0.0, aN
   FOR EACH aN IN GLNodes()
      nSum += aN[ 2 ] * V2_Length( Cv_TangentAt( c, nMid + nHalf * aN[ 1 ] ) )
   NEXT
RETURN nHalf * nSum

// ---- SegmentLengths --------------------------------------------------------
STATIC FUNCTION PolyLengths( c )
   LOCAL aCum := { 0.0 }, nTotal := 0.0, s
   FOR EACH s IN Cv_Segments( c )
      nTotal += Cv_Length( s )
      AAdd( aCum, nTotal )
   NEXT
RETURN { aCum, nTotal }

STATIC FUNCTION SL_At( sl, t )
   LOCAL nCount := Max( Len( sl[ 1 ] ) - 1, 0 ), nScaled, nIdx, nWithin, nSpan
   IF nCount == 0 ; RETURN 0.0 ; ENDIF
   t := Max( 0.0, Min( 1.0, t ) )
   nScaled := t * nCount
   nIdx := Min( Int( OCX_FLOOR( nScaled ) ), nCount - 1 )
   nWithin := nScaled - nIdx
   nSpan := sl[ 1 ][ nIdx + 2 ] - sl[ 1 ][ nIdx + 1 ]
RETURN sl[ 1 ][ nIdx + 1 ] + nSpan * nWithin

// binary_search_by(partial_cmp) de std: { lFound, nIndex } (base 0)
STATIC FUNCTION BinSearch( a, nTarget )
   LOCAL nSize := Len( a ), nBase := 0, nHalf, nMid
   IF nSize == 0 ; RETURN { .F., 0 } ; ENDIF
   DO WHILE nSize > 1
      nHalf := Int( nSize / 2 ) ; nMid := nBase + nHalf
      IF a[ nMid + 1 ] > nTarget      // cmp == Greater
         // base no cambia
      ELSE
         nBase := nMid
      ENDIF
      nSize -= nHalf
   ENDDO
   IF a[ nBase + 1 ] == nTarget
      RETURN { .T., nBase }
   ENDIF
RETURN { .F., nBase + IIF( a[ nBase + 1 ] < nTarget, 1, 0 ) }

STATIC FUNCTION SL_ParameterAt( sl, nDist )
   LOCAL nCount := Max( Len( sl[ 1 ] ) - 1, 0 ), aR, nIdx, nSpan, nWithin
   IF nCount == 0 .OR. OCX_ISNAN( sl[ 2 ] ) .OR. sl[ 2 ] <= 0.0 ; RETURN 0.0 ; ENDIF
   aR := BinSearch( sl[ 1 ], nDist )
   IF aR[ 1 ]
      nIdx := Min( aR[ 2 ], nCount )
   ELSE
      nIdx := Min( Max( aR[ 2 ] - 1, 0 ), nCount - 1 )
   ENDIF
   // indice nCount (hit en el ultimo acumulado) accederia fuera de rango en Rust: no ocurre
   // porque distance < total aqui; se acota por seguridad.
   nIdx := Min( nIdx, nCount - 1 )
   nSpan := sl[ 1 ][ nIdx + 2 ] - sl[ 1 ][ nIdx + 1 ]
   nWithin := IIF( nSpan > 0.0, ( nDist - sl[ 1 ][ nIdx + 1 ] ) / nSpan, 0.0 )
RETURN Max( 0.0, Min( 1.0, ( nIdx + nWithin ) / nCount ) )

FUNCTION Ci_Length( ci ) ; RETURN Abs( ci[ CI_RADIUS ] ) * OCX_TAU
FUNCTION Ar_Length( ar ) ; RETURN Abs( ar[ AR_RADIUS ] ) * Abs( Ar_Sweep( ar ) )
FUNCTION EA_Length( ea ) ; RETURN Cv_Length( Cv_Ellipse( ea ) )
