/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_spline.prg
   Origen Rust: opencadcodec/src/entities/spline.rs (332, 5 tests)
              + translate_spline, transform_spline, transform_normal. Licencia del original: MPL-2.0.
   Entidad = hash ("_type" "SPLINE"); SplineFlags = hash de logicos. Option -> NIL.
   Tuplas Rust (p, knots) -> { p, aKnots }. Prefijos: Esf_ (SplineFlags), Esp_ (Spline).
   Tests en t_codec_spline.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

/* transform.rs: transform_normal (inversa traspuesta del 3x3 superior) */
FUNCTION Tf_TransformNormal( t, vNormal )
   LOCAL m := t[ 1 ], mUp, mInv, vT, nLen
   mUp := { { m[1][1], m[1][2], m[1][3] }, { m[2][1], m[2][2], m[2][3] }, { m[3][1], m[3][2], m[3][3] } }
   mInv := Mx3_Inverse( mUp )
   IF mInv == NIL ; RETURN vNormal ; ENDIF
   vT := Mx3_TransformPoint( Mx3_Transpose( mInv ), vNormal )
   nLen := Vc3_Length( vT )
   IF nLen < 0.0000000001 ; RETURN vNormal ; ENDIF
RETURN Vc3_Mul( vT, 1.0 / nLen )

FUNCTION Esf_New() ; RETURN hb_Hash( "closed", .F., "periodic", .F., "rational", .F., "planar", .F., "linear", .F. )

FUNCTION Esp_New()
RETURN hb_Hash( "_type", "SPLINE", "common", Ec_New(), "degree", 3, "flags", Esf_New(), "knots", {}, "control_points", {}, "weights", {}, "fit_points", {}, ;
                "normal", Vc3_UnitZ(), "knot_tolerance", 0.0, "control_tolerance", 0.0, "fit_tolerance", 0.0, "begin_tangent", Vc3_Zero(), "end_tangent", Vc3_Zero(), ;
                "knot_parameterization", 0, "cv_frame_visible", .F., "dwg_flags1", 0, "dwg_scenario", NIL, "dxf_flags", 0 )

/* Devuelve { degree efectivo, aKnots } */
FUNCTION Esp_ClampedKnotsWithDegree( nDegree, n )
   LOCAL nMax, p, nInternal, aKv := {}, i
   IF n < 2 ; RETURN { nDegree, {} } ; ENDIF
   nMax := Min( n - 1, 2147483647 )
   p := Min( Max( nDegree, 1 ), nMax )
   nInternal := n - p - 1
   FOR i := 1 TO p + 1 ; AAdd( aKv, 0.0 ) ; NEXT
   FOR i := 1 TO nInternal ; AAdd( aKv, i / ( nInternal + 1 ) ) ; NEXT
   FOR i := 1 TO p + 1 ; AAdd( aKv, 1.0 ) ; NEXT
RETURN { p, aKv }
FUNCTION Esp_GenerateClampedKnots( nDegree, nNumControlPoints ) ; RETURN Esp_ClampedKnotsWithDegree( Min( nDegree, 2147483647 ), nNumControlPoints )[ 2 ]
FUNCTION Esp_FromControlPoints( nDegree, aPts )
   LOCAL e := Esp_New(), r := Esp_ClampedKnotsWithDegree( nDegree, Len( aPts ) )
   e[ "degree" ] := r[ 1 ] ; e[ "control_points" ] := aPts ; e[ "knots" ] := r[ 2 ]
RETURN e
FUNCTION Esp_FromFitPoints( aPts ) ; LOCAL e := Esp_New() ; e[ "fit_points" ] := aPts ; RETURN e
FUNCTION Esp_ControlPointCount( e ) ; RETURN Len( e[ "control_points" ] )
FUNCTION Esp_KnotCount( e ) ; RETURN Len( e[ "knots" ] )
FUNCTION Esp_AddControlPoint( e, p ) ; AAdd( e[ "control_points" ], p ) ; RETURN NIL
FUNCTION Esp_AddKnot( e, n ) ; AAdd( e[ "knots" ], n ) ; RETURN NIL

FUNCTION Esp_BoundingBox( e )
   IF Len( e[ "control_points" ] ) == 0
      IF Len( e[ "fit_points" ] ) == 0 ; RETURN Bb3_FromPoint( Vc3_Zero() ) ; ENDIF
      RETURN Bb3_FromPoints( e[ "fit_points" ] )
   ENDIF
RETURN Bb3_FromPoints( e[ "control_points" ] )

FUNCTION Esp_Translate( e, vOffset )
   LOCAL i
   FOR i := 1 TO Len( e[ "control_points" ] ) ; e[ "control_points" ][ i ] := Vc3_Add( e[ "control_points" ][ i ], vOffset ) ; NEXT
   FOR i := 1 TO Len( e[ "fit_points" ] ) ; e[ "fit_points" ][ i ] := Vc3_Add( e[ "fit_points" ][ i ], vOffset ) ; NEXT
RETURN NIL

FUNCTION Esp_Transform( e, t )
   LOCAL i, aAx, nMax := 0.0, lOrth := .T., nDist, aPairs := { { 1, 2 }, { 1, 3 }, { 2, 3 } }, p
   FOR i := 1 TO Len( e[ "control_points" ] ) ; e[ "control_points" ][ i ] := Tf_Apply( t, e[ "control_points" ][ i ] ) ; NEXT
   FOR i := 1 TO Len( e[ "fit_points" ] ) ; e[ "fit_points" ][ i ] := Tf_Apply( t, e[ "fit_points" ][ i ] ) ; NEXT
   e[ "begin_tangent" ] := Tf_ApplyRotation( t, e[ "begin_tangent" ] )
   e[ "end_tangent" ] := Tf_ApplyRotation( t, e[ "end_tangent" ] )
   aAx := { Tf_ApplyRotation( t, Vc3_UnitX() ), Tf_ApplyRotation( t, Vc3_UnitY() ), Tf_ApplyRotation( t, Vc3_UnitZ() ) }
   FOR i := 1 TO 3 ; nMax := Max( nMax, Vc3_Length( aAx[ i ] ) ) ; NEXT
   FOR EACH p IN aPairs
      IF ! ( Abs( Vc3_Dot( aAx[ p[ 1 ] ], aAx[ p[ 2 ] ] ) ) <= 0.000000000001 * nMax ^ 2 ) ; lOrth := .F. ; ENDIF
   NEXT
   IF lOrth
      nDist := nMax
   ELSE
      nDist := Sqrt( Vc3_LengthSquared( aAx[ 1 ] ) + Vc3_LengthSquared( aAx[ 2 ] ) + Vc3_LengthSquared( aAx[ 3 ] ) )
   ENDIF
   e[ "control_tolerance" ] *= nDist
   e[ "fit_tolerance" ] *= nDist
   e[ "normal" ] := Tf_TransformNormal( t, e[ "normal" ] )
RETURN NIL
