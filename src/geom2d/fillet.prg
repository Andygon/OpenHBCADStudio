/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/fillet.prg
   Origen Rust: opencadkernel/src/geom2d/fillet.rs (790 lineas)
   Estado: TRADUCIDO (tests en tests/t_fillet.prg).
   Fillet = { aTangent1, aTangent2, aCentre, nStartAngle, nEndAngle }
   Extended = { curve, nFrom, nTo }
----------------------------------------------------------------------------*/
#include "ocx.ch"


FUNCTION Fl_BetweenRays( aApex, aDir1, aDir2, nRadius )
   LOCAL nCorner, nHalf, nAlong, aT1, aT2, aBis, aCentre, nA1, nA2, nTurn, nS, nE
   nCorner := OCX_ACOS( Max( -1.0, Min( 1.0, V2_Dot( aDir1, aDir2 ) ) ) )
   IF nCorner < 0.000001 .OR. Abs( nCorner - OCX_PI ) < 0.000001 ; RETURN NIL ; ENDIF
   IF nRadius < 0.000000001 ; RETURN NIL ; ENDIF
   nHalf := nCorner / 2.0
   nAlong := nRadius / OCX_TAN( nHalf )
   aT1 := V2_Add( aApex, V2_Mul( aDir1, nAlong ) )
   aT2 := V2_Add( aApex, V2_Mul( aDir2, nAlong ) )
   aBis := V2_Normalize( V2_Add( aDir1, aDir2 ) )
   IF aBis == NIL ; RETURN NIL ; ENDIF
   aCentre := V2_Add( aApex, V2_Mul( aBis, nRadius / OCX_SIN( nHalf ) ) )
   nA1 := V2_Angle( V2_Sub( aT1, aCentre ) )
   nA2 := V2_Angle( V2_Sub( aT2, aCentre ) )
   nTurn := V2_Cross( aDir1, aDir2 )
   IF nTurn <= 0.0
      nS := nA1 ; nE := nA2
   ELSE
      nS := nA2 ; nE := nA1
   ENDIF
RETURN { aT1, aT2, aCentre, NormalizeAngle( nS ), NormalizeAngle( nE ) }

STATIC FUNCTION Fl_ArcThrough( aCentre, aT1, aT2 )
   LOCAL nA1 := V2_Angle( V2_Sub( aT1, aCentre ) ), nA2 := V2_Angle( V2_Sub( aT2, aCentre ) ), nS, nE
   IF ArcSpan( nA1, nA2 ) <= OCX_PI
      nS := nA1 ; nE := nA2
   ELSE
      nS := nA2 ; nE := nA1
   ENDIF
RETURN { aT1, aT2, aCentre, NormalizeAngle( nS ), NormalizeAngle( nE ) }

STATIC FUNCTION Fl_HasCentre( aOut, aCentre, nTol )
   LOCAL f
   FOR EACH f IN aOut
      IF V2_Distance( f[ FL_C ], aCentre ) <= nTol ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.

