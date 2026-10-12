/* [extra] construct.rs no tiene #[test]; comprobaciones de propiedades. UTF-8. */
#include "ocx.ch"
PROCEDURE T_Construct()
   LOCAL a, nSw
   // semicirculo por tres puntos: centro (0,0), r 5
   a := Cs_ArcThroughPoints( {5.0,0.0}, {0.0,5.0}, {-5.0,0.0} )
   Chk( a != NIL .AND. V2_Distance( a[1], {0.0,0.0} ) < 0.000000001 .AND. Abs( a[2] - 5.0 ) < 0.000000001 .AND. Abs( ArcSpan( a[3], a[4] ) - OCX_PI ) < 0.000000001, "[extra] arc through 3 points" )
   // el punto medio queda sobre el arco: con orden invertido el arco va por abajo
   a := Cs_ArcThroughPoints( {5.0,0.0}, {0.0,-5.0}, {-5.0,0.0} )
   Chk( a != NIL .AND. Abs( ArcSpan( a[3], a[4] ) - OCX_PI ) < 0.000000001 .AND. Abs( Cv_PointAt( Cv_Arc( a[1], a[2], a[3], a[4] ), 0.5 )[2] + 5.0 ) < 0.000001, "[extra] arc through 3 points goes via the middle" )
   Chk( Cs_ArcThroughPoints( {0.0,0.0}, {1.0,1.0}, {2.0,2.0} ) == NIL, "[extra] collinear -> NIL" )
   a := Cs_ArcFromEndpointsAngle( {0.0,0.0}, {10.0,0.0}, OCX_PI )
   Chk( a != NIL .AND. Abs( a[2] - 5.0 ) < 0.000000001 .AND. V2_Distance( a[1], {5.0,0.0} ) < 0.000000001, "[extra] endpoints+angle semicircle" )
   Chk( Cs_ArcFromEndpointsAngle( {0.0,0.0}, {10.0,0.0}, OCX_TAU ) == NIL .AND. Cs_ArcFromEndpointsAngle( {0.0,0.0}, {10.0,0.0}, 0.0 ) == NIL, "[extra] degenerate angles" )
   a := Cs_ArcFromEndpointsRadius( {0.0,0.0}, {10.0,0.0}, 5.0 )
   Chk( a != NIL .AND. Abs( a[2] - 5.0 ) < 0.000000001, "[extra] endpoints+radius" )
   Chk( Cs_ArcFromEndpointsRadius( {0.0,0.0}, {10.0,0.0}, 4.0 ) == NIL, "[extra] chord longer than diameter" )
   nSw := Cs_ArcSweepFromChord( 5.0, 5.0 )
   Chk( Abs( nSw - OCX_PI / 3.0 ) < 0.000000001 .AND. Abs( Cs_ArcSweepFromChord( 5.0, -5.0 ) - ( OCX_TAU - OCX_PI / 3.0 ) ) < 0.000000001, "[extra] sweep from chord minor/major" )
   a := Cs_ArcFromSagitta( {0.0,0.0}, {10.0,0.0}, 5.0 )
   Chk( a != NIL .AND. Abs( a[2] - 5.0 ) < 0.000000001, "[extra] sagitta = half chord gives semicircle" )
   a := Cs_ArcFromStartTangent( {0.0,0.0}, {0.0,1.0}, {10.0,10.0}, .F. )
   Chk( a != NIL .AND. V2_Distance( a[1], {10.0,0.0} ) < 0.000000001 .AND. Abs( a[2] - 10.0 ) < 0.000000001, "[extra] arc from start tangent" )
   Chk( Cs_BoundedArc( {0.0,0.0}, 1.0, 0.0, 0.0 ) == NIL .AND. Cs_BoundedArc( {0.0,0.0}, 1.0, 0.0, 1.0 ) != NIL .AND. Cs_BoundedArc( {0.0,0.0}, -1.0, 0.0, 1.0 ) == NIL, "[extra] bounded arc" )
RETURN
