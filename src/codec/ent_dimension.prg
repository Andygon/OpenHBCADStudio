/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_dimension.prg
   Origen Rust: opencadcodec/src/entities/dimension.rs (1114, sin tests)
              + translate_dimension (translate.rs) + transform_dimension y transform_dimension_angle (transform.rs). Licencia del original: MPL-2.0.
   Modelo: enum Dimension = hash con "_type" = entity_type() (DIMENSION_ALIGNED, DIMENSION_LINEAR, DIMENSION_RADIUS, DIMENSION_DIAMETER,
   DIMENSION_ANGULAR_2LINE, DIMENSION_ANGULAR_3POINT, DIMENSION_ORDINATE, ARC_DIMENSION, LARGE_RADIAL_DIMENSION), "base" (DimensionBase) y los
   campos de cada variante. "common" es el MISMO objeto que base["common"] (Ent_Clone conserva el enlace).
   Prefijos: Dmb_ base, Dal_ aligned, Dli_ linear, Dra_ radius, Ddi_ diameter, Da2_ angular 2 lineas, Da3_ angular 3 puntos, Dor_ ordinate,
   Dar_ arc, Dlr_ large radial, Edm_ funciones del enum Dimension.
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION Z3() ; RETURN Vc3_Zero()

// ---- DimensionBase ----
FUNCTION Dmb_New( nDimType )
RETURN hb_Hash( "common", Ec_New(), "definition_point", Z3(), "text_middle_point", Z3(), "insertion_point", Z3(), "dimension_type", nDimType, ;
   "attachment_point", DAP_MIDDLECENTER, "text", "", "user_text", NIL, "normal", Vc3_UnitZ(), "text_rotation", 0.0, "horizontal_direction", 0.0, ;
   "style_name", "Standard", "actual_measurement", 0.0, "version", 0, "block_name", "", "line_spacing_factor", 1.0, "line_spacing_style", 1, ;
   "insertion_scale", Vc3_New( 1.0, 1.0, 1.0 ), "insertion_rotation", 0.0, "dwg_unknown_bit", .F., "flip_arrow1", .F., "flip_arrow2", .F., ;
   "dwg_flags_byte", 0, "text_user_positioned", .F. )
FUNCTION Dmb_Default() ; RETURN Dmb_New( DMT_LINEAR )
/* Option<&str>: user_text, o el texto si no esta vacio */
FUNCTION Dmb_TextOverride( b )
   IF b[ "user_text" ] != NIL ; RETURN b[ "user_text" ] ; ENDIF
RETURN iif( Len( b[ "text" ] ) > 0, b[ "text" ], NIL )
FUNCTION Dmb_SetTextOverride( b, cText ) ; b[ "text" ] := iif( cText == NIL, "", cText ) ; b[ "user_text" ] := cText ; RETURN NIL
FUNCTION Dmb_WithText( b, cText ) ; Dmb_SetTextOverride( b, cText ) ; RETURN b
FUNCTION Dmb_WithStyle( b, cStyle ) ; b[ "style_name" ] := cStyle ; RETURN b
FUNCTION Dmb_WithNormal( b, vN ) ; b[ "normal" ] := vN ; RETURN b
FUNCTION Dmb_IsAngular( b ) ; RETURN b[ "dimension_type" ] == DMT_ANGULAR .OR. b[ "dimension_type" ] == DMT_ANGULAR3PT

STATIC FUNCTION NewDim( cType, nDimType, hFields )
   LOCAL b := Dmb_New( nDimType ), h := hb_Hash( "_type", cType, "common", b[ "common" ], "base", b ), k
   FOR EACH k IN hb_HKeys( hFields ) ; h[ k ] := hFields[ k ] ; NEXT
RETURN h

// ---- Aligned ----
FUNCTION Dal_Default() ; RETURN NewDim( "DIMENSION_ALIGNED", DMT_ALIGNED, hb_Hash( "first_point", Z3(), "second_point", Z3(), "definition_point", Z3(), "ext_line_rotation", 0.0 ) )
FUNCTION Dal_New( vFirst, vSecond )
   LOCAL d := Dal_Default()
   d[ "base" ][ "actual_measurement" ] := Vc3_Distance( vFirst, vSecond )
   d[ "first_point" ] := vFirst ; d[ "second_point" ] := vSecond
