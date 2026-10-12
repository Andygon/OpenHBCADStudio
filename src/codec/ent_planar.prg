/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_planar.prg
   Origen Rust: opencadcodec/src/entities/ray.rs (284, 9 tests), xline.rs (353, 11 tests),
              solid.rs (170, sin tests), face3d.rs (244, sin tests)
              + translate_/transform_/mirror_ de ray, xline, solid y face3d. Licencia del original: MPL-2.0.
   Entidades = hash ("_type" "RAY"/"XLINE"/"SOLID"/"3DFACE"); ver ent_base.prg. Tests en t_codec_planar.prg.
   Prefijos: Ery_ (Ray), Exl_ (XLine), Eso_ (Solid), Ef3_ (Face3D, incluye InvisibleEdgeFlags como entero de bits).
   Nota: entity_type de Face3D = "3DFACE" (face3d.rs).
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION OcsOff( vNormal, vOffset ) ; RETURN Mx3_TransformPoint( Mx3_Transpose( Mx3_ArbitraryAxis( vNormal ) ), vOffset )
STATIC FUNCTION Clamp0( n ) ; RETURN Max( n, 0.0 )

/* ---- Ray ---- */
FUNCTION Ery_New( vBase, vDir ) ; RETURN hb_Hash( "_type", "RAY", "common", Ec_New(), "base_point", vBase, "direction", Vc3_Normalize( vDir ) )
FUNCTION Ery_Default() ; RETURN Ery_New( Vc3_Zero(), Vc3_UnitX() )
FUNCTION Ery_FromPoints( vStart, vThrough ) ; RETURN Ery_New( vStart, Vc3_Normalize( Vc3_Sub( vThrough, vStart ) ) )
FUNCTION Ery_AlongX( vBase ) ; RETURN Ery_New( vBase, Vc3_UnitX() )
FUNCTION Ery_AlongY( vBase ) ; RETURN Ery_New( vBase, Vc3_UnitY() )
FUNCTION Ery_AlongZ( vBase ) ; RETURN Ery_New( vBase, Vc3_UnitZ() )
FUNCTION Ery_PointAt( e, t ) ; RETURN Vc3_Add( e[ "base_point" ], Vc3_Mul( e[ "direction" ], Clamp0( t ) ) )
FUNCTION Ery_ClosestPoint( e, p ) ; RETURN Ery_PointAt( e, Vc3_Dot( Vc3_Sub( p, e[ "base_point" ] ), e[ "direction" ] ) )
FUNCTION Ery_DistanceToPoint( e, p ) ; RETURN Vc3_Distance( Ery_ClosestPoint( e, p ), p )
FUNCTION Ery_ContainsPoint( e, p, nTol ) ; RETURN Ery_DistanceToPoint( e, p ) <= nTol
FUNCTION Ery_AngleXY( e ) ; RETURN OCX_ATAN2( e[ "direction" ][ 2 ], e[ "direction" ][ 1 ] )
FUNCTION Ery_AngleFromXY( e ) ; RETURN OCX_ATAN2( e[ "direction" ][ 3 ], Sqrt( e[ "direction" ][ 1 ] ^ 2 + e[ "direction" ][ 2 ] ^ 2 ) )
FUNCTION Ery_IsParallelTo( e, o, nTol ) ; RETURN Vc3_Length( Vc3_Cross( e[ "direction" ], o[ "direction" ] ) ) <= nTol
FUNCTION Ery_IsPerpendicularTo( e, o, nTol ) ; RETURN Abs( Vc3_Dot( e[ "direction" ], o[ "direction" ] ) ) <= nTol
FUNCTION Ery_SetDirection( e, vDir ) ; e[ "direction" ] := Vc3_Normalize( vDir ) ; RETURN NIL
FUNCTION Ery_BoundingBox( e ) ; RETURN Bb3_FromPoints( { e[ "base_point" ], Ery_PointAt( e, 10000000000.0 ) } )
FUNCTION Ery_Translate( e, vOffset ) ; e[ "base_point" ] := Vc3_Add( e[ "base_point" ], vOffset ) ; RETURN NIL
FUNCTION Ery_Transform( e, t )
   e[ "base_point" ] := Tf_Apply( t, e[ "base_point" ] )
   e[ "direction" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "direction" ] ) )
RETURN NIL

