/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/tb_dimstyle.prg
   Origen Rust: opencadcodec/src/tables/dimstyle.rs (401 lineas; sin #[test] en Rust, tests [extra] en t_codec_tables6.prg). Licencia del original: MPL-2.0.
   Prefijo: Dst_ (DimStyle). Generado mecanicamente desde DimStyle::new; Option<Color> -> NIL; dimjogang = PI/4 (FRAC_PI_4).
   Dst_DxfDefaults aplica los mismos overrides que dxf_defaults (struct update ..Self::new(name)).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Dst_New( cName )
RETURN hb_Hash( ;
   "handle", Hd_Null(), ;
   "name", cName, ;
   "xref_reference", .F., ;
   "xref_resolved", .F., ;
   "xref_dependent", .F., ;
   "xref_handle", Hd_Null(), ;
   "dimclrd", 0, ;
   "dimclrd_true_color", NIL, ;
   "dimdle", 0.0, ;
   "dimdli", 3.75, ;
   "dimgap", 0.625, ;
   "dimlwd", -2, ;
   "dimsd1", .F., ;
   "dimsd2", .F., ;
   "dimclre", 0, ;
   "dimclre_true_color", NIL, ;
   "dimexe", 1.25, ;
   "dimexo", 0.625, ;
   "dimlwe", -2, ;
   "dimse1", .F., ;
   "dimse2", .F., ;
   "dimfxl", 1.0, ;
   "dimfxlon", .F., ;
   "dimasz", 0.18, ;
   "dimblk", Hd_Null(), ;
   "dimblk1", Hd_Null(), ;
   "dimblk2", Hd_Null(), ;
   "dimldrblk", Hd_Null(), ;
   "dimblk_name", "", ;
   "dimblk1_name", "", ;
   "dimblk2_name", "", ;
   "dimsah", .T., ;
   "dimcen", 0.09, ;
   "dimtsz", 0.0, ;
   "dimclrt", 0, ;
   "dimclrt_true_color", NIL, ;
   "dimtxt", 0.18, ;
   "dimjust", 0, ;
   "dimtad", 1, ;
   "dimtvp", 0.0, ;
   "dimtih", .F., ;
   "dimtoh", .F., ;
   "dimtix", .F., ;
   "dimsoxd", .F., ;
   "dimtfill", 0, ;
   "dimtfillclr", 0, ;
   "dimtfillclr_true_color", NIL, ;
   "dimtmove", 0, ;
   "dimtxtdirection", .F., ;
   "dimaltmzf", 0.0, ;
   "dimaltmzs", "", ;
   "dimmzf", 0.0, ;
   "dimmzs", "", ;
   "dimtxsty_handle", Hd_Null(), ;
   "dimtxsty", "Standard", ;
   "dimscale", 1.0, ;
   "dimlfac", 1.0, ;
   "dimlunit", 2, ;
   "dimdec", 2, ;
   "dimrnd", 0.0, ;
   "dimdsep", 46, ;
   "dimzin", 8, ;
   "dimaunit", 0, ;
   "dimadec", 0, ;
   "dimazin", 0, ;
   "dimalt", .F., ;
   "dimaltf", 25.4, ;
   "dimaltd", 3, ;
   "dimaltu", 2, ;
   "dimalttd", 3, ;
   "dimaltrnd", 0.0, ;
   "dimapost", "", ;
   "dimaltz", 0, ;
   "dimalttz", 0, ;
   "dimtol", .F., ;
   "dimlim", .F., ;
   "dimtp", 0.0, ;
   "dimtm", 0.0, ;
   "dimtdec", 2, ;
   "dimtfac", 1.0, ;
   "dimtolj", 0, ;
   "dimtzin", 8, ;
   "dimatfit", 3, ;
   "dimtofl", .F., ;
   "dimupt", .F., ;
   "dimfit", 0, ;
   "dimpost", "<>", ;
   "dimfrac", 0, ;
   "dimarcsym", 0, ;
   "dimjogang", OCX_PI / 4.0, ;
   "dimltex_handle", Hd_Null(), ;
   "dimltex1_handle", Hd_Null(), ;
   "dimltex2_handle", Hd_Null(), ;
   "dimunit", 2, ;
   "annotative", .F. )

FUNCTION Dst_Standard() ; RETURN Dst_New( "Standard" )
FUNCTION Dst_IsStandard( d ) ; RETURN d[ "name"] == "Standard"

FUNCTION Dst_DxfDefaults( cName )
   LOCAL d := Dst_New( cName )
   d[ "dimdli" ] := 0.38 ; d[ "dimgap" ] := 0.09 ; d[ "dimexe" ] := 0.18 ; d[ "dimexo" ] := 0.0625 ; d[ "dimsah" ] := .F. ; d[ "dimtad" ] := 0
   d[ "dimtih" ] := .T. ; d[ "dimtoh" ] := .T. ; d[ "dimdec" ] := 4 ; d[ "dimtdec" ] := 4 ; d[ "dimzin" ] := 0 ; d[ "dimtzin" ] := 0
   d[ "dimaltd" ] := 2 ; d[ "dimalttd" ] := 2 ; d[ "dimtolj" ] := 1
RETURN d
