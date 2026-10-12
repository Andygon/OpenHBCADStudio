/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/handle.prg
   Origen Rust: opencadcodec/src/types/handle.rs (128 lineas, 6 tests en t_codec_types.prg)
   Handle = numero entero de Harbour (u64 de Rust). LIMITE: Harbour usa enteros con signo de 64 bits,
   asi que valores >= 2^63 no se representan; los handles DXF reales caben de sobra.
   Ordering/igualdad: operadores normales (<, >, ==) sobre los numeros.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Hd_Null() ; RETURN 0
FUNCTION Hd_New( n ) ; RETURN n
FUNCTION Hd_Value( h ) ; RETURN h
FUNCTION Hd_IsNull( h ) ; RETURN h == 0
FUNCTION Hd_IsValid( h ) ; RETURN h != 0
// Display "{:#X}" -> "0xABCD"
FUNCTION Hd_Display( h ) ; RETURN "0x" + Hd_UpperHex( h )
FUNCTION Hd_LowerHex( h ) ; RETURN Lower( Hd_UpperHex( h ) )
FUNCTION Hd_UpperHex( h )
   LOCAL c := hb_NumToHex( h )
   DO WHILE Len( c ) > 1 .AND. Left( c, 1 ) == "0" ; c := SubStr( c, 2 ) ; ENDDO
RETURN c
