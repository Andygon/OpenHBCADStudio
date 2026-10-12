/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/intersect.prg
   Origen Rust: opencadkernel/src/geom2d/intersect.rs (646 lineas)
   Estado: TRADUCIDO (tests portados en tests/t_intersect.prg)
   Retornos: Option<(f64,f64)> -> NIL | { a, b };  Vec<f64> -> array;
   Vec<(f64,f64)> -> array de { a, b };  Vec<[f64;2]> -> array de { x, y }.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define DETERMINANT_EPSILON   0.0000000001      // 1e-10
#define DEGENERATE_DIRECTION  0.00000000000000000001   // 1e-20
#define PROXIMITY_EPSILON     0.000000001       // 1e-9

FUNCTION Ix_LineLine( p, d, q, e )
   LOCAL nDet := d[ 1 ] * e[ 2 ] - d[ 2 ] * e[ 1 ], dx, dy
   IF Abs( nDet ) < DETERMINANT_EPSILON
      RETURN NIL
   ENDIF
   dx := q[ 1 ] - p[ 1 ] ; dy := q[ 2 ] - p[ 2 ]
RETURN { ( dx * e[ 2 ] - dy * e[ 1 ] ) / nDet, ( dx * d[ 2 ] - dy * d[ 1 ] ) / nDet }

FUNCTION Ix_LineCircle( p, d, aCentre, nRadius )
   LOCAL fx, fy, a, b, nTPerp, px, py, h, nMaxR, nTol, nHalf, nDelta
   IF nRadius <= 0.0 ; RETURN {} ; ENDIF
   fx := p[ 1 ] - aCentre[ 1 ] ; fy := p[ 2 ] - aCentre[ 2 ]
   a := d[ 1 ] * d[ 1 ] + d[ 2 ] * d[ 2 ]
   IF a < DEGENERATE_DIRECTION ; RETURN {} ; ENDIF
   b := 2.0 * ( fx * d[ 1 ] + fy * d[ 2 ] )
   nTPerp := -b / ( 2.0 * a )
   px := fx + nTPerp * d[ 1 ] ; py := fy + nTPerp * d[ 2 ]
   h := Sqrt( px * px + py * py )
   nMaxR := Max( nRadius, 1.0 )
   nTol := Max( PROXIMITY_EPSILON, 0.0000001 * nMaxR )
   IF h > nRadius + nTol ; RETURN {} ; ENDIF
   IF Abs( h - nRadius ) <= nTol ; RETURN { nTPerp } ; ENDIF
   nHalf := Sqrt( Max( nRadius * nRadius - h * h, 0.0 ) )
   nDelta := nHalf / Sqrt( a )
RETURN { nTPerp - nDelta, nTPerp + nDelta }

FUNCTION Ix_CircleCircleAngles( c1, r1, c2, r2 )
   LOCAL sx, sy, nDist, nMaxR, nTol, lExt, lInt, nAngle, nAlong, nHcSq, nHc
   LOCAL nMidX, nMidY, nOffX, nOffY, nFirst, nSecond
   IF r1 <= 0.0 .OR. r2 <= 0.0 ; RETURN {} ; ENDIF
   sx := c2[ 1 ] - c1[ 1 ] ; sy := c2[ 2 ] - c1[ 2 ]
   nDist := Sqrt( sx * sx + sy * sy )
   nMaxR := Max( Max( r1, r2 ), 1.0 )
   nTol := Max( PROXIMITY_EPSILON, 0.0000001 * nMaxR )
   // concentricos, demasiado lejos, o uno dentro del otro
   IF nDist < nTol .OR. nDist > r1 + r2 + nTol .OR. nDist < Abs( r1 - r2 ) - nTol
      RETURN {}
   ENDIF
   lExt := Abs( nDist - ( r1 + r2 ) ) <= nTol
   lInt := Abs( nDist - Abs( r1 - r2 ) ) <= nTol
   IF lExt .OR. lInt
      IF lExt .OR. r1 >= r2
         nAngle := OCX_ATAN2( sy, sx )
      ELSE
         nAngle := OCX_ATAN2( -sy, -sx )
      ENDIF
      RETURN { nAngle }
   ENDIF
   nAlong := ( r1 * r1 - r2 * r2 + nDist * nDist ) / ( 2.0 * nDist )
   nHcSq := r1 * r1 - nAlong * nAlong
   IF nHcSq <= 0.0
      IF r1 >= r2
         nAngle := OCX_ATAN2( sy, sx )
      ELSE
         nAngle := OCX_ATAN2( -sy, -sx )
      ENDIF
      RETURN { nAngle }
   ENDIF
   nHc := Sqrt( nHcSq )
   nMidX := c1[ 1 ] + nAlong * sx / nDist
   nMidY := c1[ 2 ] + nAlong * sy / nDist
   nOffX := nHc * sy / nDist
   nOffY := -nHc * sx / nDist
   nFirst := OCX_ATAN2( ( nMidY + nOffY ) - c1[ 2 ], ( nMidX + nOffX ) - c1[ 1 ] )
   IF nHc < nTol
      RETURN { nFirst }
   ENDIF
   nSecond := OCX_ATAN2( ( nMidY - nOffY ) - c1[ 2 ], ( nMidX - nOffX ) - c1[ 1 ] )
