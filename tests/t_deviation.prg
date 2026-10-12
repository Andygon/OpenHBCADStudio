/* Port 1:1 de #[cfg(test)] de deviation.rs. UTF-8. */
#include "ocx.ch"
#define MAXSEG 16384
#define MINSEG 8

STATIC FUNCTION WorstSag( c, aPts )
   LOCAL i, nW := 0.0, aMid, aOn
   FOR i := 1 TO Len( aPts ) - 1
      aMid := V2_Lerp( aPts[i], aPts[i+1], 0.5 )
      aOn := Cv_PointAt( c, Cv_ParameterAt( c, aMid ) )
      nW := Max( nW, V2_Distance( aMid, aOn ) )
   NEXT
RETURN nW
STATIC FUNCTION Circ( r ) ; RETURN Cv_Circle( {0.0,0.0}, r )
STATIC FUNCTION NurbsArc()
   LOCAL w := OCX_COS( OCX_FRAC_PI_2 / 2.0 )
RETURN NC_New( 2, { {100.0,0.0}, {100.0,100.0}, {0.0,100.0} }, { 0.0,0.0,0.0,1.0,1.0,1.0 }, { 1.0, w, 1.0 } )

PROCEDURE T_Deviation()
   LOCAL r, tol, c, pts, sag, small, large, fine, coarse, quarter, whole, a, b, ell, i, mid, guess, j, t, d, nMin
   LOCAL asCircle, asEll, poly, nc, local1, remote, arc, lOk
   // a_chord_never_sags_further_than_asked
   FOR EACH r IN { 0.5, 10.0, 1000.0, 40000.0 }
      FOR EACH tol IN { 1.0, 0.05, 0.001 }
         c := Circ( r ); pts := Cv_TessellateWithin( c, tol )
         sag := WorstSag( c, pts )
         Chk( Len( pts ) <= MAXSEG .AND. sag <= tol * 1.000001, "chord sag r=" + LTrim(Str(r)) + " tol=" + LTrim(Str(tol)) )
      NEXT
   NEXT
   // the_cap_is_what_stops_an_unreasonable_request
   c := Circ( 250000.0 ); pts := Cv_TessellateWithin( c, 0.001 )
   Chk( Len( pts ) == MAXSEG + 1 .AND. WorstSag( c, pts ) > 0.001, "cap" )
   // bigger circle more points; slacker tolerance fewer points
   small := Len( Cv_TessellateWithin( Circ(1.0), 0.01 ) ); large := Len( Cv_TessellateWithin( Circ(10000.0), 0.01 ) )
   Chk( large > small * 50, "bigger circle more points" )
   fine := Len( Cv_TessellateWithin( Circ(100.0), 0.001 ) ); coarse := Len( Cv_TessellateWithin( Circ(100.0), 0.5 ) )
   Chk( fine > coarse * 10, "slacker tolerance fewer" )
   // a_curve_smaller_than_the_tolerance_still_looks_round
   Chk( Len( Cv_TessellateWithin( Circ(0.001), 1.0 ) ) == MINSEG + 1, "tiny curve floor" )
   // a_degenerate_tolerance_is_capped_rather_than_unbounded
   FOR EACH tol IN { 0.0, -1.0, OCX_NAN() }
      Chk( Len( Cv_TessellateWithin( Circ(10.0), tol ) ) == MAXSEG + 1, "degenerate tolerance" )
   NEXT
   // a_straight_curve_is_two_points_however_fine_the_tolerance
   Chk( Len( Cv_TessellateWithin( Cv_Line( {0.0,0.0}, {1000.0,500.0} ), 0.000000000001 ) ) == 2, "line 2 points" )
   // an_arc_spends_points_only_on_the_sweep_it_has
   quarter := Cv_Arc( {0.0,0.0}, 100.0, 0.0, OCX_FRAC_PI_2 ); whole := Circ( 100.0 )
   a := Len( Cv_TessellateWithin( quarter, 0.01 ) ); b := Len( Cv_TessellateWithin( whole, 0.01 ) )
   Chk( Abs( a - b / 4.0 ) < 4.0, "arc quarter points" )
   // an_ellipse_is_held_to_its_tightest_bend
   ell := Cv_Ellipse( { Ell_New( {0.0,0.0}, 100.0, 5.0, {1.0,0.0} ), 0.0, OCX_TAU } )
   pts := Cv_TessellateWithin( ell, 0.01 ); lOk := .T.
   FOR i := 1 TO Len( pts ) - 1
      mid := V2_Lerp( pts[i], pts[i+1], 0.5 )
      guess := OCX_ATAN2( mid[2] / 5.0, mid[1] / 100.0 )
      nMin := OCX_INF()
      FOR j := 0 TO 4000
         t := guess - 0.05 + 0.1 * ( j / 4000.0 )
         d := V2_Distance( mid, { 100.0 * OCX_COS( t ), 5.0 * OCX_SIN( t ) } )
         nMin := Min( nMin, d )
      NEXT
      IF nMin > 0.01 * 1.05 ; lOk := .F. ; ENDIF
   NEXT
   Chk( lOk, "ellipse tightest bend" )
   // the_ellipse_bound_agrees_with_the_circle_it_degenerates_to
   asCircle := Len( Cv_TessellateWithin( Circ(100.0), 0.01 ) )
   asEll := Len( Cv_TessellateWithin( Cv_Ellipse( { Ell_New( {0.0,0.0}, 100.0, 100.0, {1.0,0.0} ), 0.0, OCX_TAU } ), 0.01 ) )
   Chk( Abs( asCircle - asEll ) <= 2, "ellipse bound vs circle" )
   // a_polyline_holds_each_of_its_segments_and_shares_their_vertices
   poly := Cv_Polyline( PL_New( { PV_Straight({0.0,0.0}), PV_Curved({100.0,0.0},1.0), PV_Straight({200.0,0.0}) }, .F. ) )
   pts := Cv_TessellateWithin( poly, 0.01 ); lOk := .T.
   FOR i := 1 TO Len( pts ) - 1
      IF pts[i][1] == pts[i+1][1] .AND. pts[i][2] == pts[i+1][2] ; lOk := .F. ; ENDIF
   NEXT
   Chk( Len( pts ) > 20 .AND. lOk, "polyline shares vertices" )
   Chk( pts[1][1] == 0.0 .AND. pts[1][2] == 0.0 .AND. ATail(pts)[1] == 200.0 .AND. ATail(pts)[2] == 0.0, "polyline ends" )
   // a_spline_is_cut_where_it_bends
   pts := Cv_TessellateWithin( Cv_Nurbs( NurbsArc() ), 0.05 ); lOk := .T.
   FOR i := 1 TO Len( pts ) - 1
      mid := V2_Lerp( pts[i], pts[i+1], 0.5 )
      IF Abs( V2_Length( mid ) - 100.0 ) > 0.05 * 1.5 ; lOk := .F. ; ENDIF
   NEXT
   Chk( lOk, "spline cut where it bends" )
   // a_spline_spends_fewer_points_when_the_tolerance_is_slack
   fine := Len( Cv_TessellateWithin( Cv_Nurbs( NurbsArc() ), 0.001 ) ); coarse := Len( Cv_TessellateWithin( Cv_Nurbs( NurbsArc() ), 1.0 ) )
   Chk( fine > coarse .AND. coarse >= 5, "spline slack tolerance" )
   // a_spline_keeps_both_ends
   nc := NurbsArc(); pts := Cv_TessellateWithin( Cv_Nurbs( nc ), 0.01 )
   Chk( pts[1][1] == NC_PointAt(nc,0.0)[1] .AND. pts[1][2] == NC_PointAt(nc,0.0)[2] .AND. ATail(pts)[1] == NC_PointAt(nc,1.0)[1] .AND. ATail(pts)[2] == NC_PointAt(nc,1.0)[2], "spline ends" )
   // survey_coordinates_are_sampled_as_finely_as_local_ones
   local1 := Len( Cv_TessellateWithin( Circ(50.0), 0.01 ) )
   remote := Len( Cv_TessellateWithin( Cv_Circle( {512345.678,4512345.678}, 50.0 ), 0.01 ) )
   Chk( local1 == remote, "survey sampling" )
   // a_half_turn_of_a_big_arc_matches_the_hand_computation
   arc := Cv_Arc( {0.0,0.0}, 1000.0, 0.0, OCX_PI )
   Chk( Len( Cv_TessellateWithin( arc, 0.1 ) ) == 112 + 1, "hand computation 112" )
   // [extra] tessellate_angle de elipse y NURBS ya no esta pendiente
   Chk( Len( Cv_TessellateAngle( ell, 0.1 ) ) > 10, "[extra] ellipse tessellate_angle" )
   pts := Cv_TessellateAngle( Cv_Nurbs( NurbsArc() ), 0.1 )
   Chk( Len( pts ) > 4 .AND. Abs( V2_Length( pts[2] ) - 100.0 ) < 0.000001, "[extra] nurbs tessellate_angle" )
RETURN
