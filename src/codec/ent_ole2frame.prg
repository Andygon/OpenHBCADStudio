/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_ole2frame.prg
   Origen Rust: opencadcodec/src/entities/ole2frame.rs (264, SIN tests en Rust) + translate_ole2frame + transform_ole2frame. Licencia del original: MPL-2.0.
   Prefijos: Oot_ (OleObjectType, valores OOT_*), Eo2_ (Ole2Frame, _type "OLE2FRAME").
   PENDIENTE: campos "storage"/"envelope" y decode_payload/encoded_payload dependen de compound_file.rs (StructuredStoragePayload, BinaryRecord), todavia sin portar.
   Aqui "storage" y "envelope" son NIL hasta portar ese modulo. Tests [extra] en t_codec_misc2.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Oot_FromI16( n ) ; RETURN iif( n == 1, OOT_LINK, iif( n == 3, OOT_STATIC, OOT_EMBEDDED ) )
FUNCTION Eo2_New()
RETURN hb_Hash( "_type", "OLE2FRAME", "common", Ec_New(), "version", 2, "source_application", "", "upper_left_corner", Vc3_New( 1.0, 1.0, 0.0 ), "lower_right_corner", Vc3_Zero(), ;
   "ole_object_type", OOT_EMBEDDED, "is_paper_space", .F., "storage", NIL, "envelope", NIL, "dwg_mode", 0, "lock_aspect", 0 )
FUNCTION Eo2_BoundingBox( e )
   LOCAL b := Bb3_FromPoints( { e[ "upper_left_corner" ], e[ "lower_right_corner" ] } )
RETURN iif( b == NIL, Bb3_FromPoint( e[ "upper_left_corner" ] ), b )
FUNCTION Eo2_Translate( e, vOff )
   e[ "upper_left_corner" ] := Vc3_Add( e[ "upper_left_corner" ], vOff )
   e[ "lower_right_corner" ] := Vc3_Add( e[ "lower_right_corner" ], vOff )
RETURN NIL
FUNCTION Eo2_Transform( e, t )
   e[ "upper_left_corner" ] := Tf_Apply( t, e[ "upper_left_corner" ] )
   e[ "lower_right_corner" ] := Tf_Apply( t, e[ "lower_right_corner" ] )
RETURN NIL
