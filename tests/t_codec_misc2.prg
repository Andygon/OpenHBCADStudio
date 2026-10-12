/* Tests [extra] (ole2frame, section_symbol y centerline no tienen #[test] en Rust) */
#include "ocx.ch"
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
PROCEDURE T_CodecMisc2()
   LOCAL o, s, p, bb, x, a, b, m
   o := Eo2_New() ; Chk( o[ "version" ] == 2 .AND. Vc3_Eq( o[ "upper_left_corner" ], V( 1.0, 1.0, 0.0 ) ) .AND. o[ "ole_object_type" ] == OOT_EMBEDDED .AND. Ent_EntityType( o ) == "OLE2FRAME", "[extra] ole2frame: valores por defecto" )
   Chk( Oot_FromI16( 1 ) == OOT_LINK .AND. Oot_FromI16( 3 ) == OOT_STATIC .AND. Oot_FromI16( 9 ) == OOT_EMBEDDED, "[extra] ole2frame: from_i16" )
   Ent_Translate( o, V( 1.0, 2.0, 3.0 ) ) ; bb := Ent_BoundingBox( o )
   Chk( Vc3_Eq( bb[ 1 ], V( 1.0, 2.0, 3.0 ) ) .AND. Vc3_Eq( bb[ 2 ], V( 2.0, 3.0, 3.0 ) ), "[extra] ole2frame: translate y bounding_box" )
   Ent_ApplyTransform( o, Tf_FromScale( 2.0 ) ) ; Chk( Vc3_Eq( o[ "lower_right_corner" ], V( 2.0, 4.0, 6.0 ) ), "[extra] ole2frame: transform" )
   s := Esy_New() ; Chk( s[ "symbol_scale" ] == 1.0 .AND. Ent_EntityType( s ) == "SECTIONLINE" .AND. Len( s[ "points" ] ) == 0, "[extra] section_symbol: valores por defecto" )
   Esy_SyncDisplayFields( s ) ; Chk( s[ "label" ] == "", "[extra] section_symbol: sync sin puntos no hace nada" )
   p := Ssp_New() ; p[ "point" ] := V( 1.0, 2.0, 0.0 ) ; p[ "label" ] := "A" ; p[ "label_offset" ] := V( 0.0, 3.0, 0.0 ) ; AAdd( s[ "points" ], p )
   p := Ssp_New() ; p[ "point" ] := V( 5.0, 6.0, 0.0 ) ; p[ "label_offset" ] := V( 0.0, 4.0, 0.0 ) ; AAdd( s[ "points" ], p )
   Esy_SyncDisplayFields( s )
   Chk( s[ "end_a" ][ 1 ] == 1.0 .AND. s[ "end_b" ][ 2 ] == 6.0 .AND. s[ "tick_a" ] == 3.0 .AND. s[ "tick_b" ] == 4.0 .AND. s[ "label" ] == "A", "[extra] section_symbol: sync_display_fields" )
   Esy_Translate( s, V( 1.0, 1.0, 0.0 ) ) ; Chk( s[ "points" ][ 1 ][ "point" ][ 1 ] == 2.0 .AND. s[ "end_a" ][ 1 ] == 2.0, "[extra] section_symbol: Esy_Translate" )
   Ent_Translate( s, V( 100.0, 0.0, 0.0 ) ) ; bb := Ent_BoundingBox( s ) ; Chk( s[ "end_a" ][ 1 ] == 2.0 .AND. bb[ 1 ][ 1 ] == 2.0, "[extra] section_symbol: el despachador no mueve" )
   Esy_Transform( s, Tf_FromScale( 2.0 ) ) ; Chk( s[ "points" ][ 1 ][ "point" ][ 1 ] == 4.0 .AND. s[ "points" ][ 1 ][ "label_offset" ][ 2 ] == 6.0 .AND. s[ "end_b" ][ 1 ] == 12.0, "[extra] section_symbol: Esy_Transform escala label_offset" )
   x := Xd_New() ; Chk( Cla_Read( x ) == NIL .AND. Cma_Read( x ) == NIL, "[extra] centerline: sin registro es None" )
   a := hb_Hash( "first", hb_Hash( "handle", 10, "kind", CLS_LINE, "segment_index", 0, "pick_point", V( 1.0, 2.0, 3.0 ) ), "second", hb_Hash( "handle", 11, "kind", CLS_POLY2D_SEGMENT, "segment_index", 4, "pick_point", V( 4.0, 5.0, 6.0 ) ), ;
      "plane_origin", V( 0.0, 0.0, 0.0 ), "plane_x", V( 1.0, 0.0, 0.0 ), "plane_y", V( 0.0, 1.0, 0.0 ), "start_extension", 0.5, "end_extension", 0.25, "start_length_adjustment", 1.0, "end_length_adjustment", 2.0, "associated", .T. )
   Cla_Write( a, x ) ; b := Cla_Read( x )
   Chk( b != NIL .AND. b[ "first" ][ "handle" ] == 10 .AND. b[ "second" ][ "kind" ] == CLS_POLY2D_SEGMENT .AND. b[ "second" ][ "segment_index" ] == 4 .AND. Vc3_Eq( b[ "second" ][ "pick_point" ], V( 4.0, 5.0, 6.0 ) ) .AND. b[ "end_length_adjustment" ] == 2.0 .AND. b[ "associated" ], "[extra] centerline: write/read ida y vuelta" )
   Cla_Write( a, x ) ; Chk( Xd_Len( x ) == 1, "[extra] centerline: write es upsert" )
   Cla_Remove( x ) ; Chk( Xd_Len( x ) == 0 .AND. Cla_Read( x ) == NIL, "[extra] centerline: remove" )
   m := hb_Hash( "source", hb_Hash( "handle", 7, "kind", CMS_ARC, "segment_index", 1, "pick_point", V( 1.0, 1.0, 0.0 ) ), "plane_origin", V( 0.0, 0.0, 0.0 ), "plane_x", V( 1.0, 0.0, 0.0 ), "plane_y", V( 0.0, 1.0, 0.0 ), ;
      "center", V( 2.0, 2.0, 0.0 ), "radius", 3.0, "cross_size", 0.5, "cross_gap", 0.1, "cross_size_relative", .T., "cross_gap_relative", .F., "extension_length", 1.5, "length_adjustments", { 1.0, 2.0, 3.0, 4.0 }, ;
      "overshoots", { 5.0, 6.0, 7.0, 8.0 }, "show_extensions", .T., "associated", .F. )
   Cma_Write( m, x ) ; b := Cma_Read( x )
   Chk( b != NIL .AND. b[ "source" ][ "kind" ] == CMS_ARC .AND. b[ "radius" ] == 3.0 .AND. b[ "overshoots" ][ 4 ] == 8.0 .AND. b[ "show_extensions" ] .AND. ! b[ "associated" ] .AND. b[ "cross_size_relative" ] .AND. ! b[ "cross_gap_relative" ], "[extra] centerline: marca ida y vuelta con flags" )
   Chk( Cls_FromCode( 3 ) == NIL .AND. Cms_FromCode( 4 ) == NIL .AND. Cms_FromCode( 3 ) == CMS_POLY2D_ARC_SEG, "[extra] centerline: from_code fuera de rango es None" )
RETURN
