/* Tests de reader/section_reader.rs (mod tests, 18 #[test]): 16 portados 1:1 (los de LINE/CIRCLE/ARC normal ya estan en t_dxf_rw.prg).
   NO portados: spatial_filter_matrix_is_column_major y spatial_filter_dxf_roundtrip_preserves_translation (el objeto SPATIAL_FILTER no tiene
   lector/escritor DXF aun). Roundtrip = Dxr_ReadString( Dxw_WriteString( d ) ); binario = Dxw_WriteBinaryString. */
#include "ocx.ch"

STATIC FUNCTION Rt( d ) ; RETURN Dxr_ReadString( Dxw_WriteString( d ) )
STATIC FUNCTION Rb( d ) ; RETURN Dxr_ReadString( Dxw_WriteBinaryString( d ) )
STATIC FUNCTION Nr( a, b ) ; RETURN Abs( a - b ) < 0.000000001
STATIC FUNCTION Rad( n ) ; RETURN n * ( OCX_PI / 180.0 )
STATIC FUNCTION Cr( a ) ; RETURN ArrayToCrLf( a )
STATIC FUNCTION ArrayToCrLf( a )
   LOCAL c := "", x
   FOR EACH x IN a ; c += x + Chr( 13 ) + Chr( 10 ) ; NEXT
RETURN c

