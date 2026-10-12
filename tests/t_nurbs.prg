/* Port de #[cfg(test)] de nurbs.rs (solo funciones ya traducidas). UTF-8. */
#include "ocx.ch"
STATIC FUNCTION CL( a, b, e ) ; RETURN Abs( a[1]-b[1] ) < e .AND. Abs( a[2]-b[2] ) < e
STATIC FUNCTION Linear()
RETURN NC_New( 1, { {0.0,0.0}, {10.0,0.0} }, {}, NIL )
STATIC FUNCTION RationalQuarter()
RETURN NC_New( 2, { {1.0,0.0}, {1.0,1.0}, {0.0,1.0} }, { 0.0,0.0,0.0,1.0,1.0,1.0 }, { 1.0, OCX_SQRT2_2, 1.0 } )

PROCEDURE T_Nurbs()
   LOCAL c, q, i, t, p, e, aD
   // [extra] new: grado 0 / pocos puntos -> NIL
   Chk( ValType( NC_New( 0, { {0.0,0.0}, {1.0,0.0} }, {}, NIL ) ) == "U", "degree 0 is not a curve" )
   Chk( ValType( NC_New( 2, { {0.0,0.0}, {1.0,0.0} }, {}, NIL ) ) == "U", "too_few_control_points_is_not_a_curve" )
   // a_malformed_knot_vector_falls_back_to_a_clamped_uniform_one
   c := NC_New( 2, { {0.0,0.0}, {1.0,2.0}, {2.0,0.0}, {3.0,2.0} }, { 0.0, 1.0 }, NIL )
   Chk( ValType( c ) == "A" .AND. Len( c[ NC_KNOTS ] ) == 7 .AND. c[ NC_KNOTS ][ 1 ] == 0.0 .AND. ATail( c[ NC_KNOTS ] ) == 1.0, "malformed knots fallback" )
   // nonsense_weights_are_discarded_rather_than_dividing_by_zero
   c := NC_New( 1, { {0.0,0.0}, {1.0,0.0} }, {}, { 0.0, -1.0 } )
   Chk( c[ NC_WEIGHTS ][ 1 ] == 1.0 .AND. c[ NC_WEIGHTS ][ 2 ] == 1.0 .AND. ! NC_IsRational( c ), "nonsense weights discarded" )
   // degree_one_reproduces_the_control_polygon
   c := Linear()
   Chk( CL( NC_PointAt( c, 0.0 ), {0.0,0.0}, 0.000000001 ) .AND. CL( NC_PointAt( c, 0.5 ), {5.0,0.0}, 0.000000001 ) .AND. CL( NC_PointAt( c, 1.0 ), {10.0,0.0}, 0.000000001 ), "degree one polygon" )
   // a_straight_run_has_a_constant_derivative
   Chk( CL( NC_DerivativeAt( c, 0.2 ), {10.0,0.0}, 0.000001 ) .AND. CL( NC_DerivativeAt( c, 0.8 ), {10.0,0.0}, 0.000001 ), "constant derivative" )
   // weights_are_applied: rational quarter circle stays on the unit circle
   q := RationalQuarter()
   FOR i := 0 TO 10
      p := NC_PointAt( q, i / 10.0 )
      Chk( Abs( Sqrt( p[1]*p[1] + p[2]*p[2] ) - 1.0 ) < 0.000000001, "rational quarter on circle" )
   NEXT
   Chk( NC_IsRational( q ), "rational detected" )
   // the_derivative_of_a_circle_is_perpendicular_to_its_radius
   FOR i := 1 TO 9
      t := i / 10.0
      p := NC_PointAt( q, t ); e := NC_DerivativeAt( q, t )
      Chk( Abs( p[1]*e[1] + p[2]*e[2] ) < 0.000001, "derivative perpendicular" )
   NEXT
   // the_derivative_matches_a_difference_quotient
   c := NC_New( 3, { {0.0,0.0}, {1.0,3.0}, {3.0,3.0}, {4.0,0.0}, {6.0,1.0} }, {}, NIL )
   aD := NC_Domain( c )
   FOR i := 1 TO 9
      t := aD[1] + ( aD[2] - aD[1] ) * i / 10.0
      p := NC_DerivativeAtKnot( c, t )
      e := { ( NC_PointAtKnot( c, t + 0.000001 )[1] - NC_PointAtKnot( c, t - 0.000001 )[1] ) / 0.000002, ;
             ( NC_PointAtKnot( c, t + 0.000001 )[2] - NC_PointAtKnot( c, t - 0.000001 )[2] ) / 0.000002 }
      Chk( CL( p, e, 0.0001 ), "[extra] derivative vs quotient" )
   NEXT
   // a_clamped_curve_starts_and_ends_on_its_outer_control_points
   Chk( CL( NC_PointAt( c, 0.0 ), {0.0,0.0}, 0.000000001 ) .AND. CL( NC_PointAt( c, 1.0 ), {6.0,1.0}, 0.000000001 ), "clamped ends" )
   // the_parameter_inverts_the_evaluation
   FOR i := 1 TO 9
      t := i / 10.0
      Chk( Abs( NC_ParameterAt( c, NC_PointAt( c, t ) ) - t ) < 0.0001, "parameter inverts evaluation" )
   NEXT
   // tessellation_keeps_both_ends_and_stays_on_the_curve
   p := NC_Tessellate( c, 8 )
   Chk( CL( p[1], {0.0,0.0}, 0.000000001 ) .AND. CL( ATail( p ), {6.0,1.0}, 0.000000001 ), "tess ends" )
   // a_closed_curve_is_recognised
   Chk( NC_IsClosed( NC_New( 2, { {0.0,0.0}, {2.0,0.0}, {2.0,2.0}, {0.0,0.0} }, {}, NIL ) ), "closed recognised" )
   Chk( ! NC_IsClosed( c ), "open not closed" )
   // new_strict rejects bad data
   Chk( ValType( NC_NewStrict( 1, { {0.0,0.0}, {1.0,0.0} }, { 0.0,0.0,1.0 }, { 1.0, 1.0 } ) ) == "U", "[extra] strict rejects bad knot count" )
   Chk( ValType( NC_NewStrict( 1, { {0.0,0.0}, {1.0,0.0} }, { 0.0,0.0,1.0,1.0 }, { 1.0, 1.0 } ) ) == "A", "[extra] strict accepts" )
RETURN
