/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/doc_tables.prg
   Origen Rust: opencadcodec/src/document.rs, CadDocument L4261-4659: mesh_texture_coordinates(+set), set_layer_viewport_override,
   layer_viewport_overrides, owner_chain_reaches, block_visibility_param_for_def, dynamic_visibility_for_insert,
   dynamic_definition_for_insert, copy_evaluated_block_metadata, has_null_table_entries, resync_table_keys, apply_table_renames,
   has_stale_table_keys, assign_table_entry_handles.
   Parte 5 de CadDocument. Licencia del original: MPL-2.0. Tests [extra] (el Rust no tiene #[test] aqui).
   Result<(),String> -> NIL si va bien o la cadena de error. Option<(Handle,&P)> -> { handle, param } o NIL.
   Las 10 tablas del documento se recorren en el orden del Rust.
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION Dt_Tables() ; RETURN { "layers", "line_types", "text_styles", "dim_styles", "app_ids", "views", "vports", "ucss", "vx_table", "block_records" }

FUNCTION Doc_MeshTextureCoordinates( d, nMesh )
   LOCAL x := Doc_Xrecord( d, nMesh, "ADSK_XREC_SUBDVERTEXTEXCOORDS" )
RETURN iif( x == NIL, {}, Xrc_MeshTextureCoordinates( x ) )

PROCEDURE Doc_SetMeshTextureCoordinates( d, nMesh, aCoords )
   LOCAL x
   Doc_EnsureXrecord( d, nMesh, "ADSK_XREC_SUBDVERTEXTEXCOORDS" )
   x := Doc_XrecordMut( d, nMesh, "ADSK_XREC_SUBDVERTEXTEXCOORDS" )
   IF x != NIL ; Xrc_SetMeshTextureCoordinates( x, aCoords ) ; ENDIF
RETURN

/* devuelve .T./.F.; hValue es un XRecordValue (Xrv_New) */
FUNCTION Doc_SetLayerViewportOverride( d, nLayer, nKind, nViewport, hValue )
   LOCAL cKey, cSec, nCode, lValid, x
   DO CASE
   CASE nKind == XRK_LAYER_VIEWPORT_ALPHA_OVERRIDE ; cKey := "ADSK_XREC_LAYER_ALPHA_OVR" ; cSec := "ADSK_LYR_ALPHA_OVERRIDE" ; nCode := 440
   CASE nKind == XRK_LAYER_VIEWPORT_COLOR_OVERRIDE ; cKey := "ADSK_XREC_LAYER_COLOR_OVR" ; cSec := "ADSK_LYR_COLOR_OVERRIDE" ; nCode := 420
   CASE nKind == XRK_LAYER_VIEWPORT_LINETYPE_OVERRIDE ; cKey := "ADSK_XREC_LAYER_LINETYPE_OVR" ; cSec := "ADSK_LYR_LINETYPE_OVERRIDE" ; nCode := 343
   CASE nKind == XRK_LAYER_VIEWPORT_LINEWEIGHT_OVERRIDE ; cKey := "ADSK_XREC_LAYER_LINEWT_OVR" ; cSec := "ADSK_LYR_LINEWT_OVERRIDE" ; nCode := 91
   OTHERWISE ; RETURN .F.
   ENDCASE
   IF nCode == 343
      lValid := hValue[ "_kind" ] == "Handle"
   ELSE
      lValid := hValue[ "_kind" ] == "Int32"
   ENDIF
   IF ! lValid ; RETURN .F. ; ENDIF
   Doc_EnsureXrecord( d, nLayer, cKey )
   x := Doc_XrecordMut( d, nLayer, cKey )
   IF x == NIL ; RETURN .F. ; ENDIF
   Xrc_SetLayerViewportOverride( x, cSec, nCode, nViewport, hValue )
RETURN .T.

/* devuelve { { viewport, valor }, ... } */
FUNCTION Doc_LayerViewportOverrides( d, nLayer, nKind )
   LOCAL cKey, nCode, x
   DO CASE
   CASE nKind == XRK_LAYER_VIEWPORT_ALPHA_OVERRIDE ; cKey := "ADSK_XREC_LAYER_ALPHA_OVR" ; nCode := 440
   CASE nKind == XRK_LAYER_VIEWPORT_COLOR_OVERRIDE ; cKey := "ADSK_XREC_LAYER_COLOR_OVR" ; nCode := 420
   CASE nKind == XRK_LAYER_VIEWPORT_LINETYPE_OVERRIDE ; cKey := "ADSK_XREC_LAYER_LINETYPE_OVR" ; nCode := 343
   CASE nKind == XRK_LAYER_VIEWPORT_LINEWEIGHT_OVERRIDE ; cKey := "ADSK_XREC_LAYER_LINEWT_OVR" ; nCode := 91
   OTHERWISE ; RETURN {}
   ENDCASE
   x := Doc_Xrecord( d, nLayer, cKey )
RETURN iif( x == NIL, {}, Xrc_LayerViewportOverrides( x, nCode ) )

FUNCTION Doc_OwnerChainReaches( d, nStart, nTarget )
   LOCAL nCur := nStart, i, nNext
   FOR i := 1 TO 16
      IF nCur == nTarget ; RETURN .T. ; ENDIF
      nNext := Doc_ObjectOwner( d, nCur )
      IF nNext != NIL .AND. nNext != nCur .AND. nNext != 0 ; nCur := nNext ; ELSE ; EXIT ; ENDIF
   NEXT
RETURN nCur == nTarget

FUNCTION Doc_BlockVisibilityParamForDef( d, nDefBlock )
   LOCAL p
   FOR EACH p IN hb_HValues( d[ "block_visibility_params" ] )
      IF Doc_OwnerChainReaches( d, p[ "owner" ], nDefBlock ) ; RETURN p ; ENDIF
   NEXT
RETURN NIL

FUNCTION Doc_DynamicVisibilityForInsert( d, nInsert )
   LOCAL nDef := Doc_DynamicDefinitionForInsert( d, nInsert ), p
   IF nDef == NIL ; RETURN NIL ; ENDIF
   p := Doc_BlockVisibilityParamForDef( d, nDef )
RETURN iif( p == NIL, NIL, { nDef, p } )

FUNCTION Doc_DynamicDefinitionForInsert( d, nInsert )
   LOCAL e := Doc_GetEntity( d, nInsert ), x, k, br
   IF e == NIL .OR. ! ( e[ "_type" ] == "INSERT" ) ; RETURN NIL ; ENDIF
   x := e[ "common" ][ "xdictionary_handle" ]
   IF x != NIL
      FOR EACH k IN hb_HKeys( d[ "block_representations" ] )
         IF Doc_OwnerChainReaches( d, k, x ) ; RETURN d[ "block_representations" ][ k ] ; ENDIF
      NEXT
   ENDIF
   br := Tb_Get( d[ "block_records" ], e[ "block_name" ] )
RETURN iif( br == NIL, NIL, br[ "handle" ] )

/* devuelve NIL si va bien o el mensaje de error */
FUNCTION Doc_CopyEvaluatedBlockMetadata( d, nSource, nTarget )
   LOCAL h, b, ok, nX, dic := NIL, nNew
   FOR EACH h IN { nSource, nTarget }
      ok := .F.
      FOR EACH b IN Tb_Values( d[ "block_records" ] )
         IF b[ "handle" ] == h .AND. Left( b[ "name" ], 2 ) == "*U" ; ok := .T. ; EXIT ; ENDIF
      NEXT
      IF ! ok ; RETURN "Expected an evaluated anonymous block record" ; ENDIF
   NEXT
   nX := Doc_ExtensionDictionaryHandle( d, nSource )
   IF nX != NIL
      IF hb_HHasKey( d[ "objects" ], nX ) .AND. d[ "objects" ][ nX ][ "_type" ] == "Dictionary" .AND. Len( d[ "objects" ][ nX ][ "entries" ] ) == 0 .AND. d[ "objects" ][ nX ][ "xdictionary_handle" ] == NIL
         dic := Ent_Clone( d[ "objects" ][ nX ] )
      ELSE
         RETURN "Evaluated block has additional object relationships"
      ENDIF
   ENDIF
   IF hb_HHasKey( d[ "eed_by_handle" ], nSource ) ; d[ "eed_by_handle" ][ nTarget ] := Ent_Clone( d[ "eed_by_handle" ][ nSource ] ) ; ENDIF
   IF dic != NIL
      nNew := Doc_AllocateHandle( d )
      dic[ "handle" ] := nNew ; dic[ "owner" ] := nTarget ; dic[ "reactors" ] := {}
      d[ "objects" ][ nNew ] := dic
      d[ "xdic_by_handle" ][ nTarget ] := nNew
   ENDIF
RETURN NIL

FUNCTION Doc_HasNullTableEntries( d )
   LOCAL c, e
   FOR EACH c IN Dt_Tables()
      FOR EACH e IN Tb_Values( d[ c ] )
         IF Hd_IsNull( e[ "handle" ] ) ; RETURN .T. ; ENDIF
      NEXT
   NEXT
RETURN .F.

FUNCTION Doc_HasStaleTableKeys( d )
   LOCAL c
   FOR EACH c IN Dt_Tables()
      IF Tb_HasStaleKeys( d[ c ] ) ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.

FUNCTION Doc_ResyncTableKeys( d )
   LOCAL aL, aT, aS, n := 0, c, a
   aL := Tb_ResyncKeys( d[ "layers" ] ) ; aT := Tb_ResyncKeys( d[ "line_types" ] ) ; aS := Tb_ResyncKeys( d[ "text_styles" ] )
   n := Len( aL ) + Len( aT ) + Len( aS )
   FOR EACH c IN { "dim_styles", "app_ids", "views", "vports", "ucss", "vx_table", "block_records" }
      a := Tb_ResyncKeys( d[ c ] ) ; n += Len( a )
   NEXT
   IF n == 0 ; RETURN 0 ; ENDIF
   Doc_ApplyTableRenames( d, aL, aT, aS )
RETURN n

/* pairs: { { claveAntigua, nombreNuevo }, ... } -> hash viejo(normalizado) -> nombre nuevo */
STATIC FUNCTION Dt_Resolvable( aPairs, hTable )
   LOCAL h := hb_Hash(), p, nPos, cOld
   FOR EACH p IN aPairs
      nPos := At( Chr( 0 ), p[ 1 ] ) ; cOld := iif( nPos > 0, Left( p[ 1 ], nPos - 1 ), p[ 1 ] )
      IF ! Tb_Contains( hTable, cOld ) .AND. Tb_NormalizeName( p[ 2 ] ) != cOld ; h[ cOld ] := p[ 2 ] ; ENDIF
   NEXT
RETURN h

STATIC PROCEDURE Doc_ApplyTableRenames( d, aLayers, aLineTypes, aTextStyles )
   LOCAL hL := Dt_Resolvable( aLayers, d[ "layers" ] ), hT := Dt_Resolvable( aLineTypes, d[ "line_types" ] ), hS := Dt_Resolvable( aTextStyles, d[ "text_styles" ] )
   LOCAL e, c, kl, kt, l, hd := d[ "header" ], k
   IF Len( hL ) == 0 .AND. Len( hT ) == 0 .AND. Len( hS ) == 0 ; RETURN ; ENDIF
   k := Tb_NormalizeName( hd[ "current_layer_name" ] ) ; IF hb_HHasKey( hL, k ) ; hd[ "current_layer_name" ] := hL[ k ] ; ENDIF
   k := Tb_NormalizeName( hd[ "current_linetype_name" ] ) ; IF hb_HHasKey( hT, k ) ; hd[ "current_linetype_name" ] := hT[ k ] ; ENDIF
   k := Tb_NormalizeName( hd[ "current_text_style_name" ] ) ; IF hb_HHasKey( hS, k ) ; hd[ "current_text_style_name" ] := hS[ k ] ; ENDIF
   FOR EACH e IN d[ "entities" ]
      c := e[ "common" ]
      kl := Tb_NormalizeName( c[ "layer" ] ) ; kt := Tb_NormalizeName( c[ "linetype" ] )
      IF ! hb_HHasKey( hL, kl ) .AND. ! hb_HHasKey( hT, kt ) ; LOOP ; ENDIF
      IF hb_HHasKey( hL, kl ) ; c[ "layer" ] := hL[ kl ] ; ENDIF
      IF hb_HHasKey( hT, kt ) ; c[ "linetype" ] := hT[ kt ] ; ENDIF
   NEXT
   FOR EACH l IN Tb_Values( d[ "layers" ] )
      k := Tb_NormalizeName( l[ "line_type" ] ) ; IF hb_HHasKey( hT, k ) ; l[ "line_type" ] := hT[ k ] ; ENDIF
   NEXT
RETURN

PROCEDURE Doc_AssignTableEntryHandles( d )
   LOCAL aMissing := {}, c, e, m, nNew
   FOR EACH c IN Dt_Tables()
      FOR EACH e IN Tb_Values( d[ c ] )
         IF Hd_IsNull( e[ "handle" ] ) ; AAdd( aMissing, { c, e[ "name" ] } ) ; ENDIF
      NEXT
   NEXT
   FOR EACH m IN aMissing
      nNew := Doc_AllocateHandle( d )
      e := Tb_Get( d[ m[ 1 ] ], m[ 2 ] )
      IF e != NIL ; e[ "handle" ] := nNew ; ENDIF
   NEXT
RETURN