RETURN d
FUNCTION Dal_Measurement( d ) ; RETURN Vc3_Distance( d[ "first_point" ], d[ "second_point" ] )
FUNCTION Dal_SetOffset( d, nOffset )
   LOCAL vDir := Vc3_Sub( d[ "second_point" ], d[ "first_point" ] ), vPerp := Vc3_Normalize( Vc3_New( -vDir[ 2 ], vDir[ 1 ], 0.0 ) )
   d[ "definition_point" ] := Vc3_Add( d[ "second_point" ], Vc3_Mul( vPerp, nOffset ) )
RETURN NIL
FUNCTION Dal_Offset( d ) ; RETURN Vc3_Distance( d[ "second_point" ], d[ "definition_point" ] )

// ---- Linear ----
FUNCTION Dli_Default() ; RETURN NewDim( "DIMENSION_LINEAR", DMT_LINEAR, hb_Hash( "first_point", Z3(), "second_point", Z3(), "definition_point", Z3(), "rotation", 0.0, "ext_line_rotation", 0.0 ) )
FUNCTION Dli_New( vFirst, vSecond )
   LOCAL d := Dli_Default()
   d[ "base" ][ "actual_measurement" ] := Vc3_Distance( vFirst, vSecond )
   d[ "first_point" ] := vFirst ; d[ "second_point" ] := vSecond
RETURN d
FUNCTION Dli_Horizontal( vFirst, vSecond ) ; RETURN Dli_New( vFirst, vSecond )
FUNCTION Dli_Vertical( vFirst, vSecond ) ; LOCAL d := Dli_New( vFirst, vSecond ) ; d[ "rotation" ] := OCX_PI / 2.0 ; RETURN d
FUNCTION Dli_Rotated( vFirst, vSecond, nAngle ) ; LOCAL d := Dli_New( vFirst, vSecond ) ; d[ "rotation" ] := nAngle ; RETURN d
FUNCTION Dli_Measurement( d )
   LOCAL vDiff := Mx3_TransformPoint( Mx3_Transpose( Mx3_ArbitraryAxis( d[ "base" ][ "normal" ] ) ), Vc3_Sub( d[ "second_point" ], d[ "first_point" ] ) )
   LOCAL nProj := vDiff[ 1 ] * OCX_COS( d[ "rotation" ] ) + vDiff[ 2 ] * OCX_SIN( d[ "rotation" ] )
RETURN iif( OCX_ISFINITE( nProj ), Abs( nProj ), 0.0 )
FUNCTION Dli_SetOffset( d, nOffset )
   LOCAL vAxisY := Vc3_New( -OCX_SIN( d[ "rotation" ] ), OCX_COS( d[ "rotation" ] ), 0.0 )
   d[ "definition_point" ] := Vc3_Add( d[ "second_point" ], Vc3_Mul( vAxisY, nOffset ) )
RETURN NIL

// ---- Radius / Diameter ----
FUNCTION Dra_Default() ; RETURN NewDim( "DIMENSION_RADIUS", DMT_RADIUS, hb_Hash( "definition_point", Z3(), "angle_vertex", Z3(), "leader_length", 0.0 ) )
FUNCTION Dra_New( vCenter, vPointOnArc )
   LOCAL d := Dra_Default()
   d[ "base" ][ "actual_measurement" ] := Vc3_Distance( vCenter, vPointOnArc )
   d[ "definition_point" ] := vPointOnArc ; d[ "angle_vertex" ] := vCenter
RETURN d
FUNCTION Dra_Measurement( d ) ; RETURN Vc3_Distance( d[ "definition_point" ], d[ "angle_vertex" ] )
FUNCTION Ddi_Default() ; RETURN NewDim( "DIMENSION_DIAMETER", DMT_DIAMETER, hb_Hash( "definition_point", Z3(), "angle_vertex", Z3(), "leader_length", 0.0 ) )
FUNCTION Ddi_New( vChord, vFarChord )
   LOCAL d := Ddi_Default()
   d[ "base" ][ "definition_point" ] := vFarChord
   d[ "base" ][ "actual_measurement" ] := Vc3_Distance( vChord, vFarChord )
   d[ "definition_point" ] := vFarChord ; d[ "angle_vertex" ] := vChord
RETURN d
FUNCTION Ddi_Measurement( d ) ; RETURN Vc3_Distance( d[ "definition_point" ], d[ "angle_vertex" ] )
FUNCTION Ddi_Center( d ) ; RETURN Vc3_Mul( Vc3_Add( d[ "angle_vertex" ], d[ "definition_point" ] ), 0.5 )

