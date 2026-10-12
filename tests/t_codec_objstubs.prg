/* Tests: stub_objects.rs no tiene #[test]; todos [extra] (valores por defecto y has_advanced_data) */
#include "ocx.ch"
PROCEDURE T_CodecObjStubs()
   LOCAL m, d, g, s
   d := Mmp_Default() ; Chk( d[ "blend_factor" ] == 1.0 .AND. d[ "projection" ] == 2 .AND. d[ "tiling" ] == 1 .AND. d[ "transform" ][ 1 ] == 1.0 .AND. d[ "transform" ][ 6 ] == 1.0 ;
      .AND. d[ "transform" ][ 11 ] == 1.0 .AND. d[ "transform" ][ 16 ] == 1.0 .AND. d[ "transform" ][ 2 ] == 0.0 .AND. Len( d[ "transform" ] ) == 16 .AND. Mmp_IsDefault( d ), "[extra] material map default" )
   d[ "projection" ] := 3 ; Chk( ! Mmp_IsDefault( d ), "[extra] map distinto de default" )
   Chk( Mcl_Eq( Mcl_Default(), hb_Hash( "flag", 0, "factor", 1.0, "rgb", NIL ) ) .AND. Mtx_Default()[ "procedural" ] == NIL, "[extra] material color/texture default" )
   m := Mat_New() ; Chk( m[ "channel_flags" ] == 127 .AND. m[ "specular_gloss_factor" ] == 0.5 .AND. m[ "opacity_percent" ] == 1.0 .AND. ! Mat_HasAdvancedData( m ), "[extra] material default" )
   m[ "luminance" ] := 2.0 ; Chk( Mat_HasAdvancedData( m ), "[extra] advanced por luminance" )
   m := Mat_New() ; m[ "normal_map" ][ "source" ] := 1 ; Chk( Mat_HasAdvancedData( m ), "[extra] advanced por normal_map" )
   m := Mat_New() ; m[ "advanced_data_present" ] := .T. ; Chk( Mat_HasAdvancedData( m ), "[extra] advanced por flag" )
   m := Mat_New() ; m[ "color_bleed_scale" ] := 2.0 ; Chk( Mat_HasAdvancedData( m ), "[extra] advanced por color_bleed" )
   g := Gdt_Default() ; Chk( g[ "version" ] == 2 .AND. g[ "obsolete_scale_vector" ][ 3 ] == 1.0 .AND. g[ "user_scale_factor" ] == 1.0 .AND. Len( g[ "mesh_points" ] ) == 0 .AND. Len( g[ "north_direction" ] ) == 2, "[extra] geodata default" )
   s := Spf_New() ; Chk( s[ "normal" ][ 3 ] == 1.0 .AND. s[ "display_enabled" ] .AND. s[ "front_clip" ] == NIL .AND. s[ "inverse_block_transform" ][ 4 ][ 4 ] == 1.0, "[extra] spatialfilter default" )
   Chk( Rvr_New()[ "display_image_frame" ] == 1 .AND. Rvr_New()[ "image_quality" ] == 1 .AND. Wov_New()[ "display_frame" ] == 1 .AND. Cl_Eq( Bkc_New()[ "color" ], Cl_Default() ), "[extra] raster/wipeout/bookcolor default" )
   d := Ddf_New() ; Chk( d[ "duplicate_cloning" ] == 1 .AND. ! d[ "hard_owner" ] .AND. Len( d[ "entries" ] ) == 0, "[extra] dictionarywithdefault default" )
   g := Stb_NewStub( "GeoData" ) ; Stb_SetHandle( g, 0x10 ) ; Stb_SetOwner( g, 0x20 ) ; Chk( Stb_Handle( g ) == 0x10 .AND. g[ "owner" ] == 0x20 .AND. Stb_NewStub( "PlaceHolder" )[ "_type" ] == "PlaceHolder", "[extra] trait StubObject" )
RETURN
