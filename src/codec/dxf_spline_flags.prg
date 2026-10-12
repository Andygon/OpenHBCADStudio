/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_spline_flags.prg
   Origen Rust: opencadcodec/src/io/dxf/spline_flags.rs (73 lineas, sin #[test]; tests [extra] en t_codec_dxfmisc.prg) y
   las funciones split_color_book_name / join_color_book_name de io/dxf/mod.rs. Licencia del original: MPL-2.0.
   Prefijos: Spf_ (read/write de AcDbSpline grupo 70), Dxm_ (helpers de mod.rs). Option<String> -> NIL.
   Aritmetica de i16 con mascaras positivas; "!15" -> mascara -16, "!0x7ff" -> mascara -2048 (complemento a 2).
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define SPF_PARAMETERIZATION 480
#define SPF_FRAME 512
#define SPF_FIT_METHOD 1024

PROCEDURE Spf_Read( spline, nFlags )
   LOCAL n
   spline[ "dxf_flags" ] := nFlags
   spline[ "flags" ][ "closed" ] := hb_bitAnd( nFlags, 1 ) != 0
   spline[ "flags" ][ "periodic" ] := hb_bitAnd( nFlags, 2 ) != 0
   spline[ "flags" ][ "rational" ] := hb_bitAnd( nFlags, 4 ) != 0
   spline[ "flags" ][ "planar" ] := hb_bitAnd( nFlags, 8 ) != 0
   spline[ "flags" ][ "linear" ] := hb_bitAnd( nFlags, 16 ) != 0
   n := hb_bitAnd( nFlags, SPF_PARAMETERIZATION )
   DO CASE
   CASE n == 32  ; spline[ "knot_parameterization" ] := 0
   CASE n == 64  ; spline[ "knot_parameterization" ] := 1
   CASE n == 128 ; spline[ "knot_parameterization" ] := 2
   CASE n == 256 ; spline[ "knot_parameterization" ] := 15
   OTHERWISE     ; spline[ "knot_parameterization" ] := 0
   ENDCASE
   spline[ "cv_frame_visible" ] := hb_bitAnd( nFlags, SPF_FRAME ) != 0
   spline[ "dwg_flags1" ] := hb_bitAnd( spline[ "dwg_flags1" ], -16 )
   IF hb_bitAnd( nFlags, SPF_FIT_METHOD ) != 0
      spline[ "dwg_flags1" ] := hb_bitOr( spline[ "dwg_flags1" ], 9 )
      IF spline[ "flags" ][ "closed" ]
         spline[ "dwg_flags1" ] := hb_bitOr( spline[ "dwg_flags1" ], 4 )
      ENDIF
   ENDIF
   IF spline[ "cv_frame_visible" ]
      spline[ "dwg_flags1" ] := hb_bitOr( spline[ "dwg_flags1" ], 2 )
   ENDIF
RETURN

FUNCTION Spf_Write( spline )
   LOCAL nFlags := hb_bitAnd( spline[ "dxf_flags" ], -2048 ), lFit
   lFit := hb_bitAnd( spline[ "dwg_flags1" ], 1 ) != 0 .OR. ( Len( spline[ "fit_points" ] ) > 0 .AND. Len( spline[ "control_points" ] ) == 0 )
   IF lFit .OR. spline[ "knot_parameterization" ] != 0 .OR. hb_bitAnd( spline[ "dxf_flags" ], SPF_PARAMETERIZATION ) != 0
      DO CASE
      CASE spline[ "knot_parameterization" ] == 0  ; nFlags := hb_bitOr( nFlags, 32 )
      CASE spline[ "knot_parameterization" ] == 1  ; nFlags := hb_bitOr( nFlags, 64 )
      CASE spline[ "knot_parameterization" ] == 2  ; nFlags := hb_bitOr( nFlags, 128 )
      CASE spline[ "knot_parameterization" ] == 15 ; nFlags := hb_bitOr( nFlags, 256 )
      OTHERWISE ; nFlags := hb_bitOr( nFlags, hb_bitAnd( spline[ "dxf_flags" ], SPF_PARAMETERIZATION ) )
      ENDCASE
   ENDIF
   IF lFit ; nFlags := hb_bitOr( nFlags, SPF_FIT_METHOD ) ; ENDIF
   IF spline[ "cv_frame_visible" ] ; nFlags := hb_bitOr( nFlags, SPF_FRAME ) ; ENDIF
   IF spline[ "flags" ][ "closed" ] ; nFlags := hb_bitOr( nFlags, 1 ) ; ENDIF
   IF spline[ "flags" ][ "periodic" ] ; nFlags := hb_bitOr( nFlags, 2 ) ; ENDIF
   IF spline[ "flags" ][ "rational" ] ; nFlags := hb_bitOr( nFlags, 4 ) ; ENDIF
   IF spline[ "flags" ][ "planar" ] ; nFlags := hb_bitOr( nFlags, 8 ) ; ENDIF
   IF spline[ "flags" ][ "linear" ] ; nFlags := hb_bitOr( nFlags, 16 ) ; ENDIF
RETURN nFlags

/* Devuelve { cBookName|NIL, cColorName|NIL } */
FUNCTION Dxm_SplitColorBookName( cValue )
   LOCAL n := At( "$", cValue )
   IF n > 0
      RETURN { iif( n > 1, Left( cValue, n - 1 ), NIL ), iif( Len( cValue ) > n, SubStr( cValue, n + 1 ), NIL ) }
   ENDIF
RETURN { NIL, iif( Len( cValue ) > 0, cValue, NIL ) }

FUNCTION Dxm_JoinColorBookName( cBook, cColor )
   IF cBook != NIL .AND. Len( cBook ) == 0 ; cBook := NIL ; ENDIF
   IF cColor != NIL .AND. Len( cColor ) == 0 ; cColor := NIL ; ENDIF
   IF cBook != NIL .AND. cColor != NIL ; RETURN cBook + "$" + cColor ; ENDIF
   IF cBook != NIL ; RETURN cBook + "$" ; ENDIF
RETURN cColor