// ---- helpers angulares (funciones privadas de dimension.rs) ----
STATIC FUNCTION MinorAngleRadians( v1, v2 )
   LOCAL n1 := Vc3_Length( v1 ), n2 := Vc3_Length( v2 ), nC
   IF n1 <= OCX_EPSILON() .OR. n2 <= OCX_EPSILON() ; RETURN 0.0 ; ENDIF
   nC := Vc3_Dot( v1, v2 ) / ( n1 * n2 )
RETURN OCX_ACOS( Max( -1.0, Min( 1.0, nC ) ) )

/* Option<Vector3> */
STATIC FUNCTION LineIntersection( vO1, vD1, vO2, vD2 )
   LOCAL vCross := Vc3_Cross( vD1, vD2 ), nDen := Vc3_LengthSquared( vCross ), nScaleD := Vc3_LengthSquared( vD1 ) * Vc3_LengthSquared( vD2 )
   LOCAL vOff, nP1, nP2, vP1, vP2, nScale
   IF ! OCX_ISFINITE( nDen ) .OR. nDen <= nScaleD * 0.000000000000000000000001 ; RETURN NIL ; ENDIF
   vOff := Vc3_Sub( vO2, vO1 )
   nP1 := Vc3_Dot( Vc3_Cross( vOff, vD2 ), vCross ) / nDen
   nP2 := Vc3_Dot( Vc3_Cross( vOff, vD1 ), vCross ) / nDen
   vP1 := Vc3_Add( vO1, Vc3_Mul( vD1, nP1 ) ) ; vP2 := Vc3_Add( vO2, Vc3_Mul( vD2, nP2 ) )
   nScale := Max( Max( Vc3_Length( vP1 ), Vc3_Length( vP2 ) ), 1.0 )
   IF Vc3_Distance( vP1, vP2 ) <= nScale * 0.000000001
      RETURN Vc3_Mul( Vc3_Add( vP1, vP2 ), 0.5 )
   ENDIF
RETURN NIL

STATIC FUNCTION NormAng( vV, vAx, vAy ) ; RETURN OCX_REMEUCLID( OCX_ATAN2( Vc3_Dot( vV, vAy ), Vc3_Dot( vV, vAx ) ), OCX_TAU )

/* Option<f64> */
STATIC FUNCTION SelectedLineSectorRadians( vVertex, vD1, vD2, vArcPoint, vPrefNormal )
   LOCAL vArcDir, vCross, nPrefScale, lPrefIsNormal, vNormal, vAx, vAy, nFirst, nSecond, nSel, aB, i, nStart, nEnd, nS2
   IF Vc3_LengthSquared( vD1 ) <= OCX_EPSILON() .OR. Vc3_LengthSquared( vD2 ) <= OCX_EPSILON() ; RETURN NIL ; ENDIF
   vArcDir := Vc3_Sub( vArcPoint, vVertex )
   IF Vc3_LengthSquared( vArcDir ) <= OCX_EPSILON() ; RETURN NIL ; ENDIF
   vCross := Vc3_Cross( vD1, vD2 )
   nPrefScale := Vc3_Length( vPrefNormal ) * Max( Vc3_Length( vD1 ), Vc3_Length( vD2 ) )
   lPrefIsNormal := Vc3_LengthSquared( vPrefNormal ) > OCX_EPSILON() .AND. Abs( Vc3_Dot( vPrefNormal, vD1 ) ) <= nPrefScale * 0.000000001 .AND. Abs( Vc3_Dot( vPrefNormal, vD2 ) ) <= nPrefScale * 0.000000001
   DO CASE
   CASE lPrefIsNormal ; vNormal := Vc3_Normalize( vPrefNormal )
   CASE Vc3_LengthSquared( vCross ) > OCX_EPSILON() ; vNormal := Vc3_Normalize( vCross )
   OTHERWISE ; RETURN NIL
   ENDCASE
   vAx := Vc3_Normalize( vD1 ) ; vAy := Vc3_Normalize( Vc3_Cross( vNormal, vAx ) )
   nFirst := NormAng( vD1, vAx, vAy ) ; nSecond := NormAng( vD2, vAx, vAy ) ; nSel := NormAng( vArcDir, vAx, vAy )
   aB := { nFirst, OCX_REMEUCLID( nFirst + OCX_PI, OCX_TAU ), nSecond, OCX_REMEUCLID( nSecond + OCX_PI, OCX_TAU ) }
   ASort( aB )
   FOR i := 1 TO 4
      nStart := aB[ i ]
      nEnd := iif( i < 4, aB[ i + 1 ], aB[ 1 ] + OCX_TAU )
      nS2 := iif( nSel + 0.000000000001 < nStart, nSel + OCX_TAU, nSel )
      IF nS2 >= nStart - 0.000000000001 .AND. nS2 <= nEnd + 0.000000000001
         RETURN Max( 0.0, Min( OCX_PI, nEnd - nStart ) )
      ENDIF
   NEXT
