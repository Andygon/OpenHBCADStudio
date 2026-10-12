/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_text.prg
   Origen Rust: opencadcodec/src/entities/text.rs (218, sin tests), mtext.rs (283, sin tests)
              + translate_/transform_/mirror_ de text y mtext + rotate_stored_angle. Licencia del original: MPL-2.0.
   Entidades = hash ("_type" "TEXT"/"MTEXT"). Enums -> constantes TXH_/TXV_/MTA_/MTD_/LSS_ (ocx.ch).
   Los strings se interpretan como UTF-8 (como String de Rust) en estimated_width_in_heights.
   Prefijos: Etx_ (Text), Emt_ (MText), Mcd_ (MTextColumnData). Tests [extra] en t_codec_text.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION OcsOff( vNormal, vOffset ) ; RETURN Mx3_TransformPoint( Mx3_Transpose( Mx3_ArbitraryAxis( vNormal ) ), vOffset )

/* estimated_width_in_heights: 1.0 para rangos CJK/ancho completo, 0.6 el resto */
FUNCTION Etx_EstimatedWidthInHeights( cStr )
   LOCAL nSum := 0.0, i, n, nLen := hb_utf8Len( cStr )
   FOR i := 1 TO nLen
      n := hb_utf8Asc( hb_utf8Substr( cStr, i, 1 ) )
      IF ( n >= 0x1100 .AND. n <= 0x115F ) .OR. ( n >= 0x2E80 .AND. n <= 0xA4CF ) .OR. ( n >= 0xAC00 .AND. n <= 0xD7A3 ) .OR. ;
         ( n >= 0xF900 .AND. n <= 0xFAFF ) .OR. ( n >= 0xFE30 .AND. n <= 0xFE4F ) .OR. ( n >= 0xFF00 .AND. n <= 0xFF60 ) .OR. ;
         ( n >= 0xFFE0 .AND. n <= 0xFFE6 )
         nSum += 1.0
      ELSE
         nSum += 0.6
      ENDIF
   NEXT
RETURN nSum

/* transform.rs: rotate_stored_angle( @rotation, transform ) -> devuelve el nuevo angulo */
FUNCTION Tf_RotateStoredAngle( nRotation, t )
   LOCAL v := Tf_ApplyRotation( t, Vc3_New( OCX_COS( nRotation ), OCX_SIN( nRotation ), 0.0 ) )
   IF v[ 1 ] != 0.0 .OR. v[ 2 ] != 0.0 ; RETURN OCX_ATAN2( v[ 2 ], v[ 1 ] ) ; ENDIF
RETURN nRotation

/* ---- Text ---- */
FUNCTION Etx_New()
RETURN hb_Hash( "_type", "TEXT", "common", Ec_New(), "value", "", "insertion_point", Vc3_Zero(), "alignment_point", NIL, "height", 1.0, ;
                "rotation", 0.0, "width_factor", 1.0, "oblique_angle", 0.0, "style", "Standard", "horizontal_alignment", TXH_LEFT, ;
                "vertical_alignment", TXV_BASELINE, "normal", Vc3_UnitZ(), "thickness", 0.0, "generation_flags", 0 )
FUNCTION Etx_WithValue( cValue, vPos )
   LOCAL e := Etx_New()
   e[ "value" ] := cValue ; e[ "insertion_point" ] := vPos
RETURN e
FUNCTION Etx_BoundingBox( e )
   LOCAL w := Etx_EstimatedWidthInHeights( e[ "value" ] ) * e[ "height" ] * e[ "width_factor" ], p := e[ "insertion_point" ]
RETURN Bb3_OcsToWcs( Bb3_New( p, Vc3_New( p[1] + w, p[2] + e[ "height" ], p[3] ) ), e[ "normal" ] )
FUNCTION Etx_Translate( e, vOffset )
   LOCAL v := OcsOff( e[ "normal" ], vOffset )
   e[ "insertion_point" ] := Vc3_Add( e[ "insertion_point" ], v )
   IF e[ "alignment_point" ] != NIL ; e[ "alignment_point" ] := Vc3_Add( e[ "alignment_point" ], v ) ; ENDIF
