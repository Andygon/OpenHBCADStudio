/* Port 1:1 de los 11 tests de geom2d/tessellate.rs */
#include "ocx.ch"
PROCEDURE T_Tessellate()
   LOCAL pts, f, l, c, p, lOk, nSparse, nDense, circ, asE, asA, i, e, fw, bw, cen, rad, rx, ry, nAlong, nAcross, nVal, aOrg, ax
   pts := Tz_Arc( {0.0,0.0}, 1.0, 0.0, OCX_TAU / 4.0, 0.0, Tz_DefaultSegmentsPerRadian() )
   f := pts[1] ; l := ATail( pts )
   Chk( Abs( f[1] - 1.0 ) < 0.000000000001 .AND. Abs( f[2] ) < 0.000000000001 .AND. Abs( l[1] ) < 0.000000000001 .AND. Abs( l[2] - 1.0 ) < 0.000000000001, "tess: an_arc_includes_both_endpoints" )
   c := { 3.0, -4.0 } ; lOk := .T.
   FOR EACH p IN Tz_Arc( c, 7.5, 0.3, 4.0, 2.0, Tz_DefaultSegmentsPerRadian() )
      IF Abs( Sqrt( ( p[1] - c[1] ) ^ 2 + ( p[2] - c[2] ) ^ 2 ) - 7.5 ) >= 0.000000001 .OR. p[3] != 2.0 ; lOk := .F. ; ENDIF
   NEXT
   Chk( lOk, "tess: every_sampled_point_sits_on_the_circle" )
   pts := Tz_Arc( {0.0,0.0}, 1.0, 0.0, 0.0, 0.0, Tz_DefaultSegmentsPerRadian() )
   f := pts[1] ; l := ATail( pts )
   Chk( Len( pts ) > 100 .AND. Abs( f[1] - l[1] ) < 0.000000001 .AND. Abs( f[2] - l[2] ) < 0.000000001, "tess: a_closed_arc_sweeps_a_full_turn" )
   pts := Tz_Arc( {0.0,0.0}, 1.0, 1.0, 1.000001, 0.0, Tz_DefaultSegmentsPerRadian() )
   Chk( Len( pts ) == Tz_MinimumSegments() + 1, "tess: a_vanishingly_short_arc_still_gets_a_few_segments" )
   nSparse := Len( Tz_Arc( {0.0,0.0}, 1.0, 0.0, OCX_TAU, 0.0, 1.0 ) )
   nDense := Len( Tz_Arc( {0.0,0.0}, 1.0, 0.0, OCX_TAU, 0.0, 50.0 ) )
   Chk( nDense > nSparse * 10, "tess: density_scales_with_the_requested_rate" )
   circ := Ell_New( {0.0,0.0}, 1.0, 1.0, {1.0,0.0} )
   pts := Tz_EllipseArc( circ, 0.0, OCX_TAU / 4.0, 9.0, Tz_DefaultSegmentsPerRadian() )
   l := ATail( pts )
   Chk( Abs( l[1] ) < 0.000000000001 .AND. Abs( l[2] - 1.0 ) < 0.000000000001 .AND. l[3] == 9.0, "tess: components_land_in_x_y_z_order" )
   circ := Ell_New( {1.0,2.0}, 3.0, 3.0, {1.0,0.0} )
   asE := Tz_EllipseArc( circ, 0.0, OCX_TAU / 2.0, 0.0, Tz_DefaultSegmentsPerRadian() )
   asA := Tz_Arc( {1.0,2.0}, 3.0, 0.0, OCX_TAU / 2.0, 0.0, Tz_DefaultSegmentsPerRadian() )
   lOk := Len( asE ) == Len( asA )
   IF lOk
      FOR i := 1 TO Len( asE )
         IF Abs( asE[i][1] - asA[i][1] ) >= 0.000000001 .OR. Abs( asE[i][2] - asA[i][2] ) >= 0.000000001 ; lOk := .F. ; ENDIF
      NEXT
   ENDIF
   Chk( lOk, "tess: a_unit_ratio_ellipse_matches_the_circle_of_the_same_radius" )
   e := Ell_New( {-6.0,11.0}, 8.0, 3.0, {0.6,0.8} )
   cen := {-6.0,11.0} ; rad := 8.0 ; ax := {0.6,0.8} ; lOk := .T.
   FOR EACH p IN Tz_EllipseArc( e, 0.2, 5.0, 0.0, Tz_DefaultSegmentsPerRadian() )
      rx := p[1] - cen[1] ; ry := p[2] - cen[2]
      nAlong := rx * ax[1] + ry * ax[2]
      nAcross := -rx * ax[2] + ry * ax[1]
      nVal := ( nAlong / rad ) ^ 2 + ( nAcross / 3.0 ) ^ 2
      IF Abs( nVal - 1.0 ) >= 0.000000001 ; lOk := .F. ; ENDIF
   NEXT
   Chk( lOk, "tess: every_sampled_point_satisfies_the_ellipse_equation" )
   e := Ell_New( {0.0,0.0}, 2.0, 1.0, {1.0,0.0} )
   fw := Tz_EllipseArc( e, 0.0, OCX_TAU / 4.0, 0.0, Tz_DefaultSegmentsPerRadian() )
   bw := Tz_EllipseArc( e, OCX_TAU / 4.0, 0.0, 0.0, Tz_DefaultSegmentsPerRadian() )
   Chk( Len( fw ) == Len( bw ) .AND. Abs( ATail( fw )[2] - bw[1][2] ) < 0.000000000001, "tess: a_backwards_parameter_range_sweeps_the_other_way" )
   aOrg := { 512345.678, 4512345.678 } ; lOk := .T.
   FOR EACH p IN Tz_Arc( aOrg, 0.5, 0.0, OCX_TAU, 0.0, Tz_DefaultSegmentsPerRadian() )
      IF Abs( Sqrt( ( p[1] - aOrg[1] ) ^ 2 + ( p[2] - aOrg[2] ) ^ 2 ) - 0.5 ) >= 0.000000001 ; lOk := .F. ; ENDIF
   NEXT
   Chk( lOk, "tess: survey_coordinates_keep_their_precision" )
   Chk( Tz_Lerp( {0.0,0.0}, {10.0,20.0}, 0.0 )[1] == 0.0 .AND. Tz_Lerp( {0.0,0.0}, {10.0,20.0}, 1.0 )[2] == 20.0 .AND. Tz_Lerp( {0.0,0.0}, {10.0,20.0}, 0.5 )[1] == 5.0 .AND. Tz_Lerp( {0.0,0.0}, {10.0,20.0}, 0.5 )[2] == 10.0, "tess: lerp_hits_both_ends_and_the_middle" )
RETURN
