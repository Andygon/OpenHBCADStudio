/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/geom2d/transform.prg
   Origen Rust: opencadkernel/src/geom2d/transform.rs (574 lineas)
   Estado: TRADUCIDO (tests portados en tests/t_transform.prg; el test
   a_spline_follows_any_map_exactly necesita NurbsCurve::interpolate, pendiente).
   Transform = { aXAxis, aYAxis, aOrigin } (indices TR_*).
   Cv_Transformed( c, tr ) -> Curve o NIL (Option::None).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Tr_Identity()    ; RETURN { { 1.0, 0.0 }, { 0.0, 1.0 }, { 0.0, 0.0 } }
FUNCTION Tr_Translation( aBy ) ; RETURN { { 1.0, 0.0 }, { 0.0, 1.0 }, { aBy[ 1 ], aBy[ 2 ] } }

FUNCTION Tr_Rotation( nAngle )
   LOCAL s := OCX_SIN( nAngle ), c := OCX_COS( nAngle )
RETURN { { c, s }, { -s, c }, { 0.0, 0.0 } }

FUNCTION Tr_Scale( x, y ) ; RETURN { { x, 0.0 }, { 0.0, y }, { 0.0, 0.0 } }

// scale, luego giro, luego movimiento
FUNCTION Tr_Insertion( aAt, aScale, nAngle )
RETURN Tr_ThenOf( Tr_Translation( aAt ), Tr_ThenOf( Tr_Rotation( nAngle ), Tr_Scale( aScale[ 1 ], aScale[ 2 ] ) ) )

// "self.then_of(first)": self aplicado despues de first
FUNCTION Tr_ThenOf( tr, aFirst )
RETURN { Tr_ApplyVector( tr, aFirst[ TR_X ] ), Tr_ApplyVector( tr, aFirst[ TR_Y ] ), Tr_ApplyPoint( tr, aFirst[ TR_O ] ) }

FUNCTION Tr_ApplyPoint( tr, p )
RETURN { tr[ TR_O ][ 1 ] + tr[ TR_X ][ 1 ] * p[ 1 ] + tr[ TR_Y ][ 1 ] * p[ 2 ], ;
         tr[ TR_O ][ 2 ] + tr[ TR_X ][ 2 ] * p[ 1 ] + tr[ TR_Y ][ 2 ] * p[ 2 ] }

FUNCTION Tr_ApplyVector( tr, v )
RETURN { tr[ TR_X ][ 1 ] * v[ 1 ] + tr[ TR_Y ][ 1 ] * v[ 2 ], tr[ TR_X ][ 2 ] * v[ 1 ] + tr[ TR_Y ][ 2 ] * v[ 2 ] }

FUNCTION Tr_Determinant( tr ) ; RETURN V2_Cross( tr[ TR_X ], tr[ TR_Y ] )

FUNCTION Tr_IsSimilarity( tr )
   LOCAL x := V2_Length( tr[ TR_X ] ), y := V2_Length( tr[ TR_Y ] )
   IF x < 0.000000000001 .OR. y < 0.000000000001
      RETURN .F.
   ENDIF
RETURN Abs( x - y ) <= 0.000000001 * Max( x, y ) .AND. Abs( V2_Dot( tr[ TR_X ], tr[ TR_Y ] ) ) <= 0.000000001 * x * y

STATIC FUNCTION SimilarityScale( tr ) ; RETURN V2_Length( tr[ TR_X ] )

FUNCTION Cv_Transformed( c, by )
   LOCAL d := c[ CV_DATA ], nKind := c[ CV_KIND ], nTurn, nS, nE, aPts, aP, lArcs, nFlip, aVerts, v, aNew
   DO CASE
   CASE nKind == CV_LINE
      RETURN Cv_Line( Tr_ApplyPoint( by, d[ LN_START ] ), Tr_ApplyPoint( by, d[ LN_END ] ) )
   CASE nKind == CV_RAY
      RETURN Cv_Ray( Tr_ApplyPoint( by, d[ RY_ORIGIN ] ), Tr_ApplyVector( by, d[ RY_DIR ] ) )
   CASE nKind == CV_XLINE
      RETURN Cv_XLine( Tr_ApplyPoint( by, d[ XL_BASE ] ), Tr_ApplyVector( by, d[ XL_DIR ] ) )
   CASE nKind == CV_CIRCLE .AND. Tr_IsSimilarity( by )
      RETURN Cv_Circle( Tr_ApplyPoint( by, d[ CI_CENTRE ] ), d[ CI_RADIUS ] * SimilarityScale( by ) )
   CASE nKind == CV_ARC .AND. Tr_IsSimilarity( by )
      nTurn := V2_Angle( Tr_ApplyVector( by, { 1.0, 0.0 } ) )
      IF Tr_Determinant( by ) < 0.0
         // un reflejo manda t a (turn - t): se invierte el sentido, los extremos se cruzan
         nS := nTurn - d[ AR_END ] ; nE := nTurn - d[ AR_START ]
      ELSE
         nS := d[ AR_START ] + nTurn ; nE := d[ AR_END ] + nTurn
      ENDIF
      RETURN Cv_Arc( Tr_ApplyPoint( by, d[ AR_CENTRE ] ), d[ AR_RADIUS ] * SimilarityScale( by ), nS, nE )
   CASE nKind == CV_CIRCLE      // escala desigual: sale una elipse
      RETURN Cv_Ellipse( EA_Full( TransformedEllipse( Ell_New( d[ CI_CENTRE ], d[ CI_RADIUS ], d[ CI_RADIUS ], { 1.0, 0.0 } ), by ) ) )
   CASE nKind == CV_ARC
      RETURN EllipticalArcFrom( Ell_New( d[ AR_CENTRE ], d[ AR_RADIUS ], d[ AR_RADIUS ], { 1.0, 0.0 } ), d[ AR_START ], d[ AR_START ] + Ar_Sweep( d ), by )
   CASE nKind == CV_ELLIPSE
      RETURN EllipticalArcFrom( d[ EA_ELLIPSE ], d[ EA_START ], d[ EA_START ] + EA_Sweep( d ), by )
   CASE nKind == CV_NURBS
      // una NURBS es un promedio ponderado de sus puntos de control; un mapa afin conmuta con eso
      aPts := {}
      FOR EACH aP IN NC_ControlPoints( d )
         AAdd( aPts, Tr_ApplyPoint( by, aP ) )
      NEXT
      aNew := NC_New( NC_Degree( d ), aPts, AClone( NC_Knots( d ) ), AClone( NC_Weights( d ) ) )
      IF aNew == NIL ; RETURN NIL ; ENDIF
      RETURN Cv_Nurbs( aNew )
   CASE nKind == CV_POLYLINE
      lArcs := .F.
      FOR EACH v IN d[ PL_VERTS ]
         IF Abs( v[ PV_BULGE ] ) > 0.000000000001 ; lArcs := .T. ; EXIT ; ENDIF
      NEXT
      IF lArcs .AND. ! Tr_IsSimilarity( by )
         RETURN NIL
      ENDIF
      // un bulge es la tangente de un cuarto del angulo incluido; un espejo cambia el lado
      nFlip := IIF( Tr_Determinant( by ) < 0.0, -1.0, 1.0 )
      aVerts := {}
      FOR EACH v IN d[ PL_VERTS ]
         AAdd( aVerts, PV_Curved( Tr_ApplyPoint( by, v[ PV_POS ] ), v[ PV_BULGE ] * nFlip ) )
      NEXT
      RETURN Cv_Polyline( PL_New( aVerts, d[ PL_CLOSED ] ) )
   ENDCASE
