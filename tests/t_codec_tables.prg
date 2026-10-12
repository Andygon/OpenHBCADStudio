/* Tests 1:1 de tables/mod.rs (7 #[test]) + [extra] */
#include "ocx.ch"
STATIC FUNCTION Mock( nH, cN ) ; RETURN hb_Hash( "handle", nH, "name", cN )
PROCEDURE T_CodecTables()
   LOCAL t, e, a, c, r
   t := Tb_New() ; Chk( Tb_Add( t, Mock( 1, "Test" ) ) == NIL .AND. Tb_Contains( t, "Test" ) .AND. Tb_Contains( t, "test" ) .AND. Tb_Len( t ) == 1, "tables: test_table_add_and_get" )
   t := Tb_New() ; Tb_Add( t, Mock( 1, "Test" ) ) ; Chk( ValType( Tb_Add( t, Mock( 2, "test" ) ) ) == "C", "tables: test_table_duplicate_entry" )
   t := Tb_New() ; Tb_AddAllowDuplicate( t, Mock( 1, "*Active" ) ) ; Tb_AddAllowDuplicate( t, Mock( 2, "*Active" ) ) ; a := Tb_Names( t )
   Chk( Tb_Len( t ) == 2 .AND. a[ 1 ] == "*Active" .AND. a[ 2 ] == "*Active" .AND. Tb_Get( t, "*active" )[ "handle" ] == 1, "tables: test_table_allow_duplicate_entries" )
   t := Tb_New() ; Tb_Add( t, Mock( 1, "Test" ) ) ; c := Tb_Len( t ) ; e := Tb_Remove( t, "test" ) ; Chk( c == 1 .AND. e != NIL .AND. Tb_Len( t ) == 0, "tables: test_table_remove" )
   t := Tb_New() ; Tb_Add( t, Mock( 1, "First" ) ) ; Tb_Add( t, Mock( 2, "Test" ) ) ; Tb_Add( t, Mock( 3, "Last" ) ) ; Tb_Rename( t, "Test", "Renamed" ) ; a := Tb_Names( t )
   Chk( a[ 1 ] == "First" .AND. a[ 2 ] == "Renamed" .AND. a[ 3 ] == "Last" .AND. Tb_Get( t, "renamed" )[ "handle" ] == 2, "tables: test_table_rename_preserves_entry_and_order" )
   t := Tb_New() ; Tb_Add( t, Mock( 1, "é" ) ) ; Tb_Rename( t, "é", "É" ) ; Chk( Tb_Get( t, "é" )[ "name" ] == "É", "tables: test_table_rename_allows_unicode_case_change" )
   t := Tb_New() ; Tb_Add( t, Mock( 1, "First" ) ) ; Tb_Add( t, Mock( 2, "Second" ) ) ; a := ValType( Tb_Rename( t, "First", "Second" ) ) == "C" ; c := ValType( Tb_Rename( t, "Missing", "Renamed" ) ) == "C" ; r := Tb_Names( t )
   Chk( a .AND. c .AND. Len( r ) == 2 .AND. r[ 1 ] == "First" .AND. r[ 2 ] == "Second", "tables: test_table_rename_errors_do_not_mutate" )
   /* [extra] */
   t := Tb_New() ; Tb_Add( t, Mock( 1, "A" ) ) ; Tb_Add( t, Mock( 2, "B" ) ) ; Tb_Add( t, Mock( 3, "C" ) ) ; Tb_Get( t, "B" )[ "name" ] := "A"
   Chk( Tb_HasStaleKeys( t ), "tables: [extra] has_stale_keys detecta nombre cambiado a mano" )
   r := Tb_ResyncKeys( t ) ; a := Tb_Names( t )
   Chk( Len( r ) == 1 .AND. r[ 1 ][ 1 ] == "B" .AND. r[ 1 ][ 2 ] == "A" .AND. a[ 1 ] == "A" .AND. a[ 2 ] == "A" .AND. a[ 3 ] == "C" .AND. ! Tb_HasStaleKeys( t ) .AND. Tb_Get( t, "A" )[ "handle" ] == 1, "tables: [extra] resync_keys conserva el orden y desambigua con el handle" )
   t := Tb_WithHandle( 7 ) ; Tb_SetHandle( t, 9 ) ; Tb_AddOrReplace( t, Mock( 1, "X" ) ) ; Tb_AddOrReplace( t, Mock( 2, "x" ) )
   Chk( Tb_Handle( t ) == 9 .AND. Tb_Len( t ) == 1 .AND. Tb_Get( t, "X" )[ "handle" ] == 2, "tables: [extra] with_handle y add_or_replace" )
   Tb_AddAllowDuplicate( t, Mock( 3, "X" ) ) ; Tb_AddAllowDuplicate( t, Mock( 3, "X" ) ) ; a := hb_HKeys( t[ "entries" ] )
   Chk( Tb_Len( t ) == 3 .AND. a[ 2 ] == "X" + Chr( 0 ) + "3" .AND. a[ 3 ] == "X" + Chr( 0 ) + "3-1", "tables: [extra] claves de duplicados con handle" )
   Tb_Clear( t ) ; Chk( Tb_IsEmpty( t ) .AND. Tb_Remove( t, "X" ) == NIL .AND. Tb_Get( t, "X" ) == NIL, "tables: [extra] clear y remove inexistente" )
RETURN
