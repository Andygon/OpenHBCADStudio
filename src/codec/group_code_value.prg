/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/group_code_value.prg
   Origen Rust: opencadcodec/src/io/dxf/group_code_value.rs (279 lineas, 4 tests en t_codec_dxf.prg)
   GroupCodeValueType = GVT_* (ocx.ch). DxfCode = entero (DXF_* en dxfcode.ch).
   Option<usize> -> NIL. Los brazos del match se evalucan en el mismo orden que en Rust.
----------------------------------------------------------------------------*/
#include "ocx.ch"
#include "dxfcode.ch"

STATIC FUNCTION InR( n, a, b ) ; RETURN n >= a .AND. n <= b

FUNCTION Gv_FromCode( nCode ) ; RETURN Gv_FromRawCode( nCode )

FUNCTION Gv_FromRawCode( n )
   IF InR( n, 0, 9 ) .OR. InR( n, 100, 109 ) .OR. InR( n, 300, 309 ) .OR. n == 999 ; RETURN GVT_STRING ; ENDIF
   IF InR( n, 10, 59 ) .OR. InR( n, 110, 149 ) .OR. InR( n, 210, 239 ) .OR. InR( n, 460, 469 ) ; RETURN GVT_DOUBLE ; ENDIF
   IF InR( n, 60, 79 ) .OR. InR( n, 170, 179 ) .OR. InR( n, 270, 279 ) .OR. InR( n, 370, 389 ) .OR. InR( n, 400, 409 ) ; RETURN GVT_INT16 ; ENDIF
   IF InR( n, 280, 289 ) ; RETURN GVT_BYTE ; ENDIF
   IF InR( n, 90, 99 ) .OR. InR( n, 420, 429 ) .OR. InR( n, 440, 449 ) ; RETURN GVT_INT32 ; ENDIF
   IF InR( n, 160, 169 ) ; RETURN GVT_INT64 ; ENDIF
   IF InR( n, 450, 459 ) ; RETURN GVT_INT32 ; ENDIF
   IF InR( n, 290, 299 ) ; RETURN GVT_BOOL ; ENDIF
   IF InR( n, 310, 319 ) ; RETURN GVT_BINARYDATA ; ENDIF
   IF InR( n, 320, 369 ) .OR. InR( n, 390, 399 ) .OR. InR( n, 480, 481 ) ; RETURN GVT_HANDLE ; ENDIF
   IF InR( n, 410, 419 ) .OR. InR( n, 430, 439 ) .OR. InR( n, 470, 479 ) ; RETURN GVT_STRING ; ENDIF
   IF n == 1004 ; RETURN GVT_BINARYDATA ; ENDIF
   IF n == 1005 ; RETURN GVT_HANDLE ; ENDIF
   IF InR( n, 1000, 1009 ) ; RETURN GVT_STRING ; ENDIF
   IF InR( n, 1040, 1042 ) ; RETURN GVT_DOUBLE ; ENDIF
   IF InR( n, 1010, 1059 ) ; RETURN GVT_DOUBLE ; ENDIF
   IF InR( n, 1060, 1070 ) ; RETURN GVT_INT16 ; ENDIF
   IF n == 1071 ; RETURN GVT_INT32 ; ENDIF
RETURN GVT_NONE

FUNCTION Gv_IsCoordinate( n )
RETURN InR( n, 10, 18 ) .OR. InR( n, 20, 28 ) .OR. InR( n, 30, 38 ) .OR. InR( n, 110, 112 ) .OR. InR( n, 120, 122 ) .OR. InR( n, 130, 132 ) .OR. ;
       InR( n, 210, 213 ) .OR. InR( n, 220, 223 ) .OR. InR( n, 230, 233 ) .OR. InR( n, 1010, 1013 ) .OR. InR( n, 1020, 1023 ) .OR. InR( n, 1030, 1033 )

// -> 0/1/2 o NIL
FUNCTION Gv_CoordinateAxis( n )
   IF InR( n, 10, 18 ) .OR. InR( n, 110, 112 ) .OR. InR( n, 210, 213 ) .OR. InR( n, 1010, 1013 ) ; RETURN 0 ; ENDIF
   IF InR( n, 20, 28 ) .OR. InR( n, 120, 122 ) .OR. InR( n, 220, 223 ) .OR. InR( n, 1020, 1023 ) ; RETURN 1 ; ENDIF
   IF InR( n, 30, 38 ) .OR. InR( n, 130, 132 ) .OR. InR( n, 230, 233 ) .OR. InR( n, 1030, 1033 ) ; RETURN 2 ; ENDIF
RETURN NIL

FUNCTION Gv_CoordinateGroup( n )
   LOCAL h := { 10 => 0, 20 => 0, 30 => 0, 11 => 1, 21 => 1, 31 => 1, 12 => 2, 22 => 2, 32 => 2, 13 => 3, 23 => 3, 33 => 3, ;
                14 => 4, 24 => 4, 34 => 4, 15 => 5, 25 => 5, 35 => 5, 16 => 6, 26 => 6, 36 => 6, 17 => 7, 27 => 7, 37 => 7, 18 => 8, 28 => 8, 38 => 8, ;
                110 => 10, 120 => 10, 130 => 10, 111 => 11, 121 => 11, 131 => 11, 112 => 12, 122 => 12, 132 => 12, ;
                210 => 21, 220 => 21, 230 => 21, 211 => 22, 221 => 22, 231 => 22, 212 => 23, 222 => 23, 232 => 23, 213 => 24, 223 => 24, 233 => 24, ;
                1010 => 100, 1020 => 100, 1030 => 100, 1011 => 101, 1021 => 101, 1031 => 101, 1012 => 102, 1022 => 102, 1032 => 102, 1013 => 103, 1023 => 103, 1033 => 103 }
RETURN IIf( hb_HHasKey( h, n ), h[ n ], NIL )
