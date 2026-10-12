/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_helix.prg
   Origen Rust: opencadcodec/src/entities/helix.rs (172, SIN tests en Rust) + translate_helix + transform_helix. Licencia del original: MPL-2.0.
   Prefijo Ehx_. spline = hash de Esp_New() (campo "spline"). constraint = entero HXC_* (0 TurnHeight, 1 Turns, 2 Height). Tests [extra] en t_codec_misc1.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Ehx_EntityName() ; RETURN "HELIX"
FUNCTION Hxc_FromCode( n ) ; RETURN iif( n == 1, HXC_TURNS, iif( n == 2, HXC_HEIGHT, HXC_TURN_HEIGHT ) )
FUNCTION Hxc_ToCode( n ) ; RETURN n

FUNCTION Ehx_New()
RETURN hb_Hash( "_type", "HELIX", "common", Ec_New(), "spline", Esp_New(), "major_version", 29, "maintenance_version", 0, "axis_base_point", Vc3_Zero(), "start_point", Vc3_Zero(), ;
   "axis_vector", Vc3_UnitZ(), "radius", 1.0, "turns", 3.0, "turn_height", 1.0, "handedness", .T., "constraint", HXC_TURN_HEIGHT )
FUNCTION Ehx_BoundingBox( e ) ; RETURN Esp_BoundingBox( e[ "spline" ] )
FUNCTION Ehx_Translate( e, vOff )
   Esp_Translate( e[ "spline" ], vOff )
   e[ "axis_base_point" ] := Vc3_Add( e[ "axis_base_point" ], vOff )
   e[ "start_point" ] := Vc3_Add( e[ "start_point" ], vOff )
RETURN NIL
FUNCTION Ehx_Transform( e, t )
   LOCAL vAxis := Vc3_Normalize( e[ "axis_vector" ] ), vBase := e[ "axis_base_point" ], vStart := e[ "start_point" ]
   LOCAL vTAxis := Tf_ApplyRotation( t, vAxis ), vTRad := Tf_ApplyRotation( t, Vc3_Sub( vStart, vBase ) ), vTBase := Tf_Apply( t, vBase ), vTStart := Tf_Apply( t, vStart )
   Esp_Transform( e[ "spline" ], t )
   e[ "axis_base_point" ] := vTBase ; e[ "start_point" ] := vTStart ; e[ "axis_vector" ] := Vc3_Normalize( vTAxis )
   e[ "radius" ] := Vc3_Length( vTRad ) ; e[ "turn_height" ] *= Vc3_Length( vTAxis )
   IF Tf_IsReflecting( t ) ; e[ "handedness" ] := ! e[ "handedness" ] ; ENDIF
RETURN NIL
