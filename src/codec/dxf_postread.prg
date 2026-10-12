/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_postread.prg
   Origen Rust: opencadcodec/src/io/dxf/reader.rs (snapshot_default_entry_handles,
   rehandle_colliding_default_entries, rewire_dangling_layout_block_records,
   rewire_stale_text_style_references). Licencia del original: MPL-2.0.
   El original no tiene #[test] para estas funciones; los tests [extra] estan en t_dxf_rw.prg.
   Prefijo Dxp_. Los HashMap<(tag,nombre),u64> son hashes con clave "tag|nombre".
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION Dxp_Tags() ; RETURN { "layers", "line_types", "text_styles", "dim_styles", "app_ids", "views", "vports", "ucss", "vx_table", "block_records" }

/* snapshot_default_entry_handles: { "tabla|nombre" => handle } */
FUNCTION Dxp_SnapshotDefaults( d )
   LOCAL m := hb_Hash(), cTag, e
   FOR EACH cTag IN Dxp_Tags()
      FOR EACH e IN Tb_Values( d[ cTag ] )
         IF e[ "handle" ] != 0 ; m[ cTag + "|" + e[ "name" ] ] := e[ "handle" ] ; ENDIF
      NEXT
   NEXT
RETURN m

STATIC PROCEDURE Dxp_Count( u, n )
   IF n != 0 ; u[ n ] := hb_HGetDef( u, n, 0 ) + 1 ; ENDIF
RETURN

/* rehandle_colliding_default_entries */
PROCEDURE Dxp_RehandleCollidingDefaultEntries( d, aDef )
   LOCAL u := hb_Hash(), cTag, e, aMoves := {}, mv, nNew, h, hdr := d[ "header" ], k
   IF Len( aDef ) == 0 ; RETURN ; ENDIF
   FOR EACH cTag IN Dxp_Tags()
      FOR EACH e IN Tb_Values( d[ cTag ] ) ; Dxp_Count( u, e[ "handle" ] ) ; NEXT
   NEXT
   FOR EACH e IN Tb_Values( d[ "block_records" ] )
      Dxp_Count( u, e[ "block_entity_handle" ] ) ; Dxp_Count( u, e[ "block_end_handle" ] )
   NEXT
   FOR EACH e IN d[ "entities" ] ; Dxp_Count( u, e[ "common" ][ "handle" ] ) ; NEXT
   FOR EACH h IN hb_HKeys( d[ "objects" ] ) ; Dxp_Count( u, h ) ; NEXT
   FOR EACH cTag IN Dxp_Tags()
      FOR EACH e IN Tb_Values( d[ cTag ] )
         k := cTag + "|" + e[ "name" ]
         IF e[ "handle" ] != 0 .AND. hb_HGetDef( aDef, k, NIL ) == e[ "handle" ] .AND. hb_HGetDef( u, e[ "handle" ], 0 ) > 1
            AAdd( aMoves, { cTag, e[ "name" ], e[ "handle" ] } )
         ENDIF
      NEXT
   NEXT
   FOR EACH mv IN aMoves
      nNew := Doc_AllocateHandle( d )
      e := Tb_Get( d[ mv[ 1 ] ], mv[ 2 ] )
      IF e != NIL ; e[ "handle" ] := nNew ; ENDIF
      FOR EACH k IN { { "current_layer_handle", "layers" }, { "continuous_linetype_handle", "line_types" }, { "bylayer_linetype_handle", "line_types" }, ;
                      { "current_linetype_handle", "line_types" }, { "byblock_linetype_handle", "line_types" }, { "current_text_style_handle", "text_styles" }, ;
                      { "dim_text_style_handle", "text_styles" }, { "current_dimstyle_handle", "dim_styles" }, { "model_space_block_handle", "block_records" }, ;
                      { "paper_space_block_handle", "block_records" }, { "dim_linetype_handle", "line_types" }, { "dim_linetype1_handle", "line_types" }, ;
                      { "dim_linetype2_handle", "line_types" } }
         IF mv[ 1 ] == k[ 2 ] .AND. hb_HGetDef( hdr, k[ 1 ], NIL ) == mv[ 3 ] ; hdr[ k[ 1 ] ] := nNew ; ENDIF
      NEXT
      IF mv[ 1 ] == "text_styles"
         FOR EACH e IN Tb_Values( d[ "dim_styles" ] )
            IF e[ "dimtxsty_handle" ] == mv[ 3 ] ; e[ "dimtxsty_handle" ] := nNew ; ENDIF
         NEXT
      ENDIF
   NEXT
RETURN

