/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_block.prg
   Origen Rust: opencadcodec/src/entities/block.rs (233, 3 tests) y seqend.rs (81, sin tests)
              + translate_/transform_ de block, block_end y seqend. Licencia del original: MPL-2.0.
   Entidades = hash ("_type" "BLOCK" / "ENDBLK" / "SEQEND"). Prefijos: Ebk_ (Block), Ebe_ (BlockEnd), Esq_ (Seqend).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Ebk_New( cName, vBase ) ; RETURN hb_Hash( "_type", "BLOCK", "common", Ec_New(), "name", cName, "base_point", vBase, "description", "", "xref_path", "" )
FUNCTION Ebk_WithDescription( e, cDesc ) ; e[ "description" ] := cDesc ; RETURN e
FUNCTION Ebk_WithXrefPath( e, cPath ) ; e[ "xref_path" ] := cPath ; RETURN e
FUNCTION Ebk_BoundingBox( e ) ; RETURN Bb3_FromPoint( e[ "base_point" ] )
FUNCTION Ebk_Translate( e, vOffset ) ; e[ "base_point" ] := Vc3_Add( e[ "base_point" ], vOffset ) ; RETURN NIL
FUNCTION Ebk_Transform( e, t ) ; e[ "base_point" ] := Tf_Apply( t, e[ "base_point" ] ) ; RETURN NIL

FUNCTION Ebe_New() ; RETURN hb_Hash( "_type", "ENDBLK", "common", Ec_New() )
FUNCTION Ebe_BoundingBox( e ) ; HB_SYMBOL_UNUSED( e ) ; RETURN Bb3_FromPoint( Vc3_Zero() )

FUNCTION Esq_New() ; RETURN hb_Hash( "_type", "SEQEND", "common", Ec_New() )
FUNCTION Esq_BoundingBox( e ) ; HB_SYMBOL_UNUSED( e ) ; RETURN Bb3_FromPoint( Vc3_Zero() )
