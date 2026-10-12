/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/doc_txn.prg
   Origen Rust: opencadcodec/src/document.rs, L20-160 (EntityChangeRecorder) y CadDocument L1386-1495 (record_*, begin/end recording,
   align_added_entity_structure, snapshot_structure, swap_structure), has_version_locked_data (L1665), valid_symbol_table_name (L5847).
   Parte 2 de CadDocument. Licencia del original: MPL-2.0. Tests [extra] (el Rust no tiene #[test] en esta zona).
   Prefijos: Ecr_ (EntityChangeRecorder), Doc_ (CadDocument).
   EntityChangeRecorder = hash { "order": {handles}, "before": hash handle -> entidad o NIL }. Arc<EntityType> = referencia a la entidad.
   El mapa thread_local ENTITY_CHANGE_RECORDERS (clave = direccion del documento) se porta como el campo "_recorder" del hash del documento
   (en Harbour no hay direccion estable; el Rust lo guarda fuera del documento para que clone/igualdad no lo vean: snapshot_structure lo
   deja fuera del clon igual que el Rust). Mutex -> no hace falta (un hilo).
   take_before_images devuelve { { handle, entidad|NIL }, ... } en orden de primera modificacion y vacia el recorder.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Ecr_New() ; RETURN hb_Hash( "order", {}, "before", hb_Hash() )

PROCEDURE Ecr_Record( r, nHandle, oBefore )
   IF ! hb_HHasKey( r[ "before" ], nHandle )
      AAdd( r[ "order" ], nHandle )
      r[ "before" ][ nHandle ] := oBefore
   ENDIF
RETURN

FUNCTION Ecr_TakeBeforeImages( r )
   LOCAL a := {}, h
   FOR EACH h IN r[ "order" ]
      AAdd( a, { h, r[ "before" ][ h ] } )
      hb_HDel( r[ "before" ], h )
   NEXT
   r[ "order" ] := {}
RETURN a

FUNCTION Doc_ActiveEntityChangeRecorder( d ) ; RETURN iif( hb_HHasKey( d, "_recorder" ), d[ "_recorder" ], NIL )

PROCEDURE Doc_RecordEntityBefore( d, nHandle, oBefore )
   LOCAL r := Doc_ActiveEntityChangeRecorder( d )
   IF r != NIL ; Ecr_Record( r, nHandle, oBefore ) ; ENDIF
RETURN

FUNCTION Doc_BeginEntityChangeRecording( d )
   LOCAL r := Ecr_New()
   d[ "_recorder" ] := r
RETURN r

PROCEDURE Doc_EndEntityChangeRecording( d )
   IF hb_HHasKey( d, "_recorder" ) ; hb_HDel( d, "_recorder" ) ; ENDIF
RETURN

PROCEDURE Doc_RecordAllEntitiesForTransaction( d )
   LOCAL r := Doc_ActiveEntityChangeRecorder( d ), e
   IF r != NIL
      FOR EACH e IN d[ "entities" ] ; Ecr_Record( r, Ent_Handle( e ), e ) ; NEXT
   ENDIF
RETURN

/* CadDocument::align_added_entity_structure( before, after, added_handles ) */
PROCEDURE Doc_AlignAddedEntityStructure( oBefore, oAfter, aAdded )
   LOCAL hAdded := hb_Hash(), h, rb, ra, a, b, i, same
   IF Len( aAdded ) == 0 ; RETURN ; ENDIF
   FOR EACH h IN aAdded ; hAdded[ h ] := .T. ; NEXT
   oBefore[ "next_handle" ] := oAfter[ "next_handle" ]
   oBefore[ "header" ][ "handle_seed" ] := oAfter[ "header" ][ "handle_seed" ]
   FOR EACH rb IN Tb_Values( oBefore[ "block_records" ] )
      ra := NIL
      FOR EACH a IN Tb_Values( oAfter[ "block_records" ] )
         IF a[ "handle" ] == rb[ "handle" ] ; ra := a ; EXIT ; ENDIF
      NEXT
      IF ra == NIL ; LOOP ; ENDIF
      a := {} ; b := {}
      FOR EACH h IN rb[ "entity_handles" ]
         IF ! hb_HHasKey( hAdded, h ) ; AAdd( a, h ) ; ENDIF
      NEXT
      FOR EACH h IN ra[ "entity_handles" ]
         IF ! hb_HHasKey( hAdded, h ) ; AAdd( b, h ) ; ENDIF
      NEXT
      same := Len( a ) == Len( b )
      IF same
         FOR i := 1 TO Len( a )
            IF a[ i ] != b[ i ] ; same := .F. ; EXIT ; ENDIF
         NEXT
      ENDIF
      IF same ; rb[ "entity_handles" ] := AClone( ra[ "entity_handles" ] ) ; ENDIF
   NEXT
RETURN

/* snapshot_structure: clon del documento sin entidades ni entity_index (las originales se conservan en self) */
FUNCTION Doc_SnapshotStructure( d )
   LOCAL ents := d[ "entities" ], idx := d[ "entity_index" ], rec := NIL, s
   IF hb_HHasKey( d, "_recorder" ) ; rec := d[ "_recorder" ] ; hb_HDel( d, "_recorder" ) ; ENDIF
   d[ "entities" ] := {} ; d[ "entity_index" ] := hb_Hash()
   s := Ent_Clone( d )
   d[ "entities" ] := ents ; d[ "entity_index" ] := idx
   IF rec != NIL ; d[ "_recorder" ] := rec ; ENDIF
RETURN s

/* swap_structure: intercambia todo salvo entidades/entity_index; devuelve el estado previo (sin entidades) */
FUNCTION Doc_SwapStructure( d, snapshot )
   LOCAL ents := d[ "entities" ], idx := d[ "entity_index" ], k, old := hb_Hash()
   FOR EACH k IN hb_HKeys( d )
      old[ k ] := d[ k ]
   NEXT
   FOR EACH k IN hb_HKeys( d )
      IF ! hb_HHasKey( snapshot, k ) ; hb_HDel( d, k ) ; ENDIF
   NEXT
   FOR EACH k IN hb_HKeys( snapshot )
      d[ k ] := snapshot[ k ]
   NEXT
   old[ "entities" ] := {} ; old[ "entity_index" ] := hb_Hash()
   d[ "entities" ] := ents ; d[ "entity_index" ] := idx
RETURN old

FUNCTION Doc_HasVersionLockedData( d, nTarget )
   LOCAL src := d[ "dwg_source_version" ], o, e, v
   IF src == NIL .OR. src == nTarget ; RETURN .F. ; ENDIF
   FOR EACH o IN hb_HValues( d[ "objects" ] )
      IF o[ "_type" ] == "Unknown" .AND. o[ "raw_dwg_data" ] != NIL ; RETURN .T. ; ENDIF
   NEXT
   FOR EACH e IN d[ "entities" ]
      IF e[ "_type" ] == "UNKNOWN" .AND. e[ "raw_dwg_data" ] != NIL ; RETURN .T. ; ENDIF
      IF Len( e[ "common" ][ "extended_data" ][ 2 ] ) > 0 ; RETURN .T. ; ENDIF
   NEXT
   FOR EACH v IN hb_HValues( d[ "eed_by_handle" ] )
      IF Len( v ) > 0 ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.

FUNCTION Doc_ValidSymbolTableName( c )
   LOCAL i, n
   IF Len( c ) == 0 ; RETURN .F. ; ENDIF
   FOR i := 1 TO Len( c )
      n := Asc( SubStr( c, i, 1 ) )
      IF n < 32 .OR. n == 127 .OR. SubStr( c, i, 1 ) $ '<>/\":;?*|,=`' ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.
