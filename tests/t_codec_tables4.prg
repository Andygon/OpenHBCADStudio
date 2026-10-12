/* Tests: block_record.rs (4 tests 1:1) + [extra] design_center */
#include "ocx.ch"
PROCEDURE T_CodecTables4()
   LOCAL b, a
   b := Blk_New( "MyBlock" ) ; Chk( b[ "name" ] == "MyBlock" .AND. b[ "explodable" ], "block_record_creation" )
   Chk( Blk_IsModelSpace( Blk_New( "*MODEL_SPACE" ) ) .AND. Blk_IsModelSpace( Blk_New( "*model_space" ) ) .AND. Blk_IsPaperSpace( Blk_New( "*PAPER_SPACE" ) ) ;
      .AND. Blk_IsPaperSpace( Blk_New( "*paper_space12" ) ) .AND. ! Blk_IsPaperSpace( Blk_New( "*paperwork" ) ), "space_record_names_are_ascii_case_insensitive" )
   b := Blk_ModelSpace() ; Chk( Blk_IsModelSpace( b ) .AND. Blk_IsStandard( b ) .AND. ! Blk_IsPaperSpace( b ), "model_space" )
   b := Blk_PaperSpace() ; Chk( Blk_IsPaperSpace( b ) .AND. Blk_IsStandard( b ) .AND. ! Blk_IsModelSpace( b ), "paper_space" )
   b := Blk_New( "A" ) ; Chk( ! Blk_IsLayout( b ) .AND. ! Blk_IsAnonymous( b ) .AND. Blk_IsAnonymous( Blk_New( "*U1" ) ), "[extra] block: is_layout / is_anonymous" )
   b[ "layout" ] := 5 ; b[ "flags" ][ "anonymous" ] := .T. ; Chk( Blk_IsLayout( b ) .AND. Blk_IsAnonymous( b ), "[extra] block: layout y flag anonymous" )
   a := Blk_DesignCenterUnitsValues( 4 ) ; Chk( Len( a ) == 5 .AND. Blk_DesignCenterUnits( a ) == 4, "[extra] design_center_units ida y vuelta" )
   a[ 1 ][ 2 ] := "Otro" ; Chk( Blk_DesignCenterUnits( a ) == NIL .AND. Blk_DesignCenterUnits( {} ) == NIL, "[extra] design_center_units: nombre distinto o corto da None" )
RETURN
