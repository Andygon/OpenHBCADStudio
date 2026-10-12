/* Port de opencadkernel/src/geom2d/constraint_inference.rs (557 lineas, 3 tests ported 1:1). UTF-8.
   ParametricPrimitive = Curve (Cv_Line / Cv_Circle / Cv_Arc). Endpoint: 0 = Start, 1 = End.
   InferredConstraint = { nKind(IK_*), nFirst(base 0), nSecond, nFirstEp, nSecondEp }; las de una entidad usan nFirst.
   InferenceSettings = { aPriority, nDistance, nAngle, lTangentShare, lPerpIntersect }. Prefijo Ci_. */
#include "ocx.ch"

FUNCTION Ci_AllKinds() ; RETURN { IK_COINCIDENT, IK_COLLINEAR, IK_PARALLEL, IK_PERPENDICULAR, IK_TANGENT, IK_CONCENTRIC, IK_HORIZONTAL, IK_VERTICAL, IK_EQUAL }
FUNCTION Ci_DefaultSettings() ; RETURN { Ci_AllKinds(), 0.05, 1.0 * OCX_PI / 180.0, .T., .T. }

STATIC FUNCTION Ci_Endpoints( c )
   LOCAL d := c[ CV_DATA ]
   DO CASE
   CASE c[ CV_KIND ] == CV_LINE
      RETURN { d[1], d[2] }
   CASE c[ CV_KIND ] == CV_ARC
      RETURN { { d[ AR_CENTRE ][1] + d[ AR_RADIUS ] * OCX_COS( d[ AR_START ] ), d[ AR_CENTRE ][2] + d[ AR_RADIUS ] * OCX_SIN( d[ AR_START ] ) }, ;
               { d[ AR_CENTRE ][1] + d[ AR_RADIUS ] * OCX_COS( d[ AR_END ] ), d[ AR_CENTRE ][2] + d[ AR_RADIUS ] * OCX_SIN( d[ AR_END ] ) } }
   ENDCASE
RETURN NIL

// -> { centre, radius } o NIL
STATIC FUNCTION Ci_Circle( c )
   LOCAL d := c[ CV_DATA ]
   DO CASE
   CASE c[ CV_KIND ] == CV_CIRCLE ; RETURN { d[1], d[2] }
   CASE c[ CV_KIND ] == CV_ARC    ; RETURN { d[ AR_CENTRE ], d[ AR_RADIUS ] }
   ENDCASE
RETURN NIL

STATIC FUNCTION Ci_UnitLine( l ) ; RETURN V2_Normalize( V2_Sub( l[2], l[1] ) )

STATIC FUNCTION Ci_LineDistance( l, p )
   LOCAL u := Ci_UnitLine( l )
   IF u == NIL ; RETURN NIL ; ENDIF
RETURN Abs( V2_Cross( V2_Sub( p, l[1] ), u ) )

STATIC FUNCTION Ci_LineLength( l ) ; RETURN V2_Distance( l[1], l[2] )
STATIC FUNCTION Ci_SameMeasure( a, b ) ; RETURN Abs( a - b ) <= 0.000000001 * Max( Max( Abs( a ), Abs( b ) ), 1.0 )

STATIC FUNCTION Ci_ParamOnLine( l, p )
   LOCAL d := V2_Sub( l[2], l[1] ), nLs := V2_Dot( d, d )
   IF nLs > 0.000000000000000000000001
      RETURN V2_Dot( V2_Sub( p, l[1] ), d ) / nLs
   ENDIF
RETURN NIL

STATIC FUNCTION Ci_LineIntParams( a, b )
   LOCAL p := a[1], q := b[1], r := V2_Sub( a[2], p ), s := V2_Sub( b[2], q ), nDen := V2_Cross( r, s ), qp
   IF Abs( nDen ) <= 0.00000000000000000001 ; RETURN NIL ; ENDIF
   qp := V2_Sub( q, p )
