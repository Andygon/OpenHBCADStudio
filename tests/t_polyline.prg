/* Port 1:1 de #[cfg(test)] de polyline.rs (+ tessellation: ver t_tess). UTF-8. */
#include "ocx.ch"
STATIC FUNCTION C2( a, b, e ) ; RETURN Abs( a[1]-b[1] ) < e .AND. Abs( a[2]-b[2] ) < e
STATIC FUNCTION VertsEq( a, b )
   LOCAL i
   IF Len( a ) != Len( b ) ; RETURN .F. ; ENDIF
   FOR i := 1 TO Len( a )
      IF ! ( a[i][1][1] == b[i][1][1] .AND. a[i][1][2] == b[i][1][2] .AND. a[i][2] == b[i][2] ) ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.

PROCEDURE T_Polyline()
   LOCAL arc, ccw, cw, oc, ow, st, en, nBulge, poly, origin, wa, ha, pts, rect, r, rg, orig, restr
   // a_half_turn_bulge_gives_the_chord_as_diameter
   arc := BA_FromBulge( {0.0,0.0}, {2.0,0.0}, 1.0 )
   Chk( Near(arc[BA_RADIUS],1,0.000000000001) .AND. Near(arc[BA_CENTER][1],1,0.000000000001) .AND. Abs(arc[BA_CENTER][2])<0.000000000001 .AND. Near(arc[BA_SWEEP],OCX_PI,0.000000000001), "half turn" )
   // the_bulge_sign_picks_the_side
   ccw := BA_FromBulge( {0.0,0.0}, {2.0,0.0}, 1.0 ); cw := BA_FromBulge( {0.0,0.0}, {2.0,0.0}, -1.0 )
   Chk( ccw[BA_SWEEP] > 0 .AND. cw[BA_SWEEP] < 0, "sweep signs" ); Chk( Near(ccw[BA_RADIUS],cw[BA_RADIUS],0.000000000001), "same radius" )
   oc := BA_Sample( ccw, 0.5 ); ow := BA_Sample( cw, 0.5 )
   Chk( oc[2] < 0, "pos bulge dips below" ); Chk( ow[2] > 0, "neg bulge rises" ); Chk( Abs(oc[2]+ow[2]) < 0.000000000001, "mirror" )
   // sampling_hits_the_endpoints
   arc := BA_FromBulge( {1.0,2.0}, {4.0,6.0}, 0.4 ); st := BA_Sample(arc,0.0); en := BA_Sample(arc,1.0)
   Chk( C2(st,{1,2},0.000000001) .AND. C2(en,{4,6},0.000000001), "sampling endpoints" )
   // a_quarter_turn_bulge_sweeps_a_quarter_turn
   nBulge := OCX_TAN( OCX_FRAC_PI_2 / 4.0 ); arc := BA_FromBulge( {1.0,0.0}, {0.0,1.0}, nBulge )
   Chk( Near(arc[BA_SWEEP],OCX_FRAC_PI_2,0.000000001) .AND. Abs(arc[BA_CENTER][1])<0.000000001 .AND. Abs(arc[BA_CENTER][2])<0.000000001 .AND. Near(arc[BA_RADIUS],1,0.000000001), "quarter turn" )
   // a_bulge_over_one_sweeps_past_a_half_turn
   arc := BA_FromBulge( {0.0,0.0}, {2.0,0.0}, 2.0 ); Chk( arc[BA_SWEEP] > OCX_PI .AND. arc[BA_SWEEP] < OCX_TAU, "major arc" )
   // degenerate_input_has_no_arc
   Chk( ValType( BA_FromBulge({1.0,1.0},{1.0,1.0},0.5) ) == "U", "deg chord" ); Chk( ValType( BA_FromBulge({0.0,0.0},{1.0,0.0},0.0) ) == "U", "deg bulge" )
   // closed polyline arcs back
   poly := PL_New( { PV_Straight({0.0,0.0}), PV_Curved({2.0,0.0},1.0) }, .T. )
   arc := PL_SegmentArc( poly, 1 ); Chk( ValType(arc)=="A" .AND. Near(arc[BA_RADIUS],1,0.000000000001), "closing segment arcs" ); Chk( ValType(PL_SegmentArc(poly,0))=="U", "seg0 none" )
   // open polyline has no closing segment
   poly := PL_New( { PV_Straight({0.0,0.0}), PV_Curved({2.0,0.0},1.0) }, .F. )
   Chk( ValType(PL_SegmentArc(poly,1))=="U" .AND. ValType(PL_SegmentArc(poly,5))=="U", "open no closing" )
   // rectangle_frame
   origin := {500000.0,4500000.0}; wa := {0.6,0.8}; ha := {-0.8,0.6}
   pts := { origin, V2_Add(origin,V2_Mul(wa,10.0)), V2_Add(V2_Add(origin,V2_Mul(wa,10.0)),V2_Mul(ha,4.0)), V2_Add(origin,V2_Mul(ha,4.0)) }
   poly := PL_New( { PV_Straight(pts[1]), PV_Straight(pts[2]), PV_Straight(pts[3]), PV_Straight(pts[4]) }, .T. )
   rect := PL_RectangleFrame( poly, Tol_Default() )
   Chk( ValType(rect)=="A", "rect found" )
   IF ValType(rect)=="A"
      Chk( Near(rect[4],10,0.000000001) .AND. Near(rect[5],4,0.000000001), "rect w/h" ); Chk( V2_Distance(rect[2],wa) < 0.000000001 .AND. V2_Distance(rect[3],ha) < 0.000000001, "rect axes" )
   ENDIF
   poly[PL_VERTS][4][PV_POS] := { poly[PL_VERTS][4][PV_POS][1] + 0.01, poly[PL_VERTS][4][PV_POS][2] }
   Chk( ValType(PL_RectangleFrame(poly,Tol_Default()))=="U", "rect rejects skew" )
   poly[PL_VERTS][4][PV_POS] := pts[4]; poly[PL_VERTS][1][PV_BULGE] := 0.000000000001
   Chk( ValType(PL_RectangleFrame(poly,Tol_Default()))=="U", "rect rejects bulge" )
   // a_range_keeps_segment_provenance...
   poly := PL_New( { PV_Straight({0.0,0.0}), PV_Straight({1.0,0.0}), PV_Straight({1.0,1.0}) }, .F. )
   rg := PL_Ranged( poly, 0.25, 0.75 )
   Chk( ValType(rg)=="A" .AND. VertsEq( rg[1][PL_VERTS], { PV_Straight({0.5,0.0}), PV_Straight({1.0,0.0}), PV_Straight({1.0,0.5}) } ), "range vertices" )
   Chk( Len(rg[2])==2 .AND. rg[2][1][1]==0 .AND. rg[2][1][2]==0.5 .AND. rg[2][1][3]==1.0 .AND. rg[2][2][1]==1 .AND. rg[2][2][2]==0.0 .AND. rg[2][2][3]==0.5, "range segments" )
   r := PRS_Interpolate( rg[2][1], 2.0, 6.0 ); Chk( r[1]==4.0 .AND. r[2]==6.0, "interp0" )
   r := PRS_Interpolate( rg[2][2], 6.0, 10.0 ); Chk( r[1]==6.0 .AND. r[2]==8.0, "interp1" )
   // a_partial_signed_arc_remains_the_same_exact_arc
   poly := PL_New( { PV_Curved({-1.0,0.0},-1.0), PV_Straight({1.0,0.0}) }, .F. )
   orig := PL_SegmentArc( poly, 0 ); rg := PL_Ranged( poly, 0.25, 0.75 ); restr := PL_SegmentArc( rg[1], 0 )
   Chk( V2_Distance( BA_Sample(restr,0.5), BA_Sample(orig,0.5) ) < 0.000000000001, "partial arc same" )
   Chk( Abs( rg[1][PL_VERTS][1][PV_BULGE] - ( -OCX_TAN( OCX_PI / 8.0 ) ) ) < 0.000000000001, "partial arc bulge" )
   // a_closed_range_can_wrap_once
   poly := PL_New( { PV_Straight({0.0,0.0}), PV_Straight({1.0,0.0}), PV_Straight({1.0,1.0}), PV_Straight({0.0,1.0}) }, .T. )
   rg := PL_Ranged( poly, 0.75, 1.25 )
   Chk( ValType(rg)=="A" .AND. ! rg[1][PL_CLOSED], "wrap open" )
   Chk( VertsEq( rg[1][PL_VERTS], { PV_Straight({0.0,1.0}), PV_Straight({0.0,0.0}), PV_Straight({1.0,0.0}) } ), "wrap vertices" )
   Chk( Len(rg[2])==2 .AND. rg[2][1][1]==3 .AND. rg[2][2][1]==0, "wrap source idx" )
   // invalid_ranges_and_geometry_are_rejected
   poly := PL_New( { PV_Straight({0.0,0.0}), PV_Straight({1.0,0.0}) }, .F. )
   Chk( ValType(PL_Ranged(poly,0.5,0.5))=="U", "inv .5-.5" ); Chk( ValType(PL_Ranged(poly,OCX_NAN(),0.5))=="U", "inv nan" ); Chk( ValType(PL_Ranged(poly,0.5,1.5))=="U", "inv 1.5" )
   poly[PL_VERTS][1] := PV_Curved({0.0,0.0},1.0); poly[PL_VERTS][2][PV_POS] := {0.0,0.0}
   Chk( ValType(PL_Ranged(poly,0.0,1.0))=="U", "inv degenerate arc" )
RETURN
