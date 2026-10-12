/* Tests de semantic_inventory: port 1:1 del #[test] de Rust (sin el tramo EED, ver cabecera de doc_semantic.prg) + [extra] */
#include "ocx.ch"
PROCEDURE T_DocSemantic()
   LOCAL d, e, h, dic, nDic, lXd := .F., aParts := {}, nApp, lEed := .F., x, u
   d := Doc_New() ; e := Eln_New() ; h := Doc_AddEntity( d, e )
   dic := Dic_New() ; nDic := Doc_AllocateHandle( d ) ; dic[ "handle" ] := nDic ; d[ "objects" ][ nDic ] := dic
   d[ "xdic_by_handle" ][ h ] := nDic
   nApp := Tb_Values( d[ "app_ids" ] )[ 1 ][ "handle" ]
   d[ "eed_by_handle" ][ h ] := { { nApp, "FF" } }
   Sem_Visit( d, {| p | AAdd( aParts, p ), iif( p[ "part" ] == "Relationship" .AND. p[ "kind" ] == "ExtensionDictionary" .AND. p[ "source" ][ "resolved" ] .AND. p[ "source" ][ "node" ][ "kind" ] == "Entity" ;
      .AND. p[ "target" ][ "resolved" ] .AND. p[ "target" ][ "node" ][ "kind" ] == "Object", lXd := .T., NIL ) } )
   Chk( lXd, "inventory_exposes_private_relationships (ExtensionDictionary entidad->objeto)" )
   FOR EACH x IN aParts
      IF x[ "part" ] == "NonEntityExtendedData" .AND. x[ "application" ] != NIL .AND. x[ "application" ][ "handle" ] == nApp .AND. x[ "values" ] == NIL ; lEed := .T. ; ENDIF
   NEXT
   Chk( lEed, "[extra] EED sin decodificador: values NIL (el tramo EED real queda pendiente de eed_codec)" )
   Sem_SetEedDecoder( {| c, w, b | HB_SYMBOL_UNUSED( c ), HB_SYMBOL_UNUSED( w ), HB_SYMBOL_UNUSED( b ), { Xv_New( 1, 7 ) } } )
   aParts := {} ; Sem_Visit( d, {| p | AAdd( aParts, p ) } )
   FOR EACH x IN aParts
      IF x[ "part" ] == "NonEntityExtendedData" .AND. x[ "values" ] != NIL .AND. Len( x[ "values" ] ) == 1 ; lEed := .T. ; ENDIF
   NEXT
   Chk( lEed, "[extra] EED con decodificador inyectado" )
   Sem_SetEedDecoder( NIL )
   Chk( aParts[ 1 ][ "part" ] == "Header" .AND. aParts[ 2 ][ "part" ] == "TableRecord", "[extra] orden: Header, luego tablas" )
   Chk( Sem_Resolve( d, 0 )[ "kind" ] == "Document" .AND. Sem_Resolve( d, h )[ "kind" ] == "Entity" .AND. Sem_Resolve( d, nDic )[ "kind" ] == "Object" .AND. Sem_Resolve( d, 424242 ) == NIL, "[extra] resolve" )
   Chk( Sem_Resolve( d, Tb_Get( d[ "layers" ], "0" )[ "handle" ] )[ "value" ][ "table" ] == "Layer", "[extra] resolve tabla" )
   u := Obj_NewUnknown( "FOO", 5000, 0 ) ; Chk( ! Sem_ClassifyObject( u )[ "typed" ] .AND. Sem_ClassifyObject( u )[ "type_name" ] == "FOO" .AND. Sem_ClassifyObject( dic )[ "typed" ], "[extra] classify_object" )
   u := Eun_New( "ZZZ" ) ; Chk( ! Sem_ClassifyEntity( u )[ "typed" ] .AND. Sem_ClassifyEntity( u )[ "type_name" ] == "ZZZ" .AND. Sem_ClassifyEntity( e )[ "typed" ], "[extra] classify_entity" )
   aParts := {} ; Sem_Visit( d, {| p | AAdd( aParts, p ) } )
   Chk( Sem_Version() == 1 .AND. ATail( aParts )[ "part" ] != NIL, "[extra] version y ultimo part" )
RETURN
