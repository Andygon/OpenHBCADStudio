/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/snap.prg
   Origen Rust: opencadkernel/src/geom2d/snap.rs (583 lineas)
   Estado: TRADUCIDO (tests en tests/t_snap.prg; el test con interpolate va como [extra]).
   SnapPoint = { nKind (SK_*), aPoint, nT }
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION SP_New( nKind, aPoint, nT ) ; RETURN { nKind, aPoint, nT }

FUNCTION Sn_CharacteristicPoints( c )
   LOCAL aOut := {}, aSegs, nCount, i, seg, q, aArcQ, d := c[ CV_DATA ], aLast
   IF c[ CV_KIND ] == CV_POLYLINE
      aSegs := Cv_Segments( c ) ; nCount := Len( aSegs )
      FOR i := 0 TO nCount - 1
         seg := aSegs[ i + 1 ]
         AAdd( aOut, SP_New( SK_ENDPOINT, Cv_PointAt( seg, 0.0 ), Sn_Span( i, 0.0, nCount ) ) )
         AAdd( aOut, SP_New( SK_MIDPOINT, Cv_PointAt( seg, 0.5 ), Sn_Span( i, 0.5, nCount ) ) )
         IF seg[ CV_KIND ] == CV_ARC
            AAdd( aOut, SP_New( SK_CENTRE, seg[ CV_DATA ][ AR_CENTRE ], 0.0 ) )
            aArcQ := Sn_Quadrants( seg, seg[ CV_DATA ][ AR_CENTRE ], { seg[ CV_DATA ][ AR_START ], seg[ CV_DATA ][ AR_END ] } )
            FOR EACH q IN aArcQ
               AAdd( aOut, SP_New( q[ SP_KIND ], q[ SP_POINT ], Sn_Span( i, q[ SP_T ], nCount ) ) )
            NEXT
         ENDIF
      NEXT
      IF ! d[ PL_CLOSED ] .AND. nCount > 0
         aLast := ATail( aSegs )
         AAdd( aOut, SP_New( SK_ENDPOINT, Cv_PointAt( aLast, 1.0 ), 1.0 ) )
      ENDIF
      RETURN aOut
   ENDIF
   IF ! Cv_IsClosed( c ) .AND. Cv_Extent( c ) == EXT_BOUNDED
      AAdd( aOut, SP_New( SK_ENDPOINT, Cv_PointAt( c, 0.0 ), 0.0 ) )
      AAdd( aOut, SP_New( SK_ENDPOINT, Cv_PointAt( c, 1.0 ), 1.0 ) )
      AAdd( aOut, SP_New( SK_MIDPOINT, Cv_PointAt( c, 0.5 ), 0.5 ) )
   ELSEIF Cv_Extent( c ) == EXT_FORWARD
      AAdd( aOut, SP_New( SK_ENDPOINT, Cv_PointAt( c, 0.0 ), 0.0 ) )
   ENDIF
   DO CASE
   CASE c[ CV_KIND ] == CV_CIRCLE
      AAdd( aOut, SP_New( SK_CENTRE, d[ CI_CENTRE ], 0.0 ) )
      AEval( Sn_Quadrants( c, d[ CI_CENTRE ], NIL ), {| x | AAdd( aOut, x ) } )
   CASE c[ CV_KIND ] == CV_ARC
      AAdd( aOut, SP_New( SK_CENTRE, d[ AR_CENTRE ], 0.0 ) )
      AEval( Sn_Quadrants( c, d[ AR_CENTRE ], { d[ AR_START ], d[ AR_END ] } ), {| x | AAdd( aOut, x ) } )
   CASE c[ CV_KIND ] == CV_ELLIPSE
      AAdd( aOut, SP_New( SK_CENTRE, d[ EA_ELLIPSE ][ 1 ], 0.0 ) )
      AEval( Sn_EllipseQuadrants( d ), {| x | AAdd( aOut, x ) } )
   ENDCASE
RETURN aOut

STATIC FUNCTION Sn_Span( nIndex, t, nCount ) ; RETURN ( nIndex + t ) / nCount

STATIC FUNCTION Sn_Quadrants( c, aCentre, aArc )
   LOCAL aOut := {}, i, nAngle, nRadius, aPoint
   FOR i := 0 TO 3
      nAngle := i * OCX_FRAC_PI_2
      IF aArc != NIL .AND. ! AngleWithinArc( nAngle, aArc[1], aArc[2] ) ; LOOP ; ENDIF
      nRadius := V2_Distance( Cv_PointAt( c, 0.0 ), aCentre )
      aPoint := V2_Add( aCentre, V2_Mul( { OCX_COS( nAngle ), OCX_SIN( nAngle ) }, nRadius ) )
      AAdd( aOut, SP_New( SK_QUADRANT, aPoint, Cv_ParameterAt( c, aPoint ) ) )
   NEXT
RETURN aOut

STATIC FUNCTION Sn_EllipseQuadrants( ea )
   LOCAL nSweep := EA_Sweep( ea ), aOut := {}, i, nParam, nTravelled
   FOR i := 0 TO 3
      nParam := i * OCX_FRAC_PI_2
      nTravelled := OCX_REMEUCLID( nParam - ea[ EA_START ], OCX_TAU )
      IF nTravelled <= nSweep + 0.000000001
         AAdd( aOut, SP_New( SK_QUADRANT, Ell_PointAt( ea[ EA_ELLIPSE ], nParam ), nTravelled / nSweep ) )
      ENDIF
   NEXT