RETURN NIL

STATIC FUNCTION ToDeg( n ) ; RETURN n * ( 180.0 / OCX_PI )
STATIC FUNCTION AngleBetween( vVertex, vA, vB )
   LOCAL v1 := Vc3_Normalize( Vc3_Sub( vA, vVertex ) ), v2 := Vc3_Normalize( Vc3_Sub( vB, vVertex ) )
RETURN ToDeg( OCX_ACOS( Vc3_Dot( v1, v2 ) ) )

// ---- Angular 2 lineas ----
FUNCTION Da2_Default() ; RETURN NewDim( "DIMENSION_ANGULAR_2LINE", DMT_ANGULAR, hb_Hash( "dimension_arc", Z3(), "first_point", Z3(), "second_point", Z3(), "angle_vertex", Z3(), "definition_point", Z3() ) )
FUNCTION Da2_New( vVertex, vFirst, vSecond )
   LOCAL d := Da2_Default()
   d[ "base" ][ "actual_measurement" ] := AngleBetween( vVertex, vFirst, vSecond )
   d[ "first_point" ] := vVertex ; d[ "second_point" ] := vFirst ; d[ "angle_vertex" ] := vVertex ; d[ "definition_point" ] := vSecond
RETURN d
FUNCTION Da2_MeasurementRadians( d )
   LOCAL vD1 := Vc3_Sub( d[ "second_point" ], d[ "first_point" ] ), vD2 := Vc3_Sub( d[ "definition_point" ], d[ "angle_vertex" ] ), vV, nR
   vV := LineIntersection( d[ "first_point" ], vD1, d[ "angle_vertex" ], vD2 )
   IF vV == NIL ; RETURN MinorAngleRadians( vD1, vD2 ) ; ENDIF
   nR := SelectedLineSectorRadians( vV, vD1, vD2, d[ "dimension_arc" ], d[ "base" ][ "normal" ] )
RETURN iif( nR == NIL, MinorAngleRadians( vD1, vD2 ), nR )
FUNCTION Da2_MeasurementDegrees( d ) ; RETURN ToDeg( Da2_MeasurementRadians( d ) )

// ---- Angular 3 puntos ----
FUNCTION Da3_Default() ; RETURN NewDim( "DIMENSION_ANGULAR_3POINT", DMT_ANGULAR3PT, hb_Hash( "definition_point", Z3(), "first_point", Z3(), "second_point", Z3(), "angle_vertex", Z3() ) )
FUNCTION Da3_New( vVertex, vFirst, vSecond )
   LOCAL d := Da3_Default()
   d[ "base" ][ "actual_measurement" ] := AngleBetween( vVertex, vFirst, vSecond )
   d[ "angle_vertex" ] := vVertex ; d[ "first_point" ] := vFirst ; d[ "second_point" ] := vSecond
RETURN d
FUNCTION Da3_MeasurementRadians( d )
   LOCAL vD1 := Vc3_Sub( d[ "first_point" ], d[ "angle_vertex" ] ), vD2 := Vc3_Sub( d[ "second_point" ], d[ "angle_vertex" ] ), nR
   nR := SelectedLineSectorRadians( d[ "angle_vertex" ], vD1, vD2, d[ "definition_point" ], d[ "base" ][ "normal" ] )
RETURN iif( nR == NIL, MinorAngleRadians( vD1, vD2 ), nR )
FUNCTION Da3_MeasurementDegrees( d ) ; RETURN ToDeg( Da3_MeasurementRadians( d ) )

// ---- Ordinate ----
FUNCTION Dor_Default() ; RETURN NewDim( "DIMENSION_ORDINATE", DMT_ORDINATE, hb_Hash( "definition_point", Z3(), "feature_location", Z3(), "leader_endpoint", Z3(), "is_ordinate_type_x", .T. ) )
FUNCTION Dor_New( vFeature, vLeaderEnd, lX )
   LOCAL d := Dor_Default()
   d[ "feature_location" ] := vFeature ; d[ "leader_endpoint" ] := vLeaderEnd ; d[ "is_ordinate_type_x" ] := lX
   Dor_RefreshMeasurement( d )
