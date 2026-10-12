/* Port de opencadkernel/src/geom2d/centerline.rs (126 lineas, sin tests en Rust). UTF-8.
   Line = { aStart, aEnd }. Resultado { aStart, aEnd, aBaseStart, aBaseEnd } o NIL. */
#include "ocx.ch"
#define CL_EPS 0.0000000001

STATIC FUNCTION CLn_Unit( v )
   LOCAL nLen := Sqrt( V2_Dot( v, v ) )
   IF nLen > CL_EPS ; RETURN V2_Mul( v, 1.0 / nLen ) ; ENDIF
RETURN NIL

STATIC FUNCTION CLn_Toward( aDir, aOrigin, aPick )
   IF V2_Dot( V2_Sub( aPick, aOrigin ), aDir ) < 0.0 ; RETURN V2_Mul( aDir, -1.0 ) ; ENDIF
RETURN aDir

FUNCTION CL_CenterlineBetween( aFirst, aSecond, aPick1, aPick2, nStartExt, nEndExt )
   LOCAL d1 := CLn_Unit( V2_Sub( aFirst[2], aFirst[1] ) ), d2, aPts, aHit, aOrigin, aAxis
   LOCAL aInt, r1, r2, aBis, d2a, aDir, aNormal, nOff, p, nMin := OCX_INF(), nMax := -OCX_INF(), nPar, nTmp
   LOCAL aBS, aBE, aS, aE
   IF d1 == NIL ; RETURN NIL ; ENDIF
   d2 := CLn_Unit( V2_Sub( aSecond[2], aSecond[1] ) )
   IF d2 == NIL ; RETURN NIL ; ENDIF
   aPts := { aFirst[1], aFirst[2], aSecond[1], aSecond[2] }
   aHit := Ix_LineLine( aFirst[1], d1, aSecond[1], d2 )
   IF aHit != NIL
      aInt := V2_Add( aFirst[1], V2_Mul( d1, aHit[1] ) )
      r1 := CLn_Toward( d1, aInt, aPick1 )
      r2 := CLn_Toward( d2, aInt, aPick2 )
      aBis := CLn_Unit( V2_Add( r1, r2 ) )
      IF aBis == NIL ; aBis := CLn_Unit( V2_Sub( r1, r2 ) ) ; ENDIF
      IF aBis == NIL ; RETURN NIL ; ENDIF
      aOrigin := aInt ; aAxis := aBis
   ELSE
      d2a := IIf( V2_Dot( d1, d2 ) < 0.0, V2_Mul( d2, -1.0 ), d2 )
      aDir := CLn_Unit( V2_Add( d1, d2a ) )
      IF aDir == NIL ; aDir := d1 ; ENDIF
      aDir := CLn_Toward( aDir, aFirst[1], aPick1 )
      aNormal := { -aDir[2], aDir[1] }
      nOff := 0.0
      FOR EACH p IN aPts
         nOff += V2_Dot( p, aNormal )
      NEXT
      nOff := nOff / 4.0
      aOrigin := V2_Mul( aNormal, nOff ) ; aAxis := aDir
   ENDIF
   FOR EACH p IN aPts
      nPar := V2_Dot( V2_Sub( p, aOrigin ), aAxis )
      nMin := Min( nMin, nPar ) ; nMax := Max( nMax, nPar )
   NEXT
   IF nMax - nMin <= CL_EPS ; RETURN NIL ; ENDIF
   IF V2_Dot( aAxis, CLn_Toward( d1, aOrigin, aPick1 ) ) < 0.0
      aAxis := V2_Mul( aAxis, -1.0 )
      nTmp := nMin ; nMin := -nMax ; nMax := -nTmp
   ENDIF
   aBS := V2_Add( aOrigin, V2_Mul( aAxis, nMin ) )
   aBE := V2_Add( aOrigin, V2_Mul( aAxis, nMax ) )
   aS := V2_Add( aBS, V2_Mul( aAxis, -nStartExt ) )
   aE := V2_Add( aBE, V2_Mul( aAxis, nEndExt ) )
   IF V2_Dot( V2_Sub( aE, aS ), aAxis ) <= CL_EPS ; RETURN NIL ; ENDIF
RETURN { aS, aE, aBS, aBE }
