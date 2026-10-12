/* Port 1:1 de #[cfg(test)] de curve.rs. UTF-8. */
#include "ocx.ch"
STATIC FUNCTION CL( a, b ) ; RETURN Abs( a[1]-b[1] ) < 0.000000001 .AND. Abs( a[2]-b[2] ) < 0.000000001
STATIC FUNCTION Strt( x, y ) ; RETURN PV_Straight( { x, y } )

PROCEDURE T_Curve()
   LOCAL curves, c, s, m, e, line, arc, poly, mid, lone, empty, pts, p, dx, dy
   // every_curve_runs_from_zero_to_one
   curves := { Cv_Line( {1.0,2.0}, {5.0,7.0} ), ;
               Cv_Arc( {0.0,0.0}, 3.0, 0.0, OCX_FRAC_PI_2 ), ;
               Cv_Ellipse( { Ell_New( {2.0,2.0}, 4.0, 1.0, {1.0,0.0} ), 0.0, 1.0 } ) }
   FOR EACH c IN curves
      s := Cv_PointAt( c, 0.0 ); m := Cv_PointAt( c, 0.5 ); e := Cv_PointAt( c, 1.0 )
      Chk( ! CL( s, e ), "curve start!=end" )
      Chk( ! CL( s, m ) .AND. ! CL( m, e ), "curve start!=mid!=end" )
   NEXT
   // a_line_parameter_is_the_fraction_along_it
   line := Cv_Line( {0.0,0.0}, {10.0,0.0} )
   Chk( CL( Cv_PointAt(line,0.0), {0.0,0.0} ) .AND. CL( Cv_PointAt(line,0.25), {2.5,0.0} ) .AND. CL( Cv_PointAt(line,1.0), {10.0,0.0} ), "line fraction" )
   // a_parameter_past_the_end_continues_the_line
   Chk( CL( Cv_PointAt(line,1.5), {15.0,0.0} ) .AND. CL( Cv_PointAt(line,-0.5), {-5.0,0.0} ), "line extends" )
   // an_arc_parameter_walks_its_own_sweep
   arc := Cv_Arc( {0.0,0.0}, 1.0, 0.0, OCX_FRAC_PI_2 )
   Chk( CL( Cv_PointAt(arc,0.0), {1.0,0.0} ) .AND. CL( Cv_PointAt(arc,1.0), {0.0,1.0} ), "arc ends" )
   mid := Cv_PointAt( arc, 0.5 ); Chk( Abs( mid[1]-mid[2] ) < 0.000000001, "arc 45deg" )
   // closedness_is_reported_per_shape
   Chk( ! Cv_IsClosed( Cv_Line({0.0,0.0},{1.0,0.0}) ), "line open" )
   Chk( Cv_IsClosed( Cv_Circle({0.0,0.0},1.0) ), "circle closed" )
   Chk( Cv_IsClosed( Cv_Arc({0.0,0.0},1.0,1.0,1.0) ), "degenerate arc closed" )
   Chk( ! Cv_IsClosed( Cv_Arc({0.0,0.0},1.0,0.0,OCX_FRAC_PI_2) ), "quarter arc open" )
   // a_polyline_shares_its_parameter_between_segments
   poly := Cv_Polyline( PL_New( { Strt(0.0,0.0), Strt(1.0,0.0), Strt(2.0,0.0), Strt(3.0,0.0) }, .F. ) )
   Chk( Cv_SegmentCount( poly ) == 3, "3 segments" )
   Chk( CL( Cv_PointAt(poly,0.0), {0.0,0.0} ) .AND. CL( Cv_PointAt(poly,1.0/3.0), {1.0,0.0} ) .AND. CL( Cv_PointAt(poly,0.5), {1.5,0.0} ) .AND. CL( Cv_PointAt(poly,1.0), {3.0,0.0} ), "poly parameter" )
   // a_closed_polyline_has_a_segment_back_to_the_start
   poly := Cv_Polyline( PL_New( { Strt(0.0,0.0), Strt(1.0,0.0), Strt(1.0,1.0) }, .T. ) )
   Chk( Cv_SegmentCount( poly ) == 3 .AND. Cv_IsClosed( poly ) .AND. CL( Cv_PointAt(poly,1.0), {0.0,0.0} ), "closed poly returns home" )
   // a_polyline_arc_segment_bulges
   poly := Cv_Polyline( PL_New( { PV_Curved({0.0,0.0},1.0), Strt(2.0,0.0) }, .F. ) )
   mid := Cv_PointAt( poly, 0.5 )
   Chk( Abs( mid[1]-1.0 ) < 0.000000001 .AND. Abs( mid[2]+1.0 ) < 0.000000001, "poly arc bulges" )
   // tessellation_keeps_both_endpoints
   FOR EACH c IN { Cv_Line({0.0,0.0},{4.0,3.0}), Cv_Arc({0.0,0.0},2.0,0.0,1.0) }
      pts := Cv_Tessellate( c, 20.0 )
      Chk( CL( pts[1], Cv_PointAt(c,0.0) ) .AND. CL( ATail(pts), Cv_PointAt(c,1.0) ), "tess endpoints" )
   NEXT
   // a_straight_line_needs_only_its_endpoints
   Chk( Len( Cv_Tessellate( Cv_Line({0.0,0.0},{100.0,0.0}), 50.0 ) ) == 2, "line 2 pts" )
   // a_tessellated_arc_stays_on_its_circle
   arc := Cv_Arc( {3.0,-4.0}, 2.5, 0.5, 4.0 )
   FOR EACH p IN Cv_Tessellate( arc, 20.0 )
      dx := p[1] - 3.0; dy := p[2] + 4.0
      Chk( Abs( Sqrt( dx*dx + dy*dy ) - 2.5 ) < 0.000000001, "arc on circle" )
   NEXT
   // a_degenerate_polyline_does_not_panic
   lone := Cv_Polyline( PL_New( { Strt(2.0,3.0) }, .F. ) )
   Chk( Cv_SegmentCount( lone ) == 0 .AND. CL( Cv_PointAt(lone,0.5), {2.0,3.0} ) .AND. Len( Cv_Tessellate(lone,20.0) ) == 1, "lone vertex" )
   empty := Cv_Polyline( PL_New() )
   Chk( CL( Cv_PointAt(empty,0.5), {0.0,0.0} ) .AND. Len( Cv_Tessellate(empty,20.0) ) == 0, "empty polyline" )
   // [extra] parameter_at inverts point_at
   FOR EACH c IN { Cv_Line({0.0,0.0},{10.0,5.0}), Cv_Circle({1.0,1.0},2.0), Cv_Arc({0.0,0.0},1.0,0.5,2.5), Cv_Ellipse({Ell_New({0.0,0.0},4.0,2.0,{1.0,0.0}),0.0,3.0}), ;
                   Cv_Polyline(PL_New({PV_Curved({0.0,0.0},0.5),Strt(2.0,0.0),Strt(2.0,2.0)},.F.)) }
      Chk( Abs( Cv_ParameterAt( c, Cv_PointAt( c, 0.3 ) ) - 0.3 ) < 0.00001, "[extra] parameter inverts " + LTrim(Str(c[1])) )
   NEXT
   // [extra] segments / as_ray / extent
   Chk( Len( Cv_Segments( Cv_Polyline(PL_New({PV_Curved({0.0,0.0},1.0),Strt(2.0,0.0),Strt(2.0,2.0)},.T.)) ) ) == 3, "[extra] segments closed" )
   Chk( Cv_Extent( Cv_Ray({0.0,0.0},{1.0,0.0}) ) == EXT_FORWARD .AND. Ext_Holds( EXT_BOUNDED, 1.0000000001 ) .AND. ! Ext_Holds( EXT_BOUNDED, 1.1 ), "[extra] extent" )
RETURN
