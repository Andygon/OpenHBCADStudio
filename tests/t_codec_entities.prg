/* Port de tests: xdata/mod.rs (2) y entities/line.rs (7) */
#include "ocx.ch"
STATIC FUNCTION Near( a, b ) ; RETURN Abs( a - b ) < 0.0000000001
PROCEDURE T_CodecEntities()
   LOCAL r, x, l
   // xdata
   r := Xr_New( "MYAPP" )
   Chk( Xr_ApplicationName( r ) == "MYAPP" .AND. Xr_IsEmpty( r ), "xdata: test_xdata_record_creation (1)" )
   Xr_AddValue( r, Xv_New( XV_STRING, "test" ) )
   Chk( Xr_Len( r ) == 1, "xdata: test_xdata_record_creation (2)" )
   x := Xd_New() ; Chk( Xd_IsEmpty( x ), "xdata: test_xdata_collection (1)" )
   r := Xr_New( "APP1" ) ; Xr_AddValue( r, Xv_New( XV_REAL, 3.14 ) ) ; Xd_AddRecord( x, r )
   Chk( Xd_Len( x ) == 1 .AND. Xd_GetRecord( x, "APP1" ) != NIL .AND. Xd_GetRecord( x, "APP2" ) == NIL, "xdata: test_xdata_collection (2)" )
   // [extra] xdata
   r := Xr_New( "APP1" ) ; Xd_UpsertRecord( x, r )
   Chk( Xd_Len( x ) == 1 .AND. Xr_IsEmpty( Xd_GetRecord( x, "APP1" ) ), "[extra] xdata: upsert reemplaza" )
   Xd_UpsertRecord( x, Xr_New( "B" ) )
   Chk( Xd_Len( x ) == 2 .AND. Xd_RemoveRecord( x, "B" ) != NIL .AND. Xd_RemoveRecord( x, "B" ) == NIL .AND. Xd_Len( x ) == 1, "[extra] xdata: remove" )
   Xd_Clear( x ) ; Chk( Xd_IsEmpty( x ), "[extra] xdata: clear" )
   // line
   l := Eln_New()
   Chk( Vc3_Eq( l[ "start" ], Vc3_Zero() ) .AND. Vc3_Eq( l[ "end" ], Vc3_Zero() ) .AND. Ent_EntityType( l ) == "LINE", "line: test_line_creation" )
   l := Eln_FromPoints( Vc3_New( 0.0, 0.0, 0.0 ), Vc3_New( 10.0, 0.0, 0.0 ) )
   Chk( Eln_Length( l ) == 10.0, "line: test_line_from_points" )
   Chk( Eln_Length( Eln_FromCoords( 0.0, 0.0, 0.0, 3.0, 4.0, 0.0 ) ) == 5.0, "line: test_line_length" )
   Chk( Vc3_Eq( Eln_Midpoint( Eln_FromCoords( 0.0, 0.0, 0.0, 10.0, 20.0, 30.0 ) ), Vc3_New( 5.0, 10.0, 15.0 ) ), "line: test_line_midpoint" )
   l := Eln_FromCoords( 0.0, 0.0, 0.0, 10.0, 0.0, 0.0 ) ; Ent_Translate( l, Vc3_New( 5.0, 5.0, 5.0 ) )
   Chk( Vc3_Eq( l[ "start" ], Vc3_New( 5.0, 5.0, 5.0 ) ) .AND. Vc3_Eq( l[ "end" ], Vc3_New( 15.0, 5.0, 5.0 ) ), "line: test_line_translate" )
   l := Eln_FromCoords( 1.0, 2.0, 0.0, 4.0, 6.0, 0.0 ) ; Ent_MirrorX( l )
   Chk( Near( l[ "start" ][ 1 ], -1.0 ) .AND. Near( l[ "start" ][ 2 ], 2.0 ) .AND. Near( l[ "end" ][ 1 ], -4.0 ) .AND. Near( l[ "end" ][ 2 ], 6.0 ), "line: test_line_mirror_x" )
   l := Eln_FromCoords( 0.0, 5.0, 0.0, 10.0, 5.0, 0.0 ) ; Ent_MirrorAboutLine( l, Vc3_New( 0.0, 0.0, 0.0 ), Vc3_New( 1.0, 0.0, 0.0 ) )
   Chk( Near( l[ "start" ][ 2 ], -5.0 ) .AND. Near( l[ "end" ][ 2 ], -5.0 ), "line: test_line_mirror_about_line" )
   // [extra] EntityCommon y accesores
   l := Eln_New() ; Ent_SetLayer( l, "L1" ) ; Ent_SetInvisible( l, .T. ) ; Ent_SetColor( l, Cl_Red() )
   Chk( Ent_Layer( l ) == "L1" .AND. Ent_IsInvisible( l ) .AND. Cl_Eq( Ent_Color( l ), Cl_Index( 1 ) ) .AND. Ec_WithLayer( "X" )[ "layer" ] == "X" .AND. ! Ec_HasLinetype( l[ "common" ] ), "[extra] entity_common: accesores y defaults" )
   l[ "common" ][ "linetype" ] := "DASHED"
   Chk( Ec_HasLinetype( l[ "common" ] ) .AND. ! ( Ec_New()[ "linetype_scale" ] != 1.0 ), "[extra] entity_common: has_linetype" )
   l := Eln_FromCoords( 0.0, 0.0, 0.0, 1.0, 2.0, 3.0 ) ; Ent_ApplyScaling( l, 2.0 )
   Chk( Vc3_Eq( l[ "end" ], Vc3_New( 2.0, 4.0, 6.0 ) ) .AND. Vc3_Eq( Eln_BoundingBox( l )[ 2 ], Vc3_New( 2.0, 4.0, 6.0 ) ), "[extra] line: escala y bounding box" )
RETURN
