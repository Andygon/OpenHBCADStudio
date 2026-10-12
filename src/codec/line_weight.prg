/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/line_weight.prg
   Origen Rust: opencadcodec/src/types/line_weight.rs (208 lineas, 8 tests en t_codec_types2.prg)
   LineWeight = { nKind, nValue } con LK_* (ocx.ch). Constantes W0_25 etc -> Lw_Value( 25 ).
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION Lw_Indexed() ; RETURN { 0, 5, 9, 13, 15, 18, 20, 25, 30, 35, 40, 50, 53, 60, 70, 80, 90, 100, 106, 120, 140, 158, 200, 211 }

FUNCTION Lw_ByLayer() ; RETURN { LK_BYLAYER, 0 }
FUNCTION Lw_ByBlock() ; RETURN { LK_BYBLOCK, 0 }
FUNCTION Lw_Default() ; RETURN { LK_DEFAULT, 0 }
FUNCTION Lw_Value( n ) ; RETURN { LK_VALUE, n }
FUNCTION Lw_Eq( a, b ) ; RETURN a[1] == b[1] .AND. a[2] == b[2]

FUNCTION Lw_FromValue( n )
   DO CASE
   CASE n == -1 ; RETURN Lw_ByLayer()
   CASE n == -2 ; RETURN Lw_ByBlock()
   CASE n == -3 ; RETURN Lw_Default()
   ENDCASE
RETURN Lw_Value( n )

FUNCTION Lw_GetValue( w )
   DO CASE
   CASE w[1] == LK_BYLAYER ; RETURN -1
   CASE w[1] == LK_BYBLOCK ; RETURN -2
   CASE w[1] == LK_DEFAULT ; RETURN -3
   ENDCASE
RETURN w[2]

FUNCTION Lw_ToDwgIndex( w )
   LOCAL n
   DO CASE
   CASE w[1] == LK_DEFAULT ; RETURN 31
   CASE w[1] == LK_BYBLOCK ; RETURN 30
   CASE w[1] == LK_BYLAYER ; RETURN 29
   ENDCASE
   n := AScan( Lw_Indexed(), {| v | v == w[2] } )
RETURN IIf( n == 0, 31, n - 1 )

FUNCTION Lw_FromDwgIndex( i )
   IF i == 28 .OR. i == 29 ; RETURN Lw_ByLayer() ; ENDIF
   IF i == 30 ; RETURN Lw_ByBlock() ; ENDIF
   IF i == 31 ; RETURN Lw_Default() ; ENDIF
   IF i < Len( Lw_Indexed() ) ; RETURN Lw_Value( Lw_Indexed()[ i + 1 ] ) ; ENDIF
RETURN Lw_Default()

FUNCTION Lw_Millimeters( w ) ; RETURN IIf( w[1] == LK_VALUE, w[2] / 100.0, NIL )

FUNCTION Lw_Display( w )
   DO CASE
   CASE w[1] == LK_BYLAYER ; RETURN "ByLayer"
   CASE w[1] == LK_BYBLOCK ; RETURN "ByBlock"
   CASE w[1] == LK_DEFAULT ; RETURN "Default"
   ENDCASE
RETURN LTrim( Str( w[2] / 100.0, 10, 2 ) ) + "mm"