FUNCTION Fl_Between( a, b, nRadius, nTol )
   LOCAL aAnch, aOrigin, aShift, aLa, aLb, aOut := {}, aFirst, aSecond, f, aR, aOffA, aOffB, o1, o2, cr, aCentre, aT1, aT2, p0a, p0b
   IF ValType( nRadius ) != "N" .OR. nRadius != nRadius .OR. nRadius <= 0.0 .OR. ! OCX_ISFINITE( nRadius )
      RETURN {}
   ENDIF
   p0a := Cv_PointAt( a, 0.0 ) ; p0b := Cv_PointAt( b, 0.0 )
   aAnch := { { p0a[1], p0a[2], 0.0 }, { p0b[1], p0b[2], 0.0 } }
   aOrigin := Frame_Origin( Frame_Around( aAnch ) )
   IF Max( Abs( aOrigin[1] ), Abs( aOrigin[2] ) ) >= 1000.0
      aShift := Tr_Translation( { -aOrigin[1], -aOrigin[2] } )
      aLa := Cv_Transformed( a, aShift ) ; aLb := Cv_Transformed( b, aShift )
      IF aLa != NIL .AND. aLb != NIL
         aR := Fl_Between( aLa, aLb, nRadius, nTol )
         FOR EACH f IN aR
            f := { { f[1][1] + aOrigin[1], f[1][2] + aOrigin[2] }, { f[2][1] + aOrigin[1], f[2][2] + aOrigin[2] }, ;
                   { f[3][1] + aOrigin[1], f[3][2] + aOrigin[2] }, f[4], f[5] }
            AAdd( aOut, f )
         NEXT
         RETURN aOut
      ENDIF
   ENDIF
   // una polilinea se redondea tramo a tramo
   IF a[ CV_KIND ] == CV_POLYLINE .OR. b[ CV_KIND ] == CV_POLYLINE
      FOR EACH aFirst IN Fl_Pieces( a )
         FOR EACH aSecond IN Fl_Pieces( b )
            FOR EACH f IN Fl_Between( aFirst, aSecond, nRadius, nTol )
               IF ! Fl_HasCentre( aOut, f[ FL_C ], nTol ) ; AAdd( aOut, f ) ; ENDIF
            NEXT
         NEXT
      NEXT
      RETURN aOut
   ENDIF
   aOffA := Fl_Offsets( a, nRadius ) ; aOffB := Fl_Offsets( b, nRadius )
   IF aOffA == NIL .OR. aOffB == NIL
      RETURN Fl_General( a, b, nRadius, nTol )
   ENDIF
   FOR EACH o1 IN aOffA
      FOR EACH o2 IN aOffB
         FOR EACH cr IN Cx_Intersect( o1, o2, nTol )
            aCentre := cr[ CR_POINT ]
            aT1 := Fl_TouchPoint( a, aCentre, nRadius, nTol )
            IF aT1 == NIL ; LOOP ; ENDIF
            aT2 := Fl_TouchPoint( b, aCentre, nRadius, nTol )
            IF aT2 == NIL ; LOOP ; ENDIF
            f := Fl_ArcThrough( aCentre, aT1, aT2 )
            IF ! Fl_HasCentre( aOut, aCentre, nTol ) ; AAdd( aOut, f ) ; ENDIF
         NEXT
      NEXT
   NEXT
RETURN aOut

STATIC FUNCTION Fl_Pieces( c )
   IF c[ CV_KIND ] == CV_POLYLINE ; RETURN Cv_Segments( c ) ; ENDIF
RETURN { c }

// ---- Extended = { curve, nFrom, nTo } ----------------------------------------
STATIC FUNCTION Fl_ExtOf( c, nReach )
   LOCAL aR, aUnit
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE .OR. c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE
      aR := Cv_AsRay( c )
      IF aR == NIL ; RETURN NIL ; ENDIF
      aUnit := V2_Normalize( aR[2] )
      IF aUnit == NIL ; RETURN NIL ; ENDIF
      RETURN { Cv_Line( V2_Sub( aR[1], V2_Mul( aUnit, nReach ) ), V2_Add( aR[1], V2_Mul( aUnit, nReach ) ) ), 0.0, 1.0 }
   CASE c[ CV_KIND ] == CV_ARC
      RETURN { Cv_Circle( c[ CV_DATA ][ AR_CENTRE ], c[ CV_DATA ][ AR_RADIUS ] ), 0.0, 1.0 }
   CASE c[ CV_KIND ] == CV_ELLIPSE
      RETURN { Cv_Ellipse( EA_Full( c[ CV_DATA ][ EA_ELLIPSE ] ) ), 0.0, 1.0 }
   ENDCASE
RETURN { c, 0.0, 1.0 }

STATIC FUNCTION Fl_ExtPoint( e, t ) ; RETURN Cv_PointAt( e[1], t )

STATIC FUNCTION Fl_ExtNormal( e, t )
   LOCAL h := 0.000001 * ( e[3] - e[2] ), nLo := Max( t - h, e[2] ), nHi := Min( t + h, e[3] ), aD
   aD := V2_Normalize( V2_Sub( Fl_ExtPoint( e, nHi ), Fl_ExtPoint( e, nLo ) ) )
   IF aD == NIL ; RETURN NIL ; ENDIF
RETURN V2_Perpendicular( aD )

STATIC FUNCTION Fl_ExtOffset( e, t, nSide, nRadius )
   LOCAL aN := Fl_ExtNormal( e, t )
   IF aN == NIL ; RETURN NIL ; ENDIF
RETURN V2_Add( Fl_ExtPoint( e, t ), V2_Mul( aN, nRadius * nSide ) )

STATIC FUNCTION Fl_Size( c )
   LOCAL aPts := Cv_Tessellate( c, 4.0 ), nM := 0.0, p
   FOR EACH p IN aPts
      nM := Max( nM, V2_Distance( { p[1], p[2] }, { aPts[1][1], aPts[1][2] } ) )
   NEXT
RETURN nM

STATIC FUNCTION Fl_Params( e )
   LOCAL a := {}, i
   FOR i := 0 TO 256
      AAdd( a, e[2] + ( e[3] - e[2] ) * i / 256 )
   NEXT
