/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/color.prg
   Origen Rust: opencadcodec/src/types/color.rs (231 lineas, 11 tests en t_codec_types.prg)
   Color = { nKind, a, b, c } con CK_* (ocx.ch): ByLayer/None/ByBlock sin datos; Index -> a = indice;
   Rgb -> a,b,c. El default es ByLayer. Option<..> -> NIL; (r,g,b) -> {r,g,b}.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Cl_Default() ; RETURN { CK_BYLAYER, 0, 0, 0 }
FUNCTION Cl_ByLayer() ; RETURN { CK_BYLAYER, 0, 0, 0 }
FUNCTION Cl_None()    ; RETURN { CK_NONE, 0, 0, 0 }
FUNCTION Cl_ByBlock() ; RETURN { CK_BYBLOCK, 0, 0, 0 }
FUNCTION Cl_Index( n ) ; RETURN { CK_INDEX, n, 0, 0 }
FUNCTION Cl_Red() ; RETURN Cl_Index( 1 )
FUNCTION Cl_Yellow() ; RETURN Cl_Index( 2 )
FUNCTION Cl_Green() ; RETURN Cl_Index( 3 )
FUNCTION Cl_Cyan() ; RETURN Cl_Index( 4 )
FUNCTION Cl_Blue() ; RETURN Cl_Index( 5 )
FUNCTION Cl_Magenta() ; RETURN Cl_Index( 6 )
FUNCTION Cl_White() ; RETURN Cl_Index( 7 )
FUNCTION Cl_Gray() ; RETURN Cl_Index( 8 )
FUNCTION Cl_LightGray() ; RETURN Cl_Index( 9 )
FUNCTION Cl_Eq( a, b ) ; RETURN a[1] == b[1] .AND. a[2] == b[2] .AND. a[3] == b[3] .AND. a[4] == b[4]

FUNCTION Cl_FromIndex( n )
   IF n == 0   ; RETURN Cl_ByBlock() ; ENDIF
   IF n == 256 ; RETURN Cl_ByLayer() ; ENDIF
   IF n == 257 ; RETURN Cl_None() ; ENDIF
   IF n >= 1 .AND. n <= 255 ; RETURN Cl_Index( n ) ; ENDIF
   IF n < 0 ; RETURN Cl_Index( Min( Abs( n ), 255 ) ) ; ENDIF
RETURN Cl_Index( 7 )

FUNCTION Cl_FromRgb( r, g, b ) ; RETURN { CK_RGB, r, g, b }

FUNCTION Cl_FromTrueColorValue( nValue )
RETURN { CK_RGB, hb_bitAnd( hb_bitShift( nValue, -16 ), 255 ), hb_bitAnd( hb_bitShift( nValue, -8 ), 255 ), hb_bitAnd( nValue, 255 ) }

FUNCTION Cl_ToTrueColorValue( c )
   IF c[1] != CK_RGB ; RETURN NIL ; ENDIF
RETURN hb_bitOr( hb_bitOr( hb_bitShift( c[2], 16 ), hb_bitShift( c[3], 8 ) ), c[4] )

// index() -> Option<u16>
FUNCTION Cl_IndexOf( c )
   DO CASE
   CASE c[1] == CK_BYBLOCK ; RETURN 0
   CASE c[1] == CK_INDEX   ; RETURN c[2]
   CASE c[1] == CK_BYLAYER ; RETURN 256
   CASE c[1] == CK_NONE    ; RETURN 257
   ENDCASE
RETURN NIL

// rgb() -> Option<(r,g,b)>
FUNCTION Cl_Rgb( c )
   IF c[1] == CK_RGB ; RETURN { c[2], c[3], c[4] } ; ENDIF
   IF c[1] == CK_INDEX ; RETURN Aci_ToRgb( c[2] ) ; ENDIF
RETURN NIL

FUNCTION Cl_TrueColorRgb( c )
   IF c[1] == CK_RGB ; RETURN { c[2], c[3], c[4] } ; ENDIF
RETURN NIL

FUNCTION Cl_IsTrueColor( c ) ; RETURN c[1] == CK_RGB

FUNCTION Cl_ApproximateIndex( c )
   DO CASE
   CASE c[1] == CK_BYBLOCK ; RETURN 0
   CASE c[1] == CK_BYLAYER ; RETURN 256
   CASE c[1] == CK_NONE    ; RETURN 257
   CASE c[1] == CK_INDEX   ; RETURN c[2]
   ENDCASE
RETURN Aci_Nearest( c[2], c[3], c[4] )

FUNCTION Cl_Display( c )
   DO CASE
   CASE c[1] == CK_BYLAYER ; RETURN "ByLayer"
   CASE c[1] == CK_NONE    ; RETURN "None"
   CASE c[1] == CK_BYBLOCK ; RETURN "ByBlock"
   CASE c[1] == CK_INDEX   ; RETURN "Index(" + hb_ntos( c[2] ) + ")"
   ENDCASE
RETURN "RGB(" + hb_ntos( c[2] ) + ", " + hb_ntos( c[3] ) + ", " + hb_ntos( c[4] ) + ")"
