/* Port de tests: spline.rs (5) + [extra] */
#include "ocx.ch"
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.000000001
STATIC FUNCTION AssertClamped( p, n, aK )
   LOCAL i, l := .T.
   IF Len( aK ) != n + p + 1 ; RETURN .F. ; ENDIF
   FOR i := 1 TO p + 1
      IF aK[ i ] != 0.0 ; l := .F. ; ENDIF
   NEXT
   FOR i := Len( aK ) - p TO Len( aK )
      IF aK[ i ] != 1.0 ; l := .F. ; ENDIF
   NEXT
   FOR i := 1 TO Len( aK ) - 1
      IF aK[ i ] > aK[ i + 1 ] ; l := .F. ; ENDIF
   NEXT
RETURN l
PROCEDURE T_CodecSpline()
   LOCAL r, n, l, d, e, pts
   r := Esp_ClampedKnotsWithDegree( 3, 6 )
   Chk( r[ 1 ] == 3 .AND. AssertClamped( r[ 1 ], 6, r[ 2 ] ) .AND. hb_ValToExp( r[ 2 ] ) == hb_ValToExp( Esp_GenerateClampedKnots( 3, 6 ) ), "spline: clamped_knots_regular_case" )
   l := .T.
   FOR n := 2 TO 4
      r := Esp_ClampedKnotsWithDegree( 3, n )
      IF r[ 1 ] != Min( n, 4 ) - 1 .OR. ! AssertClamped( r[ 1 ], n, r[ 2 ] ) ; l := .F. ; ENDIF
   NEXT
   r := Esp_ClampedKnotsWithDegree( 2147483647, 3 ) ; IF r[ 1 ] != 2 .OR. ! AssertClamped( 2, 3, r[ 2 ] ) ; l := .F. ; ENDIF
   IF Len( Esp_GenerateClampedKnots( 18446744073709551615, 2 ) ) != 4 ; l := .F. ; ENDIF
   Chk( l, "spline: clamped_knots_clamp_degree_to_point_count" )
   l := .T.
   FOR EACH d IN { 0, -1, -2147483648 }
      r := Esp_ClampedKnotsWithDegree( d, 3 )
      IF r[ 1 ] != 1 .OR. ! AssertClamped( 1, 3, r[ 2 ] ) ; l := .F. ; ENDIF
   NEXT
   Chk( l, "spline: clamped_knots_non_positive_degree_becomes_linear" )
   r := Esp_ClampedKnotsWithDegree( 3, 1 )
   Chk( r[ 1 ] == 3 .AND. Len( r[ 2 ] ) == 0 .AND. Esp_ClampedKnotsWithDegree( 3, 0 )[ 1 ] == 3 .AND. Len( Esp_GenerateClampedKnots( 3, 1 ) ) == 0, "spline: clamped_knots_single_or_no_point_is_empty" )
   e := Esp_FromControlPoints( 3, { Vc3_Zero(), Vc3_New( 1.0, 0.0, 0.0 ) } )
   Chk( e[ "degree" ] == 1 .AND. hb_ValToExp( e[ "knots" ] ) == hb_ValToExp( { 0.0, 0.0, 1.0, 1.0 } ), "spline: from_control_points_stores_effective_degree" )
   // [extra]
   pts := { Vc3_Zero(), Vc3_New( 1.0, 2.0, 3.0 ), Vc3_New( 4.0, 0.0, 1.0 ) } ; e := Esp_FromControlPoints( 2, pts )
   Chk( Esp_ControlPointCount( e ) == 3 .AND. Esp_KnotCount( e ) == 6 .AND. Ent_EntityType( e ) == "SPLINE", "[extra] spline: conteos" )
   Chk( Vc3_Eq( Ent_BoundingBox( e )[ 2 ], Vc3_New( 4.0, 2.0, 3.0 ) ) .AND. Vc3_Eq( Ent_BoundingBox( Esp_New() )[ 1 ], Vc3_Zero() ), "[extra] spline: bounding box" )
   Ent_Translate( e, Vc3_New( 1.0, 1.0, 1.0 ) ) ; Chk( Vc3_Eq( e[ "control_points" ][ 1 ], Vc3_New( 1.0, 1.0, 1.0 ) ), "[extra] spline: translate" )
   e[ "control_tolerance" ] := 1.0 ; Ent_ApplyScaling( e, 3.0 )
   Chk( Nr( e[ "control_tolerance" ], 3.0 ) .AND. Nr( e[ "control_points" ][ 1 ][ 1 ], 3.0 ), "[extra] spline: escala tolerancias" )
   Chk( Nr( Tf_TransformNormal( Tf_FromScaling( Vc3_New( 1.0, 1.0, 2.0 ) ), Vc3_New( 0.0, 1.0, 1.0 ) )[ 3 ], 0.4472135954999579 ), "[extra] transform_normal: escala no uniforme" )
RETURN
