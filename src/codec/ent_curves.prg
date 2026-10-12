/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_curves.prg
   Origen Rust: opencadcodec/src/entities/point.rs (160, 5 tests), circle.rs (218, 5 tests), arc.rs (329, 7 tests)
              + translate_/transform_/mirror_ de point, circle y arc (translate.rs, transform.rs, mirror.rs)
              + is_reflecting y ocs_offset/ocs_pair. Licencia del original: MPL-2.0.
   Entidades = hash ("_type" "POINT"/"CIRCLE"/"ARC"); ver ent_base.prg. Los tests estan en t_codec_curves.prg.
   Prefijos: Ept_ (Point), Eci_ (Circle), Ear_ (Arc).
----------------------------------------------------------------------------*/
#include "ocx.ch"

/* True si la transformacion invierte la orientacion (det 3x3 < 0) */
FUNCTION Tf_IsReflecting( t )
   LOCAL m := t[ 1 ]
RETURN Mx3_Determinant( { { m[1][1], m[1][2], m[1][3] }, { m[2][1], m[2][2], m[2][3] }, { m[3][1], m[3][2], m[3][3] } } ) < 0.0

STATIC FUNCTION OcsOffset( vNormal, vOffset ) ; RETURN Mx3_TransformPoint( Mx3_Transpose( Mx3_ArbitraryAxis( vNormal ) ), vOffset )

/* ---- Point ---- */
FUNCTION Ept_New()
RETURN hb_Hash( "_type", "POINT", "common", Ec_New(), "location", Vc3_Zero(), "thickness", 0.0, "normal", Vc3_UnitZ(), "x_axis_angle", 0.0 )
FUNCTION Ept_At( vLoc )
   LOCAL e := Ept_New()
   e[ "location" ] := vLoc
