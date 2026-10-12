/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_ellipse.prg
   Origen Rust: opencadcodec/src/entities/ellipse.rs (174, 2 tests)
              + translate_ellipse, transform_ellipse, mirror_ellipse. Licencia del original: MPL-2.0.
   Entidad = hash ("_type" "ELLIPSE"); ver ent_base.prg. Tests en t_codec_ellipse.prg.
   Prefijo: Eel_.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Eel_New()
RETURN hb_Hash( "_type", "ELLIPSE", "common", Ec_New(), "center", Vc3_Zero(), "major_axis", Vc3_UnitX(), "minor_axis_ratio", 0.5, ;
                "start_parameter", 0.0, "end_parameter", OCX_TAU, "normal", Vc3_UnitZ() )
FUNCTION Eel_FromCenterAxes( vCenter, vMajor, nRatio )
   LOCAL e := Eel_New()
   e[ "center" ] := vCenter ; e[ "major_axis" ] := vMajor ; e[ "minor_axis_ratio" ] := nRatio
RETURN e
FUNCTION Eel_MajorAxisLength( e ) ; RETURN Vc3_Length( e[ "major_axis" ] )
FUNCTION Eel_MinorAxisLength( e ) ; RETURN Eel_MajorAxisLength( e ) * e[ "minor_axis_ratio" ]
FUNCTION Eel_IsFull( e ) ; RETURN Abs( e[ "end_parameter" ] - e[ "start_parameter" ] - OCX_TAU ) < 0.0000000001
FUNCTION Eel_BoundingBox( e )
   LOCAL r := Max( Eel_MajorAxisLength( e ), Eel_MinorAxisLength( e ) ), c := e[ "center" ]
RETURN Bb3_New( Vc3_New( c[1] - r, c[2] - r, c[3] ), Vc3_New( c[1] + r, c[2] + r, c[3] ) )
FUNCTION Eel_Translate( e, vOffset ) ; e[ "center" ] := Vc3_Add( e[ "center" ], vOffset ) ; RETURN NIL

STATIC FUNCTION ElFallback( e, t )
   e[ "center" ] := Tf_Apply( t, e[ "center" ] )
   e[ "major_axis" ] := Tf_ApplyRotation( t, e[ "major_axis" ] )
   e[ "normal" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
RETURN NIL

FUNCTION Eel_Transform( e, t )
   LOCAL nNLen := Vc3_Length( e[ "normal" ] ), vMinor, vMajor0, vMinor0, nTheta, nSin, nCos, vMajor, vCross, nMajLen, nCrossLen
   LOCAL lFull, nSweep
   IF nNLen <= 0.000000000001 .OR. Vc3_Length( e[ "major_axis" ] ) <= 0.000000000001
      RETURN ElFallback( e, t )
   ENDIF
   vMinor := Vc3_Mul( Vc3_Cross( Vc3_Mul( e[ "normal" ], 1.0 / nNLen ), e[ "major_axis" ] ), e[ "minor_axis_ratio" ] )
   vMajor0 := Tf_ApplyRotation( t, e[ "major_axis" ] )
   vMinor0 := Tf_ApplyRotation( t, vMinor )
   nTheta := 0.5 * OCX_ATAN2( 2.0 * Vc3_Dot( vMajor0, vMinor0 ), Vc3_Dot( vMajor0, vMajor0 ) - Vc3_Dot( vMinor0, vMinor0 ) )
   nSin := OCX_SIN( nTheta ) ; nCos := OCX_COS( nTheta )
   vMajor := Vc3_Add( Vc3_Mul( vMajor0, nCos ), Vc3_Mul( vMinor0, nSin ) )
   vMinor := Vc3_Add( Vc3_Mul( vMajor0, -nSin ), Vc3_Mul( vMinor0, nCos ) )
   vCross := Vc3_Cross( vMajor, vMinor )
   nMajLen := Vc3_Length( vMajor ) ; nCrossLen := Vc3_Length( vCross )
   IF nMajLen <= 0.000000000001 .OR. nCrossLen <= 0.000000000001 * nMajLen * nMajLen
      RETURN ElFallback( e, t )
   ENDIF
   lFull := Eel_IsFull( e )
   e[ "center" ] := Tf_Apply( t, e[ "center" ] )
   e[ "major_axis" ] := vMajor
   e[ "normal" ] := Vc3_Mul( vCross, 1.0 / nCrossLen )
   e[ "minor_axis_ratio" ] := Min( Vc3_Length( vMinor ) / nMajLen, 1.0 )
   IF ! lFull
      nSweep := OCX_REMEUCLID( e[ "end_parameter" ] - e[ "start_parameter" ], OCX_TAU )
      e[ "start_parameter" ] := OCX_REMEUCLID( e[ "start_parameter" ] - nTheta, OCX_TAU )
      e[ "end_parameter" ] := e[ "start_parameter" ] + iif( nSweep <= 0.000000000001, OCX_TAU, nSweep )
   ENDIF
RETURN NIL

FUNCTION Eel_Mirror( e, t )
   LOCAL nStart
   Eel_Transform( e, t )
   IF Tf_IsReflecting( t )
      e[ "normal" ] := Vc3_Neg( e[ "normal" ] )
      IF ! Eel_IsFull( e )
         nStart := OCX_REMEUCLID( - e[ "end_parameter" ], OCX_TAU )
         e[ "end_parameter" ] := nStart + ( e[ "end_parameter" ] - e[ "start_parameter" ] )
         e[ "start_parameter" ] := nStart
      ENDIF
   ENDIF
RETURN NIL
