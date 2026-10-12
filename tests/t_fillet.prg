/* Port de #[cfg(test)] de fillet.rs. UTF-8. */
#include "ocx.ch"
STATIC FUNCTION Seg( a, b ) ; RETURN Cv_Line( a, b )
STATIC FUNCTION Circ( c, r ) ; RETURN Cv_Circle( c, r )
STATIC FUNCTION RA( r ) ; RETURN Fl_BetweenRays( {0.0,0.0}, {1.0,0.0}, {0.0,1.0}, r )
STATIC FUNCTION Tg( a, b, r )
   LOCAL found := Fl_Between( a, b, r, 0.000000001 ), f, i, c, t, nOn, aR, aAlong, cv, ok := .T.
   FOR EACH f IN found
      c := f[ FL_C ]
      FOR i := 1 TO 2
         t := f[ i ] ; cv := IIF( i == 1, a, b )
         IF Abs( V2_Distance( c, t ) - r ) >= 0.000001 ; ok := .F. ; ENDIF
         DO CASE
         CASE cv[ CV_KIND ] == CV_CIRCLE ; nOn := Abs( V2_Distance( t, cv[CV_DATA][CI_CENTRE] ) - cv[CV_DATA][CI_RADIUS] )
         CASE cv[ CV_KIND ] == CV_ARC    ; nOn := Abs( V2_Distance( t, cv[CV_DATA][AR_CENTRE] ) - cv[CV_DATA][AR_RADIUS] )
         OTHERWISE
            aR := Cv_AsRay( cv ) ; aAlong := V2_Normalize( aR[2] )
            nOn := Abs( V2_Cross( V2_Sub( t, aR[1] ), aAlong ) )
         ENDCASE
         IF nOn >= 0.000001 ; ok := .F. ; ENDIF
      NEXT
   NEXT
   IF ! ok ; Chk( .F., "tangency check failed" ) ; ENDIF
RETURN found

