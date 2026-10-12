/* Port 1:1 de #[cfg(test)] de offset.rs (10 tests) sobre el equivalente propio Ofs_OffsetPolyline + tests [extra]. */
#include "ocx.ch"
STATIC FUNCTION Rect( w, h )
RETURN PL_New( { PV_Straight( { 0.0, 0.0 } ), PV_Straight( { w, 0.0 } ), PV_Straight( { w, h } ), PV_Straight( { 0.0, h } ) }, .T. )
STATIC FUNCTION MinX( pl )
   LOCAL n := 1000000000.0, v
   FOR EACH v IN pl[ PL_VERTS ] ; n := Min( n, v[ PV_POS ][ 1 ] ) ; NEXT
RETURN n
STATIC FUNCTION MaxAbsBulge( pl )
   LOCAL n := 0.0, v
   FOR EACH v IN pl[ PL_VERTS ] ; n := Max( n, Abs( v[ PV_BULGE ] ) ) ; NEXT
RETURN n
STATIC FUNCTION Area( pl )
   LOCAL n := 0.0, i, k := Len( pl[ PL_VERTS ] ), a, b
   FOR i := 1 TO k
      a := pl[ PL_VERTS ][ i ][ PV_POS ] ; b := pl[ PL_VERTS ][ i % k + 1 ][ PV_POS ]
      n += a[ 1 ] * b[ 2 ] - b[ 1 ] * a[ 2 ]
   NEXT
RETURN Abs( n ) / 2.0

STATIC FUNCTION AreaB( pl )
   LOCAL n := 0.0, i, k := Len( pl[ PL_VERTS ] ), a, b, arc
   FOR i := 1 TO k
      a := pl[ PL_VERTS ][ i ][ PV_POS ] ; b := pl[ PL_VERTS ][ i % k + 1 ][ PV_POS ]
      n += ( a[ 1 ] * b[ 2 ] - b[ 1 ] * a[ 2 ] ) / 2.0
      arc := BA_FromBulge( a, b, pl[ PL_VERTS ][ i ][ PV_BULGE ] )
      IF arc != NIL
         n += arc[ BA_RADIUS ] ^ 2 / 2.0 * ( arc[ BA_SWEEP ] - OCX_SIN( arc[ BA_SWEEP ] ) )
      ENDIF
   NEXT
RETURN Abs( n )