RETURN e
FUNCTION Ept_FromCoords( x, y, z ) ; RETURN Ept_At( Vc3_New( x, y, z ) )
FUNCTION Ept_BoundingBox( e ) ; RETURN Bb3_FromPoint( e[ "location" ] )
FUNCTION Ept_Translate( e, vOffset ) ; e[ "location" ] := Vc3_Add( e[ "location" ], vOffset ) ; RETURN NIL
FUNCTION Ept_Transform( e, t )
   e[ "location" ] := Tf_Apply( t, e[ "location" ] )
   e[ "normal" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
RETURN NIL

/* ---- Circle ---- */
FUNCTION Eci_New()
RETURN hb_Hash( "_type", "CIRCLE", "common", Ec_New(), "center", Vc3_Zero(), "radius", 1.0, "thickness", 0.0, "normal", Vc3_UnitZ() )
FUNCTION Eci_FromCenterRadius( vCenter, nRadius )
   LOCAL e := Eci_New()
   e[ "center" ] := vCenter ; e[ "radius" ] := nRadius
RETURN e
FUNCTION Eci_FromCoords( x, y, z, nRadius ) ; RETURN Eci_FromCenterRadius( Vc3_New( x, y, z ), nRadius )
FUNCTION Eci_Diameter( e ) ; RETURN e[ "radius" ] * 2.0
FUNCTION Eci_Circumference( e ) ; RETURN 2.0 * OCX_PI * e[ "radius" ]
FUNCTION Eci_Area( e ) ; RETURN OCX_PI * e[ "radius" ] * e[ "radius" ]
FUNCTION Eci_CenterWcs( e ) ; RETURN Mx3_TransformPoint( Mx3_ArbitraryAxis( e[ "normal" ] ), e[ "center" ] )
/* axes_wcs -> { axisX, axisY } */
FUNCTION Eci_AxesWcs( e )
   LOCAL b := Mx3_ArbitraryAxis( e[ "normal" ] )
RETURN { Mx3_TransformPoint( b, Vc3_New( 1.0, 0.0, 0.0 ) ), Mx3_TransformPoint( b, Vc3_New( 0.0, 1.0, 0.0 ) ) }
FUNCTION Eci_PointAtAngleWcs( e, nAngle )
   LOCAL c := Eci_CenterWcs( e ), a := Eci_AxesWcs( e )
RETURN Vc3_Add( Vc3_Add( c, Vc3_Mul( a[ 1 ], e[ "radius" ] * OCX_COS( nAngle ) ) ), Vc3_Mul( a[ 2 ], e[ "radius" ] * OCX_SIN( nAngle ) ) )
FUNCTION Eci_BoundingBox( e )
   LOCAL c := Eci_CenterWcs( e ), a := Eci_AxesWcs( e ), r := e[ "radius" ], ex, op
   ex := Vc3_New( r * OCX_HYPOT( a[1][1], a[2][1] ), r * OCX_HYPOT( a[1][2], a[2][2] ), r * OCX_HYPOT( a[1][3], a[2][3] ) )
   op := Vc3_Add( c, Vc3_Mul( Vc3_Normalize( e[ "normal" ] ), e[ "thickness" ] ) )
RETURN Bb3_New( Vc3_New( Min( c[1] - ex[1], op[1] - ex[1] ), Min( c[2] - ex[2], op[2] - ex[2] ), Min( c[3] - ex[3], op[3] - ex[3] ) ), ;
                Vc3_New( Max( c[1] + ex[1], op[1] + ex[1] ), Max( c[2] + ex[2], op[2] + ex[2] ), Max( c[3] + ex[3], op[3] + ex[3] ) ) )
FUNCTION Eci_Translate( e, vOffset ) ; e[ "center" ] := Vc3_Add( e[ "center" ], OcsOffset( e[ "normal" ], vOffset ) ) ; RETURN NIL
FUNCTION Eci_Transform( e, t )
   LOCAL vNew := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
   LOCAL mOcs := Mx3_ArbitraryAxis( e[ "normal" ] ), mNewT := Mx3_Transpose( Mx3_ArbitraryAxis( vNew ) )
   e[ "center" ] := Mx3_TransformPoint( mNewT, Tf_Apply( t, Mx3_TransformPoint( mOcs, e[ "center" ] ) ) )
   e[ "radius" ] *= Vc3_Length( Tf_ApplyRotation( t, Vc3_New( 1.0, 0.0, 0.0 ) ) )
   e[ "normal" ] := vNew
RETURN NIL

/* ---- Arc ---- */
FUNCTION Ear_New()
RETURN hb_Hash( "_type", "ARC", "common", Ec_New(), "center", Vc3_Zero(), "radius", 1.0, "start_angle", 0.0, "end_angle", OCX_PI / 2.0, "thickness", 0.0, "normal", Vc3_UnitZ() )
FUNCTION Ear_FromCenterRadiusAngles( vCenter, nRadius, nStart, nEnd )
   LOCAL e := Ear_New()
   e[ "center" ] := vCenter ; e[ "radius" ] := nRadius ; e[ "start_angle" ] := nStart ; e[ "end_angle" ] := nEnd
RETURN e
FUNCTION Ear_FromCoords( x, y, z, nRadius, nStart, nEnd ) ; RETURN Ear_FromCenterRadiusAngles( Vc3_New( x, y, z ), nRadius, nStart, nEnd )
FUNCTION Ear_SweepAngle( e )
   LOCAL n := e[ "end_angle" ] - e[ "start_angle" ]
   IF n < 0.0 ; n += 2.0 * OCX_PI ; ENDIF
RETURN n
FUNCTION Ear_ArcLength( e ) ; RETURN e[ "radius" ] * Ear_SweepAngle( e )
STATIC FUNCTION ArPt( e, nAng ) ; RETURN Vc3_New( e[ "center" ][ 1 ] + e[ "radius" ] * OCX_COS( nAng ), e[ "center" ][ 2 ] + e[ "radius" ] * OCX_SIN( nAng ), e[ "center" ][ 3 ] )
FUNCTION Ear_StartPoint( e ) ; RETURN ArPt( e, e[ "start_angle" ] )
FUNCTION Ear_EndPoint( e ) ; RETURN ArPt( e, e[ "end_angle" ] )
FUNCTION Ear_Midpoint( e ) ; RETURN ArPt( e, e[ "start_angle" ] + Ear_SweepAngle( e ) / 2.0 )
FUNCTION Ear_CenterWcs( e ) ; RETURN Mx3_TransformPoint( Mx3_ArbitraryAxis( e[ "normal" ] ), e[ "center" ] )
FUNCTION Ear_PointAtAngleWcs( e, nAngle )
   LOCAL l := Vc3_Add( e[ "center" ], Vc3_New( e[ "radius" ] * OCX_COS( nAngle ), e[ "radius" ] * OCX_SIN( nAngle ), 0.0 ) )
RETURN Mx3_TransformPoint( Mx3_ArbitraryAxis( e[ "normal" ] ), l )
FUNCTION Ear_StartPointWcs( e ) ; RETURN Ear_PointAtAngleWcs( e, e[ "start_angle" ] )
FUNCTION Ear_EndPointWcs( e ) ; RETURN Ear_PointAtAngleWcs( e, e[ "end_angle" ] )
FUNCTION Ear_MidpointWcs( e ) ; RETURN Ear_PointAtAngleWcs( e, e[ "start_angle" ] + Ear_SweepAngle( e ) * 0.5 )
STATIC FUNCTION ArContains( e, nAngle )
   LOCAL nSweep := Ear_SweepAngle( e )
RETURN nSweep >= OCX_TAU - 0.000000000001 .OR. OCX_REMEUCLID( nAngle - e[ "start_angle" ], OCX_TAU ) <= nSweep + 0.000000000001
FUNCTION Ear_BoundingBox( e )
   LOCAL b := Mx3_ArbitraryAxis( e[ "normal" ] ), ax := Mx3_TransformPoint( b, Vc3_New( 1.0, 0.0, 0.0 ) ), ay := Mx3_TransformPoint( b, Vc3_New( 0.0, 1.0, 0.0 ) )
   LOCAL aAng := { e[ "start_angle" ], e[ "end_angle" ] }, nA, nC, aPts := {}, vN := Vc3_Normalize( e[ "normal" ] ), vBase
   FOR EACH nA IN { OCX_ATAN2( ay[1], ax[1] ), OCX_ATAN2( ay[2], ax[2] ), OCX_ATAN2( ay[3], ax[3] ) }
      FOR EACH nC IN { nA, nA + OCX_PI }
         IF ArContains( e, nC ) ; AAdd( aAng, nC ) ; ENDIF
      NEXT
   NEXT
   FOR EACH nA IN aAng
      vBase := Ear_PointAtAngleWcs( e, nA ) ; AAdd( aPts, vBase )
      IF e[ "thickness" ] != 0.0 ; AAdd( aPts, Vc3_Add( vBase, Vc3_Mul( vN, e[ "thickness" ] ) ) ) ; ENDIF
   NEXT
   b := Bb3_FromPoints( aPts )
RETURN IIf( b == NIL, Bb3_Default(), b )
FUNCTION Ear_Translate( e, vOffset ) ; e[ "center" ] := Vc3_Add( e[ "center" ], OcsOffset( e[ "normal" ], vOffset ) ) ; RETURN NIL
FUNCTION Ear_Transform( e, t )
   LOCAL mOcs := Mx3_ArbitraryAxis( e[ "normal" ] ), vCw := Mx3_TransformPoint( mOcs, e[ "center" ] )
   LOCAL vWs, vWe, vNc, nScale, vNn, mNt, nAs, nAe, nR := e[ "radius" ]
   vWs := Tf_Apply( t, Vc3_Add( vCw, Mx3_TransformPoint( mOcs, Vc3_New( nR * OCX_COS( e[ "start_angle" ] ), nR * OCX_SIN( e[ "start_angle" ] ), 0.0 ) ) ) )
   vWe := Tf_Apply( t, Vc3_Add( vCw, Mx3_TransformPoint( mOcs, Vc3_New( nR * OCX_COS( e[ "end_angle" ] ), nR * OCX_SIN( e[ "end_angle" ] ), 0.0 ) ) ) )
   vNc := Tf_Apply( t, vCw )
   nScale := Vc3_Length( Tf_ApplyRotation( t, Vc3_New( 1.0, 0.0, 0.0 ) ) )
   vNn := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
   mNt := Mx3_Transpose( Mx3_ArbitraryAxis( vNn ) )
   nAs := ArAngleOf( mNt, vWs, vNc ) ; nAe := ArAngleOf( mNt, vWe, vNc )
   IF Tf_IsReflecting( t )
      e[ "start_angle" ] := nAe ; e[ "end_angle" ] := nAs
   ELSE
      e[ "start_angle" ] := nAs ; e[ "end_angle" ] := nAe
   ENDIF
   e[ "center" ] := Mx3_TransformPoint( mNt, vNc )
   e[ "radius" ] *= nScale
   e[ "normal" ] := vNn
RETURN NIL
STATIC FUNCTION ArAngleOf( mNt, vW, vC )
   LOCAL l := Mx3_TransformPoint( mNt, Vc3_Sub( vW, vC ) )
RETURN OCX_ATAN2( l[ 2 ], l[ 1 ] )
/* mirror_arc delega en transform_arc */
FUNCTION Ear_Mirror( e, t ) ; Ear_Transform( e, t ) ; RETURN NIL