RETURN aOut

FUNCTION Sn_PerpendicularFrom( c, aFrom )
   LOCAL aFeet := {}, aCentre, nRadius, aDir, nSide, aOut := {}, t, nExt := Cv_Extent( c )
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE .OR. c[ CV_KIND ] == CV_RAY .OR. c[ CV_KIND ] == CV_XLINE
      aFeet := { Cv_ParameterAt( c, aFrom ) }
   CASE c[ CV_KIND ] == CV_CIRCLE .OR. c[ CV_KIND ] == CV_ARC
      IF c[ CV_KIND ] == CV_CIRCLE
         aCentre := c[ CV_DATA ][ CI_CENTRE ] ; nRadius := c[ CV_DATA ][ CI_RADIUS ]
      ELSE
         aCentre := c[ CV_DATA ][ AR_CENTRE ] ; nRadius := c[ CV_DATA ][ AR_RADIUS ]
      ENDIF
      aDir := V2_Normalize( V2_Sub( aFrom, aCentre ) )
      IF aDir != NIL
         FOR EACH nSide IN { 1.0, -1.0 }
            AAdd( aFeet, Cv_ParameterAt( c, V2_Add( aCentre, V2_Mul( aDir, nRadius * nSide ) ) ) )
         NEXT
      ENDIF
   OTHERWISE
      aFeet := Sn_StationaryDistances( c, aFrom )
   ENDCASE
   FOR EACH t IN aFeet
      IF ! Ext_Holds( nExt, t ) ; LOOP ; ENDIF
      IF nExt == EXT_BOUNDED ; t := Max( 0.0, Min( 1.0, t ) ) ; ENDIF
      AAdd( aOut, SP_New( SK_PERPENDICULAR, Cv_PointAt( c, t ), t ) )
   NEXT
RETURN aOut

STATIC FUNCTION Sn_Slope( c, aFrom, t )
   LOCAL nStep := 0.0000001
   LOCAL nBefore := V2_Distance( Cv_PointAt( c, Max( t - nStep, 0.0 ) ), aFrom )
   LOCAL nAfter := V2_Distance( Cv_PointAt( c, Min( t + nStep, 1.0 ) ), aFrom )
RETURN nAfter - nBefore

STATIC FUNCTION Sn_StationaryDistances( c, aFrom )
   LOCAL nSamples := 128, aOut := {}, nPrev, i, t, nCur, nLow, nHigh, nMid, k
   nPrev := Sn_Slope( c, aFrom, 0.0 )
   FOR i := 1 TO nSamples
      t := i / nSamples
      nCur := Sn_Slope( c, aFrom, t )
      IF nPrev == 0.0 .OR. ( nPrev < 0.0 ) != ( nCur < 0.0 )
         nLow := ( i - 1 ) / nSamples ; nHigh := t
         FOR k := 1 TO 60
            nMid := ( nLow + nHigh ) * 0.5
            IF ( Sn_Slope( c, aFrom, nLow ) < 0.0 ) == ( Sn_Slope( c, aFrom, nMid ) < 0.0 )
               nLow := nMid
            ELSE
               nHigh := nMid
            ENDIF
         NEXT
         AAdd( aOut, ( nLow + nHigh ) * 0.5 )
      ENDIF
      nPrev := nCur
   NEXT
RETURN aOut

FUNCTION Sn_TangentFrom( c, aFrom )
   LOCAL aCentre, nRadius, aAway, nDist, nBase, nOffset, nAngle, aPoint, t, aOut := {}
   IF c[ CV_KIND ] == CV_CIRCLE
      aCentre := c[ CV_DATA ][ CI_CENTRE ] ; nRadius := c[ CV_DATA ][ CI_RADIUS ]
   ELSEIF c[ CV_KIND ] == CV_ARC
      aCentre := c[ CV_DATA ][ AR_CENTRE ] ; nRadius := c[ CV_DATA ][ AR_RADIUS ]
   ELSE
      RETURN {}
   ENDIF
   aAway := V2_Sub( aFrom, aCentre ) ; nDist := V2_Length( aAway )
   IF nDist <= nRadius + 0.000000000001 ; RETURN {} ; ENDIF
   nBase := V2_Angle( aAway ) ; nOffset := OCX_ACOS( nRadius / nDist )
   FOR EACH nAngle IN { nBase + nOffset, nBase - nOffset }
      aPoint := V2_Add( aCentre, V2_Mul( { OCX_COS( nAngle ), OCX_SIN( nAngle ) }, nRadius ) )
      t := Cv_ParameterAt( c, aPoint )
      IF V2_Distance( Cv_PointAt( c, t ), aPoint ) < 0.000001
         AAdd( aOut, SP_New( SK_TANGENT, aPoint, t ) )
      ENDIF
   NEXT
RETURN aOut

FUNCTION Sn_NearestTo( c, aFrom )
   LOCAL aFound := Co_ClosestPoint( c, aFrom )
RETURN SP_New( SK_PERPENDICULAR, aFound[ CL_P ], aFound[ CL_T ] )
