/* Tests de CadDocument parte 1 - todos [extra] (document.rs no tiene #[test] en esta zona) */
#include "ocx.ch"
PROCEDURE T_DocDocument()
   LOCAL d, h, n, o
   d := Doc_New() ; h := d[ "header" ]
   Chk( d[ "version" ] == 1032 .AND. Tb_Len( d[ "layers" ] ) == 1 .AND. Tb_Len( d[ "line_types" ] ) == 3 .AND. Tb_Len( d[ "text_styles" ] ) == 1 .AND. Tb_Len( d[ "block_records" ] ) == 2 ;
      .AND. Tb_Len( d[ "dim_styles" ] ) == 1 .AND. Tb_Len( d[ "app_ids" ] ) == 4 .AND. Tb_Len( d[ "vports" ] ) == 1, "[extra] tablas estandar" )
   Chk( Tb_Handle( d[ "layers" ] ) == 2 .AND. Tb_Handle( d[ "block_records" ] ) == 1 .AND. h[ "named_objects_dict_handle" ] == 12, "[extra] handles de control" )
   Chk( Tb_Get( d[ "layers" ], "0" )[ "handle" ] == 16 .AND. h[ "current_layer_handle" ] == 16 .AND. h[ "continuous_linetype_handle" ] == 17 .AND. h[ "bylayer_linetype_handle" ] == 18 .AND. h[ "byblock_linetype_handle" ] == 19, "[extra] handles 0x10.. en orden" )
   o := Tb_Get( d[ "block_records" ], "*Model_Space" )
   Chk( o[ "handle" ] == 21 .AND. o[ "block_entity_handle" ] == 22 .AND. o[ "block_end_handle" ] == 23 .AND. h[ "model_space_block_handle" ] == 21 .AND. o[ "layout" ] != 0, "[extra] model space" )
   Chk( Len( d[ "objects" ] ) == 17 .AND. d[ "objects" ][ 12 ][ "_type" ] == "Dictionary" .AND. Len( d[ "objects" ][ 12 ][ "entries" ] ) == 10, "[extra] 17 objetos, diccionario raiz con 10 entradas" )
   Chk( d[ "objects" ][ h[ "acad_layout_dict_handle" ] ][ "entries" ][ 1 ][ 1 ] == "Model" .AND. d[ "objects" ][ d[ "objects" ][ h[ "acad_layout_dict_handle" ] ][ "entries" ][ 2 ][ 2 ] ][ "block_record" ] == h[ "paper_space_block_handle" ], "[extra] layouts" )
   Chk( d[ "objects" ][ h[ "acad_plotstylename_dict_handle" ] ][ "_type" ] == "DictionaryWithDefault" .AND. d[ "objects" ][ h[ "current_multiline_style_handle" ] ][ "_type" ] == "MLineStyle", "[extra] plotstyle + mlinestyle std" )
   Chk( Dcc_Contains( d[ "classes" ], "LAYOUT" ) .AND. Dcc_Contains( d[ "classes" ], "SCALE" ), "[extra] clases estandar" )
   n := Doc_NextHandle( d ) ; o := Doc_AllocateHandle( d ) ; Chk( o == n .AND. Doc_NextHandle( d ) == n + 1 .AND. h[ "handle_seed" ] == n + 1, "[extra] allocate_handle" )
   h[ "handle_seed" ] := 1000 ; Chk( Doc_AllocateHandle( d ) == 1000 .AND. Doc_NextHandle( d ) == 1001, "[extra] allocate_handle respeta handle_seed" )
   d[ "objects" ][ 5000 ] := hb_Hash( "handle", 5000 ) ; Doc_SynchronizeHandleAllocator( d ) ; Chk( Doc_NextHandle( d ) == 5001 .AND. h[ "handle_seed" ] == 5001, "[extra] synchronize_handle_allocator" )
   Chk( Doc_WithVersion( 1015 )[ "version" ] == 1015 .AND. Smi_Default()[ "title" ] == "" .AND. Fdf_Default()[ "evaluator" ] == "", "[extra] with_version, defaults" )
   d := Doc_New() ; Dcc_Clear( d[ "classes" ] ) ; Doc_RegisterObjectContextClass( d, "ACDB_TEXTOBJECTCONTEXTDATA_CLASS" ) ; Doc_RegisterObjectContextClass( d, "NOPE" )
   o := Dcc_GetByName( d[ "classes" ], "ACDB_TEXTOBJECTCONTEXTDATA_CLASS" )
   Chk( o != NIL .AND. o[ "cpp_class_name" ] == "AcDbTextObjectContextData" .AND. o[ "proxy_flags" ] == 1 + 128 + 1024 .AND. Dcc_GetByName( d[ "classes" ], "NOPE" ) == NIL, "[extra] register_object_context_class" )
RETURN