RETURN d
FUNCTION Dor_XOrdinate( vFeature, vLeaderEnd ) ; RETURN Dor_New( vFeature, vLeaderEnd, .T. )
FUNCTION Dor_YOrdinate( vFeature, vLeaderEnd ) ; RETURN Dor_New( vFeature, vLeaderEnd, .F. )
FUNCTION Dor_Measurement( d )
   LOCAL vDelta := Vc3_Sub( d[ "feature_location" ], d[ "definition_point" ] ), nA := -d[ "base" ][ "horizontal_direction" ], nS, nC, nP
   vDelta := Mx3_TransformPoint( Mx3_Transpose( Mx3_ArbitraryAxis( d[ "base" ][ "normal" ] ) ), vDelta )
   nS := OCX_SIN( nA ) ; nC := OCX_COS( nA )
   nP := iif( d[ "is_ordinate_type_x" ], vDelta[ 1 ] * nC + vDelta[ 2 ] * nS, -vDelta[ 1 ] * nS + vDelta[ 2 ] * nC )
RETURN Abs( nP )
FUNCTION Dor_RefreshMeasurement( d ) ; d[ "base" ][ "actual_measurement" ] := Dor_Measurement( d ) ; RETURN NIL
/* devuelve { xAxis, yAxis } */
FUNCTION Dor_LocalAxes( d )
   LOCAL mB := Mx3_ArbitraryAxis( d[ "base" ][ "normal" ] ), nA := -d[ "base" ][ "horizontal_direction" ], nS := OCX_SIN( nA ), nC := OCX_COS( nA )
RETURN { Mx3_TransformPoint( mB, Vc3_New( nC, nS, 0.0 ) ), Mx3_TransformPoint( mB, Vc3_New( -nS, nC, 0.0 ) ) }
/* nFixedExt: Option<f64> (NIL = None). Devuelve array de 4 puntos */
FUNCTION Dor_LeaderPolyline( d, nDogleg, nExtOffset, nFixedExt )
   LOCAL aAx := Dor_LocalAxes( d ), vX := aAx[ 1 ], vY := aAx[ 2 ], vMain, vLand, vDelta, vMainDir, vLandDir, nMainDist, nDog, nFirst, vElbow, vLandStart, vExtStart
   IF d[ "is_ordinate_type_x" ] ; vMain := vY ; vLand := vX ; ELSE ; vMain := vX ; vLand := vY ; ENDIF
   vDelta := Vc3_Sub( d[ "leader_endpoint" ], d[ "feature_location" ] )
   vMainDir := Vc3_Mul( vMain, iif( Vc3_Dot( vDelta, vMain ) < 0.0, -1.0, 1.0 ) )
   vLandDir := Vc3_Mul( vLand, iif( Vc3_Dot( vDelta, vLand ) < 0.0, -1.0, 1.0 ) )
   nMainDist := Abs( Vc3_Dot( vDelta, vMainDir ) )
   nDog := Max( nDogleg, 0.0 )
   nFirst := Max( nMainDist - 2.0 * nDog, nDog )
   vElbow := Vc3_Add( d[ "feature_location" ], Vc3_Mul( vMainDir, nFirst ) )
   vLandStart := Vc3_Sub( d[ "leader_endpoint" ], Vc3_Mul( vLandDir, nDog ) )
   IF nFixedExt != NIL
      vExtStart := Vc3_Sub( vElbow, Vc3_Mul( vMainDir, Max( nFixedExt, 0.0 ) ) )
   ELSE
      vExtStart := Vc3_Add( d[ "feature_location" ], Vc3_Mul( vMainDir, Max( nExtOffset, 0.0 ) ) )
   ENDIF
RETURN { vExtStart, vElbow, vLandStart, d[ "leader_endpoint" ] }

// ---- Arc dimension ----
FUNCTION Dar_Default()
RETURN NewDim( "ARC_DIMENSION", DMT_ARCLENGTH, hb_Hash( "definition_point", Z3(), "first_extension_point", Z3(), "second_extension_point", Z3(), "center_point", Z3(), ;
   "is_partial", .F., "arc_start_parameter", 0.0, "arc_end_parameter", 0.0, "has_leader", .F., "first_leader_point", Z3(), "second_leader_point", Z3() ) )
