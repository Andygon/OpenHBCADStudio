/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/mod.prg
   Origen Rust: opencadkernel/src/geom2d/mod.rs (284 lineas; solo la parte con
   codigo: Ellipse, ellipse_closest_parameter, Tolerance; los `pub mod`/`pub use`
   son resolucion de modulos y se reflejan en SOURCES.lst).
   Estado: TRADUCIDO
   Ellipse = {aCentre, nMajorR, nMinorR, aMajorAxis}  (indices ELL_*)
   Tolerance = nLinear (numero). Tol_New() lanza error si no es finito y > 0.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Ell_New( aCentre, nMajorR, nMinorR, aMajorAxis )
RETURN { aCentre, nMajorR, nMinorR, aMajorAxis }

FUNCTION Ell_MinorAxis( e )
RETURN { -e[ ELL_MAJOR_AXIS ][ 2 ], e[ ELL_MAJOR_AXIS ][ 1 ] }

FUNCTION Ell_PointAt( e, t )
   LOCAL nAlong  := e[ ELL_MAJOR_R ] * OCX_COS( t )
   LOCAL nAcross := e[ ELL_MINOR_R ] * OCX_SIN( t )
   LOCAL aMinor  := Ell_MinorAxis( e )
RETURN { e[ ELL_CENTRE ][ 1 ] + nAlong * e[ ELL_MAJOR_AXIS ][ 1 ] + nAcross * aMinor[ 1 ], ;
         e[ ELL_CENTRE ][ 2 ] + nAlong * e[ ELL_MAJOR_AXIS ][ 2 ] + nAcross * aMinor[ 2 ] }

FUNCTION Ell_IsDegenerate( e )
RETURN Abs( e[ ELL_MAJOR_R ] ) < OCX_1E_20 .OR. Abs( e[ ELL_MINOR_R ] ) < OCX_1E_20

FUNCTION Ell_ClosestParameter( e, aPoint )
   LOCAL rx := aPoint[ 1 ] - e[ ELL_CENTRE ][ 1 ]
   LOCAL ry := aPoint[ 2 ] - e[ ELL_CENTRE ][ 2 ]
   LOCAL nx := e[ ELL_MAJOR_AXIS ][ 1 ], ny := e[ ELL_MAJOR_AXIS ][ 2 ]
RETURN EllipseClosestParameter( e[ ELL_MAJOR_R ], e[ ELL_MINOR_R ], rx * nx + ry * ny, -rx * ny + ry * nx )

FUNCTION EllipseClosestParameter( a, b, u, v )
   LOCAL nSignX, nSignY, nUAbs, nVAbs, x, y, a2, b2, nLow, nHigh, t, i
   LOCAL tA, tB, f, df, nNext
   IF a < 0.000000000001 .OR. b < 0.000000000001
      RETURN 0.0
   ENDIF
   IF Abs( a - b ) < 0.000000001
      RETURN OCX_ATAN2( v, u )
   ENDIF
   IF a < b
      RETURN OCX_FRAC_PI_2 - EllipseClosestParameter( b, a, v, u )
   ENDIF

   nSignX := IIF( u >= 0.0, 1.0, -1.0 )
   nSignY := IIF( v >= 0.0, 1.0, -1.0 )
   nUAbs := Abs( u ); nVAbs := Abs( v )

   IF nVAbs < 0.000000000001
      IF nUAbs < ( a * a - b * b ) / a
         x := a * a * nUAbs / ( a * a - b * b )
      ELSE
         x := a
      ENDIF
      y := b * Sqrt( Max( 0.0, 1.0 - ( x / a ) * ( x / a ) ) )
      RETURN OCX_ATAN2( nSignY * y / b, nSignX * x / a )
   ENDIF
   IF nUAbs < 0.000000000001
      RETURN OCX_ATAN2( nSignY, 0.0 )
   ENDIF

   a2 := a * a; b2 := b * b
   nLow  := -b2 + b * nVAbs
   nHigh := -b2 + OCX_HYPOT( a * nUAbs, b * nVAbs )
   t := nLow
   FOR i := 1 TO 25
      tA := t + a2; tB := t + b2
      IF Abs( tA ) < 0.000000000001 .OR. Abs( tB ) < 0.000000000001
         EXIT
      ENDIF
      f := ( a * nUAbs / tA ) * ( a * nUAbs / tA ) + ( b * nVAbs / tB ) * ( b * nVAbs / tB ) - 1.0
      IF Abs( f ) < 0.000000000001
         EXIT
      ENDIF
      df := -2.0 * ( a2 * nUAbs * nUAbs / ( tA * tA * tA ) + b2 * nVAbs * nVAbs / ( tB * tB * tB ) )
      nNext := t - f / df
      IF nNext > nLow .AND. nNext < nHigh
         t := nNext
      ELSE
         IF f > 0.0
            nLow := t
         ELSE
            nHigh := t
         ENDIF
         t := 0.5 * ( nLow + nHigh )
      ENDIF
   NEXT
   x := a2 * nUAbs / ( t + a2 )
   y := b2 * nVAbs / ( t + b2 )
RETURN OCX_ATAN2( nSignY * y / b, nSignX * x / a )

// ---- Tolerance -------------------------------------------------------------
FUNCTION Tol_New( nLinear )
   LOCAL oErr
   IF ! ( ValType( nLinear ) == "N" .AND. OCX_ISFINITE( nLinear ) .AND. nLinear > 0.0 )
      oErr := ErrorNew()
      oErr:subSystem := "OCX"; oErr:operation := "Tol_New"
      oErr:description := "tolerance must be finite and positive, got " + hb_ValToStr( nLinear )
      Break( oErr )
   ENDIF
RETURN nLinear

FUNCTION Tol_Default()
RETURN 0.0000001   // 1e-7

FUNCTION Tol_AreEqual( nTol, a, b )
RETURN Abs( a - b ) <= nTol
