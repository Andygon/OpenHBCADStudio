/* text.rs y mtext.rs no tienen tests en Rust: todos los checks son [extra] */
#include "ocx.ch"
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.000000001
PROCEDURE T_CodecEntText()
   LOCAL t, m, bb
   Chk( Nr( Etx_EstimatedWidthInHeights( "abc" ), 1.8 ), "[extra] text: ancho ASCII 0.6/char" )
   Chk( Nr( Etx_EstimatedWidthInHeights( hb_UTF8ToStr( "a" ) + hb_BChar( 228 ) + hb_BChar( 184 ) + hb_BChar( 173 ) ), 1.6 ), "[extra] text: ancho CJK 1.0" )
   t := Etx_WithValue( "Hola", Vc3_New( 1.0, 2.0, 0.0 ) ) ; t[ "height" ] := 2.0 ; bb := Ent_BoundingBox( t )
   Chk( Nr( bb[ 2 ][ 1 ], 1.0 + 4.0 * 0.6 * 2.0 ) .AND. Nr( bb[ 2 ][ 2 ], 4.0 ) .AND. Ent_EntityType( t ) == "TEXT", "[extra] text: bounding box" )
   Ent_Translate( t, Vc3_New( 1.0, 1.0, 0.0 ) ) ; Chk( Vc3_Eq( t[ "insertion_point" ], Vc3_New( 2.0, 3.0, 0.0 ) ), "[extra] text: translate" )
   Ent_ApplyRotation( t, Vc3_UnitZ(), OCX_PI / 2.0 ) ; Chk( Nr( t[ "rotation" ], OCX_PI / 2.0 ), "[extra] text: rotacion 90" )
   Ent_ApplyScaling( t, 2.0 ) ; Chk( Nr( t[ "height" ], 4.0 ), "[extra] text: escala altura" )
   t := Etx_New() ; t[ "oblique_angle" ] := 0.25 ; Ent_MirrorX( t ) ; Chk( Nr( t[ "oblique_angle" ], -0.25 ) .AND. Nr( Abs( t[ "rotation" ] ), OCX_PI ), "[extra] text: espejo niega oblicuo" )
   m := Emt_WithValue( "x", Vc3_Zero() ) ; bb := Ent_BoundingBox( m )
   Chk( Nr( bb[ 2 ][ 1 ], 10.0 ) .AND. Nr( bb[ 2 ][ 2 ], 2.0 ) .AND. Ent_EntityType( m ) == "MTEXT", "[extra] mtext: bounding box por defecto" )
   m[ "rectangle_height" ] := 3.0 ; Ent_ApplyScaling( m, 2.0 )
   Chk( Nr( m[ "rectangle_width" ], 20.0 ) .AND. Nr( m[ "rectangle_height" ], 6.0 ) .AND. Nr( m[ "height" ], 2.0 ), "[extra] mtext: escala" )
   Ent_Translate( m, Vc3_New( 5.0, 5.0, 5.0 ) ) ; Chk( Vc3_Eq( m[ "insertion_point" ], Vc3_New( 5.0, 5.0, 5.0 ) ), "[extra] mtext: translate" )
RETURN