RETURN { V2_Cross( qp, s ) / nDen, V2_Cross( qp, r ) / nDen }

STATIC FUNCTION Ci_ParamSlack( l, nDist )
   LOCAL nLen := Ci_LineLength( l )
   IF nLen > 0.00000000000000000001 ; RETURN nDist / nLen ; ENDIF
RETURN 0.0

STATIC FUNCTION Ci_SegsIntersectWithin( a, b, nDist )
   LOCAL h := Ci_LineIntParams( a, b ), sa, sb
   IF h == NIL ; RETURN .F. ; ENDIF
   sa := Ci_ParamSlack( a, nDist ) ; sb := Ci_ParamSlack( b, nDist )
RETURN h[1] >= -sa .AND. h[1] <= 1.0 + sa .AND. h[2] >= -sb .AND. h[2] <= 1.0 + sb

// -> { point, t } o NIL
STATIC FUNCTION Ci_LineCircleContact( l, aCirc )
   LOCAL t := Ci_ParamOnLine( l, aCirc[1] ), d
   IF t == NIL ; RETURN NIL ; ENDIF
   d := V2_Sub( l[2], l[1] )
RETURN { V2_Add( l[1], V2_Mul( d, t ) ), t }

STATIC FUNCTION Ci_LineCircleOnSegment( l, aCirc, nDist )
   LOCAL h := Ci_LineCircleContact( l, aCirc ), nSlack
   IF h == NIL ; RETURN .F. ; ENDIF
   nSlack := Ci_ParamSlack( l, nDist )
RETURN h[2] >= -nSlack .AND. h[2] <= 1.0 + nSlack

STATIC FUNCTION Ci_PrimContainsCirclePoint( c, p, nDist )
   LOCAL d, aDelta, aEnds, e
   IF c[ CV_KIND ] != CV_ARC ; RETURN .T. ; ENDIF
   d := c[ CV_DATA ]
   aDelta := V2_Sub( p, d[ AR_CENTRE ] )
   IF AngleWithinArc( OCX_ATAN2( aDelta[2], aDelta[1] ), d[ AR_START ], d[ AR_END ] ) ; RETURN .T. ; ENDIF
   aEnds := Ci_Endpoints( c )
   FOR EACH e IN aEnds
      IF V2_Distance( e, p ) <= nDist ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.

STATIC FUNCTION Ci_CircleCircleContact( a, b, nDist )
   LOCAL ca := a[1], cb := b[1], aDelta := V2_Sub( cb, ca ), nCentres := V2_Length( aDelta ), aDir, nSign
   IF nCentres <= 0.00000000000000000001 ; RETURN NIL ; ENDIF
   aDir := V2_Div( aDelta, nCentres )
   IF Abs( nCentres - ( a[2] + b[2] ) ) <= nDist
      RETURN V2_Add( ca, V2_Mul( aDir, a[2] ) )
   ENDIF
   IF Abs( nCentres - Abs( a[2] - b[2] ) ) <= nDist
      nSign := IIf( a[2] >= b[2], 1.0, -1.0 )
      RETURN V2_Add( ca, V2_Mul( aDir, nSign * a[2] ) )
   ENDIF
RETURN NIL

STATIC FUNCTION Ci_IsPair( n ) ; RETURN n == IK_COLLINEAR .OR. n == IK_CONCENTRIC .OR. n == IK_PARALLEL .OR. n == IK_PERPENDICULAR .OR. n == IK_TANGENT .OR. n == IK_EQUAL

STATIC FUNCTION Ci_AxisState( aCands, nEnt )
   LOCAL h := .F., v := .F., it
   FOR EACH it IN aCands
      IF it[ IC_KIND ] == IK_HORIZONTAL .AND. it[ IC_FIRST ] == nEnt ; h := .T. ; ENDIF
      IF it[ IC_KIND ] == IK_VERTICAL .AND. it[ IC_FIRST ] == nEnt ; v := .T. ; ENDIF
   NEXT
RETURN { h, v }

