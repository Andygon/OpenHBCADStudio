/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_lwpoly.prg
   Origen Rust: opencadcodec/src/entities/lwpolyline.rs (209, sin tests)
              + translate_/transform_/mirror_lwpolyline. Licencia del original: MPL-2.0.
   Entidad = hash ("_type" "LWPOLYLINE"); LwVertex = hash. Tests [extra] en t_codec_lwpoly.prg.
   Prefijos: Elv_ (LwVertex), Elw_ (LwPolyline).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Elv_New( vLoc ) ; RETURN hb_Hash( "location", vLoc, "bulge", 0.0, "start_width", 0.0, "end_width", 0.0, "vertex_id", 0 )
FUNCTION Elv_FromCoords( x, y ) ; RETURN Elv_New( Vc2_New( x, y ) )
FUNCTION Elv_WithBulge( vLoc, nBulge )
   LOCAL v := Elv_New( vLoc )
   v[ "bulge" ] := nBulge
RETURN v

FUNCTION Elw_New()
RETURN hb_Hash( "_type", "LWPOLYLINE", "common", Ec_New(), "vertices", {}, "is_closed", .F., "plinegen", .F., "constant_width", 0.0, ;
                "elevation", 0.0, "thickness", 0.0, "normal", Vc3_UnitZ() )
FUNCTION Elw_FromPoints( aPts )
   LOCAL e := Elw_New(), p
   FOR EACH p IN aPts
      AAdd( e[ "vertices" ], Elv_New( p ) )
   NEXT
RETURN e
FUNCTION Elw_AddVertex( e, v ) ; AAdd( e[ "vertices" ], v ) ; RETURN NIL
FUNCTION Elw_AddPoint( e, p ) ; AAdd( e[ "vertices" ], Elv_New( p ) ) ; RETURN NIL
FUNCTION Elw_AddPointWithBulge( e, p, nBulge ) ; AAdd( e[ "vertices" ], Elv_WithBulge( p, nBulge ) ) ; RETURN NIL
FUNCTION Elw_VertexCount( e ) ; RETURN Len( e[ "vertices" ] )
FUNCTION Elw_Close( e ) ; e[ "is_closed" ] := .T. ; RETURN NIL

FUNCTION Elw_BoundingBox( e )
   LOCAL aPts := {}, v
   IF Len( e[ "vertices" ] ) == 0 ; RETURN Bb3_FromPoint( Vc3_Zero() ) ; ENDIF
   FOR EACH v IN e[ "vertices" ]
      AAdd( aPts, Vc3_New( v[ "location" ][ 1 ], v[ "location" ][ 2 ], e[ "elevation" ] ) )
   NEXT
RETURN Bb3_OcsToWcs( Bb3_FromPoints( aPts ), e[ "normal" ] )

FUNCTION Elw_Translate( e, vOffset )
   LOCAL o := Mx3_TransformPoint( Mx3_Transpose( Mx3_ArbitraryAxis( e[ "normal" ] ) ), vOffset ), v
   FOR EACH v IN e[ "vertices" ]
      v[ "location" ] := Vc2_New( v[ "location" ][ 1 ] + o[ 1 ], v[ "location" ][ 2 ] + o[ 2 ] )
   NEXT
   e[ "elevation" ] += o[ 3 ]
RETURN NIL

FUNCTION Elw_Transform( e, t )
   LOCAL lFlip := Tf_IsReflecting( t ), vNn := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
   LOCAL mOcs := Mx3_ArbitraryAxis( e[ "normal" ] ), mNt := Mx3_Transpose( Mx3_ArbitraryAxis( vNn ) ), nElev := e[ "elevation" ], v, l
   FOR EACH v IN e[ "vertices" ]
      l := Mx3_TransformPoint( mNt, Tf_Apply( t, Mx3_TransformPoint( mOcs, Vc3_New( v[ "location" ][ 1 ], v[ "location" ][ 2 ], e[ "elevation" ] ) ) ) )
      v[ "location" ] := Vc2_New( l[ 1 ], l[ 2 ] )
      nElev := l[ 3 ]
      IF lFlip ; v[ "bulge" ] := - v[ "bulge" ] ; ENDIF
   NEXT
   IF Len( e[ "vertices" ] ) == 0
      l := Mx3_TransformPoint( mNt, Tf_Apply( t, Mx3_TransformPoint( mOcs, Vc3_New( 0.0, 0.0, e[ "elevation" ] ) ) ) )
      nElev := l[ 3 ]
   ENDIF
   e[ "elevation" ] := nElev
   e[ "normal" ] := vNn
RETURN NIL
FUNCTION Elw_Mirror( e, t ) ; Elw_Transform( e, t ) ; RETURN NIL
