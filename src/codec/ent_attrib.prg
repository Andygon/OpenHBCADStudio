/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_attrib.prg
   Origen Rust: opencadcodec/src/entities/attribute_entity.rs (510, 12 tests)
              + translate_/transform_attribute_entity. Licencia del original: MPL-2.0.
   Entidad = hash ("_type" "ATTRIB"). Mismos enums/flags que ent_attdef.prg. Option -> NIL.
   Incluye Ent_Clone (equivalente a #[derive(Clone)]: copia profunda de arrays y hashes).
   Prefijo: Eat_. Builders with_* no se portan (se usan setters).
----------------------------------------------------------------------------*/
#include "ocx.ch"

/* Copia profunda (arrays y hashes anidados); el resto de valores son inmutables en Harbour */
FUNCTION Ent_Clone( x )
   LOCAL r, i, k
   DO CASE
   CASE ValType( x ) == "A"
      r := Array( Len( x ) )
      FOR i := 1 TO Len( x )
         r[ i ] := Ent_Clone( x[ i ] )
      NEXT
      RETURN r
   CASE ValType( x ) == "H"
      r := hb_Hash()
      FOR EACH k IN hb_HKeys( x )
         r[ k ] := Ent_Clone( x[ k ] )
      NEXT
      /* Dimension: "common" es el mismo objeto que base["common"]; se mantiene el enlace en la copia */
      IF hb_HHasKey( x, "base" ) .AND. hb_HHasKey( x, "common" ) .AND. ValType( x[ "base" ] ) == "H"
         r[ "common" ] := r[ "base" ][ "common" ]
      ENDIF
      RETURN r
   ENDCASE
RETURN x

FUNCTION Eat_New( cTag, cValue )
RETURN hb_Hash( "_type", "ATTRIB", "common", Ec_New(), "tag", cTag, "value", cValue, "insertion_point", Vc3_Zero(), "alignment_point", Vc3_Zero(), ;
                "height", 2.5, "rotation", 0.0, "width_factor", 1.0, "oblique_angle", 0.0, "text_style", "Standard", "text_generation_flags", 0, ;
                "horizontal_alignment", TXH_LEFT, "vertical_alignment", TXV_BASELINE, "flags", Taf_Default(), "field_length", 0, "normal", Vc3_UnitZ(), ;
                "mtext_flag", MTF_SINGLELINE, "is_multiline", .F., "line_count", 1, "embedded_mtext", NIL, "attdef_handle", Hd_Null(), "lock_position", .F. )
FUNCTION Eat_Simple( cTag, cValue ) ; RETURN Eat_New( cTag, cValue )
FUNCTION Eat_Default() ; RETURN Eat_New( "ATTRIBUTE", "" )
/* cValue = NIL equivale a None */
FUNCTION Eat_FromDefinition( d, cValue )
   LOCAL e := Eat_New( d[ "tag" ], iif( cValue == NIL, d[ "default_value" ], cValue ) ), k
   e[ "common" ][ "layer" ] := d[ "common" ][ "layer" ]
   e[ "common" ][ "color" ] := Ent_Clone( d[ "common" ][ "color" ] )
   e[ "common" ][ "color_name" ] := d[ "common" ][ "color_name" ]
   e[ "common" ][ "color_book_handle" ] := d[ "common" ][ "color_book_handle" ]
   FOR EACH k IN { "insertion_point", "alignment_point", "height", "rotation", "width_factor", "oblique_angle", "text_style", "text_generation_flags", ;
                   "horizontal_alignment", "vertical_alignment", "flags", "field_length", "normal", "mtext_flag", "is_multiline", "line_count", "embedded_mtext", "lock_position" }
      e[ k ] := Ent_Clone( d[ k ] )
   NEXT
   e[ "attdef_handle" ] := d[ "common" ][ "handle" ]
RETURN e
FUNCTION Eat_SetValue( e, c ) ; e[ "value" ] := c ; RETURN NIL
FUNCTION Eat_GetValue( e ) ; RETURN e[ "value" ]
FUNCTION Eat_SetPosition( e, v ) ; e[ "insertion_point" ] := v ; e[ "alignment_point" ] := v ; RETURN NIL
FUNCTION Eat_SetHeight( e, n ) ; e[ "height" ] := n ; RETURN NIL
FUNCTION Eat_SetRotationDegrees( e, nDeg ) ; e[ "rotation" ] := nDeg * OCX_PI / 180.0 ; RETURN NIL
FUNCTION Eat_RotationDegrees( e ) ; RETURN e[ "rotation" ] * 180.0 / OCX_PI
FUNCTION Eat_SetTextStyle( e, c ) ; e[ "text_style" ] := c ; RETURN NIL
FUNCTION Eat_SetAlignment( e, nH, nV ) ; e[ "horizontal_alignment" ] := nH ; e[ "vertical_alignment" ] := nV ; RETURN NIL
FUNCTION Eat_IsVisible( e ) ; RETURN ! e[ "flags" ][ "invisible" ]
FUNCTION Eat_IsConstant( e ) ; RETURN e[ "flags" ][ "constant" ]
FUNCTION Eat_EstimatedWidth( e ) ; RETURN Etx_EstimatedWidthInHeights( e[ "value" ] ) * e[ "height" ] * e[ "width_factor" ]
FUNCTION Eat_ApplyInsertTransform( e, vInsert, vScale, nRotation )
   LOCAL nCos := OCX_COS( nRotation ), nSin := OCX_SIN( nRotation ), vS, vR, vSa, vRa
   vS := Vc3_New( e[ "insertion_point" ][1] * vScale[1], e[ "insertion_point" ][2] * vScale[2], e[ "insertion_point" ][3] * vScale[3] )
   vR := Vc3_New( vS[1] * nCos - vS[2] * nSin, vS[1] * nSin + vS[2] * nCos, vS[3] )
   e[ "insertion_point" ] := Vc3_Add( vR, vInsert )
   vSa := Vc3_New( e[ "alignment_point" ][1] * vScale[1], e[ "alignment_point" ][2] * vScale[2], e[ "alignment_point" ][3] * vScale[3] )
   vRa := Vc3_New( vSa[1] * nCos - vSa[2] * nSin, vSa[1] * nSin + vSa[2] * nCos, vSa[3] )
   e[ "alignment_point" ] := Vc3_Add( vRa, vInsert )
   e[ "rotation" ] += nRotation
   e[ "height" ] *= ( Abs( vScale[1] ) + Abs( vScale[2] ) ) / 2.0
RETURN NIL
FUNCTION Eat_BoundingBox( e )
   LOCAL p := e[ "insertion_point" ]
RETURN Bb3_OcsToWcs( Bb3_New( p, Vc3_New( p[1] + Eat_EstimatedWidth( e ), p[2] + e[ "height" ], p[3] ) ), e[ "normal" ] )
FUNCTION Eat_Translate( e, vOffset )
   LOCAL v := Mx3_TransformPoint( Mx3_Transpose( Mx3_ArbitraryAxis( e[ "normal" ] ) ), vOffset )
   e[ "insertion_point" ] := Vc3_Add( e[ "insertion_point" ], v )
   e[ "alignment_point" ] := Vc3_Add( e[ "alignment_point" ], v )
RETURN NIL
FUNCTION Eat_Transform( e, t )
   LOCAL vNn := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) ), mOcs := Mx3_ArbitraryAxis( e[ "normal" ] ), mNt := Mx3_Transpose( Mx3_ArbitraryAxis( vNn ) )
   e[ "insertion_point" ] := Mx3_TransformPoint( mNt, Tf_Apply( t, Mx3_TransformPoint( mOcs, e[ "insertion_point" ] ) ) )
   e[ "alignment_point" ] := Mx3_TransformPoint( mNt, Tf_Apply( t, Mx3_TransformPoint( mOcs, e[ "alignment_point" ] ) ) )
   e[ "normal" ] := vNn
   e[ "height" ] *= Vc3_Length( Tf_ApplyRotation( t, Vc3_New( 1.0, 0.0, 0.0 ) ) )
   e[ "rotation" ] := Tf_RotateStoredAngle( e[ "rotation" ], t )
RETURN NIL