RETURN NIL
FUNCTION Etx_Transform( e, t )
   LOCAL vNn := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) ), mOcs := Mx3_ArbitraryAxis( e[ "normal" ] ), mNt := Mx3_Transpose( Mx3_ArbitraryAxis( vNn ) )
   e[ "insertion_point" ] := Mx3_TransformPoint( mNt, Tf_Apply( t, Mx3_TransformPoint( mOcs, e[ "insertion_point" ] ) ) )
   IF e[ "alignment_point" ] != NIL
      e[ "alignment_point" ] := Mx3_TransformPoint( mNt, Tf_Apply( t, Mx3_TransformPoint( mOcs, e[ "alignment_point" ] ) ) )
   ENDIF
   e[ "height" ] *= Vc3_Length( Tf_ApplyRotation( t, Vc3_New( 1.0, 0.0, 0.0 ) ) )
   e[ "normal" ] := vNn
   e[ "rotation" ] := Tf_RotateStoredAngle( e[ "rotation" ], t )
RETURN NIL
FUNCTION Etx_Mirror( e, t )
   Etx_Transform( e, t )
   e[ "oblique_angle" ] := - e[ "oblique_angle" ]
RETURN NIL

/* ---- MText ---- */
FUNCTION Mcd_New() ; RETURN hb_Hash( "column_type", 0, "column_count", 0, "flow_reversed", .F., "auto_height", .F., "width", 0.0, "gutter", 0.0, "heights", {} )
FUNCTION Emt_New()
RETURN hb_Hash( "_type", "MTEXT", "common", Ec_New(), "value", "", "insertion_point", Vc3_Zero(), "height", 1.0, "rectangle_width", 10.0, ;
                "rectangle_height", NIL, "rotation", 0.0, "dwg_x_direction", NIL, "style", "Standard", "attachment_point", MTA_TOPLEFT, ;
                "drawing_direction", MTD_LEFTTORIGHT, "line_spacing_factor", 1.0, "line_spacing_style", LSS_ATLEAST, "normal", Vc3_UnitZ(), ;
                "background_fill_flags", 0, "background_scale", 1.5, "background_color", Cl_ByLayer(), "background_transparency", 0, ;
                "is_annotative", .F., "column_data", Mcd_New(), "extents_width", 0.0, "extents_height", 0.0 )
FUNCTION Emt_WithValue( cValue, vPos )
   LOCAL e := Emt_New()
   e[ "value" ] := cValue ; e[ "insertion_point" ] := vPos
RETURN e
FUNCTION Emt_BoundingBox( e )
   LOCAL nH := iif( e[ "rectangle_height" ] == NIL, e[ "height" ] * 2.0, e[ "rectangle_height" ] ), p := e[ "insertion_point" ]
RETURN Bb3_New( p, Vc3_New( p[1] + e[ "rectangle_width" ], p[2] + nH, p[3] ) )
FUNCTION Emt_Translate( e, vOffset ) ; e[ "insertion_point" ] := Vc3_Add( e[ "insertion_point" ], vOffset ) ; RETURN NIL
FUNCTION Emt_Transform( e, t )
   LOCAL nS := Vc3_Length( Tf_ApplyRotation( t, Vc3_New( 1.0, 0.0, 0.0 ) ) )
   e[ "insertion_point" ] := Tf_Apply( t, e[ "insertion_point" ] )
   e[ "height" ] *= nS ; e[ "rectangle_width" ] *= nS
   IF e[ "rectangle_height" ] != NIL ; e[ "rectangle_height" ] *= nS ; ENDIF
   e[ "normal" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
   e[ "rotation" ] := Tf_RotateStoredAngle( e[ "rotation" ], t )
RETURN NIL
FUNCTION Emt_Mirror( e, t ) ; Emt_Transform( e, t ) ; RETURN NIL
