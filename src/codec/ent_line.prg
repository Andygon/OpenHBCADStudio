/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_line.prg
   Origen Rust: opencadcodec/src/entities/line.rs (196 lineas, 7 tests en t_codec_entities.prg)
              + translate_line (translate.rs) + transform_line (transform.rs)
   Licencia del original: MPL-2.0. Line = hash ("_type" "LINE"); ver ent_base.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Eln_New()
RETURN hb_Hash( "_type", "LINE", "common", Ec_New(), "start", Vc3_Zero(), "end", Vc3_Zero(), "thickness", 0.0, "normal", Vc3_UnitZ() )

FUNCTION Eln_FromPoints( vStart, vEnd )
   LOCAL e := Eln_New()
   e[ "start" ] := vStart ; e[ "end" ] := vEnd
RETURN e

FUNCTION Eln_FromCoords( x1, y1, z1, x2, y2, z2 ) ; RETURN Eln_FromPoints( Vc3_New( x1, y1, z1 ), Vc3_New( x2, y2, z2 ) )
FUNCTION Eln_Length( e ) ; RETURN Vc3_Distance( e[ "start" ], e[ "end" ] )
FUNCTION Eln_Direction( e ) ; RETURN Vc3_Normalize( Vc3_Sub( e[ "end" ], e[ "start" ] ) )
FUNCTION Eln_Midpoint( e )
   LOCAL s := e[ "start" ], f := e[ "end" ]
RETURN Vc3_New( ( s[ 1 ] + f[ 1 ] ) / 2.0, ( s[ 2 ] + f[ 2 ] ) / 2.0, ( s[ 3 ] + f[ 3 ] ) / 2.0 )
FUNCTION Eln_BoundingBox( e ) ; RETURN Bb3_FromPoints( { e[ "start" ], e[ "end" ] } )
FUNCTION Eln_Translate( e, vOffset )
   e[ "start" ] := Vc3_Add( e[ "start" ], vOffset ) ; e[ "end" ] := Vc3_Add( e[ "end" ], vOffset )
RETURN NIL
FUNCTION Eln_Transform( e, t )
   e[ "start" ] := Tf_Apply( t, e[ "start" ] ) ; e[ "end" ] := Tf_Apply( t, e[ "end" ] )
   e[ "normal" ] := Vc3_Normalize( Tf_ApplyRotation( t, e[ "normal" ] ) )
RETURN NIL
