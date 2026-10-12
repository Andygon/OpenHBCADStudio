/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/tb_layer.prg
   Origen Rust: opencadcodec/src/tables/appid.rs (51), vx.rs (69), ucs.rs (108), layer.rs (222); ninguno tiene #[test] en Rust (tests [extra] en t_codec_tables2.prg). Licencia del original: MPL-2.0.
   Prefijos: Aid_ (AppId), Vxr_ (VxTableRecord), Ucs_ (Ucs), Lfl_ (LayerFlags), Lyr_ (Layer). Entradas = hash con "handle" y "name" (ver tb_table.prg).
   is_standard del trait TableEntry: Aid_IsStandard / Lyr_IsStandard; las demas devuelven .F. (valor por defecto).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Aid_New( cName ) ; RETURN hb_Hash( "handle", Hd_Null(), "name", cName )
FUNCTION Aid_Acad() ; RETURN Aid_New( "ACAD" )
FUNCTION Aid_IsStandard( e ) ; RETURN e[ "name" ] == "ACAD"

FUNCTION Vxr_New( cName )
RETURN hb_Hash( "handle", Hd_Null(), "name", cName, "is_xref_reference", .F., "is_xref_resolved", .F., "is_xref_dependent", .F., "xref_handle", Hd_Null(), "is_on", .F., ;
   "viewport", Hd_Null(), "previous_entry", Hd_Null(), "legacy_viewport_entity_address", 0, "legacy_viewport_index", 0, "legacy_previous_entry_index", 0 )
FUNCTION Vxr_Default() ; RETURN Vxr_New( "" )

FUNCTION Ucs_New( cName )
RETURN hb_Hash( "handle", Hd_Null(), "name", cName, "origin", Vc3_Zero(), "x_axis", Vc3_UnitX(), "y_axis", Vc3_UnitY(), "elevation", 0.0, "ortho_view_type", 0, "ortho_type", 0, ;
   "named_ucs_handle", Hd_Null(), "base_ucs_handle", Hd_Null(), "xref_reference", .F., "xref_resolved", .F., "xref_dependent", .F., "xref_handle", Hd_Null() )
FUNCTION Ucs_FromOriginAxes( cName, vOrigin, vX, vY )
   LOCAL u := Ucs_New( cName )
   u[ "origin" ] := vOrigin ; u[ "x_axis" ] := vX ; u[ "y_axis" ] := vY
RETURN u
FUNCTION Ucs_ZAxis( u ) ; RETURN Vc3_Cross( u[ "x_axis" ], u[ "y_axis" ] )

FUNCTION Lfl_New() ; RETURN hb_Hash( "frozen", .F., "locked", .F., "frozen_in_new_viewport", .F., "off", .F., "xref_dependent", .F. )
FUNCTION Lfl_Standard() ; RETURN Lfl_New()
FUNCTION Lyr_DescriptionApp() ; RETURN "AcAecLayerStandard"

FUNCTION Lyr_New( cName )
RETURN hb_Hash( "handle", Hd_Null(), "name", cName, "flags", Lfl_New(), "color", Cl_White(), "color_name", NIL, "book_name", NIL, "line_type", "Continuous", "line_weight", Lw_Default(), ;
   "plot_style", "", "is_plottable", .T., "transparency", Tp_Opaque(), "description", "", "material", Hd_Null(), "plotstyle_handle", Hd_Null(), "xref_block_record_handle", Hd_Null() )
FUNCTION Lyr_Layer0() ; LOCAL l := Lyr_New( "0" ) ; l[ "flags" ] := Lfl_Standard() ; RETURN l
FUNCTION Lyr_WithColor( cName, c ) ; LOCAL l := Lyr_New( cName ) ; l[ "color" ] := c ; RETURN l
FUNCTION Lyr_Freeze( l ) ; l[ "flags" ][ "frozen" ] := .T. ; RETURN NIL
FUNCTION Lyr_Thaw( l ) ; l[ "flags" ][ "frozen" ] := .F. ; RETURN NIL
FUNCTION Lyr_IsFrozen( l ) ; RETURN l[ "flags" ][ "frozen" ]
FUNCTION Lyr_Lock( l ) ; l[ "flags" ][ "locked" ] := .T. ; RETURN NIL
FUNCTION Lyr_Unlock( l ) ; l[ "flags" ][ "locked" ] := .F. ; RETURN NIL
FUNCTION Lyr_IsLocked( l ) ; RETURN l[ "flags" ][ "locked" ]
FUNCTION Lyr_TurnOff( l ) ; l[ "flags" ][ "off" ] := .T. ; RETURN NIL
FUNCTION Lyr_TurnOn( l ) ; l[ "flags" ][ "off" ] := .F. ; RETURN NIL
FUNCTION Lyr_IsOff( l ) ; RETURN l[ "flags" ][ "off" ]
FUNCTION Lyr_IsVisible( l ) ; RETURN ! l[ "flags" ][ "off" ] .AND. ! l[ "flags" ][ "frozen" ]
FUNCTION Lyr_IsStandard( l ) ; RETURN l[ "name" ] == "0"
