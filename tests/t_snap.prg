/* Port de #[cfg(test)] de snap.rs. UTF-8. */
#include "ocx.ch"
STATIC FUNCTION Seg( a, b ) ; RETURN Cv_Line( a, b )
STATIC FUNCTION OfKind( aPts, nKind )
   LOCAL a := {}, p
   FOR EACH p IN aPts
   IF p[ SP_KIND ] == nKind
   AAdd( a, p[ SP_POINT ] )
   ENDIF
   NEXT
RETURN a
STATIC FUNCTION Near( a, b ) ; RETURN V2_Distance( a, b ) < 0.000000001
STATIC FUNCTION AnyNear( aPts, b )
   LOCAL p
   FOR EACH p IN aPts
   IF Near( p, b )
   RETURN .T.
   ENDIF
   NEXT
RETURN .F.
STATIC FUNCTION PolyV( aVerts, lClosed ) ; RETURN Cv_Polyline( PL_New( aVerts, lClosed ) )
STATIC FUNCTION Spl() ; RETURN Cv_Nurbs( NC_New( 3, { {0.0,0.0}, {2.0,4.0}, {6.0,-2.0}, {9.0,3.0}, {11.0,0.0} }, {}, NIL ) )

PROCEDURE T_Snap()
   LOCAL pts, ends, chain, quads, circ, arc, ray, feet, spl, from, f, step, bf, af, along, back, whole, touches, t, radial, bk, ok, org, mids, cen, nn
   pts := Sn_CharacteristicPoints( Seg({0.0,0.0},{10.0,4.0}) ); ends := OfKind( pts, SK_ENDPOINT )
   Chk( Len(ends)==2 .AND. AnyNear(ends,{0.0,0.0}) .AND. AnyNear(ends,{10.0,4.0}) .AND. Near( OfKind(pts,SK_MIDPOINT)[1], {5.0,2.0} ), "segment ends and middle" )
   chain := PolyV( { PV_Straight({-2.0,0.0}), PV_Curved({0.0,0.0},1.0), PV_Straight({2.0,0.0}) }, .F. )
   pts := Sn_CharacteristicPoints( chain ); quads := OfKind( pts, SK_QUADRANT )
   Chk( Near( OfKind(pts,SK_CENTRE)[1], {1.0,0.0} ) .AND. AnyNear(quads,{1.0,-1.0}) .AND. ! AnyNear(quads,{1.0,1.0}), "polyline arc segment centre and quadrants" )
   circ := Cv_Circle({3.0,4.0},2.0); pts := Sn_CharacteristicPoints( circ )
   Chk( Near( OfKind(pts,SK_CENTRE)[1], {3.0,4.0} ) .AND. Len(OfKind(pts,SK_QUADRANT))==4 .AND. Len(OfKind(pts,SK_ENDPOINT))==0 .AND. Len(OfKind(pts,SK_MIDPOINT))==0, "circle centre and 4 quadrants" )
   ok := .T.
   FOR EACH f IN OfKind( pts, SK_QUADRANT )
      ok := ok .AND. Abs( V2_Distance( f, {3.0,4.0} ) - 2.0 ) < 0.000000001 .AND. ( Abs(f[1]-3.0)<0.000000001 .OR. Abs(f[2]-4.0)<0.000000001 )
   NEXT
   Chk( ok, "quadrants on circle and axes" )
   arc := Cv_Arc({0.0,0.0},5.0,0.0,OCX_FRAC_PI_2); quads := OfKind( Sn_CharacteristicPoints( arc ), SK_QUADRANT )
   Chk( Len(quads)==2 .AND. AnyNear(quads,{5.0,0.0}) .AND. AnyNear(quads,{0.0,5.0}), "arc offers covered quadrants only" )
   arc := Cv_Arc({0.0,0.0},5.0,0.0,OCX_PI); pts := Sn_CharacteristicPoints( arc )
   Chk( Len(OfKind(pts,SK_ENDPOINT))==2 .AND. Near( OfKind(pts,SK_MIDPOINT)[1], {0.0,5.0} ), "arc ends and middle" )
   chain := PolyV( { PV_Straight({0.0,0.0}), PV_Straight({2.0,0.0}), PV_Straight({2.0,2.0}) }, .F. ); pts := Sn_CharacteristicPoints( chain )
   mids := OfKind( pts, SK_MIDPOINT )
   Chk( Len(OfKind(pts,SK_ENDPOINT))==3 .AND. Len(mids)==2 .AND. AnyNear(mids,{1.0,0.0}) .AND. AnyNear(mids,{2.0,1.0}), "polyline vertices and middles" )
   chain := PolyV( { PV_Curved({0.0,0.0},1.0), PV_Straight({2.0,0.0}) }, .F. ); cen := OfKind( Sn_CharacteristicPoints( chain ), SK_CENTRE )
   Chk( Len(cen)==1 .AND. Near( cen[1], {1.0,0.0} ), "polyline arc segment centre" )
   ray := Cv_Ray({1.0,2.0},{1.0,0.0}); ends := OfKind( Sn_CharacteristicPoints( ray ), SK_ENDPOINT )
   Chk( Len(ends)==1 .AND. Near( ends[1], {1.0,2.0} ), "ray one end" )
   feet := Sn_PerpendicularFrom( Seg({0.0,0.0},{10.0,0.0}), {4.0,3.0} )
   Chk( Len(feet)==1 .AND. Near( feet[1][SP_POINT], {4.0,0.0} ), "perpendicular foot on segment" )
   Chk( Len( Sn_PerpendicularFrom( Seg({0.0,0.0},{10.0,0.0}), {50.0,3.0} ) ) == 0, "perpendicular past end not offered" )
   circ := Cv_Circle({0.0,0.0},5.0); feet := Sn_PerpendicularFrom( circ, {20.0,0.0} ); ok := Len(feet)==2
   IF ok ; ok := ( Near( feet[1][SP_POINT], {5.0,0.0} ) .OR. Near( feet[2][SP_POINT], {5.0,0.0} ) ) .AND. ( Near( feet[1][SP_POINT], {-5.0,0.0} ) .OR. Near( feet[2][SP_POINT], {-5.0,0.0} ) ) ; ENDIF
   Chk( ok, "circle two perpendicular feet" )
   Chk( Len( Sn_PerpendicularFrom( circ, {0.0,0.0} ) ) == 0, "centre has no perpendicular" )
   // [extra] el original interpola; aqui NC_New
   spl := Spl(); from := {4.0,6.0}; feet := Sn_PerpendicularFrom( spl, from ); ok := Len(feet) > 0
   FOR EACH f IN feet
      step := 0.00001
      bf := Cv_PointAt( spl, Max( f[SP_T] - step, 0.0 ) ); af := Cv_PointAt( spl, Min( f[SP_T] + step, 1.0 ) )
      along := V2_Normalize( V2_Sub( af, bf ) ); back := V2_Normalize( V2_Sub( from, f[SP_POINT] ) )
      IF along != NIL .AND. back != NIL .AND. ! ( Abs( V2_Dot( along, back ) ) < 0.0001 ) ; ok := .F. ; ENDIF
   NEXT
   Chk( ok, "[extra] perpendicular onto a spline is at right angle" )
   whole := Cv_Ellipse( EA_Full( Ell_New( {0.0,0.0}, 5.0, 2.0, {1.0,0.0} ) ) ); quads := OfKind( Sn_CharacteristicPoints( whole ), SK_QUADRANT )
   Chk( Len(quads)==4 .AND. AnyNear(quads,{5.0,0.0}) .AND. AnyNear(quads,{0.0,2.0}), "ellipse axis ends" )
   circ := Cv_Circle({0.0,0.0},3.0); touches := Sn_TangentFrom( circ, {5.0,0.0} ); ok := Len(touches)==2
   FOR EACH t IN touches
      radial := t[SP_POINT]; bk := V2_Sub( {5.0,0.0}, radial )
      ok := ok .AND. Abs( V2_Length( radial ) - 3.0 ) < 0.000000001 .AND. Abs( V2_Dot( radial, bk ) ) < 0.000000001
   NEXT
   Chk( ok .AND. Len( Sn_TangentFrom( circ, {1.0,0.0} ) )==0 .AND. Len( Sn_TangentFrom( Seg({0.0,0.0},{1.0,1.0}), {5.0,5.0} ) )==0, "tangents from outside only" )
   org := { 512345.678, 4512345.678 }; circ := Cv_Circle( org, 2.0 ); pts := Sn_CharacteristicPoints( circ ); ok := Near( OfKind(pts,SK_CENTRE)[1], org )
   FOR EACH f IN OfKind( pts, SK_QUADRANT )
      ok := ok .AND. Abs( V2_Distance( f, org ) - 2.0 ) < 0.000000001
   NEXT
   Chk( ok, "survey coordinates snap" )
   // [extra] nearest_to
   nn := Sn_NearestTo( Seg({0.0,0.0},{10.0,0.0}), {4.0,3.0} )
   Chk( nn[SP_KIND] == SK_PERPENDICULAR .AND. Near( nn[SP_POINT], {4.0,0.0} ) .AND. Abs( nn[SP_T] - 0.4 ) < 0.000000001, "[extra] nearest_to" )
RETURN
