/* Tests [extra]: spline_flags.rs y helpers de dxf/mod.rs no tienen #[test] en Rust */
#include "ocx.ch"
PROCEDURE T_CodecDxfMisc()
   LOCAL s, a
   s := Esp_New() ; Spf_Read( s, hb_bitOr( 1, 4, 32, 512 ) )
   Chk( s[ "flags" ][ "closed" ] .AND. s[ "flags" ][ "rational" ] .AND. ! s[ "flags" ][ "periodic" ] .AND. s[ "knot_parameterization" ] == 0 .AND. s[ "cv_frame_visible" ] .AND. hb_bitAnd( s[ "dwg_flags1" ], 2 ) != 0, "[extra] spline_flags: read basico" )
   s := Esp_New() ; Spf_Read( s, hb_bitOr( 1, 256, 1024 ) )
   Chk( s[ "knot_parameterization" ] == 15 .AND. hb_bitAnd( s[ "dwg_flags1" ], 15 ) == 13, "[extra] spline_flags: fit method marca dwg_flags1 (1|8|4)" )
   s := Esp_New() ; Spf_Read( s, hb_bitOr( 2, 8, 16, 64 ) ) ; Chk( Spf_Write( s ) == hb_bitOr( 2, 8, 16, 64 ), "[extra] spline_flags: ida y vuelta" )
   s := Esp_New() ; Chk( Spf_Write( s ) == 0, "[extra] spline_flags: write de spline por defecto" )
   a := Dxm_SplitColorBookName( "DIC$Red" ) ; Chk( a[ 1 ] == "DIC" .AND. a[ 2 ] == "Red", "[extra] split_color_book_name book$color" )
   a := Dxm_SplitColorBookName( "Red" ) ; Chk( a[ 1 ] == NIL .AND. a[ 2 ] == "Red", "[extra] split_color_book_name solo color" )
   a := Dxm_SplitColorBookName( "DIC$" ) ; Chk( a[ 1 ] == "DIC" .AND. a[ 2 ] == NIL .AND. Dxm_SplitColorBookName( "" )[ 2 ] == NIL, "[extra] split_color_book_name vacios" )
   Chk( Dxm_JoinColorBookName( "DIC", "Red" ) == "DIC$Red" .AND. Dxm_JoinColorBookName( "DIC", NIL ) == "DIC$" .AND. Dxm_JoinColorBookName( NIL, "Red" ) == "Red" .AND. Dxm_JoinColorBookName( "", "" ) == NIL, "[extra] join_color_book_name" )
RETURN