PROCEDURE T_DxfReader()
   LOCAL d, e, es, t, a, dx, lw, ins, m
   /* true_color_bits_accepts_both_spellings_and_refuses_the_rest */
   Chk( Sr_TrueColorBitsP( "3271526400" ) == -1023440896 .AND. Sr_TrueColorBitsP( "-1023440896" ) == -1023440896 ;
      .AND. Sr_TrueColorBitsP( "16746496" ) == 16746496 .AND. Sr_TrueColorBitsP( "2147483647" ) == 2147483647 ;
      .AND. Sr_TrueColorBitsP( "2147483648" ) == -2147483648 .AND. Sr_TrueColorBitsP( "4294967295" ) == -1 ;
      .AND. Sr_TrueColorBitsP( "  3271526400" + Chr( 13 ) + Chr( 10 ) ) == -1023440896 ;
      .AND. Sr_TrueColorBitsP( "4294967296" ) == NIL .AND. Sr_TrueColorBitsP( "-2147483649" ) == NIL ;
      .AND. Sr_TrueColorBitsP( "" ) == NIL .AND. Sr_TrueColorBitsP( "ff8800" ) == NIL, "dxf_reader: true_color_bits_accepts_both_spellings_and_refuses_the_rest" )
   /* test_dxf_roundtrip_text_properties */
   d := Doc_New() ; t := Etx_New() ; t[ "value" ] := "Hello" ; t[ "insertion_point" ] := Vc3_New( 1.0, 2.0, 3.0 ) ; t[ "alignment_point" ] := Vc3_New( 10.0, 20.0, 0.0 )
   t[ "height" ] := 2.5 ; t[ "rotation" ] := Rad( 45.0 ) ; t[ "horizontal_alignment" ] := TXH_CENTER ; t[ "vertical_alignment" ] := TXV_MIDDLE ; t[ "normal" ] := Vc3_New( 0.0, 1.0, 0.0 )
   Doc_AddEntity( d, t )
   d := Rt( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "TEXT" .AND. es[ 1 ][ "value" ] == "Hello" .AND. Nr( es[ 1 ][ "height" ], 2.5 ) .AND. Abs( es[ 1 ][ "rotation" ] - Rad( 45.0 ) ) < 0.000001 ;
      .AND. es[ 1 ][ "horizontal_alignment" ] == TXH_CENTER .AND. es[ 1 ][ "vertical_alignment" ] == TXV_MIDDLE .AND. Nr( es[ 1 ][ "normal" ][ 2 ], 1.0 ) ;
      .AND. es[ 1 ][ "alignment_point" ] != NIL .AND. Nr( es[ 1 ][ "alignment_point" ][ 1 ], 10.0 ), "dxf_reader: test_dxf_roundtrip_text_properties" )
   /* test_dxf_read_attrib_angles_in_radians */
   dx := Cr( { "  0", "SECTION", "  2", "ENTITIES", "  0", "ATTRIB", "  5", "1", "100", "AcDbEntity", "  8", "0", "100", "AcDbText", " 10", "1.0", " 20", "2.0", " 30", "0.0", ;
      " 40", "0.5", "  1", "TAG VALUE", " 50", "75.0", " 51", "15.0", "100", "AcDbAttribute", "  2", "LABEL", " 70", "0", "  0", "ENDSEC", "  0", "EOF" } )
   d := Dxr_ReadString( dx ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "ATTRIB" .AND. es[ 1 ][ "value" ] == "TAG VALUE" .AND. Nr( es[ 1 ][ "rotation" ], Rad( 75.0 ) ) .AND. Nr( es[ 1 ][ "oblique_angle" ], Rad( 15.0 ) ), "dxf_reader: test_dxf_read_attrib_angles_in_radians" )
   /* test_dxf_roundtrip_attrib_angles */
   d := Doc_New() ; a := Eat_New( "", "" ) ; a[ "tag" ] := "LABEL" ; a[ "value" ] := "TAG VALUE" ; a[ "height" ] := 0.5 ; a[ "rotation" ] := Rad( 75.0 ) ; a[ "oblique_angle" ] := Rad( 15.0 )
   ins := Ein_New( "*Model_Space", Vc3_New( 0.0, 0.0, 0.0 ) ) ; ins[ "rotation" ] := Rad( 75.0 ) ; AAdd( ins[ "attributes" ], a ) ; Doc_AddEntity( d, ins )
   d := Rt( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} ) ; ins := NIL
   FOR EACH e IN es
      IF e[ "_type" ] == "INSERT" ; ins := e ; EXIT ; ENDIF
   NEXT
   Chk( ins != NIL .AND. Len( ins[ "attributes" ] ) == 1 .AND. Nr( ins[ "attributes" ][ 1 ][ "rotation" ], Rad( 75.0 ) ) .AND. Nr( ins[ "attributes" ][ 1 ][ "oblique_angle" ], Rad( 15.0 ) ), "dxf_reader: test_dxf_roundtrip_attrib_angles" )
   /* test_dxf_roundtrip_mtext_properties */
   d := Doc_New() ; m := Emt_New() ; m[ "value" ] := "Multi\Pline" ; m[ "insertion_point" ] := Vc3_New( 5.0, 10.0, 0.0 ) ; m[ "height" ] := 3.0 ; m[ "rectangle_width" ] := 50.0
   m[ "attachment_point" ] := MTA_MIDDLECENTER ; m[ "drawing_direction" ] := MTD_TOPTOBOTTOM ; m[ "line_spacing_factor" ] := 1.5 ; m[ "normal" ] := Vc3_New( 0.0, 0.0, -1.0 ) ; Doc_AddEntity( d, m )
   d := Rt( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "MTEXT" .AND. es[ 1 ][ "value" ] == "Multi\Pline" .AND. Nr( es[ 1 ][ "height" ], 3.0 ) .AND. Nr( es[ 1 ][ "rectangle_width" ], 50.0 ) ;
      .AND. es[ 1 ][ "attachment_point" ] == MTA_MIDDLECENTER .AND. es[ 1 ][ "drawing_direction" ] == MTD_TOPTOBOTTOM .AND. Nr( es[ 1 ][ "line_spacing_factor" ], 1.5 ) .AND. Nr( es[ 1 ][ "normal" ][ 3 ], -1.0 ), "dxf_reader: test_dxf_roundtrip_mtext_properties" )
   /* test_dxf_roundtrip_lwpolyline_properties */
   d := Doc_New() ; lw := Elw_New() ; lw[ "is_closed" ] := .T. ; lw[ "elevation" ] := 5.0 ; lw[ "thickness" ] := 2.0 ; lw[ "constant_width" ] := 0.5 ; lw[ "normal" ] := Vc3_New( 0.0, 1.0, 0.0 )
   lw[ "vertices" ] := { Elv_FromCoords( 0.0, 0.0 ), Elv_FromCoords( 10.0, 0.0 ), Elv_FromCoords( 10.0, 10.0 ) } ; Doc_AddEntity( d, lw )
   d := Rt( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "LWPOLYLINE" .AND. es[ 1 ][ "is_closed" ] .AND. Nr( es[ 1 ][ "elevation" ], 5.0 ) .AND. Nr( es[ 1 ][ "thickness" ], 2.0 ) ;
      .AND. Nr( es[ 1 ][ "constant_width" ], 0.5 ) .AND. Nr( es[ 1 ][ "normal" ][ 2 ], 1.0 ) .AND. Len( es[ 1 ][ "vertices" ] ) == 3, "dxf_reader: test_dxf_roundtrip_lwpolyline_properties" )
   /* test_dxf_roundtrip_lwpolyline_bulge_per_vertex */
   d := Doc_New() ; lw := Elw_New()
   lw[ "vertices" ] := { Elv_FromCoords( 0.0, 0.0 ), Elv_FromCoords( 10.0, 0.0 ), Elv_FromCoords( 20.0, 0.0 ), Elv_FromCoords( 30.0, 0.0 ) }
   lw[ "vertices" ][ 2 ][ "bulge" ] := 0.5 ; lw[ "vertices" ][ 2 ][ "start_width" ] := 1.0 ; lw[ "vertices" ][ 2 ][ "end_width" ] := 2.0
   lw[ "vertices" ][ 4 ][ "bulge" ] := -0.3 ; lw[ "vertices" ][ 4 ][ "start_width" ] := 0.5 ; lw[ "vertices" ][ 4 ][ "end_width" ] := 0.5 ; Doc_AddEntity( d, lw )
   d := Rt( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. Len( es[ 1 ][ "vertices" ] ) == 4, "dxf_reader: test_dxf_roundtrip_lwpolyline_bulge_per_vertex (n)" )
   IF Len( es ) == 1 .AND. Len( es[ 1 ][ "vertices" ] ) == 4
      lw := es[ 1 ][ "vertices" ]
      Chk( Abs( lw[ 1 ][ "bulge" ] ) < 0.000000001 .AND. Abs( lw[ 1 ][ "start_width" ] ) < 0.000000001 .AND. Abs( lw[ 1 ][ "end_width" ] ) < 0.000000001 ;
         .AND. Nr( lw[ 2 ][ "bulge" ], 0.5 ) .AND. Nr( lw[ 2 ][ "start_width" ], 1.0 ) .AND. Nr( lw[ 2 ][ "end_width" ], 2.0 ) ;
         .AND. Abs( lw[ 3 ][ "bulge" ] ) < 0.000000001 .AND. Abs( lw[ 3 ][ "start_width" ] ) < 0.000000001 .AND. Abs( lw[ 3 ][ "end_width" ] ) < 0.000000001 ;
         .AND. Nr( lw[ 4 ][ "bulge" ], -0.3 ) .AND. Nr( lw[ 4 ][ "start_width" ], 0.5 ) .AND. Nr( lw[ 4 ][ "end_width" ], 0.5 ), "dxf_reader: test_dxf_roundtrip_lwpolyline_bulge_per_vertex" )
   ENDIF
   /* test_dxf_read_lwpolyline_sparse_bulge */
   dx := Cr( { "  0", "SECTION", "  2", "ENTITIES", "  0", "LWPOLYLINE", "  5", "1", "100", "AcDbEntity", "  8", "0", "100", "AcDbPolyline", " 90", "4", " 70", "0", " 38", "0.0", ;
      " 10", "0.0", " 20", "0.0", " 10", "10.0", " 20", "0.0", " 42", "0.5", " 10", "20.0", " 20", "0.0", " 10", "30.0", " 20", "0.0", "  0", "ENDSEC", "  0", "EOF" } )
   d := Dxr_ReadString( dx ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "LWPOLYLINE" .AND. Len( es[ 1 ][ "vertices" ] ) == 4, "dxf_reader: test_dxf_read_lwpolyline_sparse_bulge (n)" )
   IF Len( es ) == 1 .AND. Len( es[ 1 ][ "vertices" ] ) == 4
      lw := es[ 1 ][ "vertices" ]
      Chk( Nr( lw[ 1 ][ "location" ][ 1 ], 0.0 ) .AND. Nr( lw[ 2 ][ "location" ][ 1 ], 10.0 ) .AND. Nr( lw[ 3 ][ "location" ][ 1 ], 20.0 ) .AND. Nr( lw[ 4 ][ "location" ][ 1 ], 30.0 ) ;
         .AND. Abs( lw[ 1 ][ "bulge" ] ) < 0.000000001 .AND. Nr( lw[ 2 ][ "bulge" ], 0.5 ) .AND. Abs( lw[ 3 ][ "bulge" ] ) < 0.000000001 .AND. Abs( lw[ 4 ][ "bulge" ] ) < 0.000000001, "dxf_reader: test_dxf_read_lwpolyline_sparse_bulge" )
   ENDIF
   /* test_dxf_read_lwpolyline_sparse_widths_and_bulge */
   dx := Cr( { "  0", "SECTION", "  2", "ENTITIES", "  0", "LWPOLYLINE", "  5", "1", "100", "AcDbEntity", "  8", "0", "100", "AcDbPolyline", " 90", "4", " 70", "0", " 38", "0.0", ;
      " 10", "0.0", " 20", "0.0", " 10", "10.0", " 20", "0.0", " 42", "0.5", " 10", "20.0", " 20", "0.0", " 40", "1.0", " 41", "2.0", ;
      " 10", "30.0", " 20", "0.0", " 40", "0.5", " 41", "0.5", " 42", "-0.3", "  0", "ENDSEC", "  0", "EOF" } )
   d := Dxr_ReadString( dx ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "LWPOLYLINE" .AND. Len( es[ 1 ][ "vertices" ] ) == 4, "dxf_reader: test_dxf_read_lwpolyline_sparse_widths_and_bulge (n)" )
   IF Len( es ) == 1 .AND. Len( es[ 1 ][ "vertices" ] ) == 4
      lw := es[ 1 ][ "vertices" ]
      Chk( Abs( lw[ 1 ][ "bulge" ] ) < 0.000000001 .AND. Abs( lw[ 1 ][ "start_width" ] ) < 0.000000001 .AND. Abs( lw[ 1 ][ "end_width" ] ) < 0.000000001 ;
         .AND. Nr( lw[ 2 ][ "bulge" ], 0.5 ) .AND. Abs( lw[ 2 ][ "start_width" ] ) < 0.000000001 .AND. Abs( lw[ 2 ][ "end_width" ] ) < 0.000000001 ;
         .AND. Abs( lw[ 3 ][ "bulge" ] ) < 0.000000001 .AND. Nr( lw[ 3 ][ "start_width" ], 1.0 ) .AND. Nr( lw[ 3 ][ "end_width" ], 2.0 ) ;
         .AND. Nr( lw[ 4 ][ "bulge" ], -0.3 ) .AND. Nr( lw[ 4 ][ "start_width" ], 0.5 ) .AND. Nr( lw[ 4 ][ "end_width" ], 0.5 ), "dxf_reader: test_dxf_read_lwpolyline_sparse_widths_and_bulge" )
   ENDIF
   /* test_dxf_roundtrip_linetype_and_scale */
   d := Doc_New() ; e := Eln_New() ; e[ "start" ] := Vc3_New( 0.0, 0.0, 0.0 ) ; e[ "end" ] := Vc3_New( 10.0, 0.0, 0.0 ) ; e[ "common" ][ "linetype" ] := "DASHED" ; e[ "common" ][ "linetype_scale" ] := 2.5 ; Doc_AddEntity( d, e )
   d := Rt( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "LINE" .AND. es[ 1 ][ "common" ][ "linetype" ] == "DASHED" .AND. Nr( es[ 1 ][ "common" ][ "linetype_scale" ], 2.5 ), "dxf_reader: test_dxf_roundtrip_linetype_and_scale" )
   /* test_binary_dxf_roundtrip_line */
   d := Doc_New() ; e := Eln_New() ; e[ "start" ] := Vc3_New( 1.0, 2.0, 3.0 ) ; e[ "end" ] := Vc3_New( 4.0, 5.0, 6.0 ) ; e[ "thickness" ] := 1.5 ; Doc_AddEntity( d, e )
   d := Rb( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "LINE" .AND. Nr( es[ 1 ][ "start" ][ 1 ], 1.0 ) .AND. Nr( es[ 1 ][ "end" ][ 3 ], 6.0 ) .AND. Nr( es[ 1 ][ "thickness" ], 1.5 ), "dxf_reader: test_binary_dxf_roundtrip_line" )
   /* test_binary_dxf_roundtrip_mtext_newlines */
   d := Doc_New() ; m := Emt_New() ; m[ "value" ] := "Hello" + Chr( 10 ) + "World" ; m[ "insertion_point" ] := Vc3_New( 10.0, 20.0, 0.0 ) ; Doc_AddEntity( d, m )
   d := Rb( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "MTEXT" .AND. "\P" $ es[ 1 ][ "value" ] .AND. ! ( Chr( 10 ) $ es[ 1 ][ "value" ] ), "dxf_reader: test_binary_dxf_roundtrip_mtext_newlines" )
   /* test_binary_dxf_roundtrip_circle */
   d := Doc_New() ; e := Eci_New() ; e[ "center" ] := Vc3_New( 5.0, 10.0, 0.0 ) ; e[ "radius" ] := 3.5 ; Doc_AddEntity( d, e )
   d := Rb( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "CIRCLE" .AND. Nr( es[ 1 ][ "center" ][ 1 ], 5.0 ) .AND. Nr( es[ 1 ][ "center" ][ 2 ], 10.0 ) .AND. Nr( es[ 1 ][ "radius" ], 3.5 ), "dxf_reader: test_binary_dxf_roundtrip_circle" )
   /* spatial_filter_matrix_is_column_major */
   m := Dxo_MatrixFromColMajor( { 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, -200.0, -150.0, 0.0 } )
   a := Mx4_TransformPoint( m, Vc3_New( 210.0, 160.0, 0.0 ) )
   Chk( Mx4_Eq( m, { { 1.0, 0.0, 0.0, -200.0 }, { 0.0, 1.0, 0.0, -150.0 }, { 0.0, 0.0, 1.0, 0.0 }, { 0.0, 0.0, 0.0, 1.0 } } ) ;
      .AND. Abs( a[ 1 ] - 10.0 ) < 0.000000001 .AND. Abs( a[ 2 ] - 10.0 ) < 0.000000001, "dxf_reader: spatial_filter_matrix_is_column_major" )
   /* spatial_filter_dxf_roundtrip_preserves_translation */
   d := Doc_New() ; e := Spf_New() ; e[ "handle" ] := 171
   e[ "boundary_points" ] := { { 210.0, 160.0 }, { 240.0, 190.0 } } ; e[ "inverse_block_transform" ] := Mx4_Translation( -200.0, -150.0, 0.0 )
   d[ "objects" ][ 171 ] := e
   d := Rt( d )
   Chk( ValType( d ) == "H" .AND. hb_HHasKey( d[ "objects" ], 171 ) .AND. Mx4_Eq( d[ "objects" ][ 171 ][ "inverse_block_transform" ], Mx4_Translation( -200.0, -150.0, 0.0 ) ), "dxf_reader: spatial_filter_dxf_roundtrip_preserves_translation" )
   /* [extra] spatial_filter: puntos, flags y clips */
   d := Doc_New() ; e := Spf_New() ; e[ "handle" ] := 172 ; e[ "front_clip" ] := 1.5 ; e[ "back_clip" ] := 7.0 ; e[ "display_enabled" ] := .F.
   e[ "boundary_points" ] := { { 1.0, 2.0 }, { 3.0, 4.0 } } ; e[ "clip_bound_transform" ] := Mx4_Translation( 5.0, 6.0, 7.0 )
   d[ "objects" ][ 172 ] := e ; d := Rt( d ) ; e := IIf( ValType( d ) == "H" .AND. hb_HHasKey( d[ "objects" ], 172 ), d[ "objects" ][ 172 ], NIL )
   Chk( e != NIL .AND. Len( e[ "boundary_points" ] ) == 2 .AND. e[ "boundary_points" ][ 2 ][ 2 ] == 4.0 .AND. e[ "front_clip" ] == 1.5 .AND. e[ "back_clip" ] == 7.0 ;
      .AND. ! e[ "display_enabled" ] .AND. Mx4_Eq( e[ "clip_bound_transform" ], Mx4_Translation( 5.0, 6.0, 7.0 ) ) .AND. Mx4_Eq( e[ "inverse_block_transform" ], Mx4_Identity() ), "dxf_reader: [extra] spatial_filter completo" )
   /* [extra] xdata de objetos: roundtrip por object_xdata (DICTIONARYVAR sin xdata propio) */
   d := Doc_New() ; e := Dvr_New( "X", "v" ) ; e[ "handle" ] := 180
   d[ "objects" ][ 180 ] := e
   m := Xd_New() ; a := Xr_New( "MIAPP" ) ; Xr_AddValue( a, Xv_New( XV_STRING, "hola" ) ) ; Xr_AddValue( a, Xv_New( XV_INTEGER16, 7 ) ) ; Xd_AddRecord( m, a )
   d[ "object_xdata" ][ 180 ] := m
   d := Rt( d )
   Chk( ValType( d ) == "H" .AND. hb_HHasKey( d[ "object_xdata" ], 180 ) .AND. Len( Xd_Records( d[ "object_xdata" ][ 180 ] ) ) == 1 ;
      .AND. Xr_ApplicationName( Xd_Records( d[ "object_xdata" ][ 180 ] )[ 1 ] ) == "MIAPP" .AND. Len( Xr_Values( Xd_Records( d[ "object_xdata" ][ 180 ] )[ 1 ] ) ) == 2, "dxf_reader: [extra] object_xdata roundtrip" )
   /* [extra] LIGHT roundtrip (con datos fotometricos). Fiel al Rust: los codigos 43/53/63 no son un grupo de coordenadas (web_rotation vuelve a (1,1,1)) y el 53 se lo queda web_rotation, no web_angles[3]. */
   d := Doc_New() ; e := Elt_New() ; e[ "name" ] := "L1" ; e[ "light_type" ] := 3 ; e[ "position" ] := Vc3_New( 1.0, 2.0, 3.0 ) ; e[ "target" ] := Vc3_New( 4.0, 5.0, 6.0 )
   e[ "intensity" ] := 2.5 ; e[ "light_color" ] := Cl_FromRgb( 10, 20, 30 ) ; e[ "cast_shadows" ] := .T. ; e[ "hotspot_angle" ] := 12.0 ; e[ "photometric_mode" ] := .T.
   m := Lpd_New() ; m[ "web_file" ] := "x.ies" ; m[ "has_web_file" ] := .T. ; m[ "physical_intensity" ] := 1500.0 ; m[ "web_angles" ] := { 1.0, 2.0, 3.0, 4.0, 5.0 } ; m[ "web_rotation" ] := Vc3_New( 7.0, 8.0, 9.0 )
   e[ "photometric_data" ] := m ; Doc_AddEntity( d, e ) ; d := Rt( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "LIGHT" .AND. es[ 1 ][ "name" ] == "L1" .AND. es[ 1 ][ "light_type" ] == 3 .AND. Nr( es[ 1 ][ "position" ][ 2 ], 2.0 ) .AND. Nr( es[ 1 ][ "target" ][ 3 ], 6.0 ) ;
      .AND. Nr( es[ 1 ][ "intensity" ], 2.5 ) .AND. es[ 1 ][ "cast_shadows" ] .AND. Nr( es[ 1 ][ "hotspot_angle" ], 12.0 ) .AND. es[ 1 ][ "photometric_data" ] != NIL ;
      .AND. es[ 1 ][ "photometric_data" ][ "web_file" ] == "x.ies" .AND. Nr( es[ 1 ][ "photometric_data" ][ "physical_intensity" ], 1500.0 ) .AND. Nr( es[ 1 ][ "photometric_data" ][ "web_angles" ][ 5 ], 5.0 ) ;
      .AND. Nr( es[ 1 ][ "photometric_data" ][ "web_rotation" ][ 1 ], 1.0 ) .AND. Nr( es[ 1 ][ "photometric_data" ][ "web_angles" ][ 4 ], 0.0 ) .AND. es[ 1 ][ "light_color" ][ 1 ] == CK_RGB, "dxf_reader: [extra] light roundtrip" )
   /* [extra] entidad desconocida: se conserva con sus codigos */
   dx := Cr( { "  0", "SECTION", "  2", "ENTITIES", "  0", "ZZUNKNOWN", "  5", "2A", "  8", "CAPA", "100", "AcDbZz", " 10", "1.5", "  1", "texto", "  0", "ENDSEC", "  0", "EOF" } )
   d := Dxr_ReadString( dx ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "UNKNOWN" .AND. es[ 1 ][ "dxf_name" ] == "ZZUNKNOWN" .AND. es[ 1 ][ "common" ][ "layer" ] == "CAPA" .AND. Len( es[ 1 ][ "raw_dxf_codes" ] ) == 3, "dxf_reader: [extra] unknown entity leida" )
   d := Rt( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "UNKNOWN" .AND. ATail( es[ 1 ][ "raw_dxf_codes" ] )[ 2 ] == "texto", "dxf_reader: [extra] unknown entity roundtrip" )
   /* [extra] SECTIONLINE y DRAWINGVIEW roundtrip */
   d := Doc_New() ; e := Esy_New() ; e[ "symbol_scale" ] := 2.0 ; e[ "version" ] := 3 ; a := Ssp_New() ; a[ "point" ] := Vc3_New( 1.0, 2.0, 0.0 ) ; a[ "label" ] := "A" ; a[ "label_offset" ] := Vc3_New( 0.0, 0.5, 0.0 ) ; a[ "raw_flag_280" ] := 1
   AAdd( e[ "points" ], a ) ; a := Ssp_New() ; a[ "point" ] := Vc3_New( 5.0, 6.0, 0.0 ) ; AAdd( e[ "points" ], a ) ; Doc_AddEntity( d, e )
   e := Evb_New() ; e[ "version" ] := 1 ; e[ "min" ] := { 1.0, 2.0 } ; e[ "max" ] := { 3.0, 4.0 } ; e[ "scale" ] := 0.5 ; e[ "rotation_angle" ] := 0.25 ; e[ "center" ] := { 7.0, 8.0 } ; Doc_AddEntity( d, e )
   d := Rt( d ) ; es := IIf( ValType( d ) == "H", Doc_Entities( d ), {} )
   Chk( Len( es ) == 2 .AND. es[ 1 ][ "_type" ] == "SECTIONLINE" .AND. Len( es[ 1 ][ "points" ] ) == 2 .AND. Nr( es[ 1 ][ "symbol_scale" ], 2.0 ) .AND. es[ 1 ][ "version" ] == 3 .AND. es[ 1 ][ "points" ][ 1 ][ "label" ] == "A" ;
      .AND. Nr( es[ 1 ][ "points" ][ 2 ][ "point" ][ 1 ], 5.0 ) .AND. es[ 1 ][ "points" ][ 1 ][ "raw_flag_280" ] == 1 .AND. es[ 1 ][ "label" ] == "A" .AND. Nr( es[ 1 ][ "tick_a" ], 0.5 ) ;
      .AND. es[ 2 ][ "_type" ] == "DRAWINGVIEW" .AND. es[ 2 ][ "version" ] == 1 .AND. Nr( es[ 2 ][ "max" ][ 2 ], 4.0 ) .AND. Nr( es[ 2 ][ "scale" ], 0.5 ) .AND. Nr( es[ 2 ][ "rotation_angle" ], 0.25 ) .AND. Nr( es[ 2 ][ "center" ][ 2 ], 8.0 ), "dxf_reader: [extra] sectionline y drawingview roundtrip" )
   /* [extra] objeto desconocido: se conserva (roundtrip) y si es "no restaurable" se descarta */
   dx := Cr( { "  0", "SECTION", "  2", "OBJECTS", "  0", "DICTIONARY", "  5", "C", "330", "0", "100", "AcDbDictionary", "  3", "ZZ", "350", "7F", "  0", "ZZOBJ", "  5", "7F", "330", "C", "100", "AcDbZz", " 90", "42", ;
      "  0", "ACDB_DYNAMICBLOCKPURGEPREVENTER_VERSION", "  5", "80", "330", "C", " 70", "1", "  0", "ENDSEC", "  0", "EOF" } )
   d := Dxr_ReadString( dx )
   Chk( ValType( d ) == "H" .AND. hb_HHasKey( d[ "objects" ], 127 ) .AND. d[ "objects" ][ 127 ][ "_type" ] == "Unknown" .AND. d[ "objects" ][ 127 ][ "type_name" ] == "ZZOBJ" .AND. d[ "objects" ][ 127 ][ "owner" ] == 12 .AND. Len( d[ "objects" ][ 127 ][ "raw_dxf_codes" ] ) == 2, "dxf_reader: [extra] unknown object leido" )
   d := Rt( d )
   Chk( ValType( d ) == "H" .AND. hb_HHasKey( d[ "objects" ], 127 ) .AND. d[ "objects" ][ 127 ][ "type_name" ] == "ZZOBJ" .AND. ATail( d[ "objects" ][ 127 ][ "raw_dxf_codes" ] )[ 2 ] == "42" .AND. ! hb_HHasKey( d[ "objects" ], 128 ), "dxf_reader: [extra] unknown object roundtrip y no restaurable" )
RETURN