PROCEDURE T_Fillet()
   LOCAL f, found, circle, line, ok, a, b, corner, y, x, r, d2, small, large, d1, apex, t
   // a_line_and_a_circle_have_four_fillets...
   circle := Circ({0.0,0.0},10.0); line := Seg({-100.0,-20.0},{100.0,-20.0})
   found := Tg( circle, line, 5.0 ); ok := Len(found) > 0
   FOR EACH f IN found
   ok := ok .AND. ( Abs(f[3][2]+15.0)<0.000001 .OR. Abs(f[3][2]+25.0)<0.000001 )
   NEXT
   Chk( ok, "line and circle fillets" )
   Chk( Len( Tg( Circ({0.0,0.0},10.0), Seg({-50.0,-10.0},{50.0,-10.0}), 3.0 ) ) > 0, "tangent line still yields fillet" )
   Chk( Len( Tg( Circ({-20.0,0.0},10.0), Circ({20.0,0.0},10.0), 30.0 ) ) > 0, "two circles bridging" )
   found := Tg( Circ({-3.0,0.0},1.0), Circ({3.0,0.0},1.0), 5.0 ); y := Sqrt( 7.0 ); ok := .F.
   FOR EACH f IN found
   IF Abs(f[3][1])<0.000000001 .AND. ( Abs(f[3][2]-y)<0.000000001 .OR. Abs(f[3][2]+y)<0.000000001 )
   ok := .T.
   ENDIF
   NEXT
   Chk( ok, "larger circle encloses two tangent circles" )
   found := Tg( Seg({-10.0,0.0},{10.0,0.0}), Circ({0.0,2.0},1.0), 5.0 ); x := Sqrt( 7.0 ); ok := .F.
   FOR EACH f IN found
   IF Abs(f[3][2]-5.0)<0.000000001 .AND. ( Abs(f[3][1]-x)<0.000000001 .OR. Abs(f[3][1]+x)<0.000000001 )
   ok := .T.
   ENDIF
   NEXT
   Chk( ok, "larger circle encloses circle beside line" )
   a := Seg({-10.0,0.0},{10.0,0.0}); b := Seg({0.0,-10.0},{0.0,10.0}); corner := RA( 2.0 ); found := Tg( a, b, 2.0 ); ok := Len(found)==4
   FOR EACH f IN found
   IF V2_Distance( f[3], corner[3] ) < 0.000000001
   t := .T.
   ENDIF
   NEXT
   Chk( ok .AND. t == .T., "two lines agree with the corner form (n=" + LTrim(Str(Len(found))) + ")" )
   Chk( Len( Fl_Between( Circ({-1000.0,0.0},10.0), Circ({1000.0,0.0},10.0), 1.0, 0.000000001 ) )==0, "too far apart" )
   Chk( Len( Fl_Between( Cv_Ellipse( EA_Full( Ell_New( {0.0,0.0}, 10.0, 5.0, {1.0,0.0} ) ) ), Seg({-50.0,-20.0},{50.0,-20.0}), 2.0, 0.000000001 ) )==0, "ellipse has no closed-form offset" )
   ok := .T.
   FOR EACH r IN { 0.0, -1.0, OCX_NAN(), OCX_INF() }
      ok := ok .AND. Len( Fl_Between( a, b, r, 0.000000001 ) ) == 0
   NEXT
   Chk( ok, "nonsense radius refused" )
   ok := .T.
   FOR EACH f IN Fl_Between( a, b, 2.0, 0.000000001 )
      ok := ok .AND. ArcSpan( f[4], f[5] ) <= OCX_PI + 0.000000001
   NEXT
   Chk( ok, "short way round" )
   f := RA( 1.0 )
   Chk( Abs(f[1][1]-1.0)<0.000000000001 .AND. Abs(f[1][2])<0.000000000001 .AND. Abs(f[2][1])<0.000000000001 .AND. Abs(f[2][2]-1.0)<0.000000000001, "tangent points on rays" )
   f := Fl_BetweenRays( {3.0,-2.0}, {1.0,0.0}, {0.0,1.0}, 2.5 ); ok := .T.
   FOR EACH t IN { f[1], f[2] }
   ok := ok .AND. Abs( V2_Distance( t, f[3] ) - 2.5 ) < 0.000000001
   NEXT
   Chk( ok, "centre at radius from both tangents" )
   d1 := {1.0,0.0}; d2 := {0.6,0.8}; f := Fl_BetweenRays( {0.0,0.0}, d1, d2, 1.5 )
   Chk( Abs( V2_Dot( V2_Sub( f[1], f[3] ), d1 ) ) < 0.000000001 .AND. Abs( V2_Dot( V2_Sub( f[2], f[3] ), d2 ) ) < 0.000000001, "arc tangent to both rays" )
   f := RA( 1.0 ); Chk( Abs( ArcSpan( f[4], f[5] ) - OCX_FRAC_PI_2 ) < 0.000000001, "quarter turn" )
   f := Fl_BetweenRays( {0.0,0.0}, {0.0,1.0}, {1.0,0.0}, 1.0 ); Chk( Abs( ArcSpan( f[4], f[5] ) - OCX_FRAC_PI_2 ) < 0.000000001, "quarter turn other order" )
   f := Fl_BetweenRays( {0.0,0.0}, {1.0,0.0}, { 0.5, Sqrt(3.0)/2.0 }, 1.0 ); Chk( Abs( ArcSpan( f[4], f[5] ) - 2.0 * OCX_PI / 3.0 ) < 0.000000001, "sharper corner longer sweep" )
   small := RA( 1.0 ); large := RA( 4.0 ); Chk( large[1][1] > small[1][1] .AND. large[3][2] > small[3][2], "bigger radius further out" )
   Chk( Fl_BetweenRays( {0.0,0.0}, {1.0,0.0}, {1.0,0.0}, 1.0 ) == NIL .AND. Fl_BetweenRays( {0.0,0.0}, {1.0,0.0}, {-1.0,0.0}, 1.0 ) == NIL, "parallel and opposed none" )
   Chk( Fl_BetweenRays( {0.0,0.0}, {1.0,0.0}, {0.0,1.0}, 0.0 ) == NIL, "zero radius none" )
   apex := { 512345.678, 4512345.678 }; f := Fl_BetweenRays( apex, {1.0,0.0}, {0.0,1.0}, 0.75 )
   Chk( Abs( V2_Distance( f[1], f[3] ) - 0.75 ) < 0.000000001, "survey keeps radius" )
RETURN
