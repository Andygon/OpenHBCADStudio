/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_attdef.prg
   Origen Rust: opencadcodec/src/entities/attribute_definition.rs (621, 11 tests)
              + translate_/transform_attribute_definition. Licencia del original: MPL-2.0.
   Entidad = hash ("_type" "ATTDEF"). AttributeFlags = hash de logicos. HorizontalAlignment/VerticalAlignment
   = enteros con los mismos valores que TXH_ y TXV_; MTextFlag = constantes MTF_ (ocx.ch). Option -> NIL.
   Builders with_* no se portan salvo set_*: se usan los setters. Prefijos: Taf_ (AttributeFlags), Ha_/Va_/Mtf_ (enums), Ead_ (AttributeDefinition).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Taf_Default() ; RETURN hb_Hash( "invisible", .F., "constant", .F., "verify", .F., "preset", .F., "locked_position", .F., "annotative", .F. )
FUNCTION Taf_FromBits( n )
RETURN hb_Hash( "invisible", hb_bitAnd( n, 1 ) != 0, "constant", hb_bitAnd( n, 2 ) != 0, "verify", hb_bitAnd( n, 4 ) != 0, "preset", hb_bitAnd( n, 8 ) != 0, ;
                "locked_position", hb_bitAnd( n, 16 ) != 0, "annotative", hb_bitAnd( n, 128 ) != 0 )
FUNCTION Taf_ToBits( f )
   LOCAL n := 0
   IF f[ "invisible" ] ; n := hb_bitOr( n, 1 ) ; ENDIF
   IF f[ "constant" ] ; n := hb_bitOr( n, 2 ) ; ENDIF
   IF f[ "verify" ] ; n := hb_bitOr( n, 4 ) ; ENDIF
   IF f[ "preset" ] ; n := hb_bitOr( n, 8 ) ; ENDIF
   IF f[ "locked_position" ] ; n := hb_bitOr( n, 16 ) ; ENDIF
   IF f[ "annotative" ] ; n := hb_bitOr( n, 128 ) ; ENDIF
RETURN n

/* from_value: valor fuera de rango -> Left/Baseline/SingleLine; to_value: identidad */
FUNCTION Ha_FromValue( n ) ; RETURN iif( n >= 1 .AND. n <= 5, n, TXH_LEFT )
FUNCTION Va_FromValue( n ) ; RETURN iif( n >= 1 .AND. n <= 3, n, TXV_BASELINE )
FUNCTION Mtf_FromValue( n ) ; RETURN iif( n == 2 .OR. n == 4, n, MTF_SINGLELINE )

FUNCTION Ead_New( cTag, cPrompt, cDefault )
RETURN hb_Hash( "_type", "ATTDEF", "common", Ec_New(), "tag", cTag, "prompt", cPrompt, "default_value", cDefault, "insertion_point", Vc3_Zero(), ;
                "alignment_point", Vc3_Zero(), "height", 2.5, "rotation", 0.0, "width_factor", 1.0, "oblique_angle", 0.0, "text_style", "Standard", ;
                "text_generation_flags", 0, "horizontal_alignment", TXH_LEFT, "vertical_alignment", TXV_BASELINE, "flags", Taf_Default(), "field_length", 0, ;
                "normal", Vc3_UnitZ(), "mtext_flag", MTF_SINGLELINE, "is_multiline", .F., "line_count", 1, "embedded_mtext", NIL, "lock_position", .F. )
FUNCTION Ead_Simple( cTag ) ; RETURN Ead_New( cTag, "Enter " + cTag + ":", "" )
FUNCTION Ead_Default() ; RETURN Ead_Simple( "ATTRIBUTE" )
FUNCTION Ead_Invisible( cTag, cDefault )
   LOCAL e := Ead_Simple( cTag )
   e[ "default_value" ] := cDefault ; e[ "flags" ][ "invisible" ] := .T.
