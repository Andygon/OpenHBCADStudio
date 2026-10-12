/* Port 1:1 de #[cfg(test)] de transform.rs (salvo el test de spline interpolada). UTF-8. */
#include "ocx.ch"
STATIC FUNCTION NR( a, b ) ; RETURN V2_Distance( a, b ) < 0.000000001
STATIC FUNCTION Seg( a, b ) ; RETURN Cv_Line( a, b )
STATIC FUNCTION Strt( x, y ) ; RETURN PV_Straight( { x, y } )

STATIC FUNCTION AgreesPointwise( c, by, cName )
   LOCAL moved := Cv_Transformed( c, by ), i, t, direct, after, lOk := .T.
   IF moved == NIL ; Chk( .F., cName + ": should transform" ) ; RETURN .F. ; ENDIF
   FOR i := 0 TO 20
      t := i / 20.0
      direct := Tr_ApplyPoint( by, Cv_PointAt( c, t ) )
      after := Cv_PointAt( moved, Cv_ParameterAt( moved, direct ) )
      IF ! NR( after, direct ) ; lOk := .F. ; ? "  t=", t, direct[1], direct[2], after[1], after[2] ; ENDIF
   NEXT
RETURN Chk( lOk, cName + ": pointwise" )

PROCEDURE T_Transform()
   LOCAL by, sc, mv, circle, moved, arc, ell, chain, mirrored, ray, orig, ln, spl
   Chk( NR( Tr_ApplyPoint( Tr_Identity(), {3.0,-4.0} ), {3.0,-4.0} ), "identity" )
   by := Tr_Translation( {10.0,5.0} )
   Chk( NR( Tr_ApplyPoint( by, {1.0,1.0} ), {11.0,6.0} ) .AND. NR( Tr_ApplyVector( by, {1.0,1.0} ), {1.0,1.0} ), "translation" )
   by := Tr_Rotation( OCX_FRAC_PI_2 )
   Chk( NR( Tr_ApplyVector( by, {1.0,0.0} ), {0.0,1.0} ) .AND. NR( Tr_ApplyVector( by, {0.0,1.0} ), {-1.0,0.0} ), "rotation" )
   by := Tr_Insertion( {100.0,0.0}, {2.0,2.0}, 0.0 )
   Chk( NR( Tr_ApplyPoint( by, {0.0,0.0} ), {100.0,0.0} ) .AND. NR( Tr_ApplyPoint( by, {1.0,0.0} ), {102.0,0.0} ), "insertion" )
   sc := Tr_Scale( 2.0, 2.0 ); mv := Tr_Translation( {10.0,0.0} )
   Chk( NR( Tr_ApplyPoint( Tr_ThenOf( mv, sc ), {1.0,0.0} ), {12.0,0.0} ) .AND. NR( Tr_ApplyPoint( Tr_ThenOf( sc, mv ), {1.0,0.0} ), {22.0,0.0} ), "composition" )
   Chk( Tr_IsSimilarity( Tr_Identity() ) .AND. Tr_IsSimilarity( Tr_Rotation(0.7) ) .AND. Tr_IsSimilarity( Tr_Scale(3.0,3.0) ) .AND. Tr_IsSimilarity( Tr_Scale(-2.0,2.0) ) .AND. ! Tr_IsSimilarity( Tr_Scale(2.0,1.0) ), "similarity" )
   AgreesPointwise( Seg( {1.0,2.0}, {7.0,-3.0} ), Tr_Insertion( {5.0,5.0}, {2.0,3.0}, 0.4 ), "a_line_follows_any_map" )
   circle := Cv_Circle( {1.0,2.0}, 3.0 )
   moved := Cv_Transformed( circle, Tr_Insertion( {10.0,0.0}, {2.0,2.0}, 0.5 ) )
   Chk( moved[1] == CV_CIRCLE .AND. Abs( moved[2][CI_RADIUS] - 6.0 ) < 0.000000001, "circle stays circle" )
   circle := Cv_Circle( {0.0,0.0}, 1.0 )
   moved := Cv_Transformed( circle, Tr_Scale( 3.0, 1.0 ) )
   Chk( moved[1] == CV_ELLIPSE .AND. Abs( moved[2][EA_ELLIPSE][ELL_MAJOR_R] - 3.0 ) < 0.000000001 .AND. Abs( moved[2][EA_ELLIPSE][ELL_MINOR_R] - 1.0 ) < 0.000000001, "circle -> ellipse" )
   AgreesPointwise( circle, Tr_Scale( 3.0, 1.0 ), "circle uneven pointwise" )
   arc := Cv_Arc( {0.0,0.0}, 5.0, 0.0, OCX_FRAC_PI_2 )
   AgreesPointwise( arc, Tr_Insertion( {3.0,-2.0}, {2.0,2.0}, 0.9 ), "an_arc_follows_an_even_scale_and_a_turn" )
   arc := Cv_Arc( {0.0,0.0}, 2.0, 0.2, 2.0 ); by := Tr_Scale( 4.0, 1.0 )
   moved := Cv_Transformed( arc, by )
   Chk( moved != NIL .AND. moved[1] == CV_ELLIPSE, "arc -> elliptical arc" )
   AgreesPointwise( arc, by, "arc uneven pointwise" )
   ell := Cv_Ellipse( EA_Full( Ell_New( {1.0,1.0}, 5.0, 2.0, {0.6,0.8} ) ) )
   AgreesPointwise( ell, Tr_Insertion( {2.0,3.0}, {1.5,0.5}, 0.3 ), "an_ellipse_follows_a_general_map" )
   // PENDIENTE: a_spline_follows_any_map_exactly (necesita NurbsCurve::interpolate). [extra] con NC_New:
   spl := Cv_Nurbs( NC_New( 3, { {0.0,0.0}, {2.0,4.0}, {6.0,-2.0}, {9.0,3.0}, {11.0,0.0} }, {}, NIL ) )
   AgreesPointwise( spl, Tr_Insertion( {1.0,1.0}, {2.0,0.5}, 0.7 ), "[extra] a_spline_follows_any_map (NC_New)" )
   chain := Cv_Polyline( PL_New( { Strt(0.0,0.0), Strt(2.0,0.0), Strt(2.0,2.0) }, .F. ) )
   AgreesPointwise( chain, Tr_Scale( 3.0, 0.5 ), "a_straight_polyline_follows_any_map" )
   chain := Cv_Polyline( PL_New( { PV_Curved({0.0,0.0},1.0), Strt(2.0,0.0) }, .F. ) )
   Chk( Cv_Transformed( chain, Tr_Scale( 3.0, 1.0 ) ) == NIL, "bulged polyline cannot be squashed" )
   AgreesPointwise( chain, Tr_Insertion( {5.0,5.0}, {2.0,2.0}, 0.6 ), "bulged polyline even scale" )
   mirrored := Cv_Transformed( chain, Tr_Scale( 1.0, -1.0 ) )
   Chk( Cv_PointAt( chain, 0.5 )[2] < 0.0 .AND. Cv_PointAt( mirrored, 0.5 )[2] > 0.0, "a_mirror_flips_which_way_a_bulge_bows" )
   ray := Cv_Ray( {1.0,0.0}, {1.0,0.0} )
   moved := Cv_Transformed( ray, Tr_Rotation( OCX_FRAC_PI_2 ) )
   Chk( moved[1] == CV_RAY .AND. NR( moved[2][RY_ORIGIN], {0.0,1.0} ) .AND. NR( moved[2][RY_DIR], {0.0,1.0} ), "ray keeps direction" )
   orig := { 512345.678, 4512345.678 }
   ln := Seg( orig, { orig[1] + 10.0, orig[2] } )
   moved := Cv_Transformed( ln, Tr_Translation( {1000.0,0.0} ) )
   Chk( NR( Cv_PointAt( moved, 0.0 ), { orig[1] + 1000.0, orig[2] } ) .AND. NR( Cv_PointAt( moved, 1.0 ), { orig[1] + 1010.0, orig[2] } ), "survey coordinates no drift" )
RETURN
