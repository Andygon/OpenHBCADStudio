/* Port 1:1 de #[cfg(test)] de intersect.rs. UTF-8. */
#include "ocx.ch"
STATIC FUNCTION SortNum( a ) ; ASort( a ) ; RETURN a

PROCEDURE T_Intersect()
   LOCAL hit, hits, angles, cosines, pts, p, onFirst, onSecond, dx, e, xs, offset, ang, eps, dist, c2, diff, cyclic
   LOCAL onLine, onEll, cenAng, a1, a2, flat, pair, skinny, d, pt
   // crossing_lines_report_both_parameters
   hit := Ix_LineLine( {0.0,0.0}, {1.0,0.0}, {5.0,-5.0}, {0.0,1.0} )
   Chk( Abs( hit[1]-5.0 ) < 0.000000000001 .AND. Abs( hit[2]-5.0 ) < 0.000000000001, "crossing lines" )
   Chk( ValType( Ix_LineLine( {0.0,0.0}, {1.0,0.0}, {0.0,3.0}, {1.0,0.0} ) ) == "U", "parallel" )
   Chk( ValType( Ix_LineLine( {0.0,0.0}, {1.0,0.0}, {2.0,0.0}, {1.0,0.0} ) ) == "U", "coincident" )
   hit := Ix_LineLine( {0.0,0.0}, {1.0,0.0}, {100.0,-1.0}, {0.0,1.0} ); Chk( hit[1] > 1.0, "param past end" )
   // line/circle
   hits := Ix_LineCircle( {-10.0,0.0}, {1.0,0.0}, {0.0,0.0}, 5.0 )
   Chk( Len(hits)==2 .AND. hits[1] < hits[2] .AND. Abs(hits[1]-5.0)<0.000000001 .AND. Abs(hits[2]-15.0)<0.000000001, "line through circle" )
   hits := Ix_LineCircle( {-10.0,5.0}, {1.0,0.0}, {0.0,0.0}, 5.0 ); Chk( Len(hits)==1 .AND. Abs(hits[1]-10.0)<0.000001, "tangent line" )
   Chk( Len( Ix_LineCircle( {-10.0,9.0}, {1.0,0.0}, {0.0,0.0}, 5.0 ) ) == 0, "missing line" )
   Chk( Len( Ix_LineCircle( {0.0,0.0}, {0.0,0.0}, {0.0,0.0}, 5.0 ) ) == 0, "zero direction" )
   // circle/circle
   angles := Ix_CircleCircleAngles( {0.0,0.0}, 1.0, {1.0,0.0}, 1.0 )
   Chk( Len(angles)==2, "two angles" )
   cosines := SortNum( { OCX_COS(angles[1]), OCX_COS(angles[2]) } )
   Chk( Abs(cosines[1]-0.5)<0.000000001 .AND. Abs(cosines[2]-0.5)<0.000000001, "cosines .5" )
   Chk( Abs( OCX_SIN(angles[1]) + OCX_SIN(angles[2]) ) < 0.000000001, "mirrored" )
   pts := Ix_CircleCirclePoints( {0.0,0.0}, 1.0, {1.0,0.0}, 1.0 ); Chk( Len(pts)==2, "two points" )
   FOR EACH p IN pts
      onFirst := Sqrt( p[1]*p[1] + p[2]*p[2] ); dx := p[1] - 1.0; onSecond := Sqrt( dx*dx + p[2]*p[2] )
      Chk( Abs(onFirst-1.0)<0.000000001 .AND. Abs(onSecond-1.0)<0.000000001, "points on both circles" )
   NEXT
   angles := Ix_CircleCircleAngles( {0.0,0.0}, 1.0, {2.0,0.0}, 1.0 ); Chk( Len(angles)==1 .AND. Abs(angles[1])<0.0001, "touching circles" )
   Chk( Len( Ix_CircleCircleAngles( {0.0,0.0},1.0,{10.0,0.0},1.0 ) )==0 .AND. Len( Ix_CircleCircleAngles( {0.0,0.0},5.0,{0.5,0.0},1.0 ) )==0 .AND. Len( Ix_CircleCircleAngles( {0.0,0.0},1.0,{0.0,0.0},1.0 ) )==0, "separated nested concentric" )
   // line/ellipse
   e := Ell_New( {0.0,0.0}, 3.0, 2.0, {1.0,0.0} )
   hits := Ix_LineEllipse( {-10.0,0.0}, {1.0,0.0}, e ); Chk( Len(hits)==2, "line through ellipse count" )
   xs := SortNum( { -10.0 + hits[1][1], -10.0 + hits[2][1] } ); Chk( Abs(xs[1]+3.0)<0.000000001 .AND. Abs(xs[2]-3.0)<0.000000001, "ellipse crossings x=+-3" )
   e := Ell_New( {4.0,-1.0}, 5.0, 2.0, {0.70710678118654752440,0.70710678118654752440} )
   p := {-6.0,-4.0}; d := {1.0,0.3}
   hits := Ix_LineEllipse( p, d, e ); Chk( Len(hits)==2, "skew two crossings" )
   FOR EACH pair IN hits
      onLine := { p[1] + pair[1]*d[1], p[2] + pair[1]*d[2] }; onEll := Ell_PointAt( e, pair[2] )
      Chk( Abs(onLine[1]-onEll[1])<0.000000001 .AND. Abs(onLine[2]-onEll[2])<0.000000001, "ellipse parameter reproduces point" )
   NEXT
   e := Ell_New( {0.0,0.0}, 5.0, 2.0, {1.0,0.0} )
   hits := Ix_LineEllipse( {-10.0,1.0}, {1.0,0.0}, e ); Chk( Len(hits)==2, "param not centre angle: count" )
   FOR EACH pair IN hits
      onLine := { -10.0 + pair[1], 1.0 }; cenAng := OCX_ATAN2( onLine[2], onLine[1] )
      Chk( Abs(pair[2]-cenAng) > 0.1 .AND. Abs( OCX_SIN(pair[2]) - 0.5 ) < 0.000000001, "t is not the centre angle" )
   NEXT
   e := Ell_New( {0.0,0.0}, 3.0, 2.0, {1.0,0.0} )
   hits := Ix_LineEllipse( {-10.0,2.0}, {1.0,0.0}, e ); Chk( Len(hits)==1 .AND. Abs(hits[1][2]-OCX_FRAC_PI_2)<0.0001, "tangent ellipse" )
   flat := Ell_New( {0.0,0.0}, 0.0, 2.0, {1.0,0.0} ); Chk( Len( Ix_LineEllipse( {0.0,0.0}, {1.0,0.0}, flat ) ) == 0, "degenerate ellipse" )
   // survey coordinates
   offset := { 512345.678, 4512345.678 }
   hit := Ix_LineLine( offset, {1.0,0.0}, { offset[1]+5.0, offset[2]-5.0 }, {0.0,1.0} ); Chk( Abs(hit[1]-5.0) < 0.000001, "survey line_line" )
   hits := Ix_LineCircle( { offset[1]-10.0, offset[2] }, {1.0,0.0}, offset, 5.0 )
   Chk( Len(hits)==2 .AND. Abs(hits[1]-5.0)<0.000001 .AND. Abs(hits[2]-15.0)<0.000001, "survey line_circle" )
   // symmetric pair
   angles := Ix_CircleCircleAngles( {0.0,0.0}, 2.0, {0.0,3.0}, 2.0 ); Chk( Len(angles)==2, "half-turn pair count" )
   Chk( Abs( OCX_COS(angles[1]) + OCX_COS(angles[2]) ) < 0.000000001 .AND. OCX_SIN(angles[1]) > 0.0 .AND. OCX_SIN(angles[2]) > 0.0, "half-turn pair symmetric" )
   // tangent_circles_external_at_various_angles_and_epsilons
   FOR EACH ang IN { 0.0, 0.5, 1.0, 1.57, 2.5, 3.14, 4.0, 5.0 }
      FOR EACH eps IN { -0.00000001, 0.0, 0.00000001 }
         dist := 20.0 + eps; c2 := { dist*OCX_COS(ang), dist*OCX_SIN(ang) }
         angles := Ix_CircleCircleAngles( {0.0,0.0}, 10.0, c2, 10.0 )
         diff := Abs( angles[1] - ang ); cyclic := Min( diff, OCX_TAU - diff )
         Chk( Len(angles)==1 .AND. cyclic < 0.00001, "tangent external angle " + LTrim(Str(ang)) )
      NEXT
   NEXT
   // tangent_circles_internal_both_sizes
   a1 := Ix_CircleCircleAngles( {0.0,0.0}, 10.0, {6.0,0.0}, 4.0 ); Chk( Len(a1)==1 .AND. Abs(a1[1])<0.00001, "internal tangent 1" )
   a2 := Ix_CircleCircleAngles( {6.0,0.0}, 4.0, {0.0,0.0}, 10.0 ); Chk( Len(a2)==1 .AND. Abs(a2[1])<0.00001, "internal tangent 2" )
   // skinny_ellipse_crossing_circle_detects_all_roots
   skinny := Ell_New( {0.0,0.0}, 100.0, 5.0, {1.0,0.0} )
   hits := Ix_EllipseCircle( skinny, {0.0,0.0}, 95.0 ); Chk( Len(hits)==4, "skinny: 4 roots (got " + LTrim(Str(Len(hits))) + ")" )
   FOR EACH pair IN hits
      pt := Ell_PointAt( skinny, pair[2] ); Chk( Abs( Sqrt( pt[1]*pt[1] + pt[2]*pt[2] ) - 95.0 ) < 0.001, "skinny: on circle" )
   NEXT
RETURN
