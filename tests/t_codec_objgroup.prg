/* Tests: group.rs (12 tests 1:1); block_visibility.rs sin tests en Rust ([extra]) */
#include "ocx.ch"
PROCEDURE T_CodecObjGroup()
   LOCAL g, p, s
   g := Grp_New( "TestGroup" ) ; Chk( g[ "name" ] == "TestGroup" .AND. Grp_IsEmpty( g ) .AND. g[ "selectable" ] .AND. ! Grp_IsUnnamed( g ), "group_creation" )
   g := Grp_Unnamed() ; Chk( Grp_IsUnnamed( g ) .AND. Left( g[ "name" ], 1 ) == "*", "group_unnamed" )
   g := Grp_WithDescription( "MyGroup", "This is a test group" ) ; Chk( g[ "name" ] == "MyGroup" .AND. g[ "description" ] == "This is a test group", "group_with_description" )
   g := Grp_New( "Test" ) ; Grp_AddEntity( g, 100 ) ; Grp_AddEntity( g, 101 ) ; Chk( Grp_Len( g ) == 2 .AND. Grp_Contains( g, 100 ) .AND. Grp_Contains( g, 101 ), "group_add_entity" )
   g := Grp_New( "Test" ) ; Grp_AddEntity( g, 100 ) ; Grp_AddEntity( g, 100 ) ; Chk( Grp_Len( g ) == 1, "group_add_duplicate" )
   g := Grp_New( "Test" ) ; Grp_AddEntities( g, { 100, 101, 102 } ) ; Chk( Grp_Len( g ) == 3, "group_add_entities" )
   g := Grp_New( "Test" ) ; Grp_AddEntity( g, 100 ) ; Grp_AddEntity( g, 101 )
   Chk( Grp_RemoveEntity( g, 100 ) .AND. Grp_Len( g ) == 1 .AND. ! Grp_Contains( g, 100 ) .AND. ! Grp_RemoveEntity( g, 999 ), "group_remove_entity" )
   g := Grp_New( "Test" ) ; Grp_AddEntities( g, { 100, 101 } ) ; Grp_Clear( g ) ; Chk( Grp_IsEmpty( g ), "group_clear" )
   g := Grp_New( "Test" ) ; Grp_AddEntity( g, 100 ) ; Grp_AddEntity( g, 101 ) ; Chk( Grp_Get( g, 0 ) == 100 .AND. Grp_Get( g, 1 ) == 101 .AND. Grp_Get( g, 2 ) == NIL, "group_get" )
   g := Grp_New( "Test" ) ; Chk( g[ "selectable" ], "group_selectable inicio" ) ; Grp_SetSelectable( g, .F. ) ; Chk( ! g[ "selectable" ], "group_selectable" )
   g := Grp_WithEntities( Grp_WithEntity( Grp_WithSelectable( Grp_WithDesc( Grp_New( "Test" ), "Description" ), .F. ), 100 ), { 101, 102 } )
   Chk( g[ "description" ] == "Description" .AND. ! g[ "selectable" ] .AND. Grp_Len( g ) == 3, "group_builder" )
   g := Grp_New( "Test" ) ; Grp_AddEntities( g, { 100, 101 } ) ; Chk( Len( g[ "entities" ] ) == 2 .AND. g[ "entities" ][ 1 ] == 100 .AND. g[ "entities" ][ 2 ] == 101, "group_iter" )
   Chk( Grp_Default()[ "name" ] == "*A" .AND. Grp_ObjectType() == "GROUP", "[extra] group default y OBJECT_TYPE" )
   p := Bvp_New() ; Chk( p[ "eval_value" ][ 1 ] == BEV_NONE .AND. Len( p[ "property_info"] ) == 2 .AND. Len( p[ "states" ] ) == 0 .AND. Vc3_Eq( p[ "def_point" ], Vc3_Zero() ), "[extra] block_visibility: valores por defecto" )
   p[ "handle" ] := 10 ; p[ "owner" ] := 20 ; p[ "eval_value" ] := { BEV_HANDLE, 30 } ; p[ "all_blocks" ] := { 40, 41 }
   s := Bvs_New() ; s[ "visible_blocks" ] := { 50 } ; s[ "visible_params" ] := { 60, 61 } ; AAdd( p[ "states" ], s )
   Bvp_VisitHandlesMut( p, {| h | h + 1000 } )
   Chk( p[ "handle" ] == 1010 .AND. p[ "owner" ] == 1020 .AND. p[ "eval_value" ][ 2 ] == 1030 .AND. p[ "all_blocks" ][ 2 ] == 1041 .AND. p[ "states" ][ 1 ][ "visible_blocks" ][ 1 ] == 1050 .AND. p[ "states" ][ 1 ][ "visible_params" ][ 2 ] == 1061, "[extra] visit_handles_mut visita todos los handles" )
   p[ "eval_value" ] := { BEV_REAL, 2.5 } ; Bvp_VisitHandlesMut( p, {| h | h + 1 } ) ; Chk( p[ "eval_value" ][ 2 ] == 2.5, "[extra] visit_handles_mut no toca eval_value que no es Handle" )
RETURN
