/* lwpolyline.rs no tiene tests en Rust: todos los checks son [extra] */
#include "ocx.ch"
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.000000001
PROCEDURE T_CodecLwPoly()
   LOCAL e, bb
   e := Elw_FromPoints( { Vc2_New( 0.0, 0.0 ), Vc2_New( 4.0, 0.0 ), Vc2_New( 4.0, 3.0 ) } )
   Chk( Elw_VertexCount( e ) == 3 .AND. Ent_EntityType( e ) == "LWPOLYLINE" .AND. ! e[ "is_closed" ], "[extra] lwpolyline: from_points" )
   Elw_Close( e ) ; Elw_AddPointWithBulge( e, Vc2_New( 0.0, 3.0 ), 0.5 ) ; Chk( e[ "is_closed" ] .AND. Elw_VertexCount( e ) == 4 .AND. e[ "vertices" ][ 4 ][ "bulge" ] == 0.5, "[extra] lwpolyline: close y bulge" )
   bb := Ent_BoundingBox( e ) ; Chk( Vc3_Eq( bb[ 1 ], Vc3_Zero() ) .AND. Vc3_Eq( bb[ 2 ], Vc3_New( 4.0, 3.0, 0.0 ) ), "[extra] lwpolyline: bounding box" )
   Chk( Vc3_Eq( Ent_BoundingBox( Elw_New() )[ 1 ], Vc3_Zero() ), "[extra] lwpolyline: bbox vacio" )
   Ent_Translate( e, Vc3_New( 1.0, 2.0, 3.0 ) ) ; Chk( Nr( e[ "vertices" ][ 1 ][ "location" ][ 1 ], 1.0 ) .AND. Nr( e[ "vertices" ][ 1 ][ "location" ][ 2 ], 2.0 ) .AND. Nr( e[ "elevation" ], 3.0 ), "[extra] lwpolyline: translate" )
   Ent_MirrorX( e ) ; Chk( Nr( e[ "vertices" ][ 4 ][ "bulge" ], -0.5 ) .AND. Nr( e[ "vertices" ][ 1 ][ "location" ][ 1 ], -1.0 ), "[extra] lwpolyline: espejo niega bulge" )
   e := Elw_FromPoints( { Vc2_New( 1.0, 0.0 ) } ) ; Ent_ApplyRotation( e, Vc3_UnitZ(), OCX_PI / 2.0 )
   Chk( Nr( e[ "vertices" ][ 1 ][ "location" ][ 1 ], 0.0 ) .AND. Nr( e[ "vertices" ][ 1 ][ "location" ][ 2 ], 1.0 ), "[extra] lwpolyline: rotacion 90" )
RETURN