RETURN { nFirst, nSecond }

// Vec<(s, t)>: s = parametro de la recta, t = parametro de la elipse
FUNCTION Ix_LineEllipse( p, d, e )
   LOCAL nx, ny, rx, ry, lx, ly, dirx, diry, ux, udx, uy, udy, a, b, nTPerp, px, py, h, nTol
   LOCAL aParams, nHalf, nDelta, s, aOut := {}, nCos, nSin
   IF Ell_IsDegenerate( e ) ; RETURN {} ; ENDIF
   nx := e[ ELL_MAJOR_AXIS ][ 1 ] ; ny := e[ ELL_MAJOR_AXIS ][ 2 ]
   // al sistema propio de la elipse
   rx := p[ 1 ] - e[ ELL_CENTRE ][ 1 ] ; ry := p[ 2 ] - e[ ELL_CENTRE ][ 2 ]
   lx := rx * nx + ry * ny ; ly := -rx * ny + ry * nx
   dirx := d[ 1 ] * nx + d[ 2 ] * ny ; diry := -d[ 1 ] * ny + d[ 2 ] * nx
   // escalado para que la elipse sea el circulo unidad
   ux := lx / e[ ELL_MAJOR_R ] ; udx := dirx / e[ ELL_MAJOR_R ]
   uy := ly / e[ ELL_MINOR_R ] ; udy := diry / e[ ELL_MINOR_R ]
   a := udx * udx + udy * udy
   IF a < DEGENERATE_DIRECTION ; RETURN {} ; ENDIF
   b := 2.0 * ( ux * udx + uy * udy )
   nTPerp := -b / ( 2.0 * a )
   px := ux + nTPerp * udx ; py := uy + nTPerp * udy
   h := Sqrt( px * px + py * py )
   nTol := Max( PROXIMITY_EPSILON, 0.0000001 )
   IF h > 1.0 + nTol
      aParams := {}
   ELSEIF Abs( h - 1.0 ) <= nTol
      aParams := { nTPerp }
   ELSE
      nHalf := Sqrt( Max( 1.0 - h * h, 0.0 ) )
      nDelta := nHalf / Sqrt( a )
      aParams := { nTPerp - nDelta, nTPerp + nDelta }
   ENDIF
   FOR EACH s IN aParams
      nCos := ux + s * udx ; nSin := uy + s * udy
      AAdd( aOut, { s, OCX_ATAN2( nSin, nCos ) } )
   NEXT
RETURN aOut

FUNCTION Ix_CircleCirclePoints( c1, r1, c2, r2 )
   LOCAL aOut := {}, nAngle
   FOR EACH nAngle IN Ix_CircleCircleAngles( c1, r1, c2, r2 )
      AAdd( aOut, { c1[ 1 ] + r1 * OCX_COS( nAngle ), c1[ 2 ] + r1 * OCX_SIN( nAngle ) } )
   NEXT
RETURN aOut

