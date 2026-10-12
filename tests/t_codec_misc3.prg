/* Tests [extra] (unknown_entity y view_border no tienen #[test] en Rust) */
#include "ocx.ch"
PROCEDURE T_CodecMisc3()
   LOCAL u, v, bb
   u := Eun_New( "FOO" ) ; Chk( u[ "dxf_name" ] == "FOO" .AND. u[ "dwg_type_code"  ] == 0 .AND. u[ "raw_dwg_data" ] == NIL .AND. Ent_EntityType( u ) == "UNKNOWN", "[extra] unknown: valores por defecto" )
   Ent_Translate( u, Vc3_New( 5.0, 5.0, 5.0 ) ) ; Ent_ApplyTransform( u, Tf_FromScale( 3.0 ) ) ; bb := Ent_BoundingBox( u )
   Chk( Vc3_Eq( bb[ 1 ], Vc3_Zero() ) .AND. Vc3_Eq( bb[ 2 ], Vc3_Zero() ), "[extra] unknown: sin geometria, bbox en el origen" )
   v := Evb_New() ; Chk( v[ "scale" ] == 1.0 .AND. Ent_EntityType( v ) == "DRAWINGVIEW" .AND. Hd_IsNull( v[ "active_viewport" ] ), "[extra] view_border: valores por defecto" )
   v[ "min" ] := { 1.0, 2.0 } ; v[ "max" ] := { 3.0, 5.0 } ; v[ "center" ] := { 2.0, 3.5 } ; bb := Ent_BoundingBox( v )
   Chk( Vc3_Eq( bb[ 1 ], Vc3_New( 1.0, 2.0, 0.0 ) ) .AND. Vc3_Eq( bb[ 2 ], Vc3_New( 3.0, 5.0, 0.0 ) ), "[extra] view_border: bounding_box" )
   Evb_Translate( v, Vc3_New( 10.0, 20.0, 0.0 ) ) ; Chk( v[ "min" ][ 1 ] == 11.0 .AND. v[ "max" ][ 2 ] == 25.0 .AND. v[ "center" ][ 2 ] == 23.5, "[extra] view_border: Evb_Translate" )
   Ent_Translate( v, Vc3_New( 100.0, 0.0, 0.0 ) ) ; Chk( v[ "min" ][ 1 ] == 11.0, "[extra] view_border: el despachador no mueve" )
   Evb_Transform( v, Tf_FromScale( 2.0 ) ) ; Chk( v[ "min" ][ 1 ] == 22.0 .AND. v[ "min" ][ 2 ] == 44.0 .AND. v[ "max" ][ 1 ] == 26.0 .AND. v[ "center" ][ 1 ] == 24.0, "[extra] view_border: Evb_Transform recalcula esquinas" )
   Evb_Transform( v, Tf_FromMirrorX() ) ; Chk( v[ "min" ][ 1 ] == -26.0 .AND. v[ "max" ][ 1 ] == -22.0, "[extra] view_border: espejo reordena min y max" )
RETURN
