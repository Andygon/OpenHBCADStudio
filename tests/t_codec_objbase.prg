/* Tests: objects/mod.rs (3 tests Rust 1:1 + [extra]) */
#include "ocx.ch"
PROCEDURE T_CodecObjBase()
   LOCAL d, l, src, ed
   d := Dic_New() ; Chk( Dic_IsEmpty( d ), "dictionary_creation vacio" )
   Dic_AddEntry( d, "KEY1", 100 ) ; Chk( Dic_Len( d ) == 1 .AND. Dic_Get( d, "KEY1" ) == 100 .AND. Dic_Get( d, "KEY2" ) == NIL, "dictionary_creation" )
   l := Lyo_New( "Layout1" ) ; Chk( l[ "name" ] == "Layout1" .AND. l[ "tab_order" ] == 0, "layout_creation" )
   src := Obj_NewUnknown( "CUSTOM_OBJECT", 66, Hd_Null() ) ; src[ "raw_dxf_codes" ] := { { 1, "source" } } ; src[ "raw_dwg_data" ] := hb_BChar( 1 ) + hb_BChar( 2 ) + hb_BChar( 3 ) ; src[ "raw_dwg_handle_bits" ] := 7 ; src[ "raw_dwg_version" ] := 1032
   ed := Obj_NewUnknown( "EDITED_OBJECT", 66, Hd_Null() ) ; ed[ "raw_dwg_handle_bits" ] := 7
   Obj_PreserveStorageDataFrom( ed, src )
   Chk( ed[ "type_name" ] == "EDITED_OBJECT" .AND. Len( ed[ "raw_dxf_codes" ] ) == 1 .AND. ed[ "raw_dxf_codes" ][ 1 ][ 1 ] == 1 .AND. ed[ "raw_dxf_codes" ][ 1 ][ 2 ] == "source" .AND. Len( ed[ "raw_dwg_data" ] ) == 3 .AND. ed[ "raw_dwg_version" ] == 1032, "public_record_edit_can_preserve_opaque_object_data" )
   src[ "raw_dxf_codes" ][ 1 ][ 2 ] := "cambiado" ; Chk( ed[ "raw_dxf_codes" ][ 1 ][ 2 ] == "source", "[extra] preserve clona raw_dxf_codes" )
   Dic_SetEntryHardOwner( d, "ACAD_FIELD", .T. ) ; Chk( Dic_IsEntryHardOwner( d, "acad_field" ) .AND. Dic_IsCanonicalHardOwnerKey( "acad_field" ), "[extra] hard owner key (sin distinguir mayusculas)" )
   Dic_SetEntryHardOwner( d, "ACAD_FIELD", .F. ) ; Chk( ! Dic_IsEntryHardOwner( d, "ACAD_FIELD" ) .AND. Dic_Get( d, "key1" ) == 100, "[extra] quitar hard owner y buscar sin mayusculas" )
   Obj_SetHandle( d, 77 ) ; Chk( d[ "handle" ] == 77 .AND. ! Obj_HasNullHandle( d ) .AND. Obj_HasNullHandle( l ), "[extra] set_handle / has_null_handle" )
   Obj_PreserveStorageDataFrom( d, l ) ; Chk( d[ "handle" ] == 77, "[extra] preserve con variante distinta no hace nada" )
   Chk( l[ "plot_type" ] == 5 .AND. l[ "shade_plot_dpi" ] == 300 .AND. l[ "max_extents" ][ 1 ] == 12.0 .AND. l[ "ucs_x_axis" ][ 1 ] == 1.0 .AND. l[ "raw_plot_settings_codes" ] == NIL, "[extra] layout: valores por defecto de new" )
RETURN
