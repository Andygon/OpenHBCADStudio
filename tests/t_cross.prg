/* Port de #[cfg(test)] de cross.rs. UTF-8. */
#include "ocx.ch"
#define TOL 0.000001
STATIC FUNCTION Seg( a, b ) ; RETURN Cv_Line( a, b )
STATIC FUNCTION Circ( c, r ) ; RETURN Cv_Circle( c, r )
STATIC FUNCTION Ell( c, ma, mi ) ; RETURN Cv_Ellipse( EA_Full( Ell_New( c, ma, mi, {1.0,0.0} ) ) )
STATIC FUNCTION Dist( a, b ) ; RETURN V2_Distance( a, b )
STATIC FUNCTION Strt( x, y ) ; RETURN PV_Straight( { x, y } )
STATIC FUNCTION Spl() ; RETURN Cv_Nurbs( NC_New( 3, { {0.0,0.0}, {2.0,4.0}, {6.0,-2.0}, {9.0,3.0}, {11.0,0.0} }, {}, NIL ) )

PROCEDURE T_Cross()
   LOCAL hits, h, line, round, fwd, bwd, arc, chain, a, b, loose, tight, spline, ahead, behind, origin, ell, xl, ok
   hits := Cx_Intersect( Seg({0.0,0.0},{10.0,0.0}), Seg({5.0,-5.0},{5.0,5.0}), TOL )
   Chk( Len(hits)==1 .AND. Abs(hits[1][1][1]-5.0)<0.000000001 .AND. Abs(hits[1][2]-0.5)<0.000000001 .AND. Abs(hits[1][3]-0.5)<0.000000001, "two crossing segments" )
   Chk( Len( Cx_Intersect( Seg({0.0,0.0},{10.0,0.0}), Seg({50.0,-5.0},{50.0,5.0}), TOL ) ) == 0, "only if extended" )
   hits := Cx_Intersect( Seg({-10.0,0.0},{10.0,0.0}), Circ({0.0,0.0},5.0), TOL )
   Chk( Len(hits)==2 .AND. hits[1][2] < hits[2][2] .AND. Abs(hits[1][1][1]+5.0)<TOL .AND. Abs(hits[2][1][1]-5.0)<TOL, "segment through circle in order" )
   // the_order_of_the_arguments_does_not_change_the_hits
   line := Seg({-10.0,0.0},{10.0,0.0}); round := Circ({0.0,0.0},5.0)
   fwd := Cx_Intersect( line, round, TOL ); bwd := Cx_Intersect( round, line, TOL ); ok := Len(fwd)==Len(bwd)
   FOR EACH h IN fwd
      ok := ok .AND. AScan( bwd, {| o | Dist( o[1], h[1] ) < TOL } ) > 0
   NEXT
   Chk( ok, "argument order" )
   arc := Cv_Arc( {0.0,0.0}, 5.0, 0.0, OCX_FRAC_PI_2 )
   hits := Cx_Intersect( Seg({-10.0,3.0},{10.0,3.0}), arc, TOL ); Chk( Len(hits)==1 .AND. hits[1][1][1] > 0.0, "point off the arc rejected" )
   hits := Cx_Intersect( Circ({0.0,0.0},1.0), Circ({1.0,0.0},1.0), TOL ); ok := Len(hits)==2
   FOR EACH h IN hits ; ok := ok .AND. Abs(h[1][1]-0.5) < TOL ; NEXT
   Chk( ok, "two circles two points" )
   hits := Cx_Intersect( Seg({-10.0,1.0},{10.0,1.0}), Ell({0.0,0.0},5.0,2.0), TOL ); ok := Len(hits)==2
   FOR EACH h IN hits ; ok := ok .AND. Abs(h[1][2]-1.0) < TOL ; NEXT
   Chk( ok, "segment across ellipse" )
   chain := Cv_Polyline( PL_New( { Strt(0.0,0.0), Strt(1.0,0.0), Strt(2.0,0.0), Strt(3.0,0.0) }, .F. ) )
   hits := Cx_Intersect( chain, Seg({1.5,-1.0},{1.5,1.0}), TOL )
   Chk( Len(hits)==1 .AND. Abs(hits[1][1][1]-1.5) < 0.000000000001 .AND. Abs(hits[1][2]-0.5) < 0.000000001, "polyline taken apart" )
   chain := Cv_Polyline( PL_New( { PV_Curved({0.0,0.0},1.0), Strt(2.0,0.0) }, .F. ) )
   hits := Cx_Intersect( chain, Seg({-1.0,-0.5},{3.0,-0.5}), TOL ); ok := Len(hits)==2
   FOR EACH h IN hits ; ok := ok .AND. Abs( Dist( h[1], {1.0,0.0} ) - 1.0 ) < 0.000000001 ; NEXT
   Chk( ok, "polyline arc solved as arc" )
   hits := Cx_Intersect( Ell({0.0,0.0},5.0,2.0), Ell({0.0,0.0},2.0,5.0), TOL ); ok := Len(hits)==4
   FOR EACH h IN hits ; ok := ok .AND. Abs( Abs(h[1][1]) - Abs(h[1][2]) ) < 0.00001 ; NEXT
   Chk( ok, "two ellipses cross at four diagonal points (got " + LTrim(Str(Len(hits))) + ")" )
   a := Ell({0.0,0.0},5.0,2.0); b := Ell({3.0,1.0},4.0,3.0); hits := Cx_Intersect( a, b, TOL ); ok := Len(hits) > 0
   FOR EACH h IN hits
      ok := ok .AND. Dist( Cv_PointAt(a,h[2]), h[1] ) < 0.00001 .AND. Dist( Cv_PointAt(b,h[3]), h[1] ) < 0.00001
   NEXT
   Chk( ok, "converged crossing lands on both curves" )
   a := Ell({0.0,0.0},5.0,2.0); b := Ell({0.0,0.0},2.0,5.0)
   loose := CrErr( a, b, 0.001 ); tight := CrErr( a, b, 0.0000000001 )
   Chk( tight <= loose .AND. tight < 0.000000001, "tighter tolerance closer" )
   // [extra] spline (el original usa interpolate, pendiente)
   spline := Spl(); hits := Cx_Intersect( spline, Seg({-1.0,1.0},{12.0,1.0}), TOL ); ok := Len(hits) > 0
   FOR EACH h IN hits ; ok := ok .AND. Abs(h[1][2]-1.0) < 0.00001 .AND. Dist( Cv_PointAt(spline,h[2]), h[1] ) < 0.00001 ; NEXT
   Chk( ok, "[extra] spline crossing found and converged" )
   Chk( Len( Cx_Intersect( Seg({-10.0,9.0},{10.0,9.0}), Circ({0.0,0.0},5.0), TOL ) )==0 .AND. Len( Cx_Intersect( Ell({0.0,0.0},1.0,1.0), Ell({50.0,0.0},1.0,1.0), TOL ) )==0, "curves that miss" )
   Chk( Len( Cx_Intersect( Seg({0.0,0.0},{10.0,0.0}), Seg({0.0,3.0},{10.0,3.0}), TOL ) )==0, "parallel never cross" )
   Chk( Len( Cx_Intersect( Seg({-10.0,5.0},{10.0,5.0}), Circ({0.0,0.0},5.0), TOL ) )==1, "tangent touches once" )
   // rays / xlines
   hits := Cx_Intersect( Cv_Ray({0.0,0.0},{1.0,0.0}), Seg({5.0,-5.0},{5.0,5.0}), TOL )
   Chk( Len(hits)==1 .AND. Abs(hits[1][1][1]-5.0)<0.000000001 .AND. Abs(hits[1][2]-5.0)<0.000000001, "ray ahead" )
   Chk( Len( Cx_Intersect( Cv_Ray({0.0,0.0},{1.0,0.0}), Seg({-5.0,-5.0},{-5.0,5.0}), TOL ) )==0, "ray not behind" )
   xl := Cv_XLine({0.0,0.0},{1.0,0.0})
   ahead := Cx_Intersect( xl, Seg({5.0,-1.0},{5.0,1.0}), TOL ); behind := Cx_Intersect( xl, Seg({-5.0,-1.0},{-5.0,1.0}), TOL )
   Chk( Len(ahead)==1 .AND. Len(behind)==1 .AND. ahead[1][2] > 0.0 .AND. behind[1][2] < 0.0, "xline both sides" )
   hits := Cx_Intersect( Cv_Ray({0.0,0.0},{1.0,0.0}), Circ({0.0,0.0},5.0), TOL ); Chk( Len(hits)==1 .AND. Abs(hits[1][1][1]-5.0)<TOL, "ray through circle ahead only" )
   hits := Cx_Intersect( xl, Circ({0.0,0.0},5.0), TOL ); Chk( Len(hits)==2 .AND. Abs(hits[1][1][1]+5.0)<TOL .AND. Abs(hits[2][1][1]-5.0)<TOL, "xline through circle both" )
   hits := Cx_Intersect( Cv_XLine({-100.0,1.0},{1.0,0.0}), Spl(), TOL ); ok := Len(hits) > 0
   FOR EACH h IN hits ; ok := ok .AND. Abs(h[1][2]-1.0) < 0.00001 ; NEXT
   Chk( ok, "[extra] xline crosses spline" )
   // survey
   origin := { 512345.678, 4512345.678 }
   hits := Cx_Intersect( Seg( {origin[1]-10.0,origin[2]}, {origin[1]+10.0,origin[2]} ), Circ( origin, 5.0 ), TOL )
   Chk( Len(hits)==2 .AND. Abs(hits[1][1][1]-(origin[1]-5.0))<TOL .AND. Abs(hits[2][1][1]-(origin[1]+5.0))<TOL, "survey crossing" )
   hits := Cx_Intersect( Circ({0.0,0.0},10.0), Circ({20.0,0.0},10.0), TOL )
   Chk( Len(hits)==1 .AND. Abs(hits[1][1][1]-10.0)<0.00001 .AND. Abs(hits[1][1][2])<0.00001 .AND. Abs(hits[1][2])<0.00001, "tangent circles single crossing" )
   hits := Cx_Intersect( Cv_Arc({0.0,0.0},10.0,-1.0,1.0), Circ({20.0,0.0},10.0), TOL )
   Chk( Len(hits)==1 .AND. Abs(hits[1][1][1]-10.0)<0.00001 .AND. Abs(hits[1][2]-0.5)<0.00001, "tangent arcs single crossing" )
   ell := Cv_Ellipse( { Ell_New( {0.0,0.0}, 100.0, 5.0, {1.0,0.0} ), 0.0, OCX_TAU } )
   hits := Cx_Intersect( ell, Cv_Arc( {0.0,0.0}, 95.0, 0.0, OCX_PI ), TOL ); Chk( Len(hits)==2, "skinny ellipse crossing arc" )
RETURN
STATIC FUNCTION CrErr( a, b, nT )
   LOCAL h, nMax := 0.0
   FOR EACH h IN Cx_Intersect( a, b, nT )
      nMax := Max( nMax, Dist( Cv_PointAt( a, h[2] ), Cv_PointAt( b, h[3] ) ) )
   NEXT
RETURN nMax
