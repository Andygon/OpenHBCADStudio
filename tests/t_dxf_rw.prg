/* Tests roundtrip DXF (lector+escritor). Origen: reader/section_reader.rs tests L21383+ (roundtrip line/circle/arc normal);
   el resto son [extra]. */
#include "ocx.ch"

STATIC FUNCTION RT( d ) ; RETURN Dxr_ReadString( Dxw_WriteString( d ) )

STATIC FUNCTION Sample()
   LOCAL c := "", a, i
   a := { ;
      "  0", "SECTION", "  2", "HEADER", "  9", "$ACADVER", "  1", "AC1015", "  9", "$DWGCODEPAGE", "  3", "ANSI_1252", ;
      "  9", "$HANDSEED", "  5", "A0", "  9", "$INSBASE", " 10", "1.5", " 20", "2.5", " 30", "0.0", ;
      "  9", "$LTSCALE", " 40", "2.0", "  9", "$ORTHOMODE", " 70", "     1", "  9", "$CLAYER", "  8", "Muros", ;
      "  9", "$UNKNOWNVAR", " 70", "     5", ;
      "  0", "ENDSEC", ;
      "  0", "SECTION", "  2", "TABLES", ;
      "  0", "TABLE", "  2", "LTYPE", "  5", "5", "100", "AcDbSymbolTable", " 70", "     1", ;
      "  0", "LTYPE", "  5", "14", "100", "AcDbSymbolTableRecord", "100", "AcDbLinetypeTableRecord", "  2", "Continuous", " 70", "     0", "  3", "Solid line", " 72", "    65", " 73", "     0", " 40", "0.0", ;
      "  0", "ENDTAB", ;
      "  0", "TABLE", "  2", "LAYER", "  5", "2", "100", "AcDbSymbolTable", " 70", "     2", ;
      "  0", "LAYER", "  5", "10", "100", "AcDbSymbolTableRecord", "100", "AcDbLayerTableRecord", "  2", "0", " 70", "     0", " 62", "     7", "  6", "Continuous", ;
      "  0", "LAYER", "  5", "50", "100", "AcDbSymbolTableRecord", "100", "AcDbLayerTableRecord", "  2", "Muros", " 70", "     4", " 62", "    -3", "  6", "Continuous", "370", "    50", ;
      "  0", "ENDTAB", ;
      "  0", "TABLE", "  2", "STYLE", "  5", "3", " 70", "     1", ;
      "  0", "STYLE", "  5", "11", "  2", "Standard", " 70", "     0", " 40", "0.0", " 41", "1.0", " 50", "0.0", " 71", "     0", " 42", "2.5", "  3", "txt", "  4", "", ;
      "  0", "ENDTAB", ;
      "  0", "TABLE", "  2", "BLOCK_RECORD", "  5", "1", " 70", "     3", ;
      "  0", "BLOCK_RECORD", "  5", "1F", "  2", "*Model_Space", "340", "22", ;
      "  0", "BLOCK_RECORD", "  5", "1B", "  2", "*Paper_Space", "340", "1E", ;
      "  0", "BLOCK_RECORD", "  5", "60", "  2", "CAJA", "340", "0", ;
      "  0", "ENDTAB", ;
      "  0", "ENDSEC", ;
      "  0", "SECTION", "  2", "BLOCKS", ;
      "  0", "BLOCK", "  5", "20", "330", "1F", "100", "AcDbEntity", "  8", "0", "100", "AcDbBlockBegin", "  2", "*Model_Space", " 70", "     0", " 10", "0.0", " 20", "0.0", " 30", "0.0", "  3", "*Model_Space", "  1", "", ;
      "  0", "ENDBLK", "  5", "21", "330", "1F", "100", "AcDbEntity", "  8", "0", "100", "AcDbBlockEnd", ;
      "  0", "BLOCK", "  5", "61", "330", "60", "100", "AcDbEntity", "  8", "0", "100", "AcDbBlockBegin", "  2", "CAJA", " 70", "     0", " 10", "0.0", " 20", "0.0", " 30", "0.0", "  3", "CAJA", "  1", "", ;
      "  0", "LINE", "  5", "62", "330", "60", "  8", "0", " 10", "0.0", " 20", "0.0", " 30", "0.0", " 11", "1.0", " 21", "0.0", " 31", "0.0", ;
      "  0", "ENDBLK", "  5", "63", "330", "60", "100", "AcDbEntity", "  8", "0", "100", "AcDbBlockEnd", ;
      "  0", "ENDSEC", ;
      "  0", "SECTION", "  2", "ENTITIES", ;
      "  0", "LINE", "  5", "70", "330", "1F", "100", "AcDbEntity", "  8", "Muros", "100", "AcDbLine", " 10", "0.0", " 20", "0.0", " 30", "0.0", " 11", "10.0", " 21", "5.0", " 31", "0.0", ;
      "  0", "CIRCLE", "  5", "71", "  8", "0", " 62", "     1", " 10", "3.0", " 20", "3.0", " 30", "0.0", " 40", "1.25", ;
      "  0", "ARC", "  5", "72", "  8", "0", " 10", "0.0", " 20", "0.0", " 30", "0.0", " 40", "2.0", " 50", "0.0", " 51", "90.0", ;
      "  0", "LWPOLYLINE", "  5", "73", "  8", "Muros", "100", "AcDbPolyline", " 90", "     3", " 70", "     1", " 10", "0.0", " 20", "0.0", " 10", "4.0", " 20", "0.0", " 42", "0.5", " 10", "4.0", " 20", "3.0", ;
      "  0", "TEXT", "  5", "74", "  8", "0", " 10", "1.0", " 20", "1.0", " 30", "0.0", " 40", "0.5", "  1", "Hola mundo", " 50", "45.0", "  7", "Standard", ;
      "  0", "INSERT", "  5", "75", "  8", "0", "  2", "CAJA", " 10", "7.0", " 20", "7.0", " 30", "0.0", " 41", "2.0", " 50", "30.0", ;
      "  0", "POINT", "  5", "76", "  8", "0", " 10", "9.0", " 20", "9.0", " 30", "0.0", ;
      "  0", "SPLINE", "  5", "77", "  8", "0", " 70", "     8", ;
      "  0", "ENDSEC", ;
      "  0", "EOF" }
   FOR i := 1 TO Len( a ) STEP 2 ; c += a[ i ] + Chr( 13 ) + Chr( 10 ) + a[ i + 1 ] + Chr( 13 ) + Chr( 10 ) ; NEXT
