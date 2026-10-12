/* Tests de CadDocument parte 3 - todos [extra] (document.rs no tiene #[test] para esta zona) */
#include "ocx.ch"
PROCEDURE T_DocEntities()
   LOCAL d, e, f, h, h2, r, a, ms, n, hl, v
   d := Doc_New() ; ms := Tb_Get( d[ "block_records" ], "*Model_Space" )
   e := Eln_New() ; h := Doc_AddEntity( d, e )
   Chk( h > 0 .AND. e[ "common" ][ "handle" ] == h .AND. e[ "common" ][ "owner_handle" ] == ms[ "handle" ] .AND. ms[ "entity_handles" ][ 1 ] == h .AND. Doc_GetEntity( d, h ) == e, "[extra] add_entity: handle, owner y bloque" )
   f := Eln_New() ; f[ "common" ][ "handle" ] := 5000 ; h2 := Doc_AddEntity( d, f )
   Chk( h2 == 5000 .AND. d[ "next_handle" ] == 5001 .AND. d[ "header" ][ "handle_seed" ] >= 5001, "[extra] add_entity: handle explicito sube next_handle" )
   Chk( Doc_EntityCount( d ) == 2 .AND. Len( Doc_ModelSpaceEntities( d ) ) == 2 .AND. Len( Doc_EntitiesInBlock( d, "nada" ) ) == 0, "[extra] count / model_space" )
   e := Ebk_New( "B", Vc3_Zero() ) ; Doc_AddEntity( d, e ) ; Chk( Doc_EntityCount( d ) == 2 .AND. Len( d[ "entities" ] ) == 3 .AND. Len( ms[ "entity_handles" ] ) == 2, "[extra] Block excluido de entities() y del bloque" )
   f := Doc_RemoveEntity( d, h ) ; Chk( f != NIL .AND. ! hb_HHasKey( d[ "entity_index" ], h ) .AND. Doc_GetEntity( d, 5000 ) != NIL .AND. Doc_GetEntity( d, h ) == NIL .AND. Doc_RemoveEntity( d, h ) == NIL, "[extra] remove_entity swap_remove reindexa" )
   /* copy-on-write con recorder */
   d := Doc_New() ; e := Eln_New() ; h := Doc_AddEntity( d, e ) ; r := Doc_BeginEntityChangeRecording( d )
   f := Doc_GetEntityMut( d, h ) ; f[ "common" ][ "layer" ] := "X"
   a := Ecr_TakeBeforeImages( r )
   Chk( Len( a ) == 1 .AND. a[ 1 ][ 2 ][ "common" ][ "layer" ] == "0" .AND. Doc_GetEntity( d, h )[ "common" ][ "layer" ] == "X", "[extra] get_entity_mut: before intacto" )
   Doc_EndEntityChangeRecording( d )
   Chk( Doc_ReplaceEntityArc( d, h, Eln_New() ) == NIL .AND. Doc_RestoreEntityArc( d, Doc_GetEntity( d, h ) ) == NIL, "[extra] replace con otro handle / restore duplicado -> NIL" )
   f := Eln_New() ; f[ "common" ][ "handle" ] := h ; Chk( Doc_ReplaceEntityArc( d, h, f ) != NIL .AND. Doc_GetEntity( d, h ) == f, "[extra] replace_entity_arc" )
   f := Eln_New() ; f[ "common" ][ "handle" ] := 9000 ; Chk( Doc_RestoreEntityArc( d, f ) == 9000 .AND. d[ "next_handle" ] == 9001, "[extra] restore_entity_arc" )
   /* batch */
   d := Doc_New() ; n := d[ "next_handle" ] ; a := { Eln_New(), Eln_New() } ; a[ 2 ][ "common" ][ "handle" ] := n + 10
   Doc_AddLoadedEntityBatch( d, a )
   Chk( d[ "next_handle" ] == n + 11 .AND. hb_HHasKey( d[ "entity_index" ], n + 10 ), "[extra] batch: next_handle e indice" )
   Chk( Doc_AddLoadedEntity( d, Eln_New() ) > 0, "[extra] add_loaded_entity" )
   /* layouts */
   d := Doc_New() ; Doc_EnsureModelLayout( d ) ; Chk( Len( d[ "objects" ] ) >= 17, "[extra] ensure_model_layout" )
   hl := Doc_AddLayout( d, "L1" ) ; Chk( ValType( hl ) == "N" .AND. d[ "objects" ][ hl ][ "name" ] == "L1" .AND. d[ "objects" ][ hl ][ "tab_order" ] == 2 .AND. Len( d[ "objects" ][ hl ][ "viewports" ] ) == 1, "[extra] add_layout" )
   Chk( ValType( Doc_AddLayout( d, "L1" ) ) == "C", "[extra] add_layout duplicado" )
   hl := Doc_AddLayout( d, "L2" ) ; Chk( d[ "objects" ][ hl ][ "tab_order" ] == 3 .AND. Tb_Get( d[ "block_records" ], "*Paper_Space1" ) != NIL, "[extra] add_layout 2 -> *Paper_Space1 (el doc por defecto ya trae *Paper_Space)" )
   v := Evp_New() ; v[ "id" ] := 2 ; h := Doc_AddEntityToLayout( d, v, "L2" )
   Chk( ValType( h ) == "N" .AND. AScan( d[ "objects" ][ hl ][ "viewports" ], {| z | z == h } ) > 0 .AND. Doc_GetEntity( d, h )[ "common" ][ "owner_handle" ] == d[ "objects" ][ hl ][ "block_record" ], "[extra] add_entity_to_layout viewport" )
   Chk( ValType( Doc_AddEntityToLayout( d, Eln_New(), "nada" ) ) == "C", "[extra] layout inexistente" )
   Chk( ValType( Doc_AddPaperSpaceEntity( d, Eln_New() ) ) == "N", "[extra] add_paper_space_entity" )
RETURN