FUNCTION Dar_Measurement( d )
   LOCAL nR := Vc3_Distance( d[ "center_point" ], d[ "first_extension_point" ] ), nRaw := d[ "arc_end_parameter" ] - d[ "arc_start_parameter" ], nSw, nSt, nEn
   LOCAL c := d[ "center_point" ], f := d[ "first_extension_point" ], s := d[ "second_extension_point" ]
   nSw := OCX_REMEUCLID( nRaw, OCX_TAU )
   IF nSw <= 0.000000000001 .AND. Abs( nRaw ) > 0.000000000001 ; nSw := OCX_TAU ; ENDIF
   IF nSw <= 0.000000000001 .AND. Abs( nRaw ) <= 0.000000000001
      nSt := OCX_ATAN2( f[ 2 ] - c[ 2 ], f[ 1 ] - c[ 1 ] ) ; nEn := OCX_ATAN2( s[ 2 ] - c[ 2 ], s[ 1 ] - c[ 1 ] )
      nSw := OCX_REMEUCLID( nEn - nSt, OCX_TAU )
   ENDIF
RETURN nR * nSw

// ---- Large radial ----
FUNCTION Dlr_Default() ; RETURN NewDim( "LARGE_RADIAL_DIMENSION", DMT_LARGERADIAL, hb_Hash( "definition_point", Z3(), "chord_point", Z3(), "jog_angle", 0.0, "override_center", Z3(), "jog_point", Z3() ) )
FUNCTION Dlr_Measurement( d ) ; RETURN Vc3_Distance( d[ "definition_point" ], d[ "chord_point" ] )

// ---- enum Dimension ----
FUNCTION Edm_IsDimension( cType ) ; RETURN Left( cType, 10 ) == "DIMENSION_" .OR. cType == "ARC_DIMENSION" .OR. cType == "LARGE_RADIAL_DIMENSION"
FUNCTION Edm_Base( e ) ; RETURN e[ "base" ]
FUNCTION Edm_DefinitionPoint( e ) ; RETURN e[ "definition_point" ]
FUNCTION Edm_SetDefinitionPoint( e, v ) ; e[ "definition_point" ] := v ; e[ "base" ][ "definition_point" ] := v ; RETURN NIL
FUNCTION Edm_Measurement( e )
   LOCAL c := e[ "_type" ]
   DO CASE
   CASE c == "DIMENSION_ALIGNED" ; RETURN Dal_Measurement( e )
   CASE c == "DIMENSION_LINEAR" ; RETURN Dli_Measurement( e )
   CASE c == "DIMENSION_RADIUS" ; RETURN Dra_Measurement( e )
   CASE c == "DIMENSION_DIAMETER" ; RETURN Ddi_Measurement( e )
   CASE c == "DIMENSION_ANGULAR_2LINE" ; RETURN Da2_MeasurementDegrees( e )
   CASE c == "DIMENSION_ANGULAR_3POINT" ; RETURN Da3_MeasurementDegrees( e )
   CASE c == "DIMENSION_ORDINATE" ; RETURN Dor_Measurement( e )
   CASE c == "ARC_DIMENSION" ; RETURN Dar_Measurement( e )
   ENDCASE
RETURN Dlr_Measurement( e )
FUNCTION Edm_BoundingBox( e )
   LOCAL c := e[ "_type" ], a, bb
   DO CASE
   CASE c == "DIMENSION_ALIGNED" .OR. c == "DIMENSION_LINEAR" ; a := { e[ "first_point" ], e[ "second_point" ], e[ "definition_point" ] }
   CASE c == "DIMENSION_RADIUS" .OR. c == "DIMENSION_DIAMETER" ; a := { e[ "angle_vertex" ], e[ "definition_point" ] }
   CASE c == "DIMENSION_ANGULAR_2LINE" ; a := { e[ "dimension_arc" ], e[ "angle_vertex" ], e[ "first_point" ], e[ "second_point" ], e[ "definition_point" ] }
   CASE c == "DIMENSION_ANGULAR_3POINT" ; a := { e[ "angle_vertex" ], e[ "first_point" ], e[ "second_point" ], e[ "definition_point" ] }
   CASE c == "DIMENSION_ORDINATE" ; a := { e[ "feature_location" ], e[ "leader_endpoint" ] }
   CASE c == "ARC_DIMENSION" ; a := { e[ "definition_point" ], e[ "first_extension_point" ], e[ "second_extension_point" ], e[ "center_point" ], e[ "first_leader_point" ], e[ "second_leader_point" ] }
   OTHERWISE ; a := { e[ "definition_point" ], e[ "chord_point" ], e[ "override_center" ], e[ "jog_point" ] }
   ENDCASE
   bb := Bb3_FromPoints( a )
RETURN bb /* from_points nunca es NIL aqui (siempre hay puntos); unwrap_or_default no aplica */

