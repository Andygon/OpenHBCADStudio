/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_base.prg
   Origen Rust: opencadcodec/src/objects/mod.rs (713 lineas): Dictionary, Layout y los metodos de ObjectType (preserve_storage_data_from, set_handle, has_null_handle).
   Licencia del original: MPL-2.0. Prefijos: Dic_ (Dictionary), Lyo_ (Layout), Obj_ (ObjectType).
   Modelo: un objeto es un hash con los nombres de campo de Rust mas "_type" (nombre de la variante de ObjectType). Tuplas (a,b,c) -> arrays { a, b, c }.
   Dictionary.entries = array de { cKey, nHandle }. Layout se completa aqui con Layout::new generado mecanicamente (todos los campos, mismo orden).
   TableContent guarda el handle en ["common"]["handle"] (EntityCommon de la tabla); Unknown lo guarda en "handle".
   Tests Rust del fichero (4) en t_codec_objbase.prg. Las variantes se van anadiendo a Obj_* conforme se portan los ficheros de objects/.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Dic_New()
RETURN hb_Hash( "_type", "Dictionary", "handle", Hd_Null(), "owner", Hd_Null(), "entries", {}, "hard_owner_entries", {}, "duplicate_cloning", 1, "hard_owner", .F., "reactors", {}, "xdictionary_handle", NIL )
FUNCTION Dic_AddEntry( d, cKey, nHandle ) ; AAdd( d[ "entries" ], { cKey, nHandle } ) ; RETURN NIL
FUNCTION Dic_SetEntryHardOwner( d, cKey, lHard )
   LOCAL a := {}, n
   FOR EACH n IN d[ "hard_owner_entries" ]
      IF ! Upper( n ) == Upper( cKey ) ; AAdd( a, n ) ; ENDIF
   NEXT
   d[ "hard_owner_entries" ] := a
   IF lHard ; AAdd( a, cKey ) ; ENDIF
RETURN NIL
FUNCTION Dic_IsEntryHardOwner( d, cKey )
   LOCAL n
   FOR EACH n IN d[ "hard_owner_entries" ]
      IF Upper( n ) == Upper( cKey ) ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.
FUNCTION Dic_IsCanonicalHardOwnerKey( cKey ) ; RETURN Upper( cKey ) == "ACAD_FIELD"
FUNCTION Dic_Get( d, cKey )
   LOCAL e
   FOR EACH e IN d[ "entries" ]
      IF Upper( e[ 1 ] ) == Upper( cKey ) ; RETURN e[ 2 ] ; ENDIF
   NEXT
RETURN NIL
FUNCTION Dic_Len( d ) ; RETURN Len( d[ "entries" ] )
FUNCTION Dic_IsEmpty( d ) ; RETURN Len( d[ "entries" ] ) == 0

FUNCTION Lyo_New( cName )
RETURN hb_Hash( "_type", "Layout", ;
   "handle", Hd_Null(), ;
   "owner", Hd_Null(), ;
   "name", cName, ;
   "flags", 0, ;
   "tab_order", 0, ;
   "min_limits", { 0.0, 0.0 }, ;
   "max_limits", { 0.0, 0.0 }, ;
   "insertion_base", { 0.0, 0.0, 0.0 }, ;
   "min_extents", { 0.0, 0.0, 0.0 }, ;
   "max_extents", { 12.0, 9.0, 0.0 }, ;
   "elevation", 0.0, ;
   "ucs_origin", { 0.0, 0.0, 0.0 }, ;
   "ucs_x_axis", { 1.0, 0.0, 0.0 }, ;
   "ucs_y_axis", { 0.0, 1.0, 0.0 }, ;
   "ucs_ortho_type", 0, ;
   "block_record", Hd_Null(), ;
   "viewport", Hd_Null(), ;
   "viewports", {}, ;
   "base_ucs", Hd_Null(), ;
   "named_ucs", Hd_Null(), ;
   "reactors", {}, ;
   "xdictionary_handle", NIL, ;
   "raw_plot_settings_codes", NIL, ;
   "paper_width", 0.0, ;
   "paper_height", 0.0, ;
   "plot_rotation", 0, ;
   "plot_flags", Pfl_New(), ;
   "plot_page_name", "", ;
   "plot_printer_name", "", ;
   "paper_size", "", ;
   "plot_view_name", "", ;
   "plot_style_sheet", "", ;
   "plot_margin_left", 0.0, ;
   "plot_margin_bottom", 0.0, ;
   "plot_margin_right", 0.0, ;
   "plot_margin_top", 0.0, ;
   "plot_origin_x", 0.0, ;
   "plot_origin_y", 0.0, ;
   "plot_window_min_x", 0.0, ;
   "plot_window_min_y", 0.0, ;
   "plot_window_max_x", 0.0, ;
   "plot_window_max_y", 0.0, ;
   "plot_paper_units", 0, ;
   "plot_type", 5, ;
   "plot_scale_numerator", 1.0, ;
   "plot_scale_denominator", 1.0, ;
   "plot_scale_type", 0, ;
   "plot_scale_factor", 1.0, ;
   "paper_image_origin_x", 0.0, ;
   "paper_image_origin_y", 0.0, ;
   "shade_plot_mode", 0, ;
   "shade_plot_resolution", 0, ;
   "shade_plot_dpi", 300, ;
   "plot_view_handle", Hd_Null(), ;
   "visual_style_handle", Hd_Null() )

