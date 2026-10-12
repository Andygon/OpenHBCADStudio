/* Port 1:1 de #[cfg(test)] de arclength.rs. UTF-8. */
#include "ocx.ch"
STATIC FUNCTION Walked( c, nSteps )
   LOCAL i, nSum := 0.0
   FOR i := 0 TO nSteps - 1
      nSum += V2_Distance( Cv_PointAt( c, i / nSteps ), Cv_PointAt( c, ( i + 1 ) / nSteps ) )
   NEXT
RETURN nSum
STATIC FUNCTION Strt( x, y ) ; RETURN PV_Straight( { x, y } )
STATIC FUNCTION RatQuarter()
   LOCAL w := OCX_COS( OCX_PI / 4.0 )
RETURN Cv_Nurbs( NC_New( 2, { {100.0,0.0}, {100.0,100.0}, {0.0,100.0} }, { 0.0,0.0,0.0,1.0,1.0,1.0 }, { 1.0, w, 1.0 } ) )

PROCEDURE T_Arclength()
   LOCAL line, circle, arc, quarter, expected, ell, integ, stepped, total, nGap, aPts, i, nStep, nChord
   LOCAL poly, middle, corner, endp, curve, pt, ang, ray, local1, remote, c, t, nAna, aBefore, aAfter, nScale, aN
   // a_line_measures_its_own_span
   line := Cv_Line( {0.0,0.0}, {3.0,4.0} )
   Chk( Abs( Cv_Length(line) - 5.0 ) < 0.000000000001, "line length" )
   pt := Cv_PointAtDistance( line, 2.5 ); Chk( pt[1] == 1.5 .AND. pt[2] == 2.0, "line point_at_distance" )
   Chk( Abs( Cv_ParameterAtDistance( line, 1.25 ) - 0.25 ) < 0.000000000001, "line param at distance" )
   // circle/arc closed forms
   circle := Cv_Circle( {0.0,0.0}, 10.0 ); Chk( Abs( Cv_Length(circle) - OCX_TAU*10.0 ) < 0.000000000001, "circle length" )
   arc := Cv_Arc( {1.0,2.0}, 4.0, 0.0, OCX_FRAC_PI_2 ); Chk( Abs( Cv_Length(arc) - 4.0*OCX_FRAC_PI_2 ) < 0.000000000001, "arc length" )
   quarter := Cv_PointAtDistance( arc, Cv_Length(arc) * 0.25 ); expected := Cv_PointAt( arc, 0.25 )
   Chk( Abs( quarter[1]-expected[1] ) < 0.000000000001, "arc quarter" )
   // ellipse integrated vs walked
   ell := Cv_Ellipse( { Ell_New( {0.0,0.0}, 100.0, 40.0, {1.0,0.0} ), 0.0, OCX_TAU } )
   integ := Cv_Length( ell ); stepped := Walked( ell, 200000 )
   Chk( Abs( integ - stepped ) < 0.0001 * stepped, "ellipse integrated vs walked" )
   // an_ellipse_spaced_by_distance_is_not_spaced_by_parameter
   ell := Cv_Ellipse( { Ell_New( {0.0,0.0}, 100.0, 10.0, {1.0,0.0} ), 0.0, OCX_TAU } )
   total := Cv_Length( ell )
   Chk( V2_Distance( Cv_PointAtDistance( ell, total*0.25 ), Cv_PointAt( ell, 0.25 ) ) < 0.0001, "ellipse quarter" )
   nGap := V2_Distance( Cv_PointAtDistance( ell, total*0.125 ), Cv_PointAt( ell, 0.125 ) )
   Chk( nGap > 10.0, "distance vs parameter gap " + LTrim( Str( nGap ) ) )
   // even_spacing_really_is_even
   ell := Cv_Ellipse( { Ell_New( {5.0,-3.0}, 60.0, 15.0, {0.6,0.8} ), 0.0, OCX_TAU } )
   total := Cv_Length( ell ); nStep := total / 12.0; aPts := {}
   FOR i := 0 TO 12 ; AAdd( aPts, Cv_PointAtDistance( ell, nStep * i ) ) ; NEXT
   FOR i := 1 TO 12
      nChord := V2_Distance( aPts[i], aPts[i+1] )
      Chk( Abs( nChord - nStep ) < 0.05 * nStep, "even spacing " + LTrim(Str(i)) )
   NEXT
   // a_polyline_counts_its_bulges_rather_than_its_chords
   poly := Cv_Polyline( PL_New( { Strt(0.0,0.0), PV_Curved({100.0,0.0},1.0), Strt(200.0,0.0) }, .F. ) )
   expected := 100.0 + OCX_PI * 50.0
   Chk( Abs( Cv_Length(poly) - expected ) < 0.000000001 .AND. Cv_Length(poly) > 250.0, "polyline bulge length" )
   middle := Cv_PointAtDistance( poly, expected * 0.5 ); Chk( middle[1] > 100.0, "polyline middle on arc" )
   // a_polyline_walks_to_its_own_vertices
   poly := Cv_Polyline( PL_New( { Strt(0.0,0.0), Strt(30.0,0.0), Strt(30.0,40.0) }, .F. ) )
   Chk( Abs( Cv_Length(poly) - 70.0 ) < 0.000000000001, "polyline 70" )
   corner := Cv_PointAtDistance( poly, 30.0 ); Chk( Abs(corner[1]-30.0)<0.000000001 .AND. Abs(corner[2])<0.000000001, "polyline corner" )
   endp := Cv_PointAtDistance( poly, 70.0 ); Chk( Abs(endp[2]-40.0)<0.000000001, "polyline end" )
   // spline length
   curve := RatQuarter(); expected := 100.0 * OCX_FRAC_PI_2
   Chk( Abs( Cv_Length(curve) - expected ) < 0.000001 * expected .AND. Cv_Length(curve) < 190.0, "spline length" )
   total := Cv_Length( curve )
   FOR i := 0 TO 8
      pt := Cv_PointAtDistance( curve, total * i / 8.0 ); ang := V2_Angle( pt )
      Chk( Abs( V2_Length(pt) - 100.0 ) < 0.000001 .AND. Abs( ang - OCX_FRAC_PI_2*i/8.0 ) < 0.000001, "spline walked by distance " + LTrim(Str(i)) )
   NEXT
   // an_unbounded_curve_reports_an_infinite_length
   ray := Cv_Ray( {0.0,0.0}, {3.0,4.0} )
   Chk( Cv_Length( ray ) == OCX_INF(), "ray infinite" )
   pt := Cv_PointAtDistance( ray, 5.0 ); Chk( Abs(pt[1]-3.0)<0.000000000001 .AND. Abs(pt[2]-4.0)<0.000000000001, "ray walked" )
   // distances_outside_the_curve_clamp_to_its_ends
   line := Cv_Line( {0.0,0.0}, {10.0,0.0} )
   pt := Cv_PointAtDistance( line, -5.0 ); Chk( pt[1]==0.0 .AND. pt[2]==0.0, "clamp low" )
   pt := Cv_PointAtDistance( line, 1000.0 ); Chk( pt[1]==10.0 .AND. pt[2]==0.0, "clamp high" )
   // a_collapsed_curve_has_nothing_to_measure
   line := Cv_Line( {7.0,7.0}, {7.0,7.0} ); Chk( Cv_Length(line)==0.0 .AND. Cv_ParameterAtDistance(line,1.0)==0.0, "collapsed" )
   // the_tangent_agrees_with_how_the_point_moves
   FOR EACH c IN { Cv_Circle({1.0,2.0},7.0), Cv_Arc({0.0,0.0},3.0,0.5,2.0), Cv_Ellipse({Ell_New({0.0,0.0},9.0,4.0,{0.6,0.8}),0.3,2.9}) }
      FOR i := 1 TO 9
         t := i / 10.0
         aBefore := Cv_PointAt( c, t - 0.0000001 ); aAfter := Cv_PointAt( c, t + 0.0000001 )
         aN := V2_Div( V2_Sub( aAfter, aBefore ), 2.0 * 0.0000001 )
         nAna := Cv_TangentAt( c, t )
         nScale := Max( V2_Length( aN ), 1.0 )
         Chk( V2_Length( V2_Sub( nAna, aN ) ) < 0.0001 * nScale, "tangent vs numeric kind " + LTrim(Str(c[1])) + " t=" + LTrim(Str(t)) )
      NEXT
   NEXT
   // survey_coordinates_measure_the_same_length
   local1 := Cv_Ellipse( { Ell_New( {0.0,0.0}, 30.0, 12.0, {1.0,0.0} ), 0.0, OCX_TAU } )
   remote := Cv_Ellipse( { Ell_New( {512345.678,4512345.678}, 30.0, 12.0, {1.0,0.0} ), 0.0, OCX_TAU } )
   Chk( Abs( Cv_Length(local1) - Cv_Length(remote) ) < 0.000000001, "survey length" )
RETURN