RETURN e
FUNCTION Ead_Constant( cTag, cValue )
   LOCAL e := Ead_Simple( cTag )
   e[ "default_value" ] := cValue ; e[ "flags" ][ "constant" ] := .T.
RETURN e
FUNCTION Ead_SetPosition( e, v ) ; e[ "insertion_point" ] := v ; e[ "alignment_point" ] := v ; RETURN NIL
FUNCTION Ead_SetHeight( e, n ) ; e[ "height" ] := n ; RETURN NIL
FUNCTION Ead_SetRotationDegrees( e, nDeg ) ; e[ "rotation" ] := nDeg * OCX_PI / 180.0 ; RETURN NIL
FUNCTION Ead_RotationDegrees( e ) ; RETURN e[ "rotation" ] * 180.0 / OCX_PI
FUNCTION Ead_SetTextStyle( e, c ) ; e[ "text_style" ] := c ; RETURN NIL
FUNCTION Ead_SetAlignment( e, nH, nV ) ; e[ "horizontal_alignment" ] := nH ; e[ "vertical_alignment" ] := nV ; RETURN NIL
FUNCTION Ead_CenterHorizontal( e ) ; e[ "horizontal_alignment" ] := TXH_CENTER ; RETURN NIL
FUNCTION Ead_Center( e ) ; e[ "horizontal_alignment" ] := TXH_CENTER ; e[ "vertical_alignment" ] := TXV_MIDDLE ; RETURN NIL
FUNCTION Ead_SetInvisible( e, l ) ; e[ "flags" ][ "invisible" ] := l ; RETURN NIL
FUNCTION Ead_SetConstant( e, l ) ; e[ "flags" ][ "constant" ] := l ; RETURN NIL
FUNCTION Ead_SetPreset( e, l ) ; e[ "flags" ][ "preset" ] := l ; RETURN NIL
FUNCTION Ead_SetVerify( e, l ) ; e[ "flags" ][ "verify" ] := l ; RETURN NIL
FUNCTION Ead_IsVisible( e ) ; RETURN ! e[ "flags" ][ "invisible" ]
FUNCTION Ead_IsConstant( e ) ; RETURN e[ "flags" ][ "constant" ]
FUNCTION Ead_EstimatedWidth( e ) ; RETURN Etx_EstimatedWidthInHeights( e[ "default_value" ] ) * e[ "height" ] * e[ "width_factor" ]
FUNCTION Ead_BoundingBox( e )
   LOCAL p := e[ "insertion_point" ]
RETURN Bb3_OcsToWcs( Bb3_New( p, Vc3_New( p[1] + Ead_EstimatedWidth( e ), p[2] + e[ "height" ], p[3] ) ), e[ "normal" ] )
FUNCTION Ead_Translate( e, vOffset )
   LOCAL v := Mx3_TransformPoint( Mx3_Transpose( Mx3_ArbitraryAxis( e[ "normal" ] ) ), vOffset )
   e[ "insertion_point" ] := Vc3_Add( e[ "insertion_point" ], v )
   e[ "alignment_point" ] := Vc3_Add( e[ "alignment_point" ], v )
RETURN NIL
FUNCTION Ead_Transform( e, t )
   LOCAL vNn := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) ), mOcs := Mx3_ArbitraryAxis( e[ "normal" ] ), mNt := Mx3_Transpose( Mx3_ArbitraryAxis( vNn ) )
   e[ "insertion_point" ] := Mx3_TransformPoint( mNt, Tf_Apply( t, Mx3_TransformPoint( mOcs, e[ "insertion_point" ] ) ) )
   e[ "alignment_point" ] := Mx3_TransformPoint( mNt, Tf_Apply( t, Mx3_TransformPoint( mOcs, e[ "alignment_point" ] ) ) )
   e[ "normal" ] := vNn
   e[ "height" ] *= Vc3_Length( Tf_ApplyRotation( t, Vc3_New( 1.0, 0.0, 0.0 ) ) )
   e[ "rotation" ] := Tf_RotateStoredAngle( e[ "rotation" ], t )
RETURN NIL
