/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_unknown.prg
   Origen Rust: opencadcodec/src/entities/unknown_entity.rs y view_border.rs (sin tests en Rust) + translate/transform_unknown. Licencia del original: MPL-2.0.
   Prefijos: Eun_ (UnknownEntity, _type "UNKNOWN") y Evb_ (ViewBorder, _type "DRAWINGVIEW").
   Option -> NIL: raw_dwg_data (cadena de bytes), raw_dxf_codes (array de { nCodigo, cValor }), dwg_source_version (entero DxfVersion).
   Nota: el despachador EntityType ignora ViewBorder en translate/transform (no-op), pero Evb_Translate/Evb_Transform son los metodos del trait Entity. Tests [extra] en t_codec_misc3.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Eun_New( cDxfName )
RETURN hb_Hash( "_type", "UNKNOWN", "common", Ec_New(), "dxf_name", cDxfName, "dwg_type_code", 0, "raw_dwg_data", NIL, "dwg_handle_bits", 0, "raw_dxf_codes", NIL, "dwg_source_version", NIL )
FUNCTION Eun_BoundingBox( e ) ; HB_SYMBOL_UNUSED( e ) ; RETURN Bb3_FromPoint( Vc3_Zero() )

FUNCTION Evb_New()
RETURN hb_Hash( "_type", "DRAWINGVIEW", "common", Ec_New(), "version", 0, "min", { 0.0, 0.0 }, "max", { 0.0, 0.0 }, "center", { 0.0, 0.0 }, "scale", 1.0, "rotation_angle", 0.0, ;
   "active_viewport", Hd_Null(), "scale_handle", Hd_Null() )
FUNCTION Evb_BoundingBox( e ) ; RETURN Bb3_New( Vc3_New( e[ "min" ][ 1 ], e[ "min" ][ 2 ], 0.0 ), Vc3_New( e[ "max" ][ 1 ], e[ "max" ][ 2 ], 0.0 ) )
FUNCTION Evb_Translate( e, vOff )
   e[ "min" ][ 1 ] += vOff[ 1 ] ; e[ "min" ][ 2 ] += vOff[ 2 ]
   e[ "max" ][ 1 ] += vOff[ 1 ] ; e[ "max" ][ 2 ] += vOff[ 2 ]
   e[ "center" ][ 1 ] += vOff[ 1 ] ; e[ "center" ][ 2 ] += vOff[ 2 ]
RETURN NIL
FUNCTION Evb_Transform( e, t )
   LOCAL aC := { Vc3_New( e[ "min" ][ 1 ], e[ "min" ][ 2 ], 0.0 ), Vc3_New( e[ "max" ][ 1 ], e[ "min" ][ 2 ], 0.0 ), Vc3_New( e[ "max" ][ 1 ], e[ "max" ][ 2 ], 0.0 ), Vc3_New( e[ "min" ][ 1 ], e[ "max" ][ 2 ], 0.0 ) }
   LOCAL aMin := { OCX_INF(), OCX_INF() }, aMax := { - OCX_INF(), - OCX_INF() }, p, c
   FOR EACH p IN aC
      c := Tf_Apply( t, p )
      aMin[ 1 ] := Min( aMin[ 1 ], c[ 1 ] ) ; aMin[ 2 ] := Min( aMin[ 2 ], c[ 2 ] )
      aMax[ 1 ] := Max( aMax[ 1 ], c[ 1 ] ) ; aMax[ 2 ] := Max( aMax[ 2 ], c[ 2 ] )
   NEXT
   c := Tf_Apply( t, Vc3_New( e[ "center" ][ 1 ], e[ "center" ][ 2 ], 0.0 ) )
   e[ "min" ] := aMin ; e[ "max" ] := aMax ; e[ "center" ] := { c[ 1 ], c[ 2 ] }
RETURN NIL
