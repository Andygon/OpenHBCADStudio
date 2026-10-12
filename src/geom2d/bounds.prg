/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/bounds.prg
   Origen Rust: opencadkernel/src/geom2d/bounds.rs (223 lineas)
   Estado: TRADUCIDO (tests portados en tests/t_bounds.prg)
   Bounds = { aMin, aMax }. AnalyticCurveBounds( aCurves ) -> NIL | Bounds.
   El acumulador es un array de 1 posicion { NIL | Bounds } pasado por referencia
   (equivale al &mut Option<Bounds> de Rust). Las funciones internas devuelven .T./.F.
   (Option<()> con `?`).
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION Absorb( aAcc, aPoint )
   LOCAL ax
   IF ! OCX_ISFINITE( aPoint[ 1 ] ) .OR. ! OCX_ISFINITE( aPoint[ 2 ] )
      RETURN .F.
   ENDIF
   IF aAcc[ 1 ] != NIL
      FOR ax := 1 TO 2
         aAcc[ 1 ][ 1 ][ ax ] := Min( aAcc[ 1 ][ 1 ][ ax ], aPoint[ ax ] )
         aAcc[ 1 ][ 2 ][ ax ] := Max( aAcc[ 1 ][ 2 ][ ax ], aPoint[ ax ] )
      NEXT
   ELSE
      aAcc[ 1 ] := { { aPoint[ 1 ], aPoint[ 2 ] }, { aPoint[ 1 ], aPoint[ 2 ] } }
   ENDIF
RETURN .T.

STATIC FUNCTION Conic( aAcc, e, nStart, nEnd )
   LOCAL aMinor, ax, nMax, nParam
   IF ! OCX_ISFINITE( nStart ) .OR. ! OCX_ISFINITE( nEnd ) .OR. ! OCX_ISFINITE( e[ ELL_MAJOR_R ] ) .OR. ! OCX_ISFINITE( e[ ELL_MINOR_R ] ) ;
      .OR. e[ ELL_MAJOR_R ] <= 0.0 .OR. e[ ELL_MINOR_R ] <= 0.0 ;
      .OR. ! OCX_ISFINITE( e[ ELL_MAJOR_AXIS ][ 1 ] ) .OR. ! OCX_ISFINITE( e[ ELL_MAJOR_AXIS ][ 2 ] )
      RETURN .F.
   ENDIF
   IF ! Absorb( aAcc, Ell_PointAt( e, nStart ) ) ; RETURN .F. ; ENDIF
   IF ! Absorb( aAcc, Ell_PointAt( e, nEnd ) )   ; RETURN .F. ; ENDIF
   aMinor := Ell_MinorAxis( e )
   FOR ax := 1 TO 2
      // la derivada de la coordenada es -a*sin(t) + b*cos(t)
      nMax := OCX_ATAN2( e[ ELL_MINOR_R ] * aMinor[ ax ], e[ ELL_MAJOR_R ] * e[ ELL_MAJOR_AXIS ][ ax ] )
      FOR EACH nParam IN { nMax, nMax + OCX_PI }
         IF Abs( nEnd - nStart ) >= OCX_TAU .OR. AngleWithinArc( nParam, nStart, nEnd )
            IF ! Absorb( aAcc, Ell_PointAt( e, nParam ) ) ; RETURN .F. ; ENDIF
         ENDIF
      NEXT
   NEXT
RETURN .T.

STATIC FUNCTION Circular( aAcc, aCentre, nRadius, nStart, nEnd )
RETURN Conic( aAcc, Ell_New( aCentre, nRadius, nRadius, { 1.0, 0.0 } ), nStart, nEnd )

FUNCTION AnalyticCurveBounds( aCurves )
   LOCAL aAcc := { NIL }, c, d, v, nCount, i, ba, nS, nE
   FOR EACH c IN aCurves
      d := c[ CV_DATA ]
      DO CASE
      CASE c[ CV_KIND ] == CV_LINE
         IF ! Absorb( aAcc, d[ LN_START ] ) .OR. ! Absorb( aAcc, d[ LN_END ] ) ; RETURN NIL ; ENDIF
      CASE c[ CV_KIND ] == CV_CIRCLE
         IF ! Circular( aAcc, d[ CI_CENTRE ], d[ CI_RADIUS ], 0.0, OCX_TAU ) ; RETURN NIL ; ENDIF
      CASE c[ CV_KIND ] == CV_ARC
         IF ! Circular( aAcc, d[ AR_CENTRE ], d[ AR_RADIUS ], d[ AR_START ], d[ AR_END ] ) ; RETURN NIL ; ENDIF
      CASE c[ CV_KIND ] == CV_ELLIPSE
         IF ! Conic( aAcc, d[ EA_ELLIPSE ], d[ EA_START ], d[ EA_END ] ) ; RETURN NIL ; ENDIF
      CASE c[ CV_KIND ] == CV_POLYLINE
         FOR EACH v IN d[ PL_VERTS ]
            IF ! Absorb( aAcc, v[ PV_POS ] ) ; RETURN NIL ; ENDIF
            IF ! OCX_ISFINITE( v[ PV_BULGE ] ) ; RETURN NIL ; ENDIF
         NEXT
         nCount := IIF( d[ PL_CLOSED ], Len( d[ PL_VERTS ] ), Max( Len( d[ PL_VERTS ] ) - 1, 0 ) )
         FOR i := 0 TO nCount - 1
            ba := PL_SegmentArc( d, i )
            IF ba != NIL
               IF ba[ BA_SWEEP ] >= 0.0
                  nS := ba[ BA_START ] ; nE := ba[ BA_START ] + ba[ BA_SWEEP ]
               ELSE
                  nS := ba[ BA_START ] + ba[ BA_SWEEP ] ; nE := ba[ BA_START ]
               ENDIF
               IF ! Circular( aAcc, ba[ BA_CENTER ], ba[ BA_RADIUS ], nS, nE ) ; RETURN NIL ; ENDIF
            ENDIF
         NEXT
      OTHERWISE      // Ray | XLine | Nurbs
         RETURN NIL
      ENDCASE
   NEXT
RETURN aAcc[ 1 ]
