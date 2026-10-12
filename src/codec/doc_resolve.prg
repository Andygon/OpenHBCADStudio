/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/doc_resolve.prg
   Origen Rust: opencadcodec/src/document.rs, CadDocument::resolve_references (L4660-5742) y resolve_book_colors (L5744-5780).
   Parte 6 de CadDocument. Licencia del original: MPL-2.0. Tests [extra] (el Rust no tiene #[test] aqui).
   Pendientes por depender de tipos aun no portados (se documentan, no se inventan): ObjectType DataObject / Field / FieldList / TableContent
   (remapeo de handles en objetos y en d["fields"]), entidades Dimension (base_mut().common) y Extended (RegisteredClass/Proxy).
   Todas las entidades portadas guardan "common" en e["common"].
   El remapeo usa un codeblock {| nHandle | nNuevo } (los enteros no son referencias). set_handle del objeto: clave "handle".
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION Dr_MaxH( n, nH ) ; RETURN iif( nH >= n, nH + 1, n )

STATIC FUNCTION Dr_Tables() ; RETURN { "layers", "line_types", "text_styles", "dim_styles", "app_ids", "views", "vports", "ucss", "vx_table" }

PROCEDURE Doc_ResolveReferences( d )
   LOCAL nMax, e, k, br, eh, c, aMissing := {}, m, nNew, aNullKeys := {}, aMis := {}, o, hUsed := hb_Hash(), hNonObj, aCtl, x
   LOCAL hdr := d[ "header" ], aRemap := {}, hMap := hb_Hash(), aObjH, nOld, bRe, lAcad, pair
   Doc_SynchronizeHandleAllocator( d )
   nMax := d[ "next_handle" ]
   FOR EACH e IN d[ "entities" ] ; nMax := Dr_MaxH( nMax, e[ "common" ][ "handle" ] ) ; NEXT
   FOR EACH k IN hb_HKeys( d[ "objects" ] ) ; nMax := Dr_MaxH( nMax, k ) ; NEXT
   FOR EACH br IN Tb_Values( d[ "block_records" ] )
      nMax := Dr_MaxH( nMax, br[ "handle" ] )
      FOR EACH eh IN br[ "entity_handles" ] ; nMax := Dr_MaxH( nMax, eh ) ; NEXT
   NEXT
   FOR EACH c IN Dr_Tables()
      FOR EACH x IN Tb_Values( d[ c ] ) ; nMax := Dr_MaxH( nMax, x[ "handle" ] ) ; NEXT
   NEXT
   d[ "next_handle" ] := nMax
   FOR EACH c IN { "layers", "line_types", "text_styles", "dim_styles", "app_ids", "views", "vports", "ucss", "vx_table", "block_records" }
      FOR EACH x IN Tb_Values( d[ c ] )
         IF Hd_IsNull( x[ "handle" ] ) ; AAdd( aMissing, { c, x[ "name" ] } ) ; ENDIF
      NEXT
   NEXT
   FOR EACH k IN hb_HKeys( d[ "objects" ] )
      IF Hd_IsNull( k ) ; AAdd( aNullKeys, k )
      ELSEIF Hd_IsNull( d[ "objects" ][ k ][ "handle" ] ) ; AAdd( aMis, k )
      ENDIF
   NEXT
   FOR EACH m IN aMissing
      nNew := Doc_AllocateHandle( d ) ; x := Tb_Get( d[ m[ 1 ] ], m[ 2 ] )
      IF x != NIL ; x[ "handle" ] := nNew ; ENDIF
   NEXT
   FOR EACH k IN aNullKeys
      nNew := Doc_AllocateHandle( d )
      IF hb_HHasKey( d[ "objects" ], 0 )
         o := d[ "objects" ][ 0 ] ; hb_HDel( d[ "objects" ], 0 ) ; o[ "handle" ] := nNew ; d[ "objects" ][ nNew ] := o
      ENDIF
   NEXT
   HB_SYMBOL_UNUSED( k )
   FOR EACH k IN aMis
      IF hb_HHasKey( d[ "objects" ], k ) ; d[ "objects" ][ k ][ "handle" ] := k ; ENDIF
   NEXT
   /* ACAD primero en app_ids */
   x := Tb_Values( d[ "app_ids" ] )
   lAcad := Len( x ) > 0 .AND. Upper( x[ 1 ][ "name" ] ) == "ACAD"
   IF ! lAcad .AND. Tb_Get( d[ "app_ids" ], "ACAD" ) != NIL
      o := Tb_Get( d[ "app_ids" ], "ACAD" ) ; c := d[ "app_ids" ][ "entries" ] ; hb_HDel( c, Tb_NormalizeName( "ACAD" ) )
      d[ "app_ids" ][ "entries" ] := hb_Hash() ; Tb_AddOrReplace( d[ "app_ids" ], o )
      FOR EACH e IN hb_HValues( c ) ; Tb_AddOrReplace( d[ "app_ids" ], e ) ; NEXT
   ENDIF
   FOR EACH c IN { "layers", "line_types", "text_styles", "vports", "views", "ucss", "app_ids", "dim_styles", "vx_table", "block_records" }
      FOR EACH x IN Tb_Values( d[ c ] )
         IF ! Hd_IsNull( x[ "handle" ] ) ; hUsed[ x[ "handle" ] ] := .T. ; ENDIF
      NEXT
   NEXT
   FOR EACH e IN d[ "entities" ]
      IF e[ "common" ][ "handle" ] > 0 ; hUsed[ e[ "common" ][ "handle" ] ] := .T.
      ENDIF
   NEXT
   hNonObj := hb_HClone( hUsed )
   FOR EACH k IN hb_HKeys( d[ "objects" ] )
      IF k > 0 ; hUsed[ k ] := .T.
      ENDIF
   NEXT
   /* handles de las tablas de control */
   aCtl := { { "vports", "vport_control_handle" }, { "line_types", "linetype_control_handle" }, { "layers", "layer_control_handle" }, { "text_styles", "style_control_handle" }, ;
             { "views", "view_control_handle" }, { "ucss", "ucs_control_handle" }, { "app_ids", "appid_control_handle" }, { "dim_styles", "dimstyle_control_handle" }, ;
             { "block_records", "block_control_handle" }, { "vx_table", "vpent_hdr_control_handle" } }
   FOR EACH pair IN aCtl
      IF hb_HHasKey( hUsed, d[ pair[ 1 ] ][ "handle" ] )
         nNew := d[ "next_handle" ] ; d[ "next_handle" ]++ ; d[ pair[ 1 ] ][ "handle" ] := nNew ; hdr[ pair[ 2 ] ] := nNew
      ENDIF
   NEXT
   FOR EACH pair IN aCtl
      IF ! Hd_IsNull( d[ pair[ 1 ] ][ "handle" ] ) ; hUsed[ d[ pair[ 1 ] ][ "handle" ] ] := .T. ; ENDIF
   NEXT
   FOR EACH br IN Tb_Values( d[ "block_records" ] )
      IF Hd_IsNull( br[ "block_entity_handle" ] ) .OR. hb_HHasKey( hUsed, br[ "block_entity_handle" ] )
         br[ "block_entity_handle" ] := d[ "next_handle" ] ; d[ "next_handle" ]++
      ENDIF
      hUsed[ br[ "block_entity_handle" ] ] := .T.
      IF Hd_IsNull( br[ "block_end_handle" ] ) .OR. hb_HHasKey( hUsed, br[ "block_end_handle" ] )
         br[ "block_end_handle" ] := d[ "next_handle" ] ; d[ "next_handle" ]++
      ENDIF
      hUsed[ br[ "block_end_handle" ] ] := .T.
   NEXT
   /* objetos cuyo handle choca con uno no-objeto: renumerar */
   aObjH := hb_HKeys( d[ "objects" ] ) ; ASort( aObjH )
   FOR EACH nOld IN aObjH
      IF hb_HHasKey( hNonObj, nOld ) ; AAdd( aRemap, { nOld, d[ "next_handle" ] } ) ; d[ "next_handle" ]++ ; ENDIF
   NEXT
   FOR EACH pair IN aRemap
      IF hb_HHasKey( d[ "objects" ], pair[ 1 ] )
         o := d[ "objects" ][ pair[ 1 ] ] ; hb_HDel( d[ "objects" ], pair[ 1 ] ) ; o[ "handle" ] := pair[ 2 ] ; d[ "objects" ][ pair[ 2 ] ] := o
      ENDIF
      hMap[ pair[ 1 ] ] := pair[ 2 ]
   NEXT
   IF Len( aRemap ) > 0
      bRe := {| n | iif( hb_HHasKey( hMap, n ), hMap[ n ], n ) }
      Dr_RemapAll( d, hMap, bRe, aRemap )
   ENDIF
   Dr_OwnerAndModes( d )
   Dr_ImagePaths( d )
   Doc_ResolveBookColors( d )
   Doc_ResolveXrecordNames( d )
   Doc_ResolveXrecordBackedProperties( d )
   hdr[ "handle_seed" ] := Max( hdr[ "handle_seed" ], d[ "next_handle" ] )
RETURN

/* pone cada elemento de la lista de handles a traves de bRe; devuelve la lista */
STATIC PROCEDURE Dr_List( a, bRe )
   LOCAL i
   FOR i := 1 TO Len( a ) ; a[ i ] := Eval( bRe, a[ i ] ) ; NEXT
RETURN

STATIC PROCEDURE Dr_Common( o, bRe )
   IF hb_HHasKey( o, "owner" ) ; o[ "owner" ] := Eval( bRe, o[ "owner" ] ) ; ENDIF
   Dr_List( o[ "reactors" ], bRe )
   IF o[ "xdictionary_handle" ] != NIL ; o[ "xdictionary_handle" ] := Eval( bRe, o[ "xdictionary_handle" ] ) ; ENDIF
RETURN

STATIC PROCEDURE Dr_Props( aProps, bRe )
   LOCAL p
   FOR EACH p IN aProps
      IF p[ "value" ][ "_kind" ] == "Handle" ; p[ "value" ][ "value" ] := Eval( bRe, p[ "value" ][ "value" ] ) ; ENDIF
   NEXT
RETURN

STATIC PROCEDURE Dr_Refs( aRefs, bRe )
   LOCAL r
   FOR EACH r IN aRefs ; r[ "handle" ] := Eval( bRe, r[ "handle" ] ) ; NEXT
RETURN

STATIC PROCEDURE Dr_Object( o, bRe )
   LOCAL t := iif( hb_HHasKey( o, "_type" ), o[ "_type" ], "PlotSettings" ), e, c, k, dl, a, i
   DO CASE
   CASE t == "Dictionary"
      o[ "owner" ] := Eval( bRe, o[ "owner" ] )
      FOR EACH e IN o[ "entries" ] ; e[ 2 ] := Eval( bRe, e[ 2 ] ) ; NEXT
   CASE t == "XRecord"
      Dr_Common( o, bRe )
      FOR EACH e IN o[ "entries" ]
         IF e[ "value" ][ "_kind" ] == "Handle" ; e[ "value" ][ "value" ] := Eval( bRe, e[ "value" ][ "value" ] ) ; ENDIF
      NEXT
      Dr_Refs( o[ "object_references" ], bRe )
   CASE t == "Layout"
      Dr_Common( o, bRe )
      o[ "block_record" ] := Eval( bRe, o[ "block_record" ] ) ; o[ "viewport" ] := Eval( bRe, o[ "viewport" ] ) ; Dr_List( o[ "viewports" ], bRe )
      o[ "base_ucs" ] := Eval( bRe, o[ "base_ucs" ] ) ; o[ "named_ucs" ] := Eval( bRe, o[ "named_ucs" ] )
      o[ "plot_view_handle" ] := Eval( bRe, o[ "plot_view_handle" ] ) ; o[ "visual_style_handle" ] := Eval( bRe, o[ "visual_style_handle" ] )
      IF o[ "raw_plot_settings_codes" ] != NIL
         FOR EACH c IN o[ "raw_plot_settings_codes" ]
            IF c[ 1 ] == 333
               k := hb_HexToNum( c[ 2 ] )
               IF Eval( bRe, k ) != k ; c[ 2 ] := Upper( hb_NumToHex( Eval( bRe, k ) ) ) ; ENDIF
            ENDIF
         NEXT
      ENDIF
   CASE t == "PlotSettings"
      Dr_Common( o, bRe ) ; o[ "plot_view_handle" ] := Eval( bRe, o[ "plot_view_handle" ] ) ; o[ "visual_style_handle" ] := Eval( bRe, o[ "visual_style_handle" ] )
   CASE t == "MLineStyle" .OR. t == "PlaceHolder"
      o[ "owner" ] := Eval( bRe, o[ "owner" ] )
   CASE t == "DictionaryWithDefault"
      o[ "owner" ] := Eval( bRe, o[ "owner" ] )
      FOR EACH e IN o[ "entries" ] ; e[ 2 ] := Eval( bRe, e[ 2 ] ) ; NEXT
      o[ "default_handle" ] := Eval( bRe, o[ "default_handle" ] )
   CASE t == "GeoData"
      Dr_Common( o, bRe ) ; o[ "host_block" ] := Eval( bRe, o[ "host_block" ] )
   CASE t == "DynamicBlockObject" ; Dbo_VisitHandlesMut( o, bRe )
   CASE t == "ClassObject" ; Cob_VisitHandlesMut( o, bRe )
   CASE t == "AssociativeObject" ; Aso_VisitHandlesMut( o, bRe )
   CASE t == "BlockVisibilityParameter" ; Bvp_VisitHandlesMut( o, bRe )
   CASE t == "RegisteredClassObject"
      Dr_Common( o, bRe ) ; Dr_Props( o[ "properties" ], bRe ) ; Dr_Refs( o[ "object_ids" ], bRe )
   CASE t == "ProxyObject"
      Dr_Common( o, bRe ) ; Dr_Refs( o[ "object_ids" ], bRe )
   CASE t == "DgnLineStyleObject"
      Dr_Common( o, bRe ) ; dl := o[ "data" ]
      DO CASE
      CASE dl[ "_kind" ] == "Definition"
         dl[ "root_component" ] := Eval( bRe, dl[ "root_component" ] ) ; Dr_Props( dl[ "properties" ], bRe )
      CASE dl[ "_kind" ] == "Component"
         c := dl[ "component" ]
         DO CASE
         CASE c[ "_kind" ] == "Symbol" ; c[ "value" ][ "block" ] := Eval( bRe, c[ "value" ][ "block" ] )
         CASE c[ "_kind" ] == "Compound" ; FOR EACH e IN c[ "value" ][ "entries" ] ; e[ "component" ] := Eval( bRe, e[ "component" ] ) ; NEXT
         CASE c[ "_kind" ] == "Point"
            c[ "value" ][ "stroke_component" ] := Eval( bRe, c[ "value" ][ "stroke_component" ] )
            FOR EACH e IN c[ "value" ][ "symbols" ] ; e[ "symbol_component" ] := Eval( bRe, e[ "symbol_component" ] ) ; NEXT
         ENDCASE
         Dr_Props( dl[ "properties" ], bRe )
      CASE dl[ "_kind" ] == "Registered"
         Dr_Props( dl[ "properties" ], bRe ) ; Dr_Refs( dl[ "object_ids" ], bRe )
      ENDCASE
   CASE t == "ObjectContextData"
      o[ "owner_handle" ] := Eval( bRe, o[ "owner_handle" ] ) ; Dr_List( o[ "reactors" ], bRe )
      IF o[ "xdictionary_handle" ] != NIL ; o[ "xdictionary_handle" ] := Eval( bRe, o[ "xdictionary_handle" ] ) ; ENDIF
      o[ "scale" ] := Eval( bRe, o[ "scale" ] ) ; k := o[ "kind" ]
      DO CASE
      CASE k[ "_kind" ] == "Dim" ; k[ "block" ] := Eval( bRe, k[ "block" ] )
      CASE k[ "_kind" ] == "HatchView" ; k[ "view" ] := Eval( bRe, k[ "view" ] )
      CASE k[ "_kind" ] == "MTextAttribute"
         IF k[ "context" ] != NIL ; k[ "context" ][ "scale" ] := Eval( bRe, k[ "context" ][ "scale" ] ) ; ENDIF
      CASE k[ "_kind" ] == "MLeader"
         FOR EACH a IN { "text_style_handle", "block_content_handle", "scale_handle" }
            IF k[ a ] != NIL ; k[ a ] := Eval( bRe, k[ a ] ) ; ENDIF
         NEXT
         FOR EACH e IN k[ "leader_roots" ]
            FOR EACH i IN e[ "lines" ]
               IF i[ "line_type_handle" ] != NIL ; i[ "line_type_handle" ] := Eval( bRe, i[ "line_type_handle" ] ) ; ENDIF
               IF i[ "arrowhead_handle" ] != NIL ; i[ "arrowhead_handle" ] := Eval( bRe, i[ "arrowhead_handle" ] ) ; ENDIF
            NEXT
         NEXT
      ENDCASE
   CASE t == "DictionaryVariable"
      o[ "owner_handle" ] := Eval( bRe, o[ "owner_handle" ] )
   ENDCASE
RETURN

STATIC PROCEDURE Dr_RekeyHash( h, hMap, bVal )
   LOCAL k, v, aKeys := hb_HKeys( h ), aVals := {}
   FOR EACH k IN aKeys
      IF hb_HHasKey( hMap, k )
         v := h[ k ] ; hb_HDel( h, k ) ; AAdd( aVals, { hMap[ k ], v } )
      ENDIF
   NEXT
   FOR EACH v IN aVals ; h[ v[ 1 ] ] := v[ 2 ] ; NEXT
   HB_SYMBOL_UNUSED( bVal )
RETURN

STATIC PROCEDURE Dr_RemapAll( d, hMap, bRe, aRemap )
   LOCAL o, p, k, c, e, hdr := d[ "header" ], br, v
   FOR EACH o IN hb_HValues( d[ "objects" ] ) ; Dr_Object( o, bRe ) ; NEXT
   /* tablas auxiliares: cada objeto movido cambia de clave (y sus handles internos) */
   FOR EACH p IN aRemap
      IF hb_HHasKey( d[ "block_visibility_params" ], p[ 1 ] ) ; Bvp_VisitHandlesMut( d[ "block_visibility_params" ][ p[ 1 ] ], bRe ) ; ENDIF
      IF hb_HHasKey( d[ "context_scales" ], p[ 1 ] ) ; d[ "context_scales" ][ p[ 1 ] ] := Eval( bRe, d[ "context_scales" ][ p[ 1 ] ] ) ; ENDIF
      IF hb_HHasKey( d[ "block_representations" ], p[ 1 ] ) ; d[ "block_representations" ][ p[ 1 ] ] := Eval( bRe, d[ "block_representations" ][ p[ 1 ] ] ) ; ENDIF
      IF hb_HHasKey( d[ "xdic_by_handle" ], p[ 1 ] ) ; d[ "xdic_by_handle" ][ p[ 1 ] ] := Eval( bRe, d[ "xdic_by_handle" ][ p[ 1 ] ] ) ; ENDIF
      IF hb_HHasKey( d[ "reactors_by_handle" ], p[ 1 ] ) ; Dr_List( d[ "reactors_by_handle" ][ p[ 1 ] ], bRe ) ; ENDIF
   NEXT
   FOR EACH c IN { "block_visibility_params", "context_scales", "block_representations", "eed_by_handle", "object_xdata", "xdic_by_handle", "reactors_by_handle" }
      Dr_RekeyHash( d[ c ], hMap, NIL )
   NEXT
   FOR EACH v IN hb_HValues( d[ "block_visibility_params" ] ) ; Bvp_VisitHandlesMut( v, bRe ) ; NEXT
   FOR EACH k IN hb_HKeys( d[ "context_scales" ] ) ; d[ "context_scales" ][ k ] := Eval( bRe, d[ "context_scales" ][ k ] ) ; NEXT
   FOR EACH k IN hb_HKeys( d[ "block_representations" ] ) ; d[ "block_representations" ][ k ] := Eval( bRe, d[ "block_representations" ][ k ] ) ; NEXT
   FOR EACH k IN hb_HKeys( d[ "xdic_by_handle" ] ) ; d[ "xdic_by_handle" ][ k ] := Eval( bRe, d[ "xdic_by_handle" ][ k ] ) ; NEXT
   FOR EACH v IN hb_HValues( d[ "reactors_by_handle" ] ) ; Dr_List( v, bRe ) ; NEXT
   FOR EACH k IN { "named_objects_dict_handle", "acad_group_dict_handle", "acad_mlinestyle_dict_handle", "acad_layout_dict_handle", "acad_plotsettings_dict_handle", ;
                   "acad_plotstylename_dict_handle", "acad_material_dict_handle", "acad_color_dict_handle", "acad_visualstyle_dict_handle", "current_multiline_style_handle" }
      hdr[ k ] := Eval( bRe, hdr[ k ] )
   NEXT
   FOR EACH br IN Tb_Values( d[ "block_records" ] ) ; br[ "layout" ] := Eval( bRe, br[ "layout" ] ) ; NEXT
   FOR EACH v IN Tb_Values( d[ "views" ] )
      FOR EACH k IN { "background_handle", "live_section_handle", "visual_style_handle", "sun_handle" } ; v[ k ] := Eval( bRe, v[ k ] ) ; NEXT
   NEXT
   FOR EACH v IN Tb_Values( d[ "vports" ] )
      FOR EACH k IN { "background_handle", "visual_style_handle", "sun_handle" } ; v[ k ] := Eval( bRe, v[ k ] ) ; NEXT
   NEXT
   FOR EACH e IN d[ "entities" ]
      c := e[ "common" ]
      IF c[ "color_book_handle" ] != NIL ; c[ "color_book_handle" ] := Eval( bRe, c[ "color_book_handle" ] ) ; ENDIF
      IF c[ "xdictionary_handle" ] != NIL ; c[ "xdictionary_handle" ] := Eval( bRe, c[ "xdictionary_handle" ] ) ; ENDIF
      DO CASE
      CASE e[ "_type" ] == "INSERT"
         IF e[ "view_rep_handle" ] != NIL ; e[ "view_rep_handle" ] := Eval( bRe, e[ "view_rep_handle" ] ) ; ENDIF
      CASE e[ "_type" ] == "UNDERLAY"
         e[ "definition_handle" ] := Eval( bRe, e[ "definition_handle" ] )
      CASE e[ "_type" ] == "IMAGE"
         IF e[ "definition_handle" ] != NIL ; e[ "definition_handle" ] := Eval( bRe, e[ "definition_handle" ] ) ; ENDIF
      CASE e[ "_type" ] == "SECTIONLINE"
         e[ "style_handle" ] := Eval( bRe, e[ "style_handle" ] ) ; e[ "view_rep_handle" ] := Eval( bRe, e[ "view_rep_handle" ] )
      CASE e[ "_type" ] == "DRAWINGVIEW"
         e[ "active_viewport" ] := Eval( bRe, e[ "active_viewport" ] ) ; e[ "scale_handle" ] := Eval( bRe, e[ "scale_handle" ] )
      ENDCASE
   NEXT
RETURN

STATIC PROCEDURE Dr_OwnerAndModes( d )
   LOCAL nModel := d[ "header" ][ "model_space_block_handle" ], nPaper := d[ "header" ][ "paper_space_block_handle" ], hPaper := hb_Hash(), br, eh, e, c, cn
   FOR EACH br IN Tb_Values( d[ "block_records" ] )
      cn := Upper( br[ "name" ] )
      IF cn == "*PAPER_SPACE" .OR. ( Left( cn, 12 ) == "*PAPER_SPACE" .AND. Len( cn ) > 12 .AND. Dr_AllDigits( SubStr( cn, 13 ) ) ) ; hPaper[ br[ "handle" ] ] := .T. ; ENDIF
   NEXT
   FOR EACH br IN Tb_Values( d[ "block_records" ] )
      FOR EACH eh IN br[ "entity_handles" ]
         IF hb_HHasKey( d[ "entity_index" ], eh )
            c := d[ "entities" ][ d[ "entity_index" ][ eh ] + 1 ][ "common" ]
            IF Hd_IsNull( c[ "owner_handle" ] ) ; c[ "owner_handle" ] := br[ "handle" ] ; ENDIF
         ENDIF
      NEXT
   NEXT
   FOR EACH e IN d[ "entities" ]
      c := e[ "common" ]
      IF Hd_IsNull( c[ "owner_handle" ] ) ; c[ "owner_handle" ] := iif( c[ "entity_mode" ] != NIL .AND. c[ "entity_mode" ] == 1, nPaper, nModel ) ; ENDIF
      IF c[ "owner_handle" ] == nModel ; c[ "entity_mode" ] := 2
      ELSEIF hb_HHasKey( hPaper, c[ "owner_handle" ] ) ; c[ "entity_mode" ] := 1
      ELSE ; c[ "entity_mode" ] := 0
      ENDIF
   NEXT
RETURN

STATIC FUNCTION Dr_AllDigits( s )
   LOCAL i
   FOR i := 1 TO Len( s )
      IF ! SubStr( s, i, 1 ) $ "0123456789" ; RETURN .F.
      ENDIF
   NEXT
RETURN .T.

STATIC PROCEDURE Dr_ImagePaths( d )
   LOCAL hP := hb_Hash(), k, o, e
   FOR EACH k IN hb_HKeys( d[ "objects" ] )
      o := d[ "objects" ][ k ]
      IF hb_HHasKey( o, "_type" ) .AND. o[ "_type" ] == "ImageDefinition" .AND. ! Empty( o[ "file_name" ] ) ; hP[ k ] := o[ "file_name" ] ; ENDIF
   NEXT
   IF Len( hP ) == 0 ; RETURN ; ENDIF
   FOR EACH e IN d[ "entities" ]
      IF e[ "_type" ] == "IMAGE" .AND. Empty( e[ "file_path" ] ) .AND. e[ "definition_handle" ] != NIL .AND. hb_HHasKey( hP, e[ "definition_handle" ] )
         e[ "file_path" ] := hP[ e[ "definition_handle" ] ]
      ENDIF
   NEXT
RETURN

PROCEDURE Doc_ResolveBookColors( d )
   LOCAL aCol := {}, k, o, e, c, hit, sp, cb, cn, x
   FOR EACH k IN hb_HKeys( d[ "objects" ] )
      o := d[ "objects" ][ k ]
      IF hb_HHasKey( o, "_type" ) .AND. o[ "_type" ] == "BookColor" ; AAdd( aCol, { k, o[ "color" ], o[ "book_name" ], o[ "color_name" ] } ) ; ENDIF
   NEXT
   IF Len( aCol ) == 0 ; RETURN ; ENDIF
   FOR EACH e IN Doc_EntitiesMutKeepRaw( d )
      c := e[ "common" ] ; hit := NIL
      IF c[ "color_book_handle" ] != NIL
         FOR EACH x IN aCol
            IF x[ 1 ] == c[ "color_book_handle" ] ; hit := x ; EXIT
            ENDIF
         NEXT
      ENDIF
      IF hit == NIL .AND. c[ "color_name" ] != NIL
         sp := Dxm_SplitColorBookName( c[ "color_name" ] ) ; cb := sp[ 1 ] ; cn := sp[ 2 ]
         IF cb != NIL .AND. cn != NIL
            FOR EACH x IN aCol
               IF Upper( x[ 3 ] ) == Upper( cb ) .AND. Upper( x[ 4 ] ) == Upper( cn ) ; hit := x ; EXIT
               ENDIF
            NEXT
         ENDIF
      ENDIF
      IF hit != NIL
         c[ "color_book_handle" ] := hit[ 1 ] ; c[ "color" ] := Ent_Clone( hit[ 2 ] ) ; c[ "color_name" ] := Dxm_JoinColorBookName( hit[ 3 ], hit[ 4 ] )
      ENDIF
   NEXT
RETURN