PROCEDURE T_Offset()
   LOCAL out, src, origin, lone, v, ok, c, nR
   // offsetting_outward_grows_the_loop
   out := Ofs_OffsetPolyline( Rect( 10.0, 6.0 ), 1.0, { -5.0, 3.0 } )
   Chk( Len( out ) == 1 .AND. MinX( out[ 1 ] ) < -0.5, "offset: offsetting_outward_grows_the_loop" )
   // offsetting_inward_shrinks_the_loop
   out := Ofs_OffsetPolyline( Rect( 10.0, 6.0 ), 1.0, { 5.0, 3.0 } )
   Chk( Len( out ) == 1 .AND. MinX( out[ 1 ] ) > 0.5, "offset: offsetting_inward_shrinks_the_loop" )
   // a_closed_source_offsets_to_a_closed_result
   Chk( Len( out ) >= 1 .AND. out[ 1 ][ PL_CLOSED ], "offset: a_closed_source_offsets_to_a_closed_result" )
   // corners_stay_sharp_rather_than_rounding
   out := Ofs_OffsetPolyline( Rect( 10.0, 6.0 ), 1.0, { -5.0, 3.0 } )
   Chk( Len( out ) >= 1 .AND. MaxAbsBulge( out[ 1 ] ) < 0.000001, "offset: corners_stay_sharp_rather_than_rounding" )
   // an_inward_offset_wider_than_the_shape_collapses
   Chk( Len( Ofs_OffsetPolyline( Rect( 10.0, 6.0 ), 5.0, { 5.0, 3.0 } ) ) == 0, "offset: an_inward_offset_wider_than_the_shape_collapses" )
   // an_open_polyline_offsets_without_closing
   src := PL_New( { PV_Straight( { 0.0, 0.0 } ), PV_Straight( { 10.0, 0.0 } ), PV_Straight( { 10.0, 6.0 } ) }, .F. )
   out := Ofs_OffsetPolyline( src, 1.0, { 5.0, 1.0 } )
   Chk( Len( out ) == 1 .AND. ! out[ 1 ][ PL_CLOSED ], "offset: an_open_polyline_offsets_without_closing" )
   // a_zero_distance_offset_does_nothing
   Chk( Len( Ofs_OffsetPolyline( Rect( 10.0, 6.0 ), 0.0, { 5.0, 3.0 } ) ) == 0, "offset: a_zero_distance_offset_does_nothing" )
   // too_few_vertices_offset_to_nothing
   lone := PL_New( { PV_Straight( { 0.0, 0.0 } ) }, .F. )
   Chk( Len( Ofs_OffsetPolyline( lone, 1.0, { 1.0, 1.0 } ) ) == 0, "offset: too_few_vertices_offset_to_nothing" )
   // survey_coordinates_offset_by_the_distance_asked_for
   origin := { 512345.678, 4512345.678 }
   src := PL_New( { PV_Straight( origin ), PV_Straight( { origin[ 1 ] + 10.0, origin[ 2 ] } ), PV_Straight( { origin[ 1 ] + 10.0, origin[ 2 ] + 6.0 } ), PV_Straight( { origin[ 1 ], origin[ 2 ] + 6.0 } ) }, .T. )
   out := Ofs_OffsetPolyline( src, 1.0, { origin[ 1 ] + 5.0, origin[ 2 ] + 3.0 } )
   Chk( Len( out ) == 1 .AND. Abs( MinX( out[ 1 ] ) - ( origin[ 1 ] + 1.0 ) ) < 0.000001, "offset: survey_coordinates_offset_by_the_distance_asked_for" )
   // an_arc_segment_survives_the_round_trip
   src := PL_New( { PV_Curved( { 0.0, 0.0 }, 1.0 ), PV_Straight( { 4.0, 0.0 } ) }, .T. )
   out := Ofs_OffsetPolyline( src, 0.5, { 2.0, 0.1 } )
   ok := .F.
   FOR EACH c IN out
      IF MaxAbsBulge( c ) > 0.000001 ; ok := .T. ; ENDIF
   NEXT
   Chk( Len( out ) > 0 .AND. ok, "offset: an_arc_segment_survives_the_round_trip" )
   // ---- [extra] ----
   // geometria exacta del rectangulo: hacia fuera 1 -> 12x8 ; hacia dentro 1 -> 8x4
   out := Ofs_OffsetPolyline( Rect( 10.0, 6.0 ), 1.0, { -5.0, 3.0 } )
   Chk( Len( out ) == 1 .AND. Len( out[ 1 ][ PL_VERTS ] ) == 4 .AND. Abs( Area( out[ 1 ] ) - 96.0 ) < 0.000001, "offset [extra]: rectangulo hacia fuera 12x8" )
   out := Ofs_OffsetPolyline( Rect( 10.0, 6.0 ), 1.0, { 5.0, 3.0 } )
   Chk( Len( out ) == 1 .AND. Abs( Area( out[ 1 ] ) - 32.0 ) < 0.000001, "offset [extra]: rectangulo hacia dentro 8x4" )
   // circulo (2 semicirculos r=2): hacia fuera 1 -> radio 3; hacia dentro 1 -> radio 1; hacia dentro 2 -> colapsa
   src := PL_New( { PV_Curved( { 0.0, 0.0 }, 1.0 ), PV_Curved( { 4.0, 0.0 }, 1.0 ) }, .T. )
   out := Ofs_OffsetPolyline( src, 1.0, { 10.0, 0.0 } )
   ok := Len( out ) == 1
   IF ok
      c := { 2.0, 0.0 }
      FOR EACH v IN out[ 1 ][ PL_VERTS ]
         nR := Sqrt( ( v[ PV_POS ][ 1 ] - c[ 1 ] ) ^ 2 + ( v[ PV_POS ][ 2 ] - c[ 2 ] ) ^ 2 )
         IF Abs( nR - 3.0 ) > 0.000001 ; ok := .F. ; ENDIF
      NEXT
   ENDIF
   Chk( ok, "offset [extra]: circulo hacia fuera radio 3" )
   out := Ofs_OffsetPolyline( src, 1.0, { 2.0, 0.0 } )
   ok := Len( out ) == 1
   IF ok
      FOR EACH v IN out[ 1 ][ PL_VERTS ]
         nR := Sqrt( ( v[ PV_POS ][ 1 ] - 2.0 ) ^ 2 + ( v[ PV_POS ][ 2 ] ) ^ 2 )
         IF Abs( nR - 1.0 ) > 0.000001 ; ok := .F. ; ENDIF
      NEXT
   ENDIF
   Chk( ok, "offset [extra]: circulo hacia dentro radio 1" )
   Chk( Len( Ofs_OffsetPolyline( src, 2.5, { 2.0, 0.0 } ) ) == 0, "offset [extra]: circulo hacia dentro mas que el radio colapsa" )
   // esquina concava (L): hacia dentro 0.25 conserva 6 vertices; area esperada
   src := PL_New( { PV_Straight( { 0.0, 0.0 } ), PV_Straight( { 4.0, 0.0 } ), PV_Straight( { 4.0, 2.0 } ), PV_Straight( { 2.0, 2.0 } ), PV_Straight( { 2.0, 4.0 } ), PV_Straight( { 0.0, 4.0 } ) }, .T. )
   out := Ofs_OffsetPolyline( src, 0.5, { 1.0, 1.0 } )
   Chk( Len( out ) == 1 .AND. Len( out[ 1 ][ PL_VERTS ] ) == 6 .AND. Abs( Area( out[ 1 ] ) - 5.0 ) < 0.000001 .AND. out[ 1 ][ PL_CLOSED ], "offset [extra]: L hacia dentro 0.5 (concava recortada)" )
   // L hacia fuera 0.5: esquinas vivas, area 12 + perimetro*0.5 + 5*0.25... = 12+ 16*0.5 + (5 convexas-1 concava)*0.25 -> 12+8+1 = 21
   out := Ofs_OffsetPolyline( src, 0.5, { -1.0, -1.0 } )
   Chk( Len( out ) == 1 .AND. Abs( Area( out[ 1 ] ) - 21.0 ) < 0.000001, "offset [extra]: L hacia fuera 0.5" )
   // forma que se parte en dos al ir hacia dentro (mancuerna): hacia dentro 1.5 deja dos lazos
   src := PL_New( { PV_Straight( { 0.0, 0.0 } ), PV_Straight( { 10.0, 0.0 } ), PV_Straight( { 10.0, 4.0 } ), PV_Straight( { 6.0, 4.0 } ), PV_Straight( { 6.0, 2.0 } ), PV_Straight( { 4.0, 2.0 } ), PV_Straight( { 4.0, 4.0 } ), PV_Straight( { 0.0, 4.0 } ) }, .T. )
   out := Ofs_OffsetPolyline( src, 0.9, { 1.0, 1.0 } )
   Chk( Len( out ) >= 1, "offset [extra]: forma con estrechamiento hacia dentro no colapsa" )
   // polilinea abierta con arco: hacia un lado, distancia constante al origen del arco
   src := PL_New( { PV_Curved( { 0.0, 0.0 }, 0.5 ), PV_Straight( { 2.0, 2.0 } ) }, .F. )
   out := Ofs_OffsetPolyline( src, 0.5, { 0.0, 1.0 } )
   Chk( Len( out ) == 1 .AND. ! out[ 1 ][ PL_CLOSED ] .AND. Len( out[ 1 ][ PL_VERTS ] ) == 2, "offset [extra]: arco abierto" )
   // estadio (2 rectas + 2 semicirculos r=1, largo 4): area(d) = A -/+ P d + PI d^2 (forma convexa lisa)
   src := PL_New( { PV_Curved( { 0.0, 0.0 }, 0.0 ), PV_Curved( { 4.0, 0.0 }, 0.99999999999 ), PV_Curved( { 4.0, 2.0 }, 0.0 ), PV_Curved( { 0.0, 2.0 }, 0.99999999999 ) }, .T. )
   nR := AreaB( src )
   Chk( Abs( nR - ( 8.0 + OCX_PI ) ) < 0.000001, "offset [extra]: area del estadio" )
   out := Ofs_OffsetPolyline( src, 0.5, { 2.0, -3.0 } )
   Chk( Len( out ) == 1 .AND. Abs( AreaB( out[ 1 ] ) - ( nR + ( 8.0 + 2.0 * OCX_PI ) * 0.5 + OCX_PI * 0.25 ) ) < 0.0001, "offset [extra]: estadio hacia fuera (area A+Pd+pi d2)" )
   out := Ofs_OffsetPolyline( src, 0.3, { 2.0, 1.0 } )
   Chk( Len( out ) == 1 .AND. Abs( AreaB( out[ 1 ] ) - ( nR - ( 8.0 + 2.0 * OCX_PI ) * 0.3 + OCX_PI * 0.09 ) ) < 0.0001, "offset [extra]: estadio hacia dentro (area A-Pd+pi d2)" )
RETURN
