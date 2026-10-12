/* Tests de CadDocument parte 2 - todos [extra] */
#include "ocx.ch"
PROCEDURE T_DocTxn()
   LOCAL d, r, e1, e2, a, s, h, o, old, rb
   d := Doc_New() ; e1 := Eln_New() ; e1[ "common" ][ "handle" ] := 100 ; e2 := Eln_New() ; e2[ "common" ][ "handle" ] := 101
   Chk( Doc_ActiveEntityChangeRecorder( d ) == NIL, "[extra] sin recorder" )
   Doc_RecordEntityBefore( d, 100, e1 ) ; Chk( Doc_ActiveEntityChangeRecorder( d ) == NIL, "[extra] record sin recorder no hace nada" )
   r := Doc_BeginEntityChangeRecording( d )
   Doc_RecordEntityBefore( d, 100, e1 ) ; Doc_RecordEntityBefore( d, 101, NIL ) ; Doc_RecordEntityBefore( d, 100, e2 )
   a := Ecr_TakeBeforeImages( r )
   Chk( Len( a ) == 2 .AND. a[ 1 ][ 1 ] == 100 .AND. a[ 1 ][ 2 ] == e1 .AND. a[ 2 ][ 1 ] == 101 .AND. a[ 2 ][ 2 ] == NIL .AND. Len( Ecr_TakeBeforeImages( r ) ) == 0, "[extra] first-touch y take_before_images" )
   AAdd( d[ "entities" ], e1 ) ; AAdd( d[ "entities" ], e2 ) ; Doc_RecordAllEntitiesForTransaction( d )
   a := Ecr_TakeBeforeImages( r ) ; Chk( Len( a ) == 2 .AND. a[ 2 ][ 2 ] == e2, "[extra] record_all_entities" )
   Doc_EndEntityChangeRecording( d ) ; Chk( Doc_ActiveEntityChangeRecorder( d ) == NIL, "[extra] end recording" )
   /* snapshot / swap */
   s := Doc_SnapshotStructure( d ) ; Chk( Len( s[ "entities" ] ) == 0 .AND. Len( d[ "entities" ] ) == 2 .AND. Len( s[ "objects" ] ) == 17, "[extra] snapshot_structure" )
   d[ "objects" ][ 9999 ] := hb_Hash( "handle", 9999 ) ; Chk( Len( s[ "objects" ] ) == 17, "[extra] el snapshot es un clon profundo" )
   old := Doc_SwapStructure( d, s ) ; Chk( Len( d[ "objects" ] ) == 17 .AND. Len( d[ "entities" ] ) == 2 .AND. Len( old[ "objects" ] ) == 18 .AND. Len( old[ "entities" ] ) == 0, "[extra] swap_structure" )
   /* align_added_entity_structure */
   d := Doc_New() ; o := Doc_New() ; rb := Tb_Get( o[ "block_records" ], "*Model_Space" ) ; AAdd( rb[ "entity_handles" ], 50 ) ; AAdd( rb[ "entity_handles" ], 60 )
   h := Tb_Get( d[ "block_records" ], "*Model_Space" ) ; AAdd( h[ "entity_handles" ], 50 ) ; o[ "next_handle" ] := 77 ; o[ "header" ][ "handle_seed" ] := 77
   Doc_AlignAddedEntityStructure( d, o, { 60 } )
   Chk( Len( h[ "entity_handles" ] ) == 2 .AND. d[ "next_handle" ] == 77 .AND. d[ "header" ][ "handle_seed" ] == 77, "[extra] align_added_entity_structure" )
   h[ "entity_handles" ] := { 50, 7 } ; Doc_AlignAddedEntityStructure( d, o, { 60 } ) ; Chk( Len( h[ "entity_handles" ] ) == 2 .AND. h[ "entity_handles" ][ 2 ] == 7, "[extra] align no toca si difieren" )
   /* has_version_locked_data */
   d := Doc_New() ; Chk( ! Doc_HasVersionLockedData( d, 1032 ), "[extra] locked: sin dwg_source_version" )
   d[ "dwg_source_version" ] := 1027 ; Chk( ! Doc_HasVersionLockedData( d, 1027 ) .AND. ! Doc_HasVersionLockedData( d, 1032 ), "[extra] locked: limpio" )
   d[ "eed_by_handle" ][ 5 ] := { { 1, "x" } } ; Chk( Doc_HasVersionLockedData( d, 1032 ), "[extra] locked: eed_by_handle" )
   d := Doc_New() ; d[ "dwg_source_version" ] := 1027 ; o := Obj_NewUnknown( "X", 5000, 0 ) ; o[ "raw_dwg_data" ] := "ab" ; d[ "objects" ][ 5000 ] := o ; Chk( Doc_HasVersionLockedData( d, 1032 ), "[extra] locked: objeto raw" )
   Chk( Doc_ValidSymbolTableName( "Layer 1" ) .AND. ! Doc_ValidSymbolTableName( "" ) .AND. ! Doc_ValidSymbolTableName( "a|b" ) .AND. ! Doc_ValidSymbolTableName( "a;b" ) .AND. ! Doc_ValidSymbolTableName( "a" + Chr( 9 ) ), "[extra] valid_symbol_table_name" )
RETURN
