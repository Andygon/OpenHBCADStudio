/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/doc_document.prg
   Origen Rust: opencadcodec/src/document.rs, CadDocument (L1107-1385 structs, L1496-1560 new/with_version, L1698-2260 initialize_defaults,
   register_object_context_class, allocate_handle, synchronize_handle_allocator, next_handle). Parte 1 de la portacion de CadDocument.
   Licencia del original: MPL-2.0. Los tests de este fichero son [extra] (document.rs no tiene #[test] en esta zona).
   Prefijos: Prv_ (Preview), Fdf_ (FieldDef), Smi_ (SummaryInfo), Doc_ (CadDocument).
   CadDocument = hash con los nombres de campo Rust. Tablas = Tb_New(). HashMap<Handle,_> = hash de Harbour con clave entera (handle).
   ObjectType no es un envoltorio: cada objeto es el hash del objeto con su clave "_type" (igual que las entidades). HashSet<Handle> = hash handle -> .T.
   Arc<T> = referencia compartida de Harbour (arrays/hashes ya son referencias). Option -> NIL. next_handle (campo privado) = "next_handle".
   APLAZADO a las siguientes partes: EntityChangeRecorder (thread-local), snapshot/swap_structure, rename_layer, solid_history_*, add_entity y demas.
   PreviewFormat: PVF_BMP/PVF_WMF/PVF_PNG en ocx.ch.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Prv_New( nFormat, cData ) ; RETURN hb_Hash( "format", nFormat, "data", cData )

FUNCTION Fdf_Default() ; RETURN hb_Hash( "handle", Hd_Null(), "owner", Hd_Null(), "evaluator", "", "code", "", "objects", {} )

FUNCTION Smi_Default()
RETURN hb_Hash( "title", "", "subject", "", "author", "", "keywords", "", "comments", "", "last_saved_by", "", "revision_number", "", "hyperlink_base", "", "custom_properties", {} )

FUNCTION Doc_New()
   LOCAL d := hb_Hash( ;
      "version", 1032, "maintenance_version", 0, "header", Hdr_New(), ;
      "layers", Tb_New(), "line_types", Tb_New(), "text_styles", Tb_New(), "block_records", Tb_New(), "dim_styles", Tb_New(), ;
      "app_ids", Tb_New(), "views", Tb_New(), "vports", Tb_New(), "ucss", Tb_New(), "vx_table", Tb_New(), "vx_control_entries", {}, ;
      "classes", Dcc_New(), "notifications", Ntc_New(), "entities", {}, "entity_index", hb_Hash(), "objects", hb_Hash(), ;
      "block_visibility_params", hb_Hash(), "context_scales", hb_Hash(), "block_representations", hb_Hash(), "fields", hb_Hash(), ;
      "summary_info", Smi_Default(), "source_path", NIL, "dgn_ls_definitions", hb_Hash(), "dgn_ls_components", hb_Hash(), ;
      "eed_by_handle", hb_Hash(), "object_xdata", hb_Hash(), "xdic_by_handle", hb_Hash(), "reactors_by_handle", hb_Hash(), "block_entity_handles", hb_Hash(), ;
      "dwg_source_version", NIL, "preview", NIL, "acis_sab_handles", {}, "raw_acds_data", NIL, "raw_records", hb_Hash(), "original_objects", hb_Hash(), ;
      "raw_record_owners", hb_Hash(), "raw_acds_fingerprint", {}, "dwg_data_store_handles", hb_Hash(), "section_view_style", NIL, ;
      "view_rep_refs", hb_Hash(), "section_view_reps", {}, "next_handle", 16 )
   Doc_InitializeDefaults( d )
RETURN d

FUNCTION Doc_WithVersion( nVersion )
   LOCAL d := Doc_New()
   d[ "version" ] := nVersion
RETURN d

/* Allocate a new unique handle */
FUNCTION Doc_AllocateHandle( d )
   LOCAL h
   IF d[ "header" ][ "handle_seed" ] > d[ "next_handle" ]
      d[ "next_handle" ] := d[ "header" ][ "handle_seed" ]
   ENDIF
   h := Hd_New( d[ "next_handle" ] )
   d[ "next_handle" ]++
   d[ "header" ][ "handle_seed" ] := d[ "next_handle" ]
RETURN h

FUNCTION Doc_NextHandle( d ) ; RETURN d[ "next_handle" ]

STATIC PROCEDURE Doc_IncTable( t, aNext )
   LOCAL e
   aNext[ 1 ] := Max( aNext[ 1 ], t[ "handle" ] + 1 )
   FOR EACH e IN Tb_Values( t )
      aNext[ 1 ] := Max( aNext[ 1 ], e[ "handle" ] + 1 )
   NEXT
RETURN

/* pub(crate) synchronize_handle_allocator */
PROCEDURE Doc_SynchronizeHandleAllocator( d )
   LOCAL n := { d[ "next_handle" ] }, k, r, e, h
   FOR EACH k IN { "layers", "line_types", "text_styles", "dim_styles", "app_ids", "views", "vports", "ucss", "vx_table", "block_records" }
      Doc_IncTable( d[ k ], n )
   NEXT
   FOR EACH r IN Tb_Values( d[ "block_records" ] )
      n[ 1 ] := Max( n[ 1 ], r[ "block_entity_handle" ] + 1 )
      n[ 1 ] := Max( n[ 1 ], r[ "block_end_handle" ] + 1 )
      FOR EACH h IN r[ "entity_handles" ] ; n[ 1 ] := Max( n[ 1 ], h + 1 ) ; NEXT
   NEXT
   FOR EACH e IN d[ "entities" ] ; n[ 1 ] := Max( n[ 1 ], Ent_Handle( e ) + 1 ) ; NEXT
   FOR EACH h IN hb_HKeys( d[ "objects" ] ) ; n[ 1 ] := Max( n[ 1 ], h + 1 ) ; NEXT
   d[ "next_handle" ] := n[ 1 ]
   d[ "header" ][ "handle_seed" ] := Max( d[ "header" ][ "handle_seed" ], n[ 1 ] )
RETURN

STATIC PROCEDURE Doc_PutObj( d, o ) ; d[ "objects" ][ o[ "handle" ] ] := o ; RETURN

STATIC FUNCTION Doc_NewDict( nHandle, nOwner )
   LOCAL x := Dic_New()
   x[ "handle" ] := nHandle ; x[ "owner" ] := nOwner
RETURN x

STATIC PROCEDURE Doc_AddStdClass( d, cDxf, cCpp )
   Dcc_AddOrUpdate( d[ "classes" ], Dcl_New( cDxf, cCpp ) )
RETURN

PROCEDURE Doc_InitializeDefaults( d )
   LOCAL h := d[ "header" ], l0, cont, byl, byb, std, ms, ps, dim, ac, an, ct, ld, av
   LOCAL nMlDict, nTbDict, nMlStd, nMleStd, nTbStd, nModelL, nPaperL, nPlotPh, nRoot, x, mls, ts, lay
   h[ "block_control_handle" ] := 1 ; h[ "layer_control_handle" ] := 2 ; h[ "style_control_handle" ] := 3
   h[ "linetype_control_handle" ] := 5 ; h[ "view_control_handle" ] := 6 ; h[ "ucs_control_handle" ] := 7
   h[ "vport_control_handle" ] := 8 ; h[ "appid_control_handle" ] := 9 ; h[ "dimstyle_control_handle" ] := 10
   h[ "vpent_hdr_control_handle" ] := 11 ; h[ "named_objects_dict_handle" ] := 12
   Tb_SetHandle( d[ "block_records" ], h[ "block_control_handle" ] ) ; Tb_SetHandle( d[ "layers" ], h[ "layer_control_handle" ] )
   Tb_SetHandle( d[ "text_styles" ], h[ "style_control_handle" ] ) ; Tb_SetHandle( d[ "line_types" ], h[ "linetype_control_handle" ] )
   Tb_SetHandle( d[ "views" ], h[ "view_control_handle" ] ) ; Tb_SetHandle( d[ "ucss" ], h[ "ucs_control_handle" ] )
   Tb_SetHandle( d[ "vports" ], h[ "vport_control_handle" ] ) ; Tb_SetHandle( d[ "app_ids" ], h[ "appid_control_handle" ] )
   Tb_SetHandle( d[ "dim_styles" ], h[ "dimstyle_control_handle" ] ) ; Tb_SetHandle( d[ "vx_table" ], h[ "vpent_hdr_control_handle" ] )

   l0 := Lyr_Layer0() ; l0[ "handle" ] := Doc_AllocateHandle( d ) ; h[ "current_layer_handle" ] := l0[ "handle" ] ; Tb_Add( d[ "layers" ], l0 )
   cont := Lty_Continuous() ; cont[ "handle" ] := Doc_AllocateHandle( d ) ; h[ "continuous_linetype_handle" ] := cont[ "handle" ] ; Tb_Add( d[ "line_types" ], cont )
   byl := Lty_ByLayer() ; byl[ "handle" ] := Doc_AllocateHandle( d ) ; h[ "bylayer_linetype_handle" ] := byl[ "handle" ] ; h[ "current_linetype_handle" ] := byl[ "handle" ] ; Tb_Add( d[ "line_types" ], byl )
   byb := Lty_ByBlock() ; byb[ "handle" ] := Doc_AllocateHandle( d ) ; h[ "byblock_linetype_handle" ] := byb[ "handle" ] ; Tb_Add( d[ "line_types" ], byb )
   std := Tst_Standard() ; std[ "handle" ] := Doc_AllocateHandle( d ) ; h[ "current_text_style_handle" ] := std[ "handle" ] ; Tb_Add( d[ "text_styles" ], std )
   ms := Blk_ModelSpace() ; ms[ "handle" ] := Doc_AllocateHandle( d ) ; ms[ "block_entity_handle" ] := Doc_AllocateHandle( d ) ; ms[ "block_end_handle" ] := Doc_AllocateHandle( d )
   h[ "model_space_block_handle" ] := ms[ "handle" ] ; Tb_Add( d[ "block_records" ], ms )
   ps := Blk_PaperSpace() ; ps[ "handle" ] := Doc_AllocateHandle( d ) ; ps[ "block_entity_handle" ] := Doc_AllocateHandle( d ) ; ps[ "block_end_handle" ] := Doc_AllocateHandle( d )
   h[ "paper_space_block_handle" ] := ps[ "handle" ] ; Tb_Add( d[ "block_records" ], ps )
   dim := Dst_Standard() ; dim[ "handle" ] := Doc_AllocateHandle( d ) ; dim[ "dimtxsty_handle" ] := h[ "current_text_style_handle" ]
   h[ "current_dimstyle_handle" ] := dim[ "handle" ] ; h[ "dim_text_style_handle" ] := h[ "current_text_style_handle" ]
   h[ "dim_linetype_handle" ] := h[ "byblock_linetype_handle" ] ; h[ "dim_linetype1_handle" ] := h[ "byblock_linetype_handle" ] ; h[ "dim_linetype2_handle" ] := h[ "byblock_linetype_handle" ]
   Tb_Add( d[ "dim_styles" ], dim )
   ac := Aid_New( "ACAD" ) ; ac[ "handle" ] := Doc_AllocateHandle( d ) ; Tb_Add( d[ "app_ids" ], ac )
   an := Aid_New( "AcadAnnotative" ) ; an[ "handle" ] := Doc_AllocateHandle( d ) ; Tb_Add( d[ "app_ids" ], an )
   ct := Aid_New( "AcCmTransparency" ) ; ct[ "handle" ] := Doc_AllocateHandle( d ) ; Tb_Add( d[ "app_ids" ], ct )
   ld := Aid_New( Lyr_DescriptionApp() ) ; ld[ "handle" ] := Doc_AllocateHandle( d ) ; Tb_Add( d[ "app_ids" ], ld )
   av := Vpt_Active() ; av[ "handle" ] := Doc_AllocateHandle( d ) ; Tb_Add( d[ "vports" ], av )

   h[ "acad_group_dict_handle" ] := Doc_AllocateHandle( d ) ; h[ "acad_mlinestyle_dict_handle" ] := Doc_AllocateHandle( d )
   h[ "acad_layout_dict_handle" ] := Doc_AllocateHandle( d ) ; h[ "acad_plotsettings_dict_handle" ] := Doc_AllocateHandle( d )
   h[ "acad_plotstylename_dict_handle" ] := Doc_AllocateHandle( d ) ; h[ "acad_material_dict_handle" ] := Doc_AllocateHandle( d )
   h[ "acad_color_dict_handle" ] := Doc_AllocateHandle( d ) ; h[ "acad_visualstyle_dict_handle" ] := Doc_AllocateHandle( d )
   nMlDict := Doc_AllocateHandle( d ) ; nTbDict := Doc_AllocateHandle( d )   /* mleaderstyle dict, tablestyle dict */
   nMlStd := Doc_AllocateHandle( d ) ; nMleStd := Doc_AllocateHandle( d ) ; nTbStd := Doc_AllocateHandle( d )
   nModelL := Doc_AllocateHandle( d ) ; nPaperL := Doc_AllocateHandle( d ) ; nPlotPh := Doc_AllocateHandle( d )
   h[ "current_multiline_style_handle" ] := nMlStd
   x := Tb_Get( d[ "block_records" ], "*Model_Space" ) ; IF x != NIL ; x[ "layout" ] := nModelL ; ENDIF
   x := Tb_Get( d[ "block_records" ], "*Paper_Space" ) ; IF x != NIL ; x[ "layout" ] := nPaperL ; ENDIF

   nRoot := h[ "named_objects_dict_handle" ]
   x := Doc_NewDict( nRoot, Hd_Null() )
   Dic_AddEntry( x, "ACAD_GROUP", h[ "acad_group_dict_handle" ] ) ; Dic_AddEntry( x, "ACAD_MLINESTYLE", h[ "acad_mlinestyle_dict_handle" ] )
   Dic_AddEntry( x, "ACAD_LAYOUT", h[ "acad_layout_dict_handle" ] ) ; Dic_AddEntry( x, "ACAD_PLOTSETTINGS", h[ "acad_plotsettings_dict_handle" ] )
   Dic_AddEntry( x, "ACAD_PLOTSTYLENAME", h[ "acad_plotstylename_dict_handle" ] ) ; Dic_AddEntry( x, "ACAD_MATERIAL", h[ "acad_material_dict_handle" ] )
   Dic_AddEntry( x, "ACAD_COLOR", h[ "acad_color_dict_handle" ] ) ; Dic_AddEntry( x, "ACAD_VISUALSTYLE", h[ "acad_visualstyle_dict_handle" ] )
   Dic_AddEntry( x, "ACAD_MLEADERSTYLE", nMlDict ) ; Dic_AddEntry( x, "ACAD_TABLESTYLE", nTbDict )
   Doc_PutObj( d, x )
   Doc_PutObj( d, Doc_NewDict( h[ "acad_group_dict_handle" ], nRoot ) )

   x := Doc_NewDict( h[ "acad_mlinestyle_dict_handle" ], nRoot ) ; Dic_AddEntry( x, "Standard", nMlStd ) ; Doc_PutObj( d, x )
   mls := Mlsy_Standard() ; mls[ "handle" ] := nMlStd ; mls[ "owner" ] := h[ "acad_mlinestyle_dict_handle" ] ; Doc_PutObj( d, mls )

   x := Doc_NewDict( nMlDict, nRoot ) ; Dic_AddEntry( x, "Standard", nMleStd ) ; Doc_PutObj( d, x )
   mls := Mst_Standard() ; mls[ "handle" ] := nMleStd ; mls[ "owner_handle" ] := nMlDict ; mls[ "text_style_handle" ] := h[ "current_text_style_handle" ] ; Doc_PutObj( d, mls )

   x := Doc_NewDict( nTbDict, nRoot ) ; Dic_AddEntry( x, "Standard", nTbStd ) ; Doc_PutObj( d, x )
   ts := Tbsy_Standard() ; ts[ "handle" ] := nTbStd ; ts[ "owner_handle" ] := nTbDict ; Tbsy_SetAllTextStyles( ts, "Standard", h[ "current_text_style_handle" ] ) ; Doc_PutObj( d, ts )

   x := Doc_NewDict( h[ "acad_layout_dict_handle" ], nRoot ) ; Dic_AddEntry( x, "Model", nModelL ) ; Dic_AddEntry( x, "Layout1", nPaperL ) ; Doc_PutObj( d, x )
   lay := Lyo_New( "Model" ) ; lay[ "handle" ] := nModelL ; lay[ "owner" ] := h[ "acad_layout_dict_handle" ] ; lay[ "tab_order" ] := 0 ; lay[ "flags" ] := 1 ; lay[ "block_record" ] := h[ "model_space_block_handle" ] ; Doc_PutObj( d, lay )
   lay := Lyo_New( "Layout1" ) ; lay[ "handle" ] := nPaperL ; lay[ "owner" ] := h[ "acad_layout_dict_handle" ] ; lay[ "tab_order" ] := 1 ; lay[ "block_record" ] := h[ "paper_space_block_handle" ] ; Doc_PutObj( d, lay )

   Doc_PutObj( d, Doc_NewDict( h[ "acad_plotsettings_dict_handle" ], nRoot ) )
   Doc_PutObj( d, Doc_NewDict( h[ "acad_material_dict_handle" ], nRoot ) )
   Doc_PutObj( d, Doc_NewDict( h[ "acad_color_dict_handle" ], nRoot ) )
   Doc_PutObj( d, Doc_NewDict( h[ "acad_visualstyle_dict_handle" ], nRoot ) )

   x := Ddf_New() ; x[ "handle" ] := h[ "acad_plotstylename_dict_handle" ] ; x[ "owner" ] := nRoot ; x[ "default_handle" ] := nPlotPh
   AAdd( x[ "entries" ], { "Normal", nPlotPh } ) ; Doc_PutObj( d, x )
   x := Plhd_New() ; x[ "handle" ] := nPlotPh ; x[ "owner" ] := h[ "acad_plotstylename_dict_handle" ] ; Doc_PutObj( d, x )

   Doc_AddStdClass( d, "ACDBDICTIONARYWDFLT", "AcDbDictionaryWithDefault" )
   Doc_AddStdClass( d, "DICTIONARYVAR", "AcDbDictionaryVar" )
   Doc_AddStdClass( d, "LAYOUT", "AcDbLayout" )
   Doc_AddStdClass( d, "ACDBPLACEHOLDER", "AcDbPlaceHolder" )
   Doc_AddStdClass( d, "PLOTSETTINGS", "AcDbPlotSettings" )
   Doc_AddStdClass( d, "SCALE", "AcDbScale" )
   Dcc_UpdateDefaults( d[ "classes" ] )
RETURN

PROCEDURE Doc_RegisterObjectContextClass( d, cDxf )
   LOCAL cCpp, cl
   SWITCH cDxf
   CASE "ACDB_BLKREFOBJECTCONTEXTDATA_CLASS" ; cCpp := "AcDbBlkRefObjectContextData" ; EXIT
   CASE "ACDB_TEXTOBJECTCONTEXTDATA_CLASS" ; cCpp := "AcDbTextObjectContextData" ; EXIT
   CASE "ACDB_MTEXTOBJECTCONTEXTDATA_CLASS" ; cCpp := "AcDbMTextObjectContextData" ; EXIT
   CASE "ACDB_ALDIMOBJECTCONTEXTDATA_CLASS" ; cCpp := "AcDbAlignedDimensionObjectContextData" ; EXIT
   CASE "ACDB_ANGDIMOBJECTCONTEXTDATA_CLASS" ; cCpp := "AcDbAngularDimensionObjectContextData" ; EXIT
   CASE "ACDB_DMDIMOBJECTCONTEXTDATA_CLASS" ; cCpp := "AcDbDiametricDimensionObjectContextData" ; EXIT
   CASE "ACDB_RADIMOBJECTCONTEXTDATA_CLASS" ; cCpp := "AcDbRadialDimensionObjectContextData" ; EXIT
   CASE "ACDB_RADIMLGOBJECTCONTEXTDATA_CLASS" ; cCpp := "AcDbRadialDimensionLargeObjectContextData" ; EXIT
   CASE "ACDB_ORDDIMOBJECTCONTEXTDATA_CLASS" ; cCpp := "AcDbOrdinateDimensionObjectContextData" ; EXIT
   CASE "ACDB_HATCHSCALECONTEXTDATA_CLASS" ; cCpp := "AcDbHatchScaleContextData" ; EXIT
   CASE "ACDB_HATCHVIEWCONTEXTDATA_CLASS" ; cCpp := "AcDbHatchViewContextData" ; EXIT
   OTHERWISE ; RETURN
   ENDSWITCH
   IF Dcc_GetByName( d[ "classes" ], cDxf ) != NIL ; RETURN ; ENDIF
   /* Erase | Cloning | DisablesProxyWarningDialog */
   cl := Dcl_New( cDxf, cCpp ) ; cl[ "proxy_flags" ] := PXF_ERASE_ALLOWED + PXF_CLONING_ALLOWED + PXF_DISABLES_PROXY_WARNING_DIALOG
   Dcc_AddOrUpdate( d[ "classes" ], cl )
RETURN