/* ---- XLine ---- */
FUNCTION Exl_New( vBase, vDir ) ; RETURN hb_Hash( "_type", "XLINE", "common", Ec_New(), "base_point", vBase, "direction", Vc3_Normalize( vDir ) )
FUNCTION Exl_Default() ; RETURN Exl_New( Vc3_Zero(), Vc3_UnitX() )
FUNCTION Exl_FromPoints( v1, v2 ) ; RETURN Exl_New( v1, Vc3_Normalize( Vc3_Sub( v2, v1 ) ) )
FUNCTION Exl_Horizontal( v ) ; RETURN Exl_New( v, Vc3_UnitX() )
FUNCTION Exl_Vertical( v ) ; RETURN Exl_New( v, Vc3_UnitY() )
FUNCTION Exl_AlongZ( v ) ; RETURN Exl_New( v, Vc3_UnitZ() )
FUNCTION Exl_AtAngle( v, nAng ) ; RETURN Exl_New( v, Vc3_New( OCX_COS( nAng ), OCX_SIN( nAng ), 0.0 ) )
FUNCTION Exl_PointAt( e, t ) ; RETURN Vc3_Add( e[ "base_point" ], Vc3_Mul( e[ "direction" ], t ) )
FUNCTION Exl_ClosestPoint( e, p ) ; RETURN Exl_PointAt( e, Vc3_Dot( Vc3_Sub( p, e[ "base_point" ] ), e[ "direction" ] ) )
FUNCTION Exl_DistanceToPoint( e, p ) ; RETURN Vc3_Distance( Exl_ClosestPoint( e, p ), p )
FUNCTION Exl_ContainsPoint( e, p, nTol ) ; RETURN Exl_DistanceToPoint( e, p ) <= nTol
FUNCTION Exl_AngleXY( e ) ; RETURN OCX_ATAN2( e[ "direction" ][ 2 ], e[ "direction" ][ 1 ] )
FUNCTION Exl_AngleFromXY( e ) ; RETURN OCX_ATAN2( e[ "direction" ][ 3 ], Sqrt( e[ "direction" ][ 1 ] ^ 2 + e[ "direction" ][ 2 ] ^ 2 ) )
FUNCTION Exl_IsParallelTo( e, o, nTol ) ; RETURN Vc3_Length( Vc3_Cross( e[ "direction" ], o[ "direction" ] ) ) <= nTol
FUNCTION Exl_IsPerpendicularTo( e, o, nTol ) ; RETURN Abs( Vc3_Dot( e[ "direction" ], o[ "direction" ] ) ) <= nTol
/* Devuelve el punto o NIL (Option) */
FUNCTION Exl_Intersection( e, o, nTol )
   LOCAL w, a, b, c, d, ee, nDen, t1, t2, p1, p2
   IF Vc3_Length( Vc3_Cross( e[ "direction" ], o[ "direction" ] ) ) <= nTol ; RETURN NIL ; ENDIF
   w := Vc3_Sub( e[ "base_point" ], o[ "base_point" ] )
   a := Vc3_Dot( e[ "direction" ], e[ "direction" ] ) ; b := Vc3_Dot( e[ "direction" ], o[ "direction" ] )
   c := Vc3_Dot( o[ "direction" ], o[ "direction" ] ) ; d := Vc3_Dot( e[ "direction" ], w ) ; ee := Vc3_Dot( o[ "direction" ], w )
   nDen := a * c - b * b
   IF Abs( nDen ) <= nTol ; RETURN NIL ; ENDIF
   t1 := ( b * ee - c * d ) / nDen ; t2 := ( a * ee - b * d ) / nDen
   p1 := Exl_PointAt( e, t1 ) ; p2 := Exl_PointAt( o, t2 )
   IF Vc3_Distance( p1, p2 ) <= nTol ; RETURN p1 ; ENDIF
RETURN NIL
FUNCTION Exl_SetDirection( e, vDir ) ; e[ "direction" ] := Vc3_Normalize( vDir ) ; RETURN NIL
FUNCTION Exl_BoundingBox( e ) ; RETURN Bb3_FromPoints( { Exl_PointAt( e, -10000000000.0 ), Exl_PointAt( e, 10000000000.0 ) } )
FUNCTION Exl_Translate( e, vOffset ) ; e[ "base_point" ] := Vc3_Add( e[ "base_point" ], vOffset ) ; RETURN NIL
FUNCTION Exl_Transform( e, t )
   e[ "base_point" ] := Tf_Apply( t, e[ "base_point" ] )
   e[ "direction" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "direction" ] ) )
RETURN NIL

/* ---- Solid ---- */
FUNCTION Eso_New( v1, v2, v3, v4 )
RETURN hb_Hash( "_type", "SOLID", "common", Ec_New(), "first_corner", v1, "second_corner", v2, "third_corner", v3, "fourth_corner", v4, ;
                "normal", Vc3_UnitZ(), "thickness", 0.0, "is_trace", .F. )
FUNCTION Eso_Triangle( v1, v2, v3 ) ; RETURN Eso_New( v1, v2, v3, v3 )
FUNCTION Eso_IsTriangle( e ) ; RETURN Vc3_Length( Vc3_Sub( e[ "third_corner" ], e[ "fourth_corner" ] ) ) < 0.0000000001
FUNCTION Eso_Corners( e )
   IF Eso_IsTriangle( e ) ; RETURN { e[ "first_corner" ], e[ "second_corner" ], e[ "third_corner" ] } ; ENDIF
