/* Tests [extra] (los .rs de helix, light y polygon_mesh no tienen #[test]) */
#include "ocx.ch"
STATIC FUNCTION V( x, y, z ) ; RETURN Vc3_New( x, y, z )
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecMisc1()
   LOCAL h, l, p, bb, a
   h := Ehx_New() ; Chk( h[ "major_version" ] == 29 .AND. h[ "turns" ] == 3.0 .AND. h[ "handedness" ] .AND. h[ "constraint" ] == HXC_TURN_HEIGHT .AND. Ent_EntityType( h ) == "HELIX", "[extra] helix: valores por defecto" )
   Chk( Hxc_FromCode( 0 ) == HXC_TURN_HEIGHT .AND. Hxc_FromCode( 1 ) == HXC_TURNS .AND. Hxc_FromCode( 2 ) == HXC_HEIGHT .AND. Hxc_FromCode( 7 ) == HXC_TURN_HEIGHT, "[extra] helix: from_code/to_code" )
   h := Ehx_New() ; h[ "axis_base_point" ] := V( 1.0, 2.0, 3.0 ) ; h[ "start_point" ] := V( 2.0, 2.0, 3.0 ) ; Ent_Translate( h, V( 10.0, 0.0, 0.0 ) )
   Chk( Vc3_Eq( h[ "axis_base_point" ], V( 11.0, 2.0, 3.0 ) ) .AND. Vc3_Eq( h[ "start_point" ], V( 12.0, 2.0, 3.0 ) ) .AND. Vc3_Eq( h[ "axis_vector" ], Vc3_UnitZ() ), "[extra] helix: translate no mueve axis_vector" )
   h := Ehx_New() ; h[ "start_point" ] := V( 1.0, 0.0, 0.0 ) ; Ent_ApplyTransform( h, Tf_FromScale( 2.0 ) )
   Chk( Nr( h[ "radius" ], 2.0 ) .AND. Nr( h[ "turn_height" ], 2.0 ) .AND. h[ "handedness" ], "[extra] helix: transform escala radio y paso" )
   h := Ehx_New() ; Ent_MirrorX( h ) ; Chk( ! h[ "handedness" ], "[extra] helix: espejo invierte handedness" )
   l := Elt_New() ; Chk( l[ "class_version" ] == 1 .AND. l[ "light_type" ] == 2 .AND. l[ "status" ] .AND. l[ "intensity" ] == 1.0 .AND. l[ "photometric_data" ] == NIL .AND. ! Elt_IsSpot( l ) .AND. ! Elt_IsDistant( l ), "[extra] light: valores por defecto" )
   l[ "light_type" ] := 3 ; a := Elt_IsSpot( l ) ; l[ "light_type" ] := 1 ; Chk( a .AND. Elt_IsDistant( l ) .AND. Ent_EntityType( l ) == "LIGHT", "[extra] light: is_spot/is_distant" )
   l := Elt_New() ; l[ "position" ] := V( 1.0, 1.0, 1.0 ) ; l[ "target" ] := V( 2.0, 2.0, 2.0 ) ; Ent_Translate( l, V( 1.0, 2.0, 3.0 ) ) ; bb := Ent_BoundingBox( l )
   Chk( Vc3_Eq( l[ "position" ], V( 2.0, 3.0, 4.0 ) ) .AND. Vc3_Eq( l[ "target" ], V( 3.0, 4.0, 5.0 ) ) .AND. Vc3_Eq( bb[ 1 ], V( 2.0, 3.0, 4.0 ) ) .AND. Vc3_Eq( bb[ 2 ], V( 2.0, 3.0, 4.0 ) ), "[extra] light: translate y bounding_box" )
   l := Elt_New() ; l[ "position" ] := V( 1.0, 0.0, 0.0 ) ; Elt_Transform( l, Tf_FromScale( 3.0 ) ) ; a := Lpd_New() ; Chk( l[ "position" ][ 1 ] == 3.0 .AND. Vc3_Eq( a[ "web_rotation" ], V( 1.0, 1.0, 1.0 ) ) .AND. Len( a[ "web_angles" ] ) == 5, "[extra] light: Elt_Transform y photometric por defecto" )
   l := Elt_New() ; l[ "position" ] := V( 1.0, 0.0, 0.0 ) ; Ent_ApplyTransform( l, Tf_FromScale( 3.0 ) ) ; Chk( l[ "position" ][ 1 ] == 1.0, "[extra] light: el despachador no transforma (glifo)" )
   p := Epm_New() ; Chk( p[ "flags" ] == PMF_POLYGON_MESH .AND. ! Epm_IsClosedM( p ) .AND. ! Epm_IsClosedN( p ) .AND. Ent_EntityType( p ) == "POLYLINE" .AND. Vc3_Eq( Ent_BoundingBox( p )[ 2 ], Vc3_Zero() ), "[extra] polygon_mesh: defecto, closed, bbox vacio" )
   p[ "flags" ] := hb_bitOr( PMF_POLYGON_MESH, hb_bitOr( PMF_CLOSED_M, PMF_CLOSED_N ) ) ; AAdd( p[ "vertices" ], Pmv_At( V( 0.0, 0.0, 0.0 ) ) ) ; AAdd( p[ "vertices" ], Pmv_At( V( 4.0, 5.0, 6.0 ) ) ) ; Ent_Translate( p, V( 1.0, 1.0, 1.0 ) ) ; bb := Ent_BoundingBox( p )
   Chk( Epm_IsClosedM( p ) .AND. Epm_IsClosedN( p ) .AND. Vc3_Eq( bb[ 1 ], V( 1.0, 1.0, 1.0 ) ) .AND. Vc3_Eq( bb[ 2 ], V( 5.0, 6.0, 7.0 ) ), "[extra] polygon_mesh: translate y bounding_box" )
   Ent_ApplyTransform( p, Tf_FromScale( 2.0 ) ) ; Chk( p[ "vertices" ][ 2 ][ "location" ][ 3 ] == 14.0 .AND. Sst_FromI16( 5 ) == SST_QUADRATIC_BSPLINE .AND. Sst_FromI16( 6 ) == SST_CUBIC_BSPLINE .AND. Sst_FromI16( 8 ) == SST_BEZIER .AND. Sst_FromI16( 3 ) == SST_NONE, "[extra] polygon_mesh: transform y smooth type" )
RETURN