RETURN NIL

STATIC FUNCTION TransformedEllipse( e, by )
   LOCAL aMinor := Ell_MinorAxis( e )
   LOCAL p := Tr_ApplyVector( by, V2_Mul( e[ ELL_MAJOR_AXIS ], e[ ELL_MAJOR_R ] ) )
   LOCAL q := Tr_ApplyVector( by, V2_Mul( aMinor, e[ ELL_MINOR_R ] ) )
   LOCAL nShift := PrincipalShift( p, q ), aAx, aFirst, aSecond, aMajor, aMinorV, aN
   aAx := PrincipalAxes( p, q, nShift )
   aFirst := aAx[ 1 ] ; aSecond := aAx[ 2 ]
   IF V2_Length( aFirst ) >= V2_Length( aSecond )
      aMajor := aFirst ; aMinorV := aSecond
   ELSE
      aMajor := aSecond ; aMinorV := aFirst
   ENDIF
   aN := V2_Normalize( aMajor )
   IF aN == NIL ; aN := { 1.0, 0.0 } ; ENDIF
RETURN Ell_New( Tr_ApplyPoint( by, e[ ELL_CENTRE ] ), V2_Length( aMajor ), V2_Length( aMinorV ), aN )

STATIC FUNCTION PrincipalShift( p, q )
   LOCAL nNum := 2.0 * V2_Dot( p, q ), nDen := V2_LengthSquared( p ) - V2_LengthSquared( q )
   IF Abs( nNum ) < 0.000000000000001 .AND. Abs( nDen ) < 0.000000000000001
      RETURN 0.0
   ENDIF
RETURN 0.5 * OCX_ATAN2( nNum, nDen )

STATIC FUNCTION PrincipalAxes( p, q, nShift )
   LOCAL s := OCX_SIN( nShift ), c := OCX_COS( nShift )
   LOCAL s2 := OCX_SIN( nShift + OCX_FRAC_PI_2 ), c2 := OCX_COS( nShift + OCX_FRAC_PI_2 )
RETURN { V2_Add( V2_Mul( p, c ), V2_Mul( q, s ) ), V2_Add( V2_Mul( p, c2 ), V2_Mul( q, s2 ) ) }

STATIC FUNCTION EllParamOf( e, by, res, t )
   LOCAL aWorld := Tr_ApplyPoint( by, Ell_PointAt( e, t ) )
   LOCAL aRel := V2_Sub( aWorld, res[ ELL_CENTRE ] ), aMajor := res[ ELL_MAJOR_AXIS ]
   LOCAL nAlong := V2_Dot( aRel, aMajor ) / res[ ELL_MAJOR_R ]
   LOCAL nAcross := V2_Dot( aRel, V2_Perpendicular( aMajor ) ) / res[ ELL_MINOR_R ]
RETURN OCX_ATAN2( nAcross, nAlong )

STATIC FUNCTION EllipticalArcFrom( e, nStart, nEnd, by )
   LOCAL res := TransformedEllipse( e, by ), nNewS, nNewE, nTmp
   nNewS := EllParamOf( e, by, res, nStart )
   nNewE := EllParamOf( e, by, res, nEnd )
   // un espejo invierte el sentido: los extremos se cruzan
   IF Tr_Determinant( by ) < 0.0
      nTmp := nNewS ; nNewS := nNewE ; nNewE := nTmp
   ENDIF
   IF OCX_REMEUCLID( nNewE - nNewS, OCX_TAU ) < 0.000000000001
      nNewE := nNewS + OCX_TAU
   ENDIF
RETURN Cv_Ellipse( { res, nNewS, nNewE } )
