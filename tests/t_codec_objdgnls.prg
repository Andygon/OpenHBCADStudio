/* Tests: dgn_linestyle.rs no tiene #[test]; todos [extra] */
#include "ocx.ch"
PROCEDURE T_CodecObjDgnLs()
   LOCAL o, c, r, k, i, aN
   Chk( Dlt_FromCode( 1 ) == DLT_SYMBOL .AND. Dlt_FromCode( 2 ) == DLT_COMPOUND .AND. Dlt_FromCode( 3 ) == DLT_STROKE .AND. Dlt_FromCode( 4 ) == DLT_POINT ;
      .AND. Dlt_FromCode( 6 ) == DLT_INTERNAL .AND. Dlt_FromCode( 5 ) == NIL .AND. Dlt_FromCode( 0 ) == NIL .AND. Dlt_Code( DLT_INTERNAL ) == 6, "[extra] component type codes" )
   Chk( Dlp_FromCode( 0 ) == DLP_DISTANCE .AND. Dlp_FromCode( 1 ) == DLP_FRACTION .AND. Dlp_FromCode( 2 ) == DLP_CENTERED .AND. Dlp_FromCode( 3 ) == DLP_RESERVED .AND. Dlp_FromCode( 6 ) == DLP_CENTERED .AND. Dlp_Code( DLP_RESERVED ) == 3, "[extra] phase mode & 3" )
   o := Dlo_New( hb_Hash( "_kind", "Definition" ) ) ; Chk( Dlo_DxfName( o ) == "LSDEFINITION", "[extra] dxf_name definition" )
   aN := { "LSSYMBOLCOMPONENT", "LSCOMPOUNDCOMPONENT", "LSSTROKEPATTERNCOMPONENT", "LSPOINTCOMPONENT", "LSINTERNALCOMPONENT" }
   k := { DLT_SYMBOL, DLT_COMPOUND, DLT_STROKE, DLT_POINT, DLT_INTERNAL }
   FOR i := 1 TO 5
      o := Dlo_New( hb_Hash( "_kind", "Component", "kind", k[ i ] ) ) ; Chk( Dlo_DxfName( o ) == aN[ i ], "[extra] dxf_name " + aN[ i ] )
   NEXT
   o := Dlo_New( hb_Hash( "_kind", "Registered", "dxf_name", "LSFOO" ) ) ; Chk( Dlo_DxfName( o ) == "LSFOO" .AND. o[ "handle" ] == Hd_Null(), "[extra] dxf_name registered" )
   c := hb_Hash( "_kind", "Symbol", "value", hb_Hash( "block", 0x30 ) ) ; r := Dcd_References( c ) ; Chk( Len( r ) == 1 .AND. r[ 1 ] == 0x30, "[extra] references symbol" )
   c := hb_Hash( "_kind", "Compound", "value", hb_Hash( "entries", { hb_Hash( "component", 0x41, "offset", 1.0 ), hb_Hash( "component", 0x42, "offset", 2.0 ) } ) ) ; r := Dcd_References( c )
   Chk( Len( r ) == 2 .AND. r[ 1 ] == 0x41 .AND. r[ 2 ] == 0x42, "[extra] references compound" )
   c := hb_Hash( "_kind", "Point", "value", hb_Hash( "stroke_component", 0x50, "symbols", { hb_Hash( "symbol_component", 0x51 ), hb_Hash( "symbol_component", 0x52 ) } ) ) ; r := Dcd_References( c )
   Chk( Len( r ) == 3 .AND. r[ 1 ] == 0x50 .AND. r[ 2 ] == 0x51 .AND. r[ 3 ] == 0x52, "[extra] references point" )
   Chk( Len( Dcd_References( hb_Hash( "_kind", "Stroke", "value", hb_Hash() ) ) ) == 0 .AND. Len( Dcd_References( hb_Hash( "_kind", "Internal", "value", hb_Hash() ) ) ) == 0, "[extra] references stroke/internal vacias" )
   c := hb_Hash( "component_type", DLT_SYMBOL, "refs", { 0x60, 0x61 } ) ; Chk( Dlk_SymbolBlock( c ) == 0x60, "[extra] symbol_block" )
   c := hb_Hash( "component_type", DLT_STROKE, "refs", { 0x60 } ) ; Chk( Dlk_SymbolBlock( c ) == NIL, "[extra] symbol_block no symbol" )
   c := hb_Hash( "component_type", DLT_SYMBOL, "refs", {} ) ; Chk( Dlk_SymbolBlock( c ) == NIL, "[extra] symbol_block sin refs" )
RETURN