/* rewire_stale_text_style_references */
PROCEDURE Dxp_RewireStaleTextStyleReferences( d )
   LOCAL ok := hb_Hash(), e, aNames := {}, c, ts, h, o
   FOR EACH e IN Tb_Values( d[ "text_styles" ] ) ; ok[ e[ "handle" ] ] := .T. ; NEXT
   FOR EACH e IN Tb_Values( d[ "dim_styles" ] )
      IF e[ "dimtxsty_handle" ] != 0 .AND. ! hb_HHasKey( ok, e[ "dimtxsty_handle" ] ) ; AAdd( aNames, e[ "name" ] ) ; ENDIF
   NEXT
   FOR EACH c IN aNames
      ts := Tb_Get( d[ "text_styles" ], c )
      IF ts != NIL ; Tb_Get( d[ "dim_styles" ], c )[ "dimtxsty_handle" ] := ts[ "handle" ] ; ENDIF
   NEXT
   aNames := {}
   FOR EACH h IN hb_HKeys( d[ "objects" ] )
      o := d[ "objects" ][ h ]
      IF o[ "_type" ] == "MultiLeaderStyle" .AND. o[ "text_style_handle" ] != NIL .AND. o[ "text_style_handle" ] != 0 .AND. ! hb_HHasKey( ok, o[ "text_style_handle" ] )
         AAdd( aNames, { h, o[ "name" ] } )
      ENDIF
   NEXT
   FOR EACH c IN aNames
      ts := Tb_Get( d[ "text_styles" ], c[ 2 ] )
      IF ts != NIL ; d[ "objects" ][ c[ 1 ] ][ "text_style_handle" ] := ts[ "handle" ] ; ENDIF
   NEXT
RETURN

/* rewire_dangling_layout_block_records */
PROCEDURE Dxp_RewireDanglingLayoutBlockRecords( d )
   LOCAL rec := hb_Hash(), e, h, o, aDang := {}, owned := hb_Hash(), aFree := {}, cSuf, nOrd, nFreeI := 1, nModel, d1, nTarget, br, lModel
   FOR EACH e IN Tb_Values( d[ "block_records" ] ) ; rec[ e[ "handle" ] ] := Lower( e[ "name" ] ) ; NEXT
   FOR EACH h IN hb_HKeys( d[ "objects" ] )
      o := d[ "objects" ][ h ]
      IF o[ "_type" ] == "Layout"
         IF hb_HHasKey( rec, o[ "block_record" ] )
            owned[ o[ "block_record" ] ] := .T.
         ELSE
            AAdd( aDang, { o[ "tab_order" ], h, Lower( o[ "name" ] ) == "model" } )
         ENDIF
      ENDIF
   NEXT
   IF Len( aDang ) == 0 ; RETURN ; ENDIF
   ASort( aDang,,, {| a, b | IIf( a[ 1 ] != b[ 1 ], a[ 1 ] < b[ 1 ], IIf( a[ 2 ] != b[ 2 ], a[ 2 ] < b[ 2 ], ! a[ 3 ] .AND. b[ 3 ] ) ) } )
   FOR EACH h IN hb_HKeys( rec )
      IF ! hb_HHasKey( owned, h ) .AND. Left( rec[ h ], 12 ) == "*paper_space"
         cSuf := SubStr( rec[ h ], 13 )
         IF Len( cSuf ) == 0
            AAdd( aFree, { -1, h } )
         ELSEIF hb_RegexLike( "^[0-9]+$", cSuf )
            nOrd := Val( cSuf ) ; AAdd( aFree, { nOrd, h } )
         ENDIF
      ENDIF
   NEXT
   ASort( aFree,,, {| a, b | IIf( a[ 1 ] != b[ 1 ], a[ 1 ] < b[ 1 ], a[ 2 ] < b[ 2 ] ) } )
   nModel := d[ "header" ][ "model_space_block_handle" ]
   FOR EACH d1 IN aDang
      lModel := d1[ 3 ] ; nTarget := NIL
      IF lModel .AND. hb_HHasKey( rec, nModel ) .AND. ! hb_HHasKey( owned, nModel )
         nTarget := nModel
      ELSEIF lModel
         LOOP
      ELSE
         IF nFreeI > Len( aFree ) ; LOOP ; ENDIF
         nTarget := aFree[ nFreeI ][ 2 ] ; nFreeI++
      ENDIF
      owned[ nTarget ] := .T.
      d[ "objects" ][ d1[ 2 ] ][ "block_record" ] := nTarget
      FOR EACH br IN Tb_Values( d[ "block_records" ] )
         IF br[ "handle" ] == nTarget ; br[ "layout" ] := d1[ 2 ] ; EXIT ; ENDIF
      NEXT
   NEXT
RETURN