// Vec<(angle, t)>
FUNCTION Ix_EllipseCircle( e, aCentre, nRadius )
   LOCAL a, b, nx, ny, rx, ry, u, v, r2, bF, bDf, nTol, nTangency, aRoots := {}, i, t0, t1, aCuts, nExt, k
   LOCAL nLo, nHi, aOut := {}, t, pt, nAngle, c_e
   IF Ell_IsDegenerate( e ) .OR. nRadius < DEGENERATE_DIRECTION ; RETURN {} ; ENDIF
   c_e := e[ ELL_CENTRE ] ; a := e[ ELL_MAJOR_R ] ; b := e[ ELL_MINOR_R ]
   IF a < DEGENERATE_DIRECTION .OR. b < DEGENERATE_DIRECTION ; RETURN {} ; ENDIF
   nx := e[ ELL_MAJOR_AXIS ][ 1 ] ; ny := e[ ELL_MAJOR_AXIS ][ 2 ]
   rx := aCentre[ 1 ] - c_e[ 1 ] ; ry := aCentre[ 2 ] - c_e[ 2 ]
   u := rx * nx + ry * ny ; v := -rx * ny + ry * nx
   r2 := nRadius * nRadius
   // F(t) = distancia^2(elipse(t), centro del circulo) - r^2
   bF  := {| t | ( a * OCX_COS( t ) - u ) * ( a * OCX_COS( t ) - u ) + ( b * OCX_SIN( t ) - v ) * ( b * OCX_SIN( t ) - v ) - r2 }
   bDf := {| t | ( b * b - a * a ) * OCX_SIN( 2.0 * t ) + 2.0 * a * u * OCX_SIN( t ) - 2.0 * b * v * OCX_COS( t ) }
   nTol := Max( PROXIMITY_EPSILON, 0.0000001 * Max( nRadius, 1.0 ) )
   nTangency := 2.0 * nRadius * nTol
   // Muestrea F y parte cada intervalo en un extremo de F: dos cortes pueden quedar entre
   // dos muestras del mismo signo; cada trozo se acota y la biseccion no se escapa a otra raiz.
   FOR i := 0 TO 63
      t0 := i * OCX_TAU / 64
      t1 := ( i + 1 ) * OCX_TAU / 64
      aCuts := { t0 }
      IF Eval( bDf, t0 ) * Eval( bDf, t1 ) < 0.0
         nExt := Ix_Bisect( bDf, t0, t1 )
         IF Abs( Eval( bF, nExt ) ) <= nTangency
            // un toque, no dos cortes separados por un pelo
            Ix_PushRoot( aRoots, nExt )
            LOOP
         ENDIF
         AAdd( aCuts, nExt )
      ENDIF
      AAdd( aCuts, t1 )
      FOR k := 1 TO Len( aCuts ) - 1
         nLo := Eval( bF, aCuts[ k ] ) ; nHi := Eval( bF, aCuts[ k + 1 ] )
         IF nLo == 0.0
            Ix_PushRoot( aRoots, aCuts[ k ] )
         ELSEIF nLo * nHi < 0.0
            Ix_PushRoot( aRoots, Ix_Bisect( bF, aCuts[ k ], aCuts[ k + 1 ] ) )
         ENDIF
      NEXT
   NEXT
   FOR EACH t IN aRoots
      pt := { c_e[ 1 ] + a * OCX_COS( t ) * nx - b * OCX_SIN( t ) * ny, ;
              c_e[ 2 ] + a * OCX_COS( t ) * ny + b * OCX_SIN( t ) * nx }
      nAngle := OCX_ATAN2( pt[ 2 ] - aCentre[ 2 ], pt[ 1 ] - aCentre[ 1 ] )
      AAdd( aOut, { nAngle, t } )
   NEXT
RETURN aOut

STATIC FUNCTION Ix_PushRoot( aRoots, t )
   LOCAL r
   t := OCX_REMEUCLID( t, OCX_TAU )
   FOR EACH r IN aRoots
      IF Abs( r - t ) < 0.000000001 .OR. Abs( r - t ) > OCX_TAU - 0.000000001
         RETURN NIL
      ENDIF
   NEXT
   AAdd( aRoots, t )
RETURN NIL

STATIC FUNCTION Ix_Bisect( bG, nLo, nHi )
   LOCAL lLoNeg := Eval( bG, nLo ) < 0.0, i, nMid
   FOR i := 1 TO 60
      nMid := 0.5 * ( nLo + nHi )
      IF ( Eval( bG, nMid ) < 0.0 ) == lLoNeg
         nLo := nMid
      ELSE
         nHi := nMid
      ENDIF
   NEXT
RETURN 0.5 * ( nLo + nHi )
