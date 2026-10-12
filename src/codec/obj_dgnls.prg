/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_dgnls.prg
   Origen Rust: opencadcodec/src/objects/dgn_linestyle.rs (285 lineas, sin tests en Rust). Licencia del original: MPL-2.0.
   Prefijos: Dlt_ (DgnLsComponentType, constantes DLT_* en ocx.ch), Dlp_ (DgnLsPhaseMode, DLP_*), Dlo_ (DgnLineStyleObject + DgnLineStyleData),
             Dcd_ (DgnLsComponentData), Dlk_ (DgnLsComponent).
   Los structs de datos son hashes con los nombres de campo de Rust. Los enums con payload son hashes con "_kind" = nombre de la variante:
     DgnLineStyleData: "Definition" | "Component" | "Registered";  DgnLsComponentData: "Symbol"|"Compound"|"Stroke"|"Point"|"Internal" y "value" = struct.
   component_uid [u8;16] -> cadena de 16 bytes. Los tests son [extra]: el fichero Rust no tiene #[test].
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Dlt_FromCode( n )
   SWITCH n
   CASE 1 ; RETURN DLT_SYMBOL
   CASE 2 ; RETURN DLT_COMPOUND
   CASE 3 ; RETURN DLT_STROKE
   CASE 4 ; RETURN DLT_POINT
   CASE 6 ; RETURN DLT_INTERNAL
   ENDSWITCH
RETURN NIL
FUNCTION Dlt_Code( n ) ; RETURN n

FUNCTION Dlp_FromCode( n ) ; RETURN hb_bitAnd( n, 3 )
FUNCTION Dlp_Code( n ) ; RETURN n

FUNCTION Dlo_New( hData )
RETURN hb_Hash( "_type", "DgnLineStyleObject", "handle", Hd_Null(), "owner", Hd_Null(), "reactors", {}, "xdictionary_handle", NIL, "data", hData )

FUNCTION Dlo_DxfName( o )
   LOCAL d := o[ "data" ]
   SWITCH d[ "_kind" ]
   CASE "Definition" ; RETURN "LSDEFINITION"
   CASE "Component"
      SWITCH d[ "kind" ]
      CASE DLT_SYMBOL   ; RETURN "LSSYMBOLCOMPONENT"
      CASE DLT_COMPOUND ; RETURN "LSCOMPOUNDCOMPONENT"
      CASE DLT_STROKE   ; RETURN "LSSTROKEPATTERNCOMPONENT"
      CASE DLT_POINT    ; RETURN "LSPOINTCOMPONENT"
      CASE DLT_INTERNAL ; RETURN "LSINTERNALCOMPONENT"
      ENDSWITCH
      EXIT
   CASE "Registered" ; RETURN d[ "dxf_name" ]
   ENDSWITCH
RETURN NIL

/* DgnLsComponentData::references -> array de handles */
FUNCTION Dcd_References( c )
   LOCAL v := c[ "value" ], a := {}, e, s
   SWITCH c[ "_kind" ]
   CASE "Symbol"
      AAdd( a, v[ "block" ] )
      EXIT
   CASE "Compound"
      FOR EACH e IN v[ "entries" ]
         AAdd( a, e[ "component" ] )
      NEXT
      EXIT
   CASE "Point"
      AAdd( a, v[ "stroke_component" ] )
      FOR EACH s IN v[ "symbols" ]
         AAdd( a, s[ "symbol_component" ] )
      NEXT
      EXIT
   ENDSWITCH
RETURN a

/* DgnLsComponent::symbol_block -> handle o NIL */
FUNCTION Dlk_SymbolBlock( k )
   IF k[ "component_type" ] == DLT_SYMBOL .AND. Len( k[ "refs" ] ) > 0
      RETURN k[ "refs" ][ 1 ]
   ENDIF
RETURN NIL
