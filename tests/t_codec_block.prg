/* Port de tests: block.rs (3); seqend.rs sin tests -> [extra] */
#include "ocx.ch"
PROCEDURE T_CodecBlock()
   LOCAL b, s
   b := Ebk_New( "MyBlock", Vc3_New( 10.0, 20.0, 0.0 ) )
   Chk( b[ "name" ] == "MyBlock" .AND. Vc3_Eq( b[ "base_point" ], Vc3_New( 10.0, 20.0, 0.0 ) ) .AND. b[ "description" ] == "", "block: test_block_creation" )
   Chk( Ebk_WithDescription( Ebk_New( "MyBlock", Vc3_Zero() ), "Test block" )[ "description" ] == "Test block", "block: test_block_with_description" )
   Chk( Hd_IsNull( Ebe_New()[ "common" ][ "handle" ] ), "block: test_block_end_creation" )
   // [extra]
   Ent_Translate( b, Vc3_New( 1.0, 1.0, 1.0 ) ) ; Chk( Vc3_Eq( b[ "base_point" ], Vc3_New( 11.0, 21.0, 1.0 ) ) .AND. Ent_EntityType( b ) == "BLOCK", "[extra] block: translate" )
   Ent_ApplyScaling( b, 2.0 ) ; Chk( Vc3_Eq( b[ "base_point" ], Vc3_New( 22.0, 42.0, 2.0 ) ), "[extra] block: escala" )
   Chk( Vc3_Eq( Ent_BoundingBox( b )[ 1 ], b[ "base_point" ] ) .AND. Ent_EntityType( Ebe_New() ) == "ENDBLK", "[extra] block: bbox y endblk" )
   s := Esq_New() ; Ent_Translate( s, Vc3_New( 1.0, 2.0, 3.0 ) ) ; Ent_ApplyScaling( s, 2.0 )
   Chk( Ent_EntityType( s ) == "SEQEND" .AND. Vc3_Eq( Ent_BoundingBox( s )[ 1 ], Vc3_Zero() ), "[extra] seqend: sin geometria" )
RETURN
