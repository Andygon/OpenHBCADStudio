/* hatch.rs no tiene tests. Port de tests de hatch_origin.rs (3 de 4; el de DWG queda fuera de alcance) + [extra] */
#include "ocx.ch"
STATIC FUNCTION Ap( a, b ) ; RETURN Abs( a - b ) < 0.000000000001
STATIC FUNCTION Same( a, b ) ; RETURN hb_ValToExp( a ) == hb_ValToExp( b )
STATIC FUNCTION Patterned()
   LOCAL p := Hpt_New( "TEST" )
   Hpt_AddLine( p, Hpl_New( 0.0, Vc2_New( 2.0, 1.0 ), Vc2_New( 1.0, 0.0 ), { 2.0, -1.0 } ) )
RETURN Ehh_WithPattern( p )
PROCEDURE T_CodecHatch()
   LOCAL h, acad, other, r, before, l, vq, e, p, bb
   // recording_an_origin_preserves_nested_and_unrelated_data
   h := Patterned() ; acad := Xr_New( "ACAD" )
   Xr_AddValue( acad, Xv_New( XV_CONTROLSTRING, "{" ) ) ; Xr_AddValue( acad, Xv_New( XV_POINT3D, Vc3_New( 90.0, 91.0, 92.0 ) ) ) ; Xr_AddValue( acad, Xv_New( XV_CONTROLSTRING, "}" ) )
   Xr_AddValue( acad, Xv_New( XV_STRING, "keep" ) ) ; Xr_AddValue( acad, Xv_New( XV_POINT3D, Vc3_New( 1.0, 2.0, 3.0 ) ) )
   Xd_AddRecord( h[ "common" ][ "extended_data" ], acad )
   other := Xr_New( "OTHER" ) ; Xr_AddValue( other, Xv_New( XV_INTEGER16, 7 ) ) ; Xd_AddRecord( h[ "common" ][ "extended_data" ], Ent_Clone( other ) )
   Chk( Ehh_RecordPatternOrigin( h, Vc2_New( 4.0, 5.0 ) ) .AND. Vc2_Eq( Ehh_PatternOrigin( h ), Vc2_New( 4.0, 5.0 ) ), "hatch_origin: record origin" )
   r := Xd_GetRecord( h[ "common" ][ "extended_data" ], "ACAD" )
   Chk( Same( Xr_Values( r )[ 2 ], Xv_New( XV_POINT3D, Vc3_New( 90.0, 91.0, 92.0 ) ) ) .AND. Same( Xr_Values( r )[ 4 ], Xv_New( XV_STRING, "keep" ) ) .AND. Same( Xd_GetRecord( h[ "common" ][ "extended_data" ], "OTHER" ), other ), "hatch_origin: recording_an_origin_preserves_nested_and_unrelated_data" )
   // changing_scaling_and_rotating_origin_move_pattern_geometry_consistently
   h := Patterned()
   Chk( Ehh_SetPatternOrigin( h, Vc2_New( 1.0, 1.0 ) ) .AND. Vc2_Eq( h[ "pattern" ][ "lines" ][ 1 ][ "base_point" ], Vc2_New( 3.0, 2.0 ) ), "hatch_origin: set_pattern_origin mueve base" )
   before := Ent_Clone( h )
   Chk( ! Ehh_SetPatternOrigin( h, Vc2_New( OCX_NAN(), 0.0 ) ) .AND. Same( h, before ), "hatch_origin: origen NaN rechazado sin cambios" )
   Ehh_ScalePatternAboutOrigin( h, 2.0 ) ; l := h[ "pattern" ][ "lines" ][ 1 ]
   Chk( Vc2_Eq( l[ "base_point" ], Vc2_New( 5.0, 3.0 ) ) .AND. Vc2_Eq( l[ "offset" ], Vc2_New( 2.0, 0.0 ) ) .AND. l[ "dash_lengths" ][ 1 ] == 4.0 .AND. l[ "dash_lengths" ][ 2 ] == -2.0, "hatch_origin: scale_pattern_about_origin" )
   Ehh_RotatePatternAboutOrigin( h, OCX_PI / 2.0 ) ; l := h[ "pattern" ][ "lines" ][ 1 ]
   Chk( Ap( l[ "base_point" ][ 1 ] + 1.0, 0.0 ) .AND. Ap( l[ "base_point" ][ 2 ], 5.0 ) .AND. Ap( l[ "offset" ][ 1 ], 0.0 ) .AND. Ap( l[ "offset" ][ 2 ], 2.0 ), "hatch_origin: rotate_pattern_about_origin" )
   // translation_and_transform_move_the_recorded_origin_with_the_hatch
   h := Patterned() ; Ehh_RecordPatternOrigin( h, Vc2_New( 1.0, 2.0 ) ) ; Ent_Translate( h, Vc3_New( 5.0, -1.0, 0.0 ) )
   Chk( Vc2_Eq( Ehh_PatternOrigin( h ), Vc2_New( 6.0, 1.0 ) ) .AND. Vc2_Eq( h[ "pattern" ][ "lines" ][ 1 ][ "base_point" ], Vc2_New( 7.0, 0.0 ) ), "hatch_origin: translate mueve origen" )
   h := Patterned() ; Ehh_RecordPatternOrigin( h, Vc2_New( 1.0, 2.0 ) ) ; Ent_ApplyTransform( h, Tf_FromScale( 2.0 ) )
   Chk( Vc2_Eq( Ehh_PatternOrigin( h ), Vc2_New( 2.0, 4.0 ) ) .AND. Vc2_Eq( h[ "pattern" ][ "lines" ][ 1 ][ "base_point" ], Vc2_New( 4.0, 2.0 ) ), "hatch_origin: transform mueve origen" )
   // [extra] hatch.rs
   h := Ehh_Solid() ; p := Bpa_External() ; Bpa_AddEdge( p, Bed_Polyline( { Vc2_New( 0.0, 0.0 ), Vc2_New( 4.0, 0.0 ), Vc2_New( 4.0, 3.0 ) }, .T. ) ) ; Ehh_AddPath( h, p )
   Chk( Bpf_IsExternal( p[ "flags" ] ) .AND. Bpf_IsPolyline( p[ "flags" ] ) .AND. Bpa_IsPolyline( p ) .AND. Ehh_PathCount( h ) == 1 .AND. ! Bed_HasBulge( p[ "edges" ][ 1 ] ), "[extra] hatch: flags y path polyline" )
   bb := Ent_BoundingBox( h ) ; Chk( Vc3_Eq( bb[ 1 ], Vc3_New( 0.0, 0.0, 0.0 ) ) .AND. Vc3_Eq( bb[ 2 ], Vc3_New( 4.0, 3.0, 0.0 ) ), "[extra] hatch: bounding_box" )
   h := Ehh_Solid() ; p := Bpa_New() ; Bpa_AddEdge( p, Bed_Line( Vc2_New( 0.0, 0.0 ), Vc2_New( 1.0, 0.0 ) ) ) ; Bpa_AddEdge( p, Bed_CircularArc( Vc2_New( 1.0, 1.0 ), 1.0, 0.0, OCX_PI / 2.0, .T. ) ) ; Ehh_AddPath( h, p )
   Ent_Translate( h, Vc3_New( 1.0, 2.0, 3.0 ) ) ; e := h[ "paths" ][ 1 ][ "edges" ]
   Chk( Vc2_Eq( e[ 1 ][ "start" ], Vc2_New( 1.0, 2.0 ) ) .AND. Vc2_Eq( e[ 2 ][ "center" ], Vc2_New( 2.0, 3.0 ) ) .AND. Ap( h[ "elevation" ], 3.0 ), "[extra] hatch: translate de aristas y elevacion" )
   Ent_ApplyTransform( h, Tf_FromRotation( Vc3_New( 0.0, 0.0, 1.0 ), OCX_PI / 2.0 ) ) ; e := h[ "paths" ][ 1 ][ "edges" ]
   Chk( Ap( e[ 1 ][ "start" ][ 1 ], -2.0 ) .AND. Ap( e[ 1 ][ "start" ][ 2 ], 1.0 ) .AND. Ap( e[ 2 ][ "start_angle" ], OCX_PI / 2.0 ), "[extra] hatch: rotacion 90 de linea y arco" )
   h := Ehh_Solid() ; p := Bpa_New() ; Bpa_AddEdge( p, Bed_CircularArc( Vc2_Zero(), 1.0, 0.0, OCX_PI / 2.0, .T. ) ) ; Ehh_AddPath( h, p )
   Ent_ApplyTransform( h, Tf_FromScaling( Vc3_New( 2.0, 1.0, 1.0 ) ) ) ; e := h[ "paths" ][ 1 ][ "edges" ][ 1 ]
   Chk( e[ "kind" ] == "EllipticArc" .AND. Ap( Vc2_Length( e[ "major_axis_endpoint" ] ), 2.0 ) .AND. Ap( e[ "minor_axis_ratio" ], 0.5 ), "[extra] hatch: arco con escala no uniforme pasa a EllipticArc" )
   h := Ehh_New() ; Ehh_AddSeedPoint( h, Vc2_New( 1.0, 1.0 ) ) ; Hgp_AddColor( h[ "gradient_color" ], 0.5, Cl_FromIndex( 1 ) )
   Chk( Len( h[ "gradient_color" ][ "colors" ] ) == 1 .AND. ! Hgp_IsEnabled( h[ "gradient_color" ] ) .AND. Ent_BoundingBox( h )[ 1 ][ 1 ] == 0.0, "[extra] hatch: gradiente, seed y bbox vacio" )
   vq := Patterned() ; Ehh_SetPatternScale( vq, 2.0 ) ; Ehh_SetPatternAngle( vq, 1.0 )
   Chk( Vc2_Eq( vq[ "pattern" ][ "lines" ][ 1 ][ "offset" ], Vc2_New( 4.0, 0.0 ) ) .AND. Ap( vq[ "pattern" ][ "lines" ][ 1 ][ "angle" ], 1.0 ), "[extra] hatch: pattern update acumula escala (quirk upstream: cada set_* reaplica la escala)" )
RETURN
