/* Port de opencadkernel/src/geom2d/gradient.rs (66 lineas, sin tests en Rust). UTF-8.
   GradientFrame = { aCenter, nProjectionMin, nProjectionSpan, nRadius }. Option -> NIL. */
#include "ocx.ch"

FUNCTION Gr_Frame( aBoundary, nAngle, nShift, nTol )
   LOCAL aDir, nMinX := OCX_INF(), nMinY := OCX_INF(), nMaxX := -OCX_INF(), nMaxY := -OCX_INF()
   LOCAL nPMin := OCX_INF(), nPMax := -OCX_INF(), p, nProj, aBase, aOff, aCen, nRad := 0.0, nD
   IF ! OCX_ISFINITE( nAngle ) .OR. ! OCX_ISFINITE( nShift ) ; RETURN NIL ; ENDIF
   aDir := { OCX_COS( nAngle ), OCX_SIN( nAngle ) }
   FOR EACH p IN aBoundary
      IF ! OCX_ISFINITE( p[1] ) .OR. ! OCX_ISFINITE( p[2] )
         LOOP
      ENDIF
      nMinX := Min( nMinX, p[1] ) ; nMinY := Min( nMinY, p[2] )
      nMaxX := Max( nMaxX, p[1] ) ; nMaxY := Max( nMaxY, p[2] )
      nProj := p[1] * aDir[1] + p[2] * aDir[2]
      nPMin := Min( nPMin, nProj ) ; nPMax := Max( nPMax, nProj )
   NEXT
   IF ! OCX_ISFINITE( nPMin ) ; RETURN NIL ; ENDIF
   aBase := { ( nMinX + nMaxX ) * 0.5, ( nMinY + nMaxY ) * 0.5 }
   nShift := Max( 0.0, Min( 1.0, nShift ) )
   aOff := { -( nMaxX - nMinX ) * 0.25 * nShift, ( nMaxY - nMinY ) * 0.25 * nShift }
   aCen := { aBase[1] + aOff[1], aBase[2] + aOff[2] }
   FOR EACH p IN aBoundary
      IF OCX_ISFINITE( p[1] ) .AND. OCX_ISFINITE( p[2] )
         nD := OCX_HYPOT( p[1] - aCen[1], p[2] - aCen[2] )
         nRad := Max( nRad, nD )
      ENDIF
   NEXT
   nRad := Max( nRad, nTol )
RETURN { aCen, nPMin + aOff[1] * aDir[1] + aOff[2] * aDir[2], Max( nPMax - nPMin, nTol ), nRad }