RETURN c

PROCEDURE T_DxfRw()
   LOCAL d, d2, e, l, es, c, tx, s1, s2, s3, s4, ms, x, ok
   /* test_dxf_roundtrip_line_normal */
   d := Doc_New() ; l := Eln_New()
   l[ "start" ] := Vc3_New( 1.0, 2.0, 3.0 ) ; l[ "end" ] := Vc3_New( 4.0, 5.0, 6.0 ) ; l[ "normal" ] := Vc3_New( 0.0, 1.0, 0.0 )
   l[ "thickness" ] := 2.5 ; l[ "common" ][ "layer" ] := "TestLayer" ; Doc_AddEntity( d, l )
   d2 := RT( d )
   Chk( ValType( d2 ) == "H", "roundtrip line: el documento relee (" + IIf( ValType( d2 ) == "C", d2, "" ) + ")" )
   es := Doc_ModelSpaceEntities( d2 )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "LINE", "roundtrip line: 1 entidad LINE" )
   e := es[ 1 ]
   Chk( e[ "common" ][ "layer" ] == "TestLayer" .AND. Near( e[ "normal" ][ 1 ], 0.0, 0.000000001 ) .AND. Near( e[ "normal" ][ 2 ], 1.0, 0.000000001 ) .AND. Near( e[ "normal" ][ 3 ], 0.0, 0.000000001 ) .AND. Near( e[ "thickness" ], 2.5, 0.000000001 ) .AND. Near( e[ "start" ][ 1 ], 1.0, 0.000000001 ) .AND. Near( e[ "end" ][ 1 ], 4.0, 0.000000001 ), "test_dxf_roundtrip_line_normal" )
   /* circle */
   d := Doc_New() ; c := Eci_New() ; c[ "center" ] := Vc3_New( 10.0, 20.0, 0.0 ) ; c[ "radius" ] := 5.0 ; c[ "normal" ] := Vc3_New( 0.0, 0.0, -1.0 ) ; c[ "thickness" ] := 1.5 ; Doc_AddEntity( d, c )
   es := Doc_ModelSpaceEntities( RT( d ) ) ; e := es[ 1 ]
   Chk( Len( es ) == 1 .AND. e[ "_type" ] == "CIRCLE" .AND. Near( e[ "normal" ][ 3 ], -1.0, 0.000000001 ) .AND. Near( e[ "thickness" ], 1.5, 0.000000001 ) .AND. Near( e[ "radius" ], 5.0, 0.000000001 ), "test_dxf_roundtrip_circle_normal" )
   /* arc (el original usa end_angle 90.0 en radianes: se mantiene) */
   d := Doc_New() ; c := Ear_New() ; c[ "radius" ] := 10.0 ; c[ "start_angle" ] := 0.0 ; c[ "end_angle" ] := 90.0 ; c[ "normal" ] := Vc3_New( 1.0, 0.0, 0.0 ) ; c[ "thickness" ] := 3.0 ; Doc_AddEntity( d, c )
   es := Doc_ModelSpaceEntities( RT( d ) ) ; e := es[ 1 ]
   Chk( Len( es ) == 1 .AND. e[ "_type" ] == "ARC" .AND. Near( e[ "normal" ][ 1 ], 1.0, 0.000000001 ) .AND. Near( e[ "thickness" ], 3.0, 0.000000001 ), "test_dxf_roundtrip_arc_normal" )
   Chk( Near( e[ "end_angle" ], 90.0, 0.000001 ), "[extra] arc: angulos grados<->radianes simetricos" )
   /* [extra] elipse / solid / trace / 3dface / ray / xline */
   d := Doc_New()
   e := Eel_New() ; e[ "center" ] := Vc3_New( 1.0, 2.0, 3.0 ) ; e[ "major_axis" ] := Vc3_New( 4.0, 0.0, 0.0 ) ; e[ "minor_axis_ratio" ] := 0.25 ; e[ "start_parameter" ] := 0.5 ; e[ "end_parameter" ] := 2.0 ; e[ "normal" ] := Vc3_New( 0.0, 0.0, -1.0 ) ; Doc_AddEntity( d, e )
   e := Eso_New( Vc3_New( 0.0, 0.0, 0.0 ), Vc3_New( 1.0, 0.0, 0.0 ), Vc3_New( 0.0, 1.0, 0.0 ), Vc3_New( 1.0, 1.0, 0.0 ) ) ; e[ "thickness" ] := 2.0 ; Doc_AddEntity( d, e )
   e := Eso_New( Vc3_New( 0.0, 0.0, 0.0 ), Vc3_New( 2.0, 0.0, 0.0 ), Vc3_New( 0.0, 2.0, 0.0 ), Vc3_New( 0.0, 2.0, 0.0 ) ) ; e[ "is_trace" ] := .T. ; Doc_AddEntity( d, e )
   e := Ef3_New( Vc3_New( 0.0, 0.0, 1.0 ), Vc3_New( 1.0, 0.0, 1.0 ), Vc3_New( 1.0, 1.0, 2.0 ), Vc3_New( 0.0, 1.0, 2.0 ) ) ; e[ "invisible_edges" ] := 5 ; Doc_AddEntity( d, e )
   Doc_AddEntity( d, Ery_New( Vc3_New( 1.0, 1.0, 0.0 ), Vc3_New( 0.0, 1.0, 0.0 ) ) )
   Doc_AddEntity( d, Exl_New( Vc3_New( 2.0, 2.0, 0.0 ), Vc3_New( 1.0, 0.0, 0.0 ) ) )
   es := Doc_ModelSpaceEntities( RT( d ) )
   Chk( Len( es ) == 6, "[extra] roundtrip 6 entidades nuevas" )
   IF Len( es ) == 6
      Chk( es[ 1 ][ "_type" ] == "ELLIPSE" .AND. Near( es[ 1 ][ "minor_axis_ratio" ], 0.25, 0.000000001 ) .AND. Near( es[ 1 ][ "end_parameter" ], 2.0, 0.000000001 ) .AND. Near( es[ 1 ][ "normal" ][ 3 ], -1.0, 0.000000001 ) .AND. Near( es[ 1 ][ "major_axis" ][ 1 ], 4.0, 0.000000001 ), "[extra] roundtrip ellipse" )
      Chk( es[ 2 ][ "_type" ] == "SOLID" .AND. ! es[ 2 ][ "is_trace" ] .AND. Near( es[ 2 ][ "thickness" ], 2.0, 0.000000001 ) .AND. Near( es[ 2 ][ "fourth_corner" ][ 2 ], 1.0, 0.000000001 ), "[extra] roundtrip solid" )
      Chk( es[ 3 ][ "_type" ] == "SOLID" .AND. es[ 3 ][ "is_trace" ] .AND. Near( es[ 3 ][ "second_corner" ][ 1 ], 2.0, 0.000000001 ), "[extra] roundtrip trace" )
      Chk( es[ 4 ][ "_type" ] == "3DFACE" .AND. es[ 4 ][ "invisible_edges" ] == 5 .AND. Near( es[ 4 ][ "third_corner" ][ 3 ], 2.0, 0.000000001 ), "[extra] roundtrip 3dface" )
      Chk( es[ 5 ][ "_type" ] == "RAY" .AND. Near( es[ 5 ][ "direction" ][ 2 ], 1.0, 0.000000001 ) .AND. Near( es[ 5 ][ "base_point" ][ 1 ], 1.0, 0.000000001 ), "[extra] roundtrip ray" )
      Chk( es[ 6 ][ "_type" ] == "XLINE" .AND. Near( es[ 6 ][ "direction" ][ 1 ], 1.0, 0.000000001 ) .AND. Near( es[ 6 ][ "base_point" ][ 2 ], 2.0, 0.000000001 ), "[extra] roundtrip xline" )
   ENDIF
   /* [extra] ATTDEF + INSERT con ATTRIB */
   d := Doc_New()
   e := Ead_New( "NOMBRE", "Nombre:", "def" ) ; e[ "insertion_point" ] := Vc3_New( 1.0, 1.0, 0.0 ) ; e[ "height" ] := 3.0 ; e[ "rotation" ] := OCX_PI / 2.0 ; e[ "flags" ][ "constant" ] := .T. ; Doc_AddEntity( d, e )
   e := Ein_New( "BLK", Vc3_New( 5.0, 5.0, 0.0 ) ) ; l := Eat_New( "NOMBRE", "Pedro" ) ; l[ "height" ] := 1.5 ; l[ "text_style" ] := "Standard" ; l[ "lock_position" ] := .T. ; AAdd( e[ "attributes" ], l ) ; Doc_AddEntity( d, e )
   s1 := Dxw_WriteString( d ) ; d2 := Dxr_ReadString( s1 )
   Chk( "ATTDEF" $ s1 .AND. "ATTRIB" $ s1 .AND. "SEQEND" $ s1, "[extra] escritura contiene ATTDEF, ATTRIB y SEQEND" )
   es := IIf( ValType( d2 ) == "H", Doc_ModelSpaceEntities( d2 ), {} )
   Chk( Len( es ) == 2, "[extra] roundtrip ATTDEF + INSERT" )
   IF Len( es ) == 2
      Chk( es[ 1 ][ "_type" ] == "ATTDEF" .AND. es[ 1 ][ "tag" ] == "NOMBRE" .AND. es[ 1 ][ "prompt" ] == "Nombre:" .AND. es[ 1 ][ "default_value" ] == "def" .AND. es[ 1 ][ "flags" ][ "constant" ] .AND. Near( es[ 1 ][ "rotation" ], OCX_PI / 2.0, 0.000000001 ) .AND. Near( es[ 1 ][ "height" ], 3.0, 0.000000001 ), "[extra] roundtrip attdef" )
      Chk( es[ 2 ][ "_type" ] == "INSERT" .AND. Len( es[ 2 ][ "attributes" ] ) == 1 .AND. es[ 2 ][ "attributes" ][ 1 ][ "tag" ] == "NOMBRE" .AND. es[ 2 ][ "attributes" ][ 1 ][ "value" ] == "Pedro" .AND. es[ 2 ][ "attributes" ][ 1 ][ "lock_position" ] .AND. Near( es[ 2 ][ "attributes" ][ 1 ][ "height" ], 1.5, 0.000000001 ), "[extra] roundtrip insert con attrib" )
   ENDIF
   /* lwpolyline / text / insert / point / bloque */
   d := Doc_New()
   e := Elw_New() ; AAdd( e[ "vertices" ], Elv_FromCoords( 0.0, 0.0 ) ) ; AAdd( e[ "vertices" ], Elv_WithBulge( Vc2_New( 4.0, 0.0 ), 0.5 ) ) ; e[ "is_closed" ] := .T. ; Doc_AddEntity( d, e )
   tx := Etx_WithValue( "Hola", Vc3_New( 1.0, 2.0, 0.0 ) ) ; tx[ "rotation" ] := OCX_PI ; tx[ "height" ] := 0.7 ; tx[ "horizontal_alignment" ] := TXH_CENTER ; tx[ "vertical_alignment" ] := TXV_TOP ; tx[ "alignment_point" ] := Vc3_New( 3.0, 3.0, 0.0 ) ; Doc_AddEntity( d, tx )
   Doc_AddEntity( d, Ept_At( Vc3_New( 9.0, 8.0, 0.0 ) ) )
   e := Ein_New( "CAJA", Vc3_New( 5.0, 5.0, 0.0 ) ) ; Ein_SetXScale( e, 2.0 ) ; e[ "rotation" ] := OCX_PI / 2.0 ; e[ "column_count" ] := 3 ; e[ "column_spacing" ] := 1.5
   s1 := Dxw_WriteString( d )
   Chk( "LWPOLYLINE" $ s1 .AND. "AcDbText" $ s1 .AND. "AcDbPoint" $ s1, "[extra] escritura contiene entidades" )
   d2 := Dxr_ReadString( s1 ) ; es := Doc_ModelSpaceEntities( d2 )
   Chk( Len( es ) == 3 .AND. es[ 1 ][ "_type" ] == "LWPOLYLINE" .AND. Len( es[ 1 ][ "vertices" ] ) == 2 .AND. es[ 1 ][ "is_closed" ] .AND. Near( es[ 1 ][ "vertices" ][ 2 ][ "bulge" ], 0.5, 0.000000001 ), "[extra] roundtrip lwpolyline" )
   Chk( es[ 2 ][ "_type" ] == "TEXT" .AND. es[ 2 ][ "value" ] == "Hola" .AND. Near( es[ 2 ][ "rotation" ], OCX_PI, 0.000000001 ) .AND. es[ 2 ][ "horizontal_alignment" ] == TXH_CENTER .AND. es[ 2 ][ "vertical_alignment" ] == TXV_TOP .AND. es[ 2 ][ "alignment_point" ] != NIL, "[extra] roundtrip text" )
   Chk( es[ 3 ][ "_type" ] == "POINT" .AND. Near( es[ 3 ][ "location" ][ 1 ], 9.0, 0.000000001 ), "[extra] roundtrip point" )
   /* idempotencia: escribir -> leer -> escribir da el mismo texto */
   s2 := Dxw_WriteString( d2 )
   Chk( s1 == s2, "[extra] escritura estable tras roundtrip (write(read(write(d))) == write(d))" )
   /* header, tablas, bloques, insert */
   d := Doc_New()
   d[ "header" ][ "linetype_scale" ] := 3.5 ; d[ "header" ][ "ortho_mode" ] := .T. ; d[ "header" ][ "current_layer_name" ] := "Capa1" ; d[ "header" ][ "model_space_insertion_base" ] := Vc3_New( 1.0, 2.0, 3.0 )
   d[ "summary_info" ][ "title" ] := "Titulo" ; d[ "summary_info" ][ "author" ] := "Andres"
   l := Lyr_New( "Capa1" ) ; l[ "color" ] := Cl_Index( 3 ) ; l[ "flags" ][ "locked" ] := .T. ; l[ "line_weight" ] := Lw_Value( 50 ) ; l[ "description" ] := "desc capa" ; Tb_AddOrReplace( d[ "layers" ], l )
   x := Tst_WithTruetype( "Arial1", "Arial" ) ; x[ "handle" ] := Doc_AllocateHandle( d ) ; Tb_AddOrReplace( d[ "text_styles" ], x )
   l[ "handle" ] := Doc_AllocateHandle( d )
   x := Blk_New( "CAJA" ) ; x[ "handle" ] := Doc_AllocateHandle( d ) ; x[ "block_entity_handle" ] := Doc_AllocateHandle( d ) ; x[ "block_end_handle" ] := Doc_AllocateHandle( d ) ; Tb_AddOrReplace( d[ "block_records" ], x )
   e := Ein_New( "CAJA", Vc3_New( 5.0, 5.0, 0.0 ) ) ; Ein_SetXScale( e, 2.0 ) ; e[ "rotation" ] := OCX_PI / 2.0 ; e[ "column_count" ] := 3 ; e[ "column_spacing" ] := 1.5 ; Doc_AddEntity( d, e )
   Doc_AddEntityToBlock( d, Eln_FromCoords( 0.0, 0.0, 0.0, 2.0, 2.0, 0.0 ), "CAJA" )
   s3 := Dxw_WriteString( d ) ; d2 := Dxr_ReadString( s3 )
   Chk( ValType( d2 ) == "H", "[extra] roundtrip documento completo relee" )
   IF ValType( d2 ) == "H"
      Chk( Near( d2[ "header" ][ "linetype_scale" ], 3.5, 0.000000001 ) .AND. d2[ "header" ][ "ortho_mode" ] .AND. d2[ "header" ][ "current_layer_name" ] == "Capa1" .AND. Near( d2[ "header" ][ "model_space_insertion_base" ][ 3 ], 3.0, 0.000000001 ), "[extra] header roundtrip (escalar, bool, string, punto)" )
      Chk( d2[ "summary_info" ][ "title" ] == "Titulo" .AND. d2[ "summary_info" ][ "author" ] == "Andres", "[extra] summary_info roundtrip" )
      l := Tb_Get( d2[ "layers" ], "Capa1" )
      Chk( l != NIL .AND. Cl_Eq( l[ "color" ], Cl_Index( 3 ) ) .AND. l[ "flags" ][ "locked" ] .AND. Lw_Eq( l[ "line_weight" ], Lw_Value( 50 ) ) .AND. l[ "description" ] == "desc capa", "[extra] capa roundtrip (color, bloqueo, grosor, descripcion xdata)" )
      Chk( Tb_Get( d2[ "text_styles" ], "Arial1" ) != NIL .AND. Tb_Get( d2[ "text_styles" ], "Arial1" )[ "true_type_font" ] == "Arial", "[extra] estilo truetype roundtrip" )
      ms := Doc_ModelSpaceEntities( d2 )
      Chk( Len( ms ) == 1 .AND. ms[ 1 ][ "_type" ] == "INSERT" .AND. ms[ 1 ][ "block_name" ] == "CAJA" .AND. Near( ms[ 1 ][ "x_scale" ], 2.0, 0.000000001 ) .AND. ms[ 1 ][ "column_count" ] == 3, "[extra] insert roundtrip" )
      x := Tb_Get( d2[ "block_records" ], "CAJA" )
      Chk( x != NIL .AND. Len( x[ "entity_handles" ] ) == 1, "[extra] bloque CAJA con su LINE" )
      s4 := Dxw_WriteString( d2 )
      Chk( s3 == s4, "[extra] documento completo: escritura estable tras roundtrip" )
   ENDIF
   /* DXF de muestra estilo AutoCAD (R2000) escrito a mano */
   d := Dxr_ReadString( Sample() )
   ok := ValType( d ) == "H"
   Chk( ok, "[extra] lee DXF de muestra estilo AutoCAD R2000" )
   IF ok
      Chk( d[ "version" ] == Dxv_FromVersionString( "AC1015" ) .AND. d[ "header" ][ "handle_seed" ] == 160 .AND. Near( d[ "header" ][ "linetype_scale" ], 2.0, 0.000000001 ) .AND. d[ "header" ][ "ortho_mode" ] .AND. d[ "header" ][ "current_layer_name" ] == "Muros" .AND. Near( d[ "header" ][ "model_space_insertion_base" ][ 1 ], 1.5, 0.000000001 ), "[extra] muestra: cabecera (version, $HANDSEED, $LTSCALE, $ORTHOMODE, $CLAYER, $INSBASE, var desconocida saltada)" )
      l := Tb_Get( d[ "layers" ], "Muros" )
      Chk( Tb_Len( d[ "layers" ] ) >= 2 .AND. l != NIL .AND. l[ "flags" ][ "off" ] .AND. l[ "flags" ][ "locked" ] .AND. Cl_Eq( l[ "color" ], Cl_Index( 3 ) ) .AND. Lw_GetValue( l[ "line_weight" ] ) == 50, "[extra] muestra: capa Muros (apagada, bloqueada, color 3, grosor 50)" )
      es := Doc_ModelSpaceEntities( d )
      Chk( Len( es ) == 7, "[extra] muestra: 7 entidades en modelo (SPLINE no portada se salta) = " + hb_ntos( Len( es ) ) )
      IF Len( es ) == 7
         Chk( es[ 1 ][ "_type" ] == "LINE" .AND. Near( es[ 1 ][ "end" ][ 2 ], 5.0, 0.000000001 ) .AND. es[ 1 ][ "common" ][ "layer" ] == "Muros" .AND. Ent_Handle( es[ 1 ] ) == 112, "[extra] muestra: LINE con capa y handle 0x70" )
         Chk( es[ 2 ][ "_type" ] == "CIRCLE" .AND. Near( es[ 2 ][ "radius" ], 1.25, 0.000000001 ) .AND. Cl_Eq( es[ 2 ][ "common" ][ "color" ], Cl_Index( 1 ) ), "[extra] muestra: CIRCLE" )
         Chk( es[ 3 ][ "_type" ] == "ARC" .AND. Near( es[ 3 ][ "end_angle" ], OCX_PI / 2.0, 0.000000001 ), "[extra] muestra: ARC 90 grados -> pi/2" )
         Chk( es[ 4 ][ "_type" ] == "LWPOLYLINE" .AND. Len( es[ 4 ][ "vertices" ] ) == 3 .AND. Near( es[ 4 ][ "vertices" ][ 2 ][ "bulge" ], 0.5, 0.000000001 ) .AND. Near( es[ 4 ][ "vertices" ][ 1 ][ "bulge" ], 0.0, 0.000000001 ) .AND. es[ 4 ][ "is_closed" ], "[extra] muestra: LWPOLYLINE (bulge asignado al vertice previo)" )
         Chk( es[ 5 ][ "_type" ] == "TEXT" .AND. es[ 5 ][ "value" ] == "Hola mundo" .AND. Near( es[ 5 ][ "rotation" ], 45.0 * OCX_PI / 180.0, 0.000000001 ), "[extra] muestra: TEXT rotacion 45 grados" )
         Chk( es[ 6 ][ "_type" ] == "INSERT" .AND. es[ 6 ][ "block_name" ] == "CAJA" .AND. Near( es[ 6 ][ "x_scale" ], 2.0, 0.000000001 ) .AND. es[ 7 ][ "_type" ] == "POINT", "[extra] muestra: INSERT y POINT" )
      ENDIF
      x := Tb_Get( d[ "block_records" ], "CAJA" )
      Chk( x != NIL .AND. Len( x[ "entity_handles" ] ) == 1 .AND. x[ "block_entity_handle" ] == 97 .AND. x[ "block_end_handle" ] == 99, "[extra] muestra: bloque CAJA (LINE, handles BLOCK/ENDBLK)" )
      s1 := Dxw_WriteString( d ) ; d2 := Dxr_ReadString( s1 )
      Chk( ValType( d2 ) == "H" .AND. Len( Doc_ModelSpaceEntities( d2 ) ) == 7 .AND. s1 == Dxw_WriteString( d2 ), "[extra] muestra: escribir y releer conserva 7 entidades y es estable" )
   ENDIF
RETURN