RETURN { e[ "first_corner" ], e[ "second_corner" ], e[ "third_corner" ], e[ "fourth_corner" ] }
FUNCTION Eso_BoundaryCorners( e )
   IF Eso_IsTriangle( e ) ; RETURN { e[ "first_corner" ], e[ "second_corner" ], e[ "third_corner" ] } ; ENDIF
RETURN { e[ "first_corner" ], e[ "second_corner" ], e[ "fourth_corner" ], e[ "third_corner" ] }
FUNCTION Eso_BoundingBox( e ) ; RETURN Bb3_OcsToWcs( Bb3_FromPoints( Eso_Corners( e ) ), e[ "normal" ] )
FUNCTION Eso_Translate( e, vOffset )
   LOCAL v := OcsOff( e[ "normal" ], vOffset ), k
   FOR EACH k IN { "first_corner", "second_corner", "third_corner", "fourth_corner" }
      e[ k ] := Vc3_Add( e[ k ], v )
   NEXT
RETURN NIL
FUNCTION Eso_Transform( e, t )
   LOCAL vNn := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) ), mOcs := Mx3_ArbitraryAxis( e[ "normal" ] )
   LOCAL mNt := Mx3_Transpose( Mx3_ArbitraryAxis( vNn ) ), k
   FOR EACH k IN { "first_corner", "second_corner", "third_corner", "fourth_corner" }
      e[ k ] := Mx3_TransformPoint( mNt, Tf_Apply( t, Mx3_TransformPoint( mOcs, e[ k ] ) ) )
   NEXT
   e[ "normal" ] := vNn
RETURN NIL
FUNCTION Eso_Mirror( e, t )
   LOCAL v
   Eso_Transform( e, t )
   v := e[ "second_corner" ] ; e[ "second_corner" ] := e[ "fourth_corner" ] ; e[ "fourth_corner" ] := v
RETURN NIL

/* ---- Face3D ---- */
FUNCTION Ef3_New( v1, v2, v3, v4 )
RETURN hb_Hash( "_type", "3DFACE", "common", Ec_New(), "first_corner", v1, "second_corner", v2, "third_corner", v3, "fourth_corner", v4, "invisible_edges", 0 )
FUNCTION Ef3_Triangle( v1, v2, v3 ) ; RETURN Ef3_New( v1, v2, v3, v3 )
FUNCTION Ef3_IsTriangle( e ) ; RETURN Vc3_Length( Vc3_Sub( e[ "third_corner" ], e[ "fourth_corner" ] ) ) < 0.0000000001
FUNCTION Ef3_Corners( e )
   IF Ef3_IsTriangle( e ) ; RETURN { e[ "first_corner" ], e[ "second_corner" ], e[ "third_corner" ] } ; ENDIF
RETURN { e[ "first_corner" ], e[ "second_corner" ], e[ "third_corner" ], e[ "fourth_corner" ] }
FUNCTION Ef3_Area( e )
   LOCAL v1 := Vc3_Sub( e[ "second_corner" ], e[ "first_corner" ] ), v2 := Vc3_Sub( e[ "third_corner" ], e[ "first_corner" ] ), a1, v4
   a1 := Vc3_Length( Vc3_Cross( v1, v2 ) ) * 0.5
   IF Ef3_IsTriangle( e ) ; RETURN a1 ; ENDIF
   v4 := Vc3_Sub( e[ "fourth_corner" ], e[ "first_corner" ] )
RETURN a1 + Vc3_Length( Vc3_Cross( v2, v4 ) ) * 0.5
FUNCTION Ef3_BoundingBox( e ) ; RETURN Bb3_FromPoints( Ef3_Corners( e ) )
FUNCTION Ef3_Translate( e, vOffset )
   LOCAL k
   FOR EACH k IN { "first_corner", "second_corner", "third_corner", "fourth_corner" }
      e[ k ] := Vc3_Add( e[ k ], vOffset )
   NEXT
RETURN NIL
FUNCTION Ef3_Transform( e, t )
   LOCAL k
   FOR EACH k IN { "first_corner", "second_corner", "third_corner", "fourth_corner" }
      e[ k ] := Tf_Apply( t, e[ k ] )
   NEXT
RETURN NIL
FUNCTION Ef3_Mirror( e, t )
   LOCAL v
   Ef3_Transform( e, t )
   v := e[ "second_corner" ] ; e[ "second_corner" ] := e[ "fourth_corner" ] ; e[ "fourth_corner" ] := v
RETURN NIL
/* InvisibleEdgeFlags: bits 1,2,4,8. nEdge 1..4 */
FUNCTION Ief_IsInvisible( nBits, nEdge ) ; RETURN hb_bitAnd( nBits, hb_bitShift( 1, nEdge - 1 ) ) != 0
FUNCTION Ief_Set( nBits, nEdge, lValue )
   LOCAL n := hb_bitShift( 1, nEdge - 1 )
RETURN iif( lValue, hb_bitOr( nBits, n ), hb_bitAnd( nBits, hb_bitXor( 255, n ) ) )