STATIC FUNCTION Mv( e, cKey, vOff ) ; e[ cKey ] := Vc3_Add( e[ cKey ], vOff ) ; RETURN NIL
FUNCTION Edm_Translate( e, vOffset )
   LOCAL c := e[ "_type" ], k
   Edm_SetDefinitionPoint( e, Vc3_Add( Edm_DefinitionPoint( e ), vOffset ) )
   Mv( e[ "base" ], "text_middle_point", vOffset )
   DO CASE
   CASE c == "DIMENSION_ALIGNED" .OR. c == "DIMENSION_LINEAR" ; Mv( e, "first_point", vOffset ) ; Mv( e, "second_point", vOffset )
   CASE c == "DIMENSION_RADIUS" .OR. c == "DIMENSION_DIAMETER" ; Mv( e, "angle_vertex", vOffset )
   CASE c == "DIMENSION_ANGULAR_2LINE"
      FOR EACH k IN { "dimension_arc", "angle_vertex", "first_point", "second_point" } ; Mv( e, k, vOffset ) ; NEXT
   CASE c == "DIMENSION_ANGULAR_3POINT"
      FOR EACH k IN { "angle_vertex", "first_point", "second_point" } ; Mv( e, k, vOffset ) ; NEXT
   CASE c == "DIMENSION_ORDINATE" ; Mv( e, "feature_location", vOffset ) ; Mv( e, "leader_endpoint", vOffset )
   CASE c == "ARC_DIMENSION"
      FOR EACH k IN { "first_extension_point", "second_extension_point", "center_point", "first_leader_point", "second_leader_point" } ; Mv( e, k, vOffset ) ; NEXT
   OTHERWISE
      FOR EACH k IN { "chord_point", "override_center", "jog_point" } ; Mv( e, k, vOffset ) ; NEXT
   ENDCASE
RETURN NIL

STATIC FUNCTION DimAngle( vOldN, vNewN, nAngle, t )
   LOCAL vOld := Mx3_TransformPoint( Mx3_ArbitraryAxis( vOldN ), Vc3_New( OCX_COS( nAngle ), OCX_SIN( nAngle ), 0.0 ) )
   LOCAL vNew := Mx3_TransformPoint( Mx3_Transpose( Mx3_ArbitraryAxis( vNewN ) ), Tf_ApplyRotation( t, vOld ) )
RETURN iif( Vc3_LengthSquared( vNew ) > 0.000000000000000000000001, OCX_ATAN2( vNew[ 2 ], vNew[ 1 ] ), nAngle )