RETURN a

STATIC FUNCTION Fl_General( a, b, nRadius, nTol )
   LOCAL nSamples := 256, nReach, ea, eb, ta, tb, aOut := {}, sa, sb, pa, pb, i, j, t, aHit, aSeed, aCv, nT, nU
   LOCAL aCentre, aT1, aT2, a0, a1, b0, b1, nS, nW, aSides := { 1.0, -1.0 }
   nReach := 4.0 * ( Fl_Size( a ) + Fl_Size( b ) + nRadius )
   ea := Fl_ExtOf( a, nReach ) ; eb := Fl_ExtOf( b, nReach )
   IF ea == NIL .OR. eb == NIL ; RETURN {} ; ENDIF
   ta := Fl_Params( ea ) ; tb := Fl_Params( eb )
   FOR EACH sa IN aSides
      FOR EACH sb IN aSides
         pa := {} ; pb := {}
         FOR EACH t IN ta ; AAdd( pa, Fl_ExtOffset( ea, t, sa, nRadius ) ) ; NEXT
         FOR EACH t IN tb ; AAdd( pb, Fl_ExtOffset( eb, t, sb, nRadius ) ) ; NEXT
         FOR i := 1 TO nSamples
            a0 := pa[ i ] ; a1 := pa[ i + 1 ]
            IF a0 == NIL .OR. a1 == NIL ; LOOP ; ENDIF
            FOR j := 1 TO nSamples
               b0 := pb[ j ] ; b1 := pb[ j + 1 ]
               IF b0 == NIL .OR. b1 == NIL ; LOOP ; ENDIF
               aHit := Ix_LineLine( a0, V2_Sub( a1, a0 ), b0, V2_Sub( b1, b0 ) )
               IF aHit == NIL ; LOOP ; ENDIF
               nS := aHit[1] ; nW := aHit[2]
               IF ! ( nS >= 0.0 .AND. nS <= 1.0 ) .OR. ! ( nW >= 0.0 .AND. nW <= 1.0 ) ; LOOP ; ENDIF
               aSeed := { ta[i] + ( ta[i+1] - ta[i] ) * nS, tb[j] + ( tb[j+1] - tb[j] ) * nW }
               aCv := Fl_Converge( ea, eb, sa, sb, nRadius, aSeed, nTol )
               IF aCv == NIL ; LOOP ; ENDIF
               nT := aCv[1] ; nU := aCv[2]
               aCentre := Fl_ExtOffset( ea, nT, sa, nRadius )
               IF aCentre == NIL ; LOOP ; ENDIF
               aT1 := Fl_ExtPoint( ea, nT ) ; aT2 := Fl_ExtPoint( eb, nU )
               IF Abs( V2_Distance( aCentre, aT2 ) - nRadius ) > nTol ; LOOP ; ENDIF
               IF ! Fl_HasCentre( aOut, aCentre, nTol )
                  AAdd( aOut, Fl_ArcThrough( aCentre, aT1, aT2 ) )
               ENDIF
            NEXT
         NEXT
      NEXT
   NEXT
RETURN aOut

STATIC FUNCTION Fl_Resid( a, b, sa, sb, nRadius, t, u )
   LOCAL pa := Fl_ExtOffset( a, t, sa, nRadius ), pb
   IF pa == NIL ; RETURN NIL ; ENDIF
   pb := Fl_ExtOffset( b, u, sb, nRadius )
   IF pb == NIL ; RETURN NIL ; ENDIF
RETURN V2_Sub( pa, pb )

STATIC FUNCTION Fl_Converge( a, b, sa, sb, nRadius, aSeed, nTol )
   LOCAL t := aSeed[1], u := aSeed[2], ha := 0.0000001 * ( a[3] - a[2] ), hb := 0.0000001 * ( b[3] - b[2] )
   LOCAL i, f, r1, r2, dt, du, nDet
   FOR i := 1 TO 40
      f := Fl_Resid( a, b, sa, sb, nRadius, t, u )
      IF f == NIL ; RETURN NIL ; ENDIF
      IF V2_Length( f ) <= nTol * 0.001 ; RETURN { t, u } ; ENDIF
      r1 := Fl_Resid( a, b, sa, sb, nRadius, t + ha, u ) ; r2 := Fl_Resid( a, b, sa, sb, nRadius, t - ha, u )
      IF r1 == NIL .OR. r2 == NIL ; RETURN NIL ; ENDIF
      dt := V2_Mul( V2_Sub( r1, r2 ), 0.5 / ha )
      r1 := Fl_Resid( a, b, sa, sb, nRadius, t, u + hb ) ; r2 := Fl_Resid( a, b, sa, sb, nRadius, t, u - hb )
      IF r1 == NIL .OR. r2 == NIL ; RETURN NIL ; ENDIF
      du := V2_Mul( V2_Sub( r1, r2 ), 0.5 / hb )
      nDet := dt[1] * du[2] - dt[2] * du[1]
      IF Abs( nDet ) < ( 10.0 ^ -300 ) ; RETURN NIL ; ENDIF
      t := t - ( f[1] * du[2] - f[2] * du[1] ) / nDet
      u := u - ( dt[1] * f[2] - dt[2] * f[1] ) / nDet
      t := Max( a[2], Min( a[3], t ) )
      u := Max( b[2], Min( b[3], u ) )
   NEXT
   f := Fl_Resid( a, b, sa, sb, nRadius, t, u )
   IF f == NIL ; RETURN NIL ; ENDIF
   IF V2_Length( f ) <= nTol ; RETURN { t, u } ; ENDIF
