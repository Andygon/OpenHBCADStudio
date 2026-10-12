/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_polyline.prg
   Origen Rust: opencadcodec/src/entities/polyline.rs (472, sin tests)
              + translate_/transform_/mirror_ de polyline y polyline2d. Licencia del original: MPL-2.0.
   Polyline2D -> hash con "_type" "POLYLINE2D" (Ent_EntityType devuelve "POLYLINE" como Rust);
   Polyline (3D heavy) -> "_type" "POLYLINE". Flags = enteros de bits (PF_*, VF_* en ocx.ch).
   Prefijos: Pfl_ (PolylineFlags), Vfl_ (VertexFlags), Sst_, Vx2_ (Vertex2D), Vx3_ (Vertex3D), Pl2_ (Polyline2D), Plh_ (Polyline).
   Tests [extra] en t_codec_polyline.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION OcsOff( vNormal, vOffset ) ; RETURN Mx3_TransformPoint( Mx3_Transpose( Mx3_ArbitraryAxis( vNormal ) ), vOffset )

FUNCTION Pfl_IsClosed( n ) ; RETURN hb_bitAnd( n, 1 ) != 0
FUNCTION Pfl_Is3d( n ) ; RETURN hb_bitAnd( n, 8 ) != 0
FUNCTION Pfl_IsSplineFit( n ) ; RETURN hb_bitAnd( n, 4 ) != 0
FUNCTION Pfl_SetClosed( n, l ) ; RETURN iif( l, hb_bitOr( n, 1 ), hb_bitAnd( n, 65534 ) )
FUNCTION Pfl_Set3d( n, l ) ; RETURN iif( l, hb_bitOr( n, 8 ), hb_bitAnd( n, 65527 ) )

/* From<i16> for SmoothSurfaceType */
FUNCTION Sst_From( n )
   DO CASE
   CASE n == 5 ; RETURN SST_QUADRATIC_BSPLINE
   CASE n == 6 ; RETURN SST_CUBIC_BSPLINE
   CASE n == 8 ; RETURN SST_BEZIER
   ENDCASE
RETURN SST_NONE

FUNCTION Vx2_New( vLoc ) ; RETURN hb_Hash( "location", vLoc, "flags", 0, "start_width", 0.0, "end_width", 0.0, "bulge", 0.0, "curve_tangent", 0.0, "id", 0 )
FUNCTION Vx2_FromPoint( p ) ; RETURN Vx2_New( Vc3_New( p[ 1 ], p[ 2 ], 0.0 ) )
FUNCTION Vx2_WithBulge( v, nBulge ) ; v[ "bulge" ] := nBulge ; RETURN v
FUNCTION Vx2_WithWidth( v, nS, nE ) ; v[ "start_width" ] := nS ; v[ "end_width" ] := nE ; RETURN v
FUNCTION Vx3_New( vLoc ) ; RETURN hb_Hash( "location", vLoc, "flags", 0 )
FUNCTION Vx3_FromCoords( x, y, z ) ; RETURN Vx3_New( Vc3_New( x, y, z ) )

FUNCTION Pl2_New()
RETURN hb_Hash( "_type", "POLYLINE2D", "common", Ec_New(), "flags", 0, "smooth_surface", SST_NONE, "start_width", 0.0, "end_width", 0.0, ;
                "thickness", 0.0, "elevation", 0.0, "normal", Vc3_UnitZ(), "vertices", {} )
FUNCTION Pl2_AddVertex( e, v ) ; AAdd( e[ "vertices" ], v ) ; RETURN NIL
FUNCTION Pl2_IsClosed( e ) ; RETURN Pfl_IsClosed( e[ "flags" ] )
FUNCTION Pl2_Close( e ) ; e[ "flags" ] := Pfl_SetClosed( e[ "flags" ], .T. ) ; RETURN NIL
FUNCTION Pl2_BoundingBox( e )
   LOCAL aPts := {}, v
   IF Len( e[ "vertices" ] ) == 0 ; RETURN Bb3_FromPoint( Vc3_Zero() ) ; ENDIF
   FOR EACH v IN e[ "vertices" ]
      AAdd( aPts, v[ "location" ] )
   NEXT
RETURN Bb3_OcsToWcs( Bb3_FromPoints( aPts ), e[ "normal" ] )
FUNCTION Pl2_Translate( e, vOffset )
   LOCAL o := OcsOff( e[ "normal" ], vOffset ), v
   FOR EACH v IN e[ "vertices" ]
      v[ "location" ] := Vc3_Add( v[ "location" ], o )
   NEXT
RETURN NIL
FUNCTION Pl2_Transform( e, t )
   LOCAL lFlip := Tf_IsReflecting( t ), vNn := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
   LOCAL mOcs := Mx3_ArbitraryAxis( e[ "normal" ] ), mNt := Mx3_Transpose( Mx3_ArbitraryAxis( vNn ) ), v
   FOR EACH v IN e[ "vertices" ]
      v[ "location" ] := Mx3_TransformPoint( mNt, Tf_Apply( t, Mx3_TransformPoint( mOcs, v[ "location" ] ) ) )
      IF lFlip ; v[ "bulge" ] := - v[ "bulge" ] ; ENDIF
   NEXT
   e[ "normal" ] := vNn
RETURN NIL
FUNCTION Pl2_Mirror( e, t ) ; Pl2_Transform( e, t ) ; RETURN NIL

FUNCTION Plh_New() ; RETURN hb_Hash( "_type", "POLYLINE", "common", Ec_New(), "flags", Pfl_Set3d( 0, .T. ), "vertices", {} )
FUNCTION Plh_FromPoints( aPts )
   LOCAL e := Plh_New(), p
   FOR EACH p IN aPts
      AAdd( e[ "vertices" ], Vx3_New( p ) )
   NEXT
RETURN e
FUNCTION Plh_AddVertex( e, v ) ; AAdd( e[ "vertices" ], v ) ; RETURN NIL
FUNCTION Plh_AddPoint( e, p ) ; AAdd( e[ "vertices" ], Vx3_New( p ) ) ; RETURN NIL
FUNCTION Plh_VertexCount( e ) ; RETURN Len( e[ "vertices" ] )
FUNCTION Plh_IsClosed( e ) ; RETURN Pfl_IsClosed( e[ "flags" ] )
FUNCTION Plh_Close( e ) ; e[ "flags" ] := Pfl_SetClosed( e[ "flags" ], .T. ) ; RETURN NIL
FUNCTION Plh_BoundingBox( e )
   LOCAL aPts := {}, v
   IF Len( e[ "vertices" ] ) == 0 ; RETURN Bb3_FromPoint( Vc3_Zero() ) ; ENDIF
   FOR EACH v IN e[ "vertices" ]
      AAdd( aPts, v[ "location" ] )
   NEXT
RETURN Bb3_FromPoints( aPts )
FUNCTION Plh_Translate( e, vOffset )
   LOCAL v
   FOR EACH v IN e[ "vertices" ]
      v[ "location" ] := Vc3_Add( v[ "location" ], vOffset )
   NEXT
RETURN NIL
FUNCTION Plh_Transform( e, t )
   LOCAL v
   FOR EACH v IN e[ "vertices" ]
      v[ "location" ] := Tf_Apply( t, v[ "location" ] )
   NEXT
RETURN NIL
