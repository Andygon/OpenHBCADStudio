/* Port 1:1 de #[cfg(test)] de vec.rs. UTF-8. */
#include "ocx.ch"
PROCEDURE T_Vec()
   LOCAL a, b, unit, v, s, e, p
   // arithmetic_is_componentwise
   a := {1,2}; b := {10,20}
   Chk( V2_Eq( V2_Add(a,b), {11,22} ), "add" )
   Chk( V2_Eq( V2_Sub(b,a), {9,18} ), "sub" )
   Chk( V2_Eq( V2_Mul(a,3.0), {3,6} ), "mul" )
   Chk( V2_Eq( V2_Div(b,2.0), {5,10} ), "div" )
   Chk( V2_Eq( V2_Neg(a), {-1,-2} ), "neg" )
   // dot
   a := {1,0}
   Chk( V2_Dot(a,{1,0}) == 1, "dot1" ); Chk( V2_Dot(a,{0,1}) == 0, "dot0" ); Chk( V2_Dot(a,{-1,0}) == -1, "dot-1" )
   // cross sign / area
   Chk( V2_Cross(a,{0,1}) > 0, "cross+" ); Chk( V2_Cross(a,{0,-1}) < 0, "cross-" ); Chk( V2_Cross(a,{2,0}) == 0, "cross par" )
   Chk( V2_Cross({4,0},{0,3}) == 12, "cross area" )
   // length/distance
   a := {1,1}; b := {4,5}
   Chk( V2_Length(V2_Sub(b,a)) == 5, "len" ); Chk( V2_Distance(a,b) == 5, "dist" ); Chk( V2_DistanceSquared(a,b) == 25, "dist2" )
   // normalize
   unit := V2_Normalize({3,4})
   Chk( Near(V2_Length(unit),1,0.000000000000001), "unit len" ); Chk( Near(unit[1],0.6,0.000000000000001), "unit x" )
   Chk( V2_Normalize(V2_Zero()) == NIL, "normalize zero None" )
   // perpendicular
   v := V2_Perpendicular({1,0})
   Chk( V2_Eq(v,{0,1}), "perp" ); Chk( V2_Dot({1,0},v) == 0, "perp dot" ); Chk( V2_Cross({1,0},v) > 0, "perp cross" )
   // angle
   Chk( V2_Angle({1,0}) == 0, "ang0" ); Chk( Near(V2_Angle({0,1}),OCX_FRAC_PI_2,0.000000000000001), "ang90" ); Chk( V2_Angle({0,-1}) < 0, "ang-" )
   // lerp
   a := {0,0}; b := {10,20}
   Chk( V2_Eq(V2_Lerp(a,b,0.0),a), "lerp0" ); Chk( V2_Eq(V2_Lerp(a,b,1.0),b), "lerp1" ); Chk( V2_Eq(V2_Lerp(a,b,0.5),{5,10}), "lerp.5" )
   // distance_to_segment
   s := {0,0}; e := {10,0}
   Chk( V2_DistanceToSegment({4,3},s,e) == 3, "seg beside" )
   Chk( V2_DistanceToSegment({14,3},s,e) == 5, "seg past end" )
   Chk( V2_DistanceToSegment({-4,3},s,e) == 5, "seg before start" )
   p := {3,4}
   Chk( V2_DistanceToSegment(V2_Zero(),p,p) == 5, "collapsed seg" )
   // survey coordinates
   a := {512345.678, 4512345.678}; b := V2_Add(a,{0.001,0})
   Chk( Abs(V2_Distance(a,b)-0.001) < 0.000000001, "survey" )
RETURN