RETURN NIL

STATIC FUNCTION Fl_Offsets( c, nRadius )
   LOCAL aR, aAcross, aOut := {}, nSide
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE .OR. c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE
      aR := Cv_AsRay( c )
      IF aR == NIL ; RETURN NIL ; ENDIF
      aAcross := V2_Normalize( aR[2] )
      IF aAcross == NIL ; RETURN NIL ; ENDIF
      aAcross := V2_Perpendicular( aAcross )
      FOR EACH nSide IN { 1.0, -1.0 }
         AAdd( aOut, Cv_XLine( V2_Add( aR[1], V2_Mul( aAcross, nRadius * nSide ) ), aR[2] ) )
      NEXT
      RETURN aOut
   CASE c[ CV_KIND ] == CV_CIRCLE
      RETURN Fl_Concentric( c[ CV_DATA ][ CI_CENTRE ], c[ CV_DATA ][ CI_RADIUS ], nRadius )
   CASE c[ CV_KIND ] == CV_ARC
      RETURN Fl_Concentric( c[ CV_DATA ][ AR_CENTRE ], c[ CV_DATA ][ AR_RADIUS ], nRadius )
   ENDCASE
RETURN NIL

STATIC FUNCTION Fl_Concentric( aCentre, nOwn, nRadius )
   LOCAL aOut := {}, r
   FOR EACH r IN { nOwn + nRadius, Abs( nOwn - nRadius ) }
      IF r > 0.000000000001 ; AAdd( aOut, Cv_Circle( aCentre, r ) ) ; ENDIF
   NEXT
RETURN aOut

STATIC FUNCTION Fl_TouchPoint( c, aCentre, nRadius, nTol )
   LOCAL aR, nSq, aTouch := NIL
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE .OR. c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE
      aR := Cv_AsRay( c )
      IF aR == NIL ; RETURN NIL ; ENDIF
      nSq := V2_LengthSquared( aR[2] )
      IF nSq <= 0.0 ; RETURN NIL ; ENDIF
      aTouch := V2_Add( aR[1], V2_Mul( aR[2], V2_Dot( V2_Sub( aCentre, aR[1] ), aR[2] ) / nSq ) )
   CASE c[ CV_KIND ] == CV_CIRCLE
      aTouch := Fl_CircleTouch( c[ CV_DATA ][ CI_CENTRE ], c[ CV_DATA ][ CI_RADIUS ], aCentre, nRadius )
   CASE c[ CV_KIND ] == CV_ARC
      aTouch := Fl_CircleTouch( c[ CV_DATA ][ AR_CENTRE ], c[ CV_DATA ][ AR_RADIUS ], aCentre, nRadius )
   ENDCASE
   IF aTouch == NIL ; RETURN NIL ; ENDIF
   IF Abs( V2_Distance( aTouch, aCentre ) - nRadius ) <= nTol ; RETURN aTouch ; ENDIF
RETURN NIL

STATIC FUNCTION Fl_CircleTouch( aMiddle, nOwn, aCentre, nRadius )
   LOCAL aOut := V2_Normalize( V2_Sub( aCentre, aMiddle ) ), p1, p2
   IF aOut == NIL ; RETURN NIL ; ENDIF
   p1 := V2_Add( aMiddle, V2_Mul( aOut, nOwn ) ) ; p2 := V2_Sub( aMiddle, V2_Mul( aOut, nOwn ) )
   // min_by: el primero si hay empate
RETURN IIF( Abs( V2_Distance( p2, aCentre ) - nRadius ) < Abs( V2_Distance( p1, aCentre ) - nRadius ), p2, p1 )
