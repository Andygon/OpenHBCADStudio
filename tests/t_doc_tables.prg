/* Tests de CadDocument parte 5 (tablas, dynamic blocks, overrides) - todos [extra] */
#include "ocx.ch"
PROCEDURE T_DocTables()
   LOCAL d, l, e, h, hm, a, br, i, b1, b2, p
   d := Doc_New()
   Chk( ! Doc_HasNullTableEntries( d ) .AND. ! Doc_HasStaleTableKeys( d ) .AND. Doc_ResyncTableKeys( d ) == 0, "[extra] documento limpio" )
   l := Lyr_New( "Muros" ) ; Tb_Add( d[ "layers" ], l ) ; e := Eln_New() ; e[ "common" ][ "layer" ] := "Muros" ; Doc_AddEntity( d, e )
   d[ "header" ][ "current_layer_name" ] := "Muros"
   l[ "name" ] := "Paredes"
   Chk( Doc_HasStaleTableKeys( d ), "[extra] stale tras cambiar nombre" )
   Chk( Doc_ResyncTableKeys( d ) == 1 .AND. ! Doc_HasStaleTableKeys( d ) .AND. Tb_Get( d[ "layers" ], "Paredes" ) == l, "[extra] resync_table_keys" )
   Chk( e[ "common" ][ "layer" ] == "Paredes" .AND. d[ "header" ][ "current_layer_name" ] == "Paredes", "[extra] apply_table_renames: entidad y cabecera" )
   l[ "handle" ] := 0 ; Chk( Doc_HasNullTableEntries( d ), "[extra] null handle" )
   Doc_AssignTableEntryHandles( d ) ; Chk( l[ "handle" ] > 0 .AND. ! Doc_HasNullTableEntries( d ), "[extra] assign_table_entry_handles" )
   /* overrides */
   h := Doc_AllocateHandle( d ) ; d[ "objects" ][ h ] := Nil_Layer( h )
   Chk( ! Doc_SetLayerViewportOverride( d, l[ "handle" ], XRK_LAYER_VIEWPORT_ALPHA_OVERRIDE, 55, Xrv_New( "Handle", 1 ) ) .AND. ! Doc_SetLayerViewportOverride( d, l[ "handle" ], XRK_ANNOTATION_SCALE, 55, Xrv_New( "Int32", 1 ) ), "[extra] override: valor/tipo invalido" )
   Chk( Len( Doc_LayerViewportOverrides( d, l[ "handle" ], XRK_LAYER_VIEWPORT_ALPHA_OVERRIDE ) ) == 0 .AND. Len( Doc_LayerViewportOverrides( d, l[ "handle" ], XRK_ANNOTATION_SCALE ) ) == 0, "[extra] overrides vacios" )
   Chk( Doc_SetLayerViewportOverride( d, l[ "handle" ], XRK_LAYER_VIEWPORT_ALPHA_OVERRIDE, 55, Xrv_New( "Int32", 128 ) ), "[extra] set override" )
   a := Doc_LayerViewportOverrides( d, l[ "handle" ], XRK_LAYER_VIEWPORT_ALPHA_OVERRIDE )
   Chk( Len( a ) == 1 .AND. a[ 1 ][ 1 ] == 55 .AND. a[ 1 ][ 2 ][ "value" ] == 128, "[extra] layer_viewport_overrides" )
   /* mesh */
   Chk( Len( Doc_MeshTextureCoordinates( d, 5 ) ) == 0, "[extra] mesh sin coords" )
   /* owner chain + dynamic block */
   d[ "objects" ][ 9001 ] := Nil_Layer( 9001 ) ; d[ "objects" ][ 9001 ][ "owner" ] := 9002 ; d[ "objects" ][ 9002 ] := Nil_Layer( 9002 ) ; d[ "objects" ][ 9002 ][ "owner" ] := 9003
   Chk( Doc_OwnerChainReaches( d, 9001, 9003 ) .AND. Doc_OwnerChainReaches( d, 9001, 9001 ) .AND. ! Doc_OwnerChainReaches( d, 9001, 1234 ), "[extra] owner_chain_reaches" )
   p := hb_Hash( "owner", 9001, "handle", 8000 ) ; d[ "block_visibility_params" ][ 8000 ] := p
   Chk( Doc_BlockVisibilityParamForDef( d, 9003 ) == p .AND. Doc_BlockVisibilityParamForDef( d, 77 ) == NIL, "[extra] block_visibility_param_for_def" )
   br := Blk_New( "BLK" ) ; br[ "handle" ] := 9003 ; Tb_Add( d[ "block_records" ], br )
   i := Ein_New( "BLK" ) ; hm := Doc_AddEntity( d, i )
   Chk( Doc_DynamicDefinitionForInsert( d, hm ) == 9003 .AND. Doc_DynamicDefinitionForInsert( d, 31337 ) == NIL, "[extra] dynamic_definition_for_insert por nombre" )
   Chk( Doc_DynamicVisibilityForInsert( d, hm )[ 2 ] == p .AND. Doc_DynamicVisibilityForInsert( d, hm )[ 1 ] == 9003, "[extra] dynamic_visibility_for_insert" )
   d[ "block_representations" ][ 9001 ] := 4444 ; i[ "common" ][ "xdictionary_handle" ] := 9003
   Chk( Doc_DynamicDefinitionForInsert( d, hm ) == 4444, "[extra] dynamic_definition por representacion" )
   /* copy_evaluated_block_metadata */
   b1 := Blk_New( "*U1" ) ; b1[ "handle" ] := 7001 ; Tb_Add( d[ "block_records" ], b1 ) ; b2 := Blk_New( "*U2" ) ; b2[ "handle" ] := 7002 ; Tb_Add( d[ "block_records" ], b2 )
   Chk( Doc_CopyEvaluatedBlockMetadata( d, 7001, 9003 ) == "Expected an evaluated anonymous block record", "[extra] copy: no anonimo" )
   d[ "eed_by_handle" ][ 7001 ] := { { 1, "x" } }
   Chk( Doc_CopyEvaluatedBlockMetadata( d, 7001, 7002 ) == NIL .AND. d[ "eed_by_handle" ][ 7002 ][ 1 ][ 2 ] == "x" .AND. ! hb_HHasKey( d[ "xdic_by_handle" ], 7002 ), "[extra] copy: eed" )
   Doc_EnsureExtensionDictionary( d, 7001 ) ; Doc_EnsureExtensionDictionary( d, 7002 )
   Chk( Doc_CopyEvaluatedBlockMetadata( d, 7001, 7002 ) == NIL, "[extra] copy: diccionario vacio" )
   Doc_EnsureXrecord( d, 7001, "K" )
   Chk( Doc_CopyEvaluatedBlockMetadata( d, 7001, 7002 ) == "Evaluated block has additional object relationships", "[extra] copy: diccionario con entradas" )
RETURN
STATIC FUNCTION Nil_Layer( h ) ; RETURN hb_Hash( "_type", "Group", "handle", h, "owner", 0 )
