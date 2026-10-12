/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/tb_block.prg
   Origen Rust: opencadcodec/src/tables/block_record.rs (258 lineas, 4 tests). Licencia del original: MPL-2.0.
   Prefijos: Bkf_ (BlockFlags), Blk_ (BlockRecord). Vec<u8> -> cadena de bytes; Vec<Handle> -> array.
   Comparacion "eq_ignore_ascii_case" -> Upper() sobre prefijo ASCII (nombres con bytes no ASCII no coinciden con el literal en ningun caso).
   design_center_units_values / design_center_units: pub(crate) en Rust; xdata como XDataValue (XV_*).
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define DESIGN_CENTER_DATA "DesignCenter Data"

FUNCTION Bkf_New() ; RETURN hb_Hash( "anonymous", .F., "has_attributes", .F., "is_xref", .F., "is_xref_overlay", .F., "is_external", .F., "is_xref_unloaded", .F. )

FUNCTION Blk_New( cName )
RETURN hb_Hash( "handle", Hd_Null(), "block_entity_handle", Hd_Null(), "block_end_handle", Hd_Null(), "name", cName, "flags", Bkf_New(), "layout", Hd_Null(), "units", 0, ;
   "explodable", .T., "scale_uniformly", .F., "entity_handles", {}, "xref_path", "", "description", "", "insert_count_bytes", "", "preview_data", "", "insert_handles", {}, "base_point", Vc3_Zero() )
FUNCTION Blk_ModelSpace() ; RETURN Blk_New( "*Model_Space" )
FUNCTION Blk_PaperSpace() ; RETURN Blk_New( "*Paper_Space" )
FUNCTION Blk_IsModelSpace( b ) ; RETURN Upper( b[ "name" ] ) == "*MODEL_SPACE"
FUNCTION Blk_IsPaperSpace( b ) ; RETURN Len( b[ "name" ] ) >= 12 .AND. Upper( Left( b[ "name" ], 12 ) ) == "*PAPER_SPACE"
FUNCTION Blk_IsLayout( b ) ; RETURN ! Hd_IsNull( b[ "layout" ] )
FUNCTION Blk_IsAnonymous( b ) ; RETURN b[ "flags" ][ "anonymous" ] .OR. Left( b[ "name" ], 1 ) == "*"
FUNCTION Blk_IsStandard( b ) ; RETURN Blk_IsModelSpace( b ) .OR. Blk_IsPaperSpace( b )

FUNCTION Blk_DesignCenterUnitsValues( nUnits )
RETURN { Xv_New( XV_STRING, DESIGN_CENTER_DATA ), Xv_New( XV_CONTROLSTRING, "{" ), Xv_New( XV_INTEGER16, 1 ), Xv_New( XV_INTEGER16, nUnits ), Xv_New( XV_CONTROLSTRING, "}" ) }

/* Devuelve NIL si el patron [String(DESIGN_CENTER_DATA), Control, I16, I16, ..] no encaja */
FUNCTION Blk_DesignCenterUnits( aValues )
   IF Len( aValues ) >= 4 .AND. aValues[ 1 ][ 1 ] == XV_STRING .AND. aValues[ 1 ][ 2 ] == DESIGN_CENTER_DATA .AND. aValues[ 2 ][ 1 ] == XV_CONTROLSTRING ;
      .AND. aValues[ 3 ][ 1 ] == XV_INTEGER16 .AND. aValues[ 4 ][ 1 ] == XV_INTEGER16
      RETURN aValues[ 4 ][ 2 ]
   ENDIF
RETURN NIL
