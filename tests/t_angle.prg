/* Port 1:1 de #[cfg(test)] de angle.rs. UTF-8. */
#include "ocx.ch"
PROCEDURE T_Angle()
   LOCAL nS, nE, nB, nZ, nA
   Chk( Near(NormalizeAngle(0.0),0,0.000000000001), "n0" ); Chk( Near(NormalizeAngle(OCX_TAU),0,0.000000000001), "nTAU" )
   Chk( Near(NormalizeAngle(-OCX_FRAC_PI_2),OCX_TAU-OCX_FRAC_PI_2,0.000000000001), "n-" ); Chk( Near(NormalizeAngle(3*OCX_TAU+OCX_PI),OCX_PI,0.000000000001), "n3T" )
   Chk( Near(ArcSpan(0,0),OCX_TAU,0.000000000001), "closed0" ); Chk( Near(ArcSpan(OCX_PI,OCX_PI),OCX_TAU,0.000000000001), "closedPI" )
   Chk( Near(ArcSpan(0,OCX_FRAC_PI_2),OCX_FRAC_PI_2,0.000000000001), "span" ); Chk( Near(ArcSpan(OCX_FRAC_PI_2,0),OCX_TAU-OCX_FRAC_PI_2,0.000000000001), "span long" )
   nS := 7*OCX_PI/4; nE := OCX_PI/4
   Chk( AngleWithinArc(0.0,nS,nE), "w0" ); Chk( AngleWithinArc(0.1,nS,nE), "w.1" ); Chk( AngleWithinArc(OCX_TAU-0.1,nS,nE), "wT-.1" ); Chk( !AngleWithinArc(OCX_PI,nS,nE), "!wPI" )
   Chk( AngleWithinArc(OCX_FRAC_PI_2,0,OCX_PI), "nz in" ); Chk( !AngleWithinArc(3*OCX_PI/2,0,OCX_PI), "nz out" )
   Chk( AngleWithinArc(OCX_PI,0,0), "closed all" ); Chk( AngleWithinArc(0.3,1,1), "closed all2" )
   Chk( Near(ArcParameter(0,0,OCX_PI),0,0.000000000001), "p0" ); Chk( Near(ArcParameter(OCX_FRAC_PI_2,0,OCX_PI),0.5,0.000000000001), "p.5" ); Chk( Near(ArcParameter(OCX_PI,0,OCX_PI),1,0.000000000001), "p1" )
   Chk( ArcParameter(3*OCX_PI/2,0,OCX_PI) == 1.0, "clamp" )
   nB := ArcParameter(7.1*OCX_PI/4,nS,nE); nZ := ArcParameter(0,nS,nE); nA := ArcParameter(0.1,nS,nE)
   Chk( nB < nZ, "mono1" ); Chk( nZ < nA, "mono2" )
RETURN
