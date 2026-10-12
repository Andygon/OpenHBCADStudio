/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_polymesh.prg
   Origen Rust: opencadcodec/src/entities/polygon_mesh.rs (207, SIN tests en Rust) + translate_polygon_mesh + transform_polygon_mesh. Licencia del original: MPL-2.0.
   Prefijos: Pmv_ (PolygonMeshVertex), Epm_ (PolygonMesh, _type "POLYGON_MESH", entity_type "POLYLINE"). SurfaceSmoothType = SST_* (Sst_FromI16). Flags = PMF_*.
   Tests [extra] en t_codec_misc1.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Epm_EntityName() ; RETURN "POLYLINE"
FUNCTION Sst_FromI16( n ) ; RETURN iif( n == 5 .OR. n == 6 .OR. n == 8, n, SST_NONE )
FUNCTION Pmv_New() ; RETURN hb_Hash( "common", Ec_New(), "location", Vc3_Zero(), "flags", 0 )
FUNCTION Pmv_At( v ) ; LOCAL x := Pmv_New() ; x[ "location" ] := v ; RETURN x
FUNCTION Epm_New()
RETURN hb_Hash( "_type", "POLYGON_MESH", "common", Ec_New(), "flags", PMF_POLYGON_MESH, "m_vertex_count", 0, "n_vertex_count", 0, "m_smooth_density", 0, "n_smooth_density", 0, ;
   "smooth_type", SST_NONE, "elevation", 0.0, "normal", Vc3_UnitZ(), "vertices", {} )
FUNCTION Epm_IsClosedM( e ) ; RETURN hb_bitAnd( e[ "flags" ], PMF_CLOSED_M ) != 0
FUNCTION Epm_IsClosedN( e ) ; RETURN hb_bitAnd( e[ "flags" ], PMF_CLOSED_N ) != 0
FUNCTION Epm_BoundingBox( e )
   LOCAL aP := {}, v
   IF Len( e[ "vertices" ] ) == 0 ; RETURN Bb3_FromPoint( Vc3_Zero() ) ; ENDIF
   FOR EACH v IN e[ "vertices" ] ; AAdd( aP, v[ "location" ] ) ; NEXT
RETURN Bb3_FromPoints( aP )
FUNCTION Epm_Translate( e, vOff )
   LOCAL v
   FOR EACH v IN e[ "vertices" ] ; v[ "location" ] := Vc3_Add( v[ "location" ], vOff ) ; NEXT
RETURN NIL
FUNCTION Epm_Transform( e, t )
   LOCAL v
   FOR EACH v IN e[ "vertices" ] ; v[ "location" ] := Tf_Apply( t, v[ "location" ] ) ; NEXT
RETURN NIL