FUNCTION Edm_Transform( e, t )
   LOCAL vOldN, vNewN, mOldBasis, nOldAxisAngle, vOldAxis, nOldTextAngle, vOldTextAxis, mOld, mNewW2O, vTAxis, nNewAxisAngle, vTText, nRel
   LOCAL lKeep, nTextRot, nHorDir, nInsRot, aLin, b, c := e[ "_type" ], k
   b := e[ "base" ]
   IF c == "DIMENSION_ORDINATE"
      vOldN := b[ "normal" ] ; mOldBasis := Mx3_ArbitraryAxis( vOldN )
      nOldAxisAngle := -b[ "horizontal_direction" ]
      vOldAxis := Mx3_TransformPoint( mOldBasis, Vc3_New( OCX_COS( nOldAxisAngle ), OCX_SIN( nOldAxisAngle ), 0.0 ) )
      nOldTextAngle := nOldAxisAngle + b[ "text_rotation" ]
      vOldTextAxis := Mx3_TransformPoint( mOldBasis, Vc3_New( OCX_COS( nOldTextAngle ), OCX_SIN( nOldTextAngle ), 0.0 ) )
      e[ "definition_point" ] := Tf_Apply( t, e[ "definition_point" ] )
      e[ "feature_location" ] := Tf_Apply( t, e[ "feature_location" ] )
      e[ "leader_endpoint" ] := Tf_Apply( t, e[ "leader_endpoint" ] )
      b[ "definition_point" ] := e[ "definition_point" ]
      b[ "text_middle_point" ] := Tf_Apply( t, b[ "text_middle_point" ] )
      vNewN := Tf_TransformNormal( t, vOldN )
      mOld := Mx3_ArbitraryAxis( vOldN ) ; mNewW2O := Mx3_Transpose( Mx3_ArbitraryAxis( vNewN ) )
      b[ "insertion_point" ] := Mx3_TransformPoint( mNewW2O, Tf_Apply( t, Mx3_TransformPoint( mOld, b[ "insertion_point" ] ) ) )
      b[ "normal" ] := vNewN
      vTAxis := Mx3_TransformPoint( mNewW2O, Tf_ApplyRotation( t, vOldAxis ) )
      nNewAxisAngle := nOldAxisAngle
      IF Vc3_LengthSquared( vTAxis ) > 0.000000000000000000000001
         nNewAxisAngle := OCX_ATAN2( vTAxis[ 2 ], vTAxis[ 1 ] )
         b[ "horizontal_direction" ] := -nNewAxisAngle
      ENDIF
      vTText := Mx3_TransformPoint( mNewW2O, Tf_ApplyRotation( t, vOldTextAxis ) )
      IF Vc3_LengthSquared( vTText ) > 0.000000000000000000000001
         nRel := OCX_ATAN2( vTText[ 2 ], vTText[ 1 ] ) - nNewAxisAngle
         b[ "text_rotation" ] := OCX_ATAN2( OCX_SIN( nRel ), OCX_COS( nRel ) )
      ENDIF
      Dor_RefreshMeasurement( e )
      RETURN NIL
   ENDIF
   vOldN := b[ "normal" ] ; vNewN := Tf_TransformNormal( t, vOldN )
   lKeep := Tf_IsReflecting( t )
   nTextRot := iif( lKeep, b[ "text_rotation" ], DimAngle( vOldN, vNewN, b[ "text_rotation" ], t ) )
   nHorDir := iif( lKeep, b[ "horizontal_direction" ], DimAngle( vOldN, vNewN, b[ "horizontal_direction" ], t ) )
   nInsRot := DimAngle( vOldN, vNewN, b[ "insertion_rotation" ], t )
   aLin := NIL
   IF c == "DIMENSION_LINEAR"
      aLin := { DimAngle( vOldN, vNewN, e[ "rotation" ], t ), DimAngle( vOldN, vNewN, e[ "ext_line_rotation" ], t ) }
   ENDIF
   Edm_SetDefinitionPoint( e, Tf_Apply( t, Edm_DefinitionPoint( e ) ) )
   b[ "text_middle_point" ] := Tf_Apply( t, b[ "text_middle_point" ] )
   mOld := Mx3_ArbitraryAxis( vOldN ) ; mNewW2O := Mx3_Transpose( Mx3_ArbitraryAxis( vNewN ) )
   b[ "insertion_point" ] := Mx3_TransformPoint( mNewW2O, Tf_Apply( t, Mx3_TransformPoint( mOld, b[ "insertion_point" ] ) ) )
   b[ "normal" ] := vNewN ; b[ "text_rotation" ] := nTextRot ; b[ "horizontal_direction" ] := nHorDir ; b[ "insertion_rotation" ] := nInsRot
   DO CASE
   CASE c == "DIMENSION_ALIGNED"
      e[ "first_point" ] := Tf_Apply( t, e[ "first_point" ] ) ; e[ "second_point" ] := Tf_Apply( t, e[ "second_point" ] )
   CASE c == "DIMENSION_LINEAR"
      e[ "first_point" ] := Tf_Apply( t, e[ "first_point" ] ) ; e[ "second_point" ] := Tf_Apply( t, e[ "second_point" ] )
      e[ "rotation" ] := aLin[ 1 ] ; e[ "ext_line_rotation" ] := aLin[ 2 ]
   CASE c == "DIMENSION_RADIUS" .OR. c == "DIMENSION_DIAMETER"
      e[ "angle_vertex" ] := Tf_Apply( t, e[ "angle_vertex" ] )
   CASE c == "DIMENSION_ANGULAR_2LINE"
      FOR EACH k IN { "dimension_arc", "first_point", "second_point", "angle_vertex" } ; e[ k ] := Tf_Apply( t, e[ k ] ) ; NEXT
   CASE c == "DIMENSION_ANGULAR_3POINT"
      FOR EACH k IN { "first_point", "second_point", "angle_vertex" } ; e[ k ] := Tf_Apply( t, e[ k ] ) ; NEXT
   CASE c == "ARC_DIMENSION"
      FOR EACH k IN { "first_extension_point", "second_extension_point", "center_point", "first_leader_point", "second_leader_point" } ; e[ k ] := Tf_Apply( t, e[ k ] ) ; NEXT
   OTHERWISE
      FOR EACH k IN { "chord_point", "override_center", "jog_point" } ; e[ k ] := Tf_Apply( t, e[ k ] ) ; NEXT
   ENDCASE
   b[ "actual_measurement" ] := Edm_Measurement( e )
RETURN NIL