STATIC FUNCTION Ci_Pair( nKind, f, s ) ; RETURN { nKind, f, s, 0, 0 }

FUNCTION Ci_InferWithSettings( aPrims, aSet )
   LOCAL aPriority := aSet[1], nDist := aSet[2], nAngle := aSet[3], lTanShare := aSet[4], lPerpInt := aSet[5]
   LOCAL nSin, aCands := {}, i, f, s, u, a, b, ai, bi, ua, ub, nCross, ca, cb, nCentres, p, line, circ, aAxis, aFin := {}, it, aS1, aS2, lKeep, kd, h
   IF ! OCX_ISFINITE( nDist ) .OR. nDist < 0.0 .OR. ! OCX_ISFINITE( nAngle ) .OR. nAngle < 0.0 ; RETURN {} ; ENDIF
   nSin := Abs( OCX_SIN( nAngle ) )
   FOR i := 0 TO Len( aPrims ) - 1
      IF aPrims[ i + 1 ][ CV_KIND ] == CV_LINE
         u := Ci_UnitLine( aPrims[ i + 1 ][ CV_DATA ] )
         IF u != NIL
            IF Abs( u[2] ) <= nSin ; AAdd( aCands, { IK_HORIZONTAL, i, 0, 0, 0 } ) ; ENDIF
            IF Abs( u[1] ) <= nSin ; AAdd( aCands, { IK_VERTICAL, i, 0, 0, 0 } ) ; ENDIF
         ENDIF
      ENDIF
   NEXT
   FOR f := 0 TO Len( aPrims ) - 1
      FOR s := f + 1 TO Len( aPrims ) - 1
         a := Ci_Endpoints( aPrims[ f + 1 ] ) ; b := Ci_Endpoints( aPrims[ s + 1 ] )
         IF a != NIL .AND. b != NIL
            FOR ai := 0 TO 1
               FOR bi := 0 TO 1
                  IF V2_Distance( a[ ai + 1 ], b[ bi + 1 ] ) <= nDist
                     AAdd( aCands, { IK_COINCIDENT, f, s, ai, bi } )
                  ENDIF
               NEXT
            NEXT
         ENDIF
         IF aPrims[ f + 1 ][ CV_KIND ] == CV_LINE .AND. aPrims[ s + 1 ][ CV_KIND ] == CV_LINE
            a := aPrims[ f + 1 ][ CV_DATA ] ; b := aPrims[ s + 1 ][ CV_DATA ]
            ua := Ci_UnitLine( a ) ; ub := Ci_UnitLine( b )
            IF ua != NIL .AND. ub != NIL
               nCross := Abs( V2_Cross( ua, ub ) )
               IF nCross <= nSin
                  h := Ci_LineDistance( a, b[1] )
                  IF h != NIL .AND. h <= nDist
                     AAdd( aCands, Ci_Pair( IK_COLLINEAR, f, s ) )
                  ELSE
                     AAdd( aCands, Ci_Pair( IK_PARALLEL, f, s ) )
                  ENDIF
               ELSEIF Abs( V2_Dot( ua, ub ) ) <= nSin .AND. ( ! lPerpInt .OR. Ci_SegsIntersectWithin( a, b, nDist ) )
                  AAdd( aCands, Ci_Pair( IK_PERPENDICULAR, f, s ) )
               ENDIF
               IF Ci_SameMeasure( Ci_LineLength( a ), Ci_LineLength( b ) )
                  AAdd( aCands, Ci_Pair( IK_EQUAL, f, s ) )
               ENDIF
            ENDIF
         ENDIF
         ca := Ci_Circle( aPrims[ f + 1 ] ) ; cb := Ci_Circle( aPrims[ s + 1 ] )
         DO CASE
         CASE ca != NIL .AND. cb != NIL
            nCentres := V2_Distance( ca[1], cb[1] )
            IF nCentres <= nDist
               AAdd( aCands, Ci_Pair( IK_CONCENTRIC, f, s ) )
            ELSE
               p := Ci_CircleCircleContact( ca, cb, nDist )
               IF p != NIL .AND. ( ! lTanShare .OR. ( Ci_PrimContainsCirclePoint( aPrims[ f + 1 ], p, nDist ) .AND. Ci_PrimContainsCirclePoint( aPrims[ s + 1 ], p, nDist ) ) )
                  AAdd( aCands, Ci_Pair( IK_TANGENT, f, s ) )
               ENDIF
            ENDIF
            IF Ci_SameMeasure( ca[2], cb[2] )
               AAdd( aCands, Ci_Pair( IK_EQUAL, f, s ) )
            ENDIF
         CASE ca != NIL .AND. cb == NIL .AND. aPrims[ s + 1 ][ CV_KIND ] == CV_LINE
            line := aPrims[ s + 1 ][ CV_DATA ] ; circ := ca
            IF Ci_TangentLineCircle( line, circ, aPrims[ f + 1 ], nDist, lTanShare )
               AAdd( aCands, Ci_Pair( IK_TANGENT, f, s ) )
            ENDIF
         CASE ca == NIL .AND. cb != NIL .AND. aPrims[ f + 1 ][ CV_KIND ] == CV_LINE
            line := aPrims[ f + 1 ][ CV_DATA ] ; circ := cb
            IF Ci_TangentLineCircle( line, circ, aPrims[ s + 1 ], nDist, lTanShare )
               AAdd( aCands, Ci_Pair( IK_TANGENT, f, s ) )
            ENDIF
         ENDCASE
      NEXT
   NEXT
   // filtrar por prioridad habilitada
   aAxis := {}
   FOR EACH it IN aCands
      IF AScan( aPriority, it[ IC_KIND ] ) > 0 ; AAdd( aAxis, it ) ; ENDIF
   NEXT
   aCands := {}
   FOR EACH it IN aAxis
      lKeep := .T.
      IF Ci_IsPair( it[ IC_KIND ] )
         aS1 := Ci_AxisState( aAxis, it[ IC_FIRST ] ) ; aS2 := Ci_AxisState( aAxis, it[ IC_SECOND ] )
         DO CASE
         CASE it[ IC_KIND ] == IK_COLLINEAR .OR. it[ IC_KIND ] == IK_PARALLEL
            lKeep := ! ( ( aS1[1] .AND. aS2[1] ) .OR. ( aS1[2] .AND. aS2[2] ) )
         CASE it[ IC_KIND ] == IK_PERPENDICULAR
            lKeep := ! ( ( aS1[1] .AND. aS2[2] ) .OR. ( aS1[2] .AND. aS2[1] ) )
         ENDCASE
      ENDIF
      IF lKeep ; AAdd( aCands, it ) ; ENDIF
   NEXT
   FOR EACH kd IN aPriority
      FOR EACH it IN aCands
         IF it[ IC_KIND ] == kd ; AAdd( aFin, it ) ; ENDIF
      NEXT
   NEXT
RETURN aFin

STATIC FUNCTION Ci_TangentLineCircle( line, circ, aCircPrim, nDist, lTanShare )
   LOCAL h := Ci_LineDistance( line, circ[1] ), hc
   IF h == NIL .OR. ! ( Abs( h - circ[2] ) <= nDist ) ; RETURN .F. ; ENDIF
   IF ! lTanShare ; RETURN .T. ; ENDIF
   hc := Ci_LineCircleContact( line, circ )
   IF hc == NIL ; RETURN .F. ; ENDIF
RETURN Ci_LineCircleOnSegment( line, circ, nDist ) .AND. Ci_PrimContainsCirclePoint( aCircPrim, hc[1], nDist )

FUNCTION Ci_Infer( aPrims, nDistTol, nAngle )
   LOCAL aSet := Ci_DefaultSettings()
   aSet[2] := nDistTol ; aSet[3] := nAngle
RETURN Ci_InferWithSettings( aPrims, aSet )
