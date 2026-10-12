/* Port de #[cfg(test)] de containment.rs. UTF-8. */
#include "ocx.ch"
#define TOL 0.000001
STATIC FUNCTION Seg( a, b ) ; RETURN Cv_Line( a, b )
STATIC FUNCTION Poly( aPts )
   LOCAL aV := {}, p
   FOR EACH p IN aPts ; AAdd( aV, PV_Straight( p ) ) ; NEXT
RETURN Cv_Polyline( PL_New( aV, .T. ) )
STATIC FUNCTION Rect() ; RETURN Poly( { {0.0,0.0}, {10.0,0.0}, {10.0,6.0}, {0.0,6.0} } )

PROCEDURE T_Containment()
   LOCAL f, ray, line, circ, arc, curves, r, pieces, lsh, org, far, a1, a2
   f := Co_ClosestPoint( Seg({0.0,0.0},{10.0,0.0}), {4.0,3.0} )
   Chk( Abs(f[2][1]-4.0)<0.000000000001 .AND. Abs(f[2][2])<0.000000000001 .AND. Abs(f[3]-3.0)<0.000000000001 .AND. Abs(f[1]-0.4)<0.000000000001, "foot of perpendicular" )
   f := Co_ClosestPoint( Seg({0.0,0.0},{10.0,0.0}), {50.0,0.0} )
   Chk( f[1] == 1.0 .AND. Abs(f[2][1]-10.0)<0.000000000001 .AND. Abs(f[3]-40.0)<0.000000000001, "past a segment snaps to its end" )
   ray := Cv_Ray({0.0,0.0},{1.0,0.0})
   Chk( Co_ClosestPoint( ray, {-5.0,0.0} )[1] == 0.0 .AND. Abs( Co_ClosestPoint( ray, {500.0,0.0} )[1] - 500.0 ) < 0.000000001, "ray floor no ceiling" )
   line := Cv_XLine({0.0,0.0},{1.0,0.0})
   Chk( Co_ClosestPoint( line, {-500.0,3.0} )[1] < 0.0 .AND. Abs( Co_DistanceTo( line, {-500.0,3.0} ) - 3.0 ) < 0.000000001, "infinite line" )
   circ := Cv_Circle({0.0,0.0},5.0)
   Chk( Abs( Co_DistanceTo( circ, {10.0,0.0} ) - 5.0 ) < 0.000000001 .AND. Abs( Co_DistanceTo( circ, {2.0,0.0} ) - 3.0 ) < 0.000000001, "circle along radius" )
   arc := Cv_Arc({0.0,0.0},5.0,0.0,OCX_FRAC_PI_2); f := Co_ClosestPoint( arc, {5.0,-10.0} )
   Chk( Abs(f[2][1]-5.0)<TOL .AND. Abs(f[2][2])<TOL, "beyond an arc snaps to nearer end" )
   curves := { Seg({0.0,10.0},{10.0,10.0}), Seg({0.0,0.0},{10.0,0.0}), Seg({0.0,-20.0},{10.0,-20.0}) }
   r := Co_NearestOf( curves, {5.0,1.0} )
   Chk( r[1] == 1 .AND. Abs( r[2][3] - 1.0 ) < 0.000000000001 .AND. Co_NearestOf( {}, {0.0,0.0} ) == NIL, "nearest of several" )
   Chk( Co_Contains( { Rect() }, {5.0,3.0}, TOL ) .AND. Co_Contains( { Rect() }, {0.5,0.5}, TOL ), "inside rectangle" )
   Chk( ! Co_Contains( { Rect() }, {-1.0,3.0}, TOL ) .AND. ! Co_Contains( { Rect() }, {5.0,20.0}, TOL ) .AND. ! Co_Contains( { Rect() }, {50.0,50.0}, TOL ), "outside rectangle" )
   Chk( Co_Contains( { Rect() }, {5.0,0.0}, TOL ) .AND. Co_Contains( { Rect() }, {0.0,0.0}, TOL ), "boundary counts as inside" )
   pieces := { Seg({0.0,0.0},{10.0,0.0}), Seg({10.0,0.0},{10.0,6.0}), Seg({10.0,6.0},{0.0,6.0}), Seg({0.0,6.0},{0.0,0.0}) }
   Chk( Co_Contains( pieces, {5.0,3.0}, TOL ) .AND. ! Co_Contains( pieces, {15.0,3.0}, TOL ), "separate pieces" )
   circ := Cv_Circle({3.0,4.0},2.0)
   Chk( Co_Contains( {circ}, {3.0,4.0}, TOL ) .AND. Co_Contains( {circ}, {4.5,4.0}, TOL ) .AND. ! Co_Contains( {circ}, {6.0,4.0}, TOL ) .AND. ! Co_Contains( {circ}, {-1.0,6.0}, TOL ), "circle contains within radius" )
   Chk( Co_Contains( { Rect() }, {5.0, 6.0 - 0.000000001}, TOL ) .AND. ! Co_Contains( { Rect() }, {-5.0,6.0}, TOL ) .AND. ! Co_Contains( { Rect() }, {-5.0,0.0}, TOL ), "level with a corner" )
   lsh := Poly( { {0.0,0.0}, {10.0,0.0}, {10.0,4.0}, {4.0,4.0}, {4.0,10.0}, {0.0,10.0} } )
   Chk( Co_Contains( {lsh}, {2.0,8.0}, TOL ) .AND. Co_Contains( {lsh}, {8.0,2.0}, TOL ) .AND. ! Co_Contains( {lsh}, {8.0,8.0}, TOL ) .AND. ! Co_Contains( {lsh}, {-1.0,4.0}, TOL ), "concave L shape" )
   Chk( ! Co_Contains( {}, {0.0,0.0}, TOL ), "empty boundary" )
   org := { 512345.678, 4512345.678 }
   far := Poly( { org, {org[1]+10.0,org[2]}, {org[1]+10.0,org[2]+6.0}, {org[1],org[2]+6.0} } )
   a1 := Co_Contains( {far}, {org[1]+5.0,org[2]+3.0}, TOL ); a2 := Co_Contains( {far}, {org[1]-5.0,org[2]+3.0}, TOL )
   Chk( a1 .AND. ! a2, "survey coordinates" )
RETURN
