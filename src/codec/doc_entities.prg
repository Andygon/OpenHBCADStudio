/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/doc_entities.prg
   Origen Rust: opencadcodec/src/document.rs, CadDocument L3312-3941 (add_entity ... model_space_entities, add_layout, ensure_model_layout).
   Parte 3 de CadDocument. Licencia del original: MPL-2.0. Tests [extra] (el Rust no tiene #[test] en esta zona).
   Result<T,E> -> el valor T si va bien o una CADENA con el mensaje si falla (ValType "C"); los handles son numeros, no hay ambiguedad.
   Option<&T> -> la entidad (referencia) o NIL. Arc<EntityType>: las entidades son referencias de Harbour; la semantica Arc::make_mut
   (copy-on-write) se reproduce donde importa: si el recorder de transacciones guarda como "before" la MISMA referencia que hay en el
   documento (record_all_entities_for_transaction), get_entity_mut / entities_mut sustituyen la entidad por un clon profundo antes de
   entregarla, de modo que la imagen "before" no se altera. remove_entity: devuelve la entidad tal cual (Rust: try_unwrap o clone).
   reserve_loaded_entities es solo capacidad: no se porta. explode_entity depende de entities/explode (aplazado): no se porta aqui.
   entities() / entities_in_block() devuelven arrays (Rust: iteradores).
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION Doc_IsExcluded( e ) ; RETURN e[ "_type" ] == "ATTRIB" .OR. e[ "_type" ] == "BLOCK" .OR. e[ "_type" ] == "ENDBLK"

STATIC PROCEDURE Doc_BumpHandle( d, nH )
   IF nH >= d[ "next_handle" ]
      d[ "next_handle" ] := nH + 1
      d[ "header" ][ "handle_seed" ] := Max( d[ "header" ][ "handle_seed" ], d[ "next_handle" ] )
   ENDIF
RETURN

STATIC FUNCTION Doc_HandleFor( d, e )
   LOCAL h
   IF Hd_IsNull( e[ "common" ][ "handle" ] )
      h := Doc_AllocateHandle( d ) ; Ent_SetHandle( e, h )
   ELSE
      h := e[ "common" ][ "handle" ] ; Doc_BumpHandle( d, h )
   ENDIF
RETURN h

STATIC PROCEDURE Doc_Push( d, e, h )
   AAdd( d[ "entities" ], e )
   d[ "entity_index" ][ h ] := Len( d[ "entities" ] ) - 1
RETURN

FUNCTION Doc_AddEntity( d, e )
   LOCAL h, ms, ps, nTarget, nOwner, lAdded := .F., br, c := e[ "common" ]
   c[ "raw_record" ] := NIL
   h := Doc_HandleFor( d, e )
   Doc_RecordEntityBefore( d, h, NIL )
   ms := d[ "header" ][ "model_space_block_handle" ] ; ps := d[ "header" ][ "paper_space_block_handle" ]
   IF Hd_IsNull( c[ "owner_handle" ] )
      nTarget := iif( c[ "entity_mode" ] != NIL .AND. c[ "entity_mode" ] == 1 .AND. ! Hd_IsNull( ps ), ps, ms )
      IF ! Hd_IsNull( nTarget ) ; c[ "owner_handle" ] := nTarget ; ENDIF
   ENDIF
   nOwner := c[ "owner_handle" ]
   IF ! Doc_IsExcluded( e ) .AND. ! Hd_IsNull( nOwner )
      FOR EACH br IN Tb_Values( d[ "block_records" ] )
         IF br[ "handle" ] == nOwner ; AAdd( br[ "entity_handles" ], h ) ; lAdded := .T. ; EXIT ; ENDIF
      NEXT
   ENDIF
   IF ! Doc_IsExcluded( e ) .AND. ! lAdded
      br := Tb_Get( d[ "block_records" ], "*Model_Space" )
      IF br != NIL
         AAdd( br[ "entity_handles" ], h ) ; c[ "owner_handle" ] := br[ "handle" ]
      ENDIF
   ENDIF
   Doc_Push( d, e, h )
RETURN h

FUNCTION Doc_AddLoadedEntity( d, e )
   LOCAL h := Doc_HandleFor( d, e )
   Doc_Push( d, e, h )
RETURN h

/* add_loaded_entity_batch: vacia aEnts (Vec::append) */
PROCEDURE Doc_AddLoadedEntityBatch( d, aEnts )
   LOCAL nNext, e, h, nBase, i
   IF Len( aEnts ) == 0 ; RETURN ; ENDIF
   nNext := Max( d[ "next_handle" ], d[ "header" ][ "handle_seed" ] )
   FOR EACH e IN aEnts
      h := e[ "common" ][ "handle" ]
      IF Hd_IsNull( h )
         Ent_SetHandle( e, nNext ) ; nNext++
      ELSE
         nNext := Max( nNext, h + 1 )
      ENDIF
   NEXT
   nBase := Len( d[ "entities" ] )
   FOR i := 1 TO Len( aEnts )
      AAdd( d[ "entities" ], aEnts[ i ] )
      d[ "entity_index" ][ aEnts[ i ][ "common" ][ "handle" ] ] := nBase + i - 1
   NEXT
   ASize( aEnts, 0 )
   d[ "next_handle" ] := nNext
   d[ "header" ][ "handle_seed" ] := Max( d[ "header" ][ "handle_seed" ], nNext )
RETURN

FUNCTION Doc_GetEntity( d, h )
RETURN iif( hb_HHasKey( d[ "entity_index" ], h ), d[ "entities" ][ d[ "entity_index" ][ h ] + 1 ], NIL )

FUNCTION Doc_GetEntityArc( d, h ) ; RETURN Doc_GetEntity( d, h )

/* Arc::make_mut: si el recorder comparte la referencia, el documento pasa a tener un clon */
STATIC PROCEDURE Doc_MakeMut( d, nIdx )
   LOCAL r := Doc_ActiveEntityChangeRecorder( d ), e := d[ "entities" ][ nIdx + 1 ], h := e[ "common" ][ "handle" ]
   IF r != NIL .AND. hb_HHasKey( r[ "before" ], h ) .AND. r[ "before" ][ h ] == e
      d[ "entities" ][ nIdx + 1 ] := Ent_Clone( e )
   ENDIF
RETURN

FUNCTION Doc_GetEntityMut( d, h )
   LOCAL nIdx, e
   IF ! hb_HHasKey( d[ "entity_index" ], h ) ; RETURN NIL ; ENDIF
   nIdx := d[ "entity_index" ][ h ]
   Doc_RecordEntityBefore( d, h, d[ "entities" ][ nIdx + 1 ] )
   Doc_MakeMut( d, nIdx )
   e := d[ "entities" ][ nIdx + 1 ] ; e[ "common" ][ "raw_record" ] := NIL
RETURN e

/* devuelve la entidad anterior o NIL */
FUNCTION Doc_ReplaceEntityArc( d, h, e )
   LOCAL nIdx, old
   IF e[ "common" ][ "handle" ] != h .OR. ! hb_HHasKey( d[ "entity_index" ], h ) ; RETURN NIL ; ENDIF
   nIdx := d[ "entity_index" ][ h ]
   Doc_RecordEntityBefore( d, h, d[ "entities" ][ nIdx + 1 ] )
   old := d[ "entities" ][ nIdx + 1 ] ; d[ "entities" ][ nIdx + 1 ] := e
RETURN old

/* devuelve el handle o NIL */
FUNCTION Doc_RestoreEntityArc( d, e )
   LOCAL h := e[ "common" ][ "handle" ]
   IF Hd_IsNull( h ) .OR. hb_HHasKey( d[ "entity_index" ], h ) ; RETURN NIL ; ENDIF
   Doc_RecordEntityBefore( d, h, NIL )
   Doc_BumpHandle( d, h )
   Doc_Push( d, e, h )
RETURN h

FUNCTION Doc_AddPaperSpaceEntity( d, e ) ; RETURN Doc_AddEntityToBlock( d, e, "*Paper_Space" )

FUNCTION Doc_AddEntityToLayout( d, e, cLayout )
   LOCAL o, nBlock := NIL, cBlock := NIL, br, lVp := e[ "_type" ] == "VIEWPORT", h, lay := NIL, x
   IF lVp .AND. e[ "id" ] > 1 .AND. Len( e[ "frozen_layers" ] ) == 0
      e[ "frozen_layers" ] := {}
      FOR EACH x IN Tb_Values( d[ "layers" ] )
         IF x[ "flags" ][ "frozen_in_new_viewport" ] ; AAdd( e[ "frozen_layers" ], x[ "handle" ] ) ; ENDIF
      NEXT
   ENDIF
   FOR EACH o IN hb_HValues( d[ "objects" ] )
      IF o[ "_type" ] == "Layout" .AND. o[ "name" ] == cLayout ; nBlock := o[ "block_record" ] ; lay := o ; EXIT ; ENDIF
   NEXT
   IF nBlock == NIL ; RETURN "Layout '" + cLayout + "' not found" ; ENDIF
   FOR EACH br IN Tb_Values( d[ "block_records" ] )
      IF br[ "handle" ] == nBlock ; cBlock := br[ "name" ] ; EXIT ; ENDIF
   NEXT
   IF cBlock == NIL ; RETURN "Block record for layout '" + cLayout + "' not found" ; ENDIF
   h := Doc_AddEntityToBlock( d, e, cBlock )
   IF ValType( h ) == "C" ; RETURN h ; ENDIF
   IF lVp
      IF AScan( lay[ "viewports" ], {| z | z == h } ) == 0 ; AAdd( lay[ "viewports" ], h ) ; ENDIF
      IF Hd_IsNull( lay[ "viewport" ] ) ; lay[ "viewport" ] := h ; ENDIF
   ENDIF
RETURN h

FUNCTION Doc_AddEntityToBlock( d, e, cBlock )
   LOCAL h, br, nOwner, lAdded := .F., t
   e[ "common" ][ "raw_record" ] := NIL
   h := Doc_HandleFor( d, e )
   Doc_RecordEntityBefore( d, h, NIL )
   br := Tb_Get( d[ "block_records" ], cBlock )
   IF br != NIL ; e[ "common" ][ "owner_handle" ] := br[ "handle" ] ; ENDIF
   nOwner := e[ "common" ][ "owner_handle" ]
   IF ! Hd_IsNull( nOwner )
      FOR EACH br IN Tb_Values( d[ "block_records" ] )
         IF br[ "handle" ] == nOwner ; AAdd( br[ "entity_handles" ], h ) ; lAdded := .T. ; EXIT ; ENDIF
      NEXT
   ENDIF
   IF ! lAdded
      t := Tb_Get( d[ "block_records" ], cBlock )
      IF t != NIL ; AAdd( t[ "entity_handles" ], h ) ; ENDIF
   ENDIF
   Doc_Push( d, e, h )
RETURN h

/* swap_remove: el ultimo ocupa el hueco */
FUNCTION Doc_RemoveEntityArc( d, h )
   LOCAL nIdx, e, nLast, mv
   IF ! hb_HHasKey( d[ "entity_index" ], h ) ; RETURN NIL ; ENDIF
   nIdx := d[ "entity_index" ][ h ]
   e := d[ "entities" ][ nIdx + 1 ]
   Doc_RecordEntityBefore( d, h, e )
   hb_HDel( d[ "entity_index" ], h )
   nLast := Len( d[ "entities" ] )
   d[ "entities" ][ nIdx + 1 ] := d[ "entities" ][ nLast ]
   ASize( d[ "entities" ], nLast - 1 )
   IF nIdx < Len( d[ "entities" ] )
      mv := d[ "entities" ][ nIdx + 1 ]
      d[ "entity_index" ][ mv[ "common" ][ "handle" ] ] := nIdx
   ENDIF
RETURN e

FUNCTION Doc_RemoveEntity( d, h ) ; RETURN Doc_RemoveEntityArc( d, h )

FUNCTION Doc_AddLayout( d, cName )
   LOCAL o, nPs := 0, br, cBlock, nBr, nLay, lay, vp, nVp, dict
   FOR EACH o IN hb_HValues( d[ "objects" ] )
      IF o[ "_type" ] == "Layout" .AND. o[ "name" ] == cName ; RETURN "Layout '" + cName + "' already exists" ; ENDIF
   NEXT
   FOR EACH br IN Tb_Values( d[ "block_records" ] )
      IF Blk_IsPaperSpace( br ) ; nPs++ ; ENDIF
   NEXT
   cBlock := iif( nPs == 0, "*Paper_Space", "*Paper_Space" + hb_ntos( nPs - 1 ) )
   br := Blk_New( cBlock ) ; br[ "handle" ] := Doc_AllocateHandle( d ) ; br[ "block_entity_handle" ] := Doc_AllocateHandle( d ) ; br[ "block_end_handle" ] := Doc_AllocateHandle( d )
   nBr := br[ "handle" ]
   nLay := Doc_AllocateHandle( d )
   lay := Lyo_New( cName ) ; lay[ "handle" ] := nLay ; lay[ "owner" ] := d[ "header" ][ "acad_layout_dict_handle" ] ; lay[ "tab_order" ] := nPs + 1 ; lay[ "block_record" ] := nBr
   br[ "layout" ] := nLay
   o := Tb_Add( d[ "block_records" ], br ) ; IF o != NIL ; RETURN o ; ENDIF
   vp := Evp_New() ; vp[ "id" ] := 1 ; vp[ "status" ] := Vsf_DefaultOn()
   nVp := Doc_AllocateHandle( d ) ; vp[ "common" ][ "handle" ] := nVp ; vp[ "common" ][ "owner_handle" ] := nBr
   lay[ "viewport" ] := nVp ; AAdd( lay[ "viewports" ], nVp )
   AAdd( Tb_Get( d[ "block_records" ], cBlock )[ "entity_handles" ], nVp )
   Doc_RecordEntityBefore( d, nVp, NIL )
   Doc_Push( d, vp, nVp )
   IF hb_HHasKey( d[ "objects" ], d[ "header" ][ "acad_layout_dict_handle" ] )
      dict := d[ "objects" ][ d[ "header" ][ "acad_layout_dict_handle" ] ]
      IF dict[ "_type" ] == "Dictionary" ; Dic_AddEntry( dict, cName, nLay ) ; ENDIF
   ENDIF
   d[ "objects" ][ nLay ] := lay
RETURN nLay

PROCEDURE Doc_EnsureModelLayout( d )
   LOCAL hOwners := hb_Hash(), o, k, rec, nModel := NIL, lHas := .F., nDict, nRoot, dict, nH, lay, x
   FOR EACH k IN hb_HKeys( d[ "objects" ] )
      o := d[ "objects" ][ k ]
      IF o[ "_type" ] == "Layout" ; hOwners[ o[ "block_record" ] ] := k ; ENDIF
   NEXT
   FOR EACH rec IN Tb_Values( d[ "block_records" ] )
      IF ! ( hb_HHasKey( d[ "objects" ], rec[ "layout" ] ) .AND. d[ "objects" ][ rec[ "layout" ] ][ "_type" ] == "Layout" )
         rec[ "layout" ] := iif( hb_HHasKey( hOwners, rec[ "handle" ] ), hOwners[ rec[ "handle" ] ], Hd_Null() )
      ENDIF
   NEXT
   FOR EACH rec IN Tb_Values( d[ "block_records" ] )
      IF Blk_IsModelSpace( rec ) ; nModel := rec[ "handle" ] ; EXIT ; ENDIF
   NEXT
   IF nModel == NIL ; RETURN ; ENDIF
   FOR EACH o IN hb_HValues( d[ "objects" ] )
      IF o[ "_type" ] == "Layout" .AND. o[ "block_record" ] == nModel ; lHas := .T. ; EXIT ; ENDIF
   NEXT
   IF lHas ; RETURN ; ENDIF
   nDict := d[ "header" ][ "acad_layout_dict_handle" ]
   IF ! ( hb_HHasKey( d[ "objects" ], nDict ) .AND. d[ "objects" ][ nDict ][ "_type" ] == "Dictionary" )
      nH := Doc_AllocateHandle( d ) ; nRoot := d[ "header" ][ "named_objects_dict_handle" ]
      dict := Dic_New() ; dict[ "handle" ] := nH ; dict[ "owner" ] := nRoot
      IF hb_HHasKey( d[ "objects" ], nRoot ) .AND. d[ "objects" ][ nRoot ][ "_type" ] == "Dictionary" ; Dic_AddEntry( d[ "objects" ][ nRoot ], "ACAD_LAYOUT", nH ) ; ENDIF
      d[ "objects" ][ nH ] := dict ; d[ "header" ][ "acad_layout_dict_handle" ] := nH ; nDict := nH
   ENDIF
   nH := Doc_AllocateHandle( d )
   lay := Lyo_New( "Model" ) ; lay[ "handle" ] := nH ; lay[ "owner" ] := nDict ; lay[ "tab_order" ] := 0 ; lay[ "flags" ] := 1 ; lay[ "block_record" ] := nModel
   IF hb_HHasKey( d[ "objects" ], nDict ) .AND. d[ "objects" ][ nDict ][ "_type" ] == "Dictionary" ; Dic_AddEntry( d[ "objects" ][ nDict ], "Model", nH ) ; ENDIF
   FOR EACH x IN Tb_Values( d[ "block_records" ] )
      IF x[ "handle" ] == nModel ; x[ "layout" ] := nH ; EXIT ; ENDIF
   NEXT
   d[ "objects" ][ nH ] := lay
RETURN

FUNCTION Doc_Entities( d )
   LOCAL a := {}, e
   FOR EACH e IN d[ "entities" ]
      IF e[ "_type" ] != "BLOCK" .AND. e[ "_type" ] != "ENDBLK" ; AAdd( a, e ) ; ENDIF
   NEXT
RETURN a

FUNCTION Doc_EntityCount( d ) ; RETURN Len( Doc_Entities( d ) )

STATIC FUNCTION Doc_EntitiesMutCore( d, lClearRaw )
   LOCAL r := Doc_ActiveEntityChangeRecorder( d ), e, i, a := {}
   IF r != NIL
      FOR EACH e IN d[ "entities" ] ; Ecr_Record( r, e[ "common" ][ "handle" ], e ) ; NEXT
   ENDIF
   FOR i := 0 TO Len( d[ "entities" ] ) - 1
      Doc_MakeMut( d, i )
      e := d[ "entities" ][ i + 1 ]
      IF lClearRaw ; e[ "common" ][ "raw_record" ] := NIL ; ENDIF
      AAdd( a, e )
   NEXT
RETURN a
FUNCTION Doc_EntitiesMut( d ) ; RETURN Doc_EntitiesMutCore( d, .T. )
FUNCTION Doc_EntitiesMutKeepRaw( d ) ; RETURN Doc_EntitiesMutCore( d, .F. )

FUNCTION Doc_EntitiesInBlock( d, cBlock )
   LOCAL a := {}, br := Tb_Get( d[ "block_records" ], cBlock ), h, e
   IF br == NIL ; RETURN a ; ENDIF
   FOR EACH h IN br[ "entity_handles" ]
      e := Doc_GetEntity( d, h ) ; IF e != NIL ; AAdd( a, e ) ; ENDIF
   NEXT
RETURN a

FUNCTION Doc_ModelSpaceEntities( d ) ; RETURN Doc_EntitiesInBlock( d, "*Model_Space" )