/* ObjectType::preserve_storage_data_from: copia solo si ambos objetos son de la misma variante */
PROCEDURE Obj_PreserveStorageDataFrom( o, src )
   LOCAL t := o[ "_type" ]
   IF ! t == src[ "_type" ] ; RETURN ; ENDIF
   DO CASE
   CASE t == "Layout"
      o[ "raw_plot_settings_codes" ] := Obj_CloneOpt( src[ "raw_plot_settings_codes" ] )
   CASE t == "XRecord"
      o[ "raw_dwg_data" ] := src[ "raw_dwg_data" ] ; o[ "raw_dwg_version" ] := src[ "raw_dwg_version" ]
   CASE t == "TableStyle"
      o[ "raw_dxf_codes" ] := Obj_CloneOpt( src[ "raw_dxf_codes" ] )
   CASE t == "SortEntitiesTable"
      o[ "raw_dxf_codes" ] := Obj_CloneOpt( src[ "raw_dxf_codes" ] ) ; o[ "raw_dxf_version" ] := src[ "raw_dxf_version" ]
   CASE t == "Associative"
      o[ "source_version" ] := src[ "source_version" ]
   CASE t == "ClassObject"
      IF o[ "data" ][ "_type" ] == "CsacDocumentOptions" .AND. src[ "data" ][ "_type" ] == "CsacDocumentOptions"
         o[ "data" ][ "raw_dwg_data" ] := src[ "data" ][ "raw_dwg_data" ] ; o[ "data" ][ "raw_dwg_version" ] := src[ "data" ][ "raw_dwg_version" ]
      ENDIF
   CASE t == "RegisteredClass"
      o[ "raw_dwg_data" ] := src[ "raw_dwg_data" ] ; o[ "raw_dwg_version" ] := src[ "raw_dwg_version" ]
   CASE t == "Unknown"
      o[ "raw_dxf_codes" ] := Obj_CloneOpt( src[ "raw_dxf_codes" ] ) ; o[ "raw_dwg_data" ] := src[ "raw_dwg_data" ] ; o[ "raw_dwg_version" ] := src[ "raw_dwg_version" ]
   ENDCASE
RETURN

/* Option<Vec<..>>.clone(): copia profunda de arrays de arrays (NIL se queda NIL) */
FUNCTION Obj_CloneOpt( x )
   LOCAL a, i
   IF ! ValType( x ) == "A" ; RETURN x ; ENDIF
   a := AClone( x )
   FOR i := 1 TO Len( a )
      a[ i ] := Obj_CloneOpt( a[ i ] )
   NEXT
RETURN a

PROCEDURE Obj_SetHandle( o, nHandle )
   IF o[ "_type" ] == "TableContent"
      o[ "common" ][ "handle" ] := nHandle
   ELSE
      o[ "handle" ] := nHandle
   ENDIF
RETURN
FUNCTION Obj_HasNullHandle( o )
RETURN Hd_IsNull( iif( o[ "_type" ] == "TableContent", o[ "common" ][ "handle" ], o[ "handle" ] ) )

FUNCTION Obj_NewUnknown( cTypeName, nHandle, nOwner )
RETURN hb_Hash( "_type", "Unknown", "type_name", cTypeName, "handle", nHandle, "owner", nOwner, "raw_dxf_codes", NIL, "raw_dwg_data", NIL, "raw_dwg_handle_bits", 0, "raw_dwg_version", NIL )
