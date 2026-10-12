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

STATIC FUNCTION Dxo_CountLayouts( d )
   LOCAL o, n := 0
   FOR EACH o IN hb_HValues( d[ "objects" ] )
      IF o[ "_type" ] == "Layout"
         n++
      ENDIF
   NEXT
RETURN n

STATIC FUNCTION Dxo_RootForTest( d )
   LOCAL h, nB := 0, nC := 0
   FOR EACH h IN hb_HKeys( d[ "objects" ] )
      IF d[ "objects" ][ h ][ "_type" ] == "Dictionary" .AND. Hd_IsNull( d[ "objects" ][ h ][ "owner" ] ) .AND. Len( d[ "objects" ][ h ][ "entries" ] ) >= nC
         nB := h ; nC := Len( d[ "objects" ][ h ][ "entries" ] )
      ENDIF
   NEXT
RETURN nB

PROCEDURE T_DxfRw()
   LOCAL d, d2, d5, e, l, es, c, tx, s1, s2, s3, s4, ms, x, ok, u
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
   /* [extra] MTEXT: texto largo (trozos de 250), saltos de linea, fondo y columnas */
   d := Doc_New()
   e := Emt_WithValue( Replicate( "ab", 200 ) + Chr( 10 ) + "fin", Vc3_New( 2.0, 3.0, 0.0 ) ) ; e[ "height" ] := 0.5 ; e[ "rectangle_width" ] := 20.0 ; e[ "rotation" ] := OCX_PI / 2.0 ; e[ "attachment_point" ] := MTA_MIDDLECENTER
   e[ "background_fill_flags" ] := 1 ; e[ "background_color" ] := Cl_FromRgb( 255, 136, 0 ) ; e[ "rectangle_height" ] := 7.0
   e[ "column_data" ][ "column_type" ] := 1 ; e[ "column_data" ][ "column_count" ] := 3 ; e[ "column_data" ][ "width" ] := 6.0 ; e[ "column_data" ][ "gutter" ] := 1.0
   Doc_AddEntity( d, e )
   s1 := Dxw_WriteString( d ) ; d2 := Dxr_ReadString( s1 )
   es := IIf( ValType( d2 ) == "H", Doc_ModelSpaceEntities( d2 ), {} )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "MTEXT", "[extra] roundtrip mtext presente" )
   IF Len( es ) == 1
      e := es[ 1 ]
      Chk( e[ "value" ] == Replicate( "ab", 200 ) + "\Pfin", "[extra] mtext: valor largo troceado y salto -> \P" )
      Chk( Near( e[ "rotation" ], OCX_PI / 2.0, 0.000000001 ) .AND. e[ "attachment_point" ] == MTA_MIDDLECENTER .AND. Near( e[ "rectangle_height" ], 7.0, 0.000000001 ) .AND. Near( e[ "rectangle_width" ], 20.0, 0.000000001 ), "[extra] mtext: rotacion, anclaje y rectangulo" )
      Chk( e[ "background_fill_flags" ] == 1 .AND. Cl_Eq( e[ "background_color" ], Cl_FromRgb( 255, 136, 0 ) ), "[extra] mtext: fondo con color verdadero" )
      Chk( e[ "column_data" ][ "column_type" ] == 1 .AND. e[ "column_data" ][ "column_count" ] == 3 .AND. Near( e[ "column_data" ][ "width" ], 6.0, 0.000000001 ), "[extra] mtext: columnas estandar" )
   ENDIF
   /* [extra] SPLINE con puntos de control, pesos, nudos y puntos de ajuste */
   d := Doc_New() ; e := Esp_New() ; e[ "degree" ] := 3 ; e[ "flags" ][ "rational" ] := .T.
   e[ "knots" ] := { 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0 }
   e[ "control_points" ] := { Vc3_New( 0.0, 0.0, 0.0 ), Vc3_New( 1.0, 2.0, 0.0 ), Vc3_New( 3.0, 2.0, 0.0 ), Vc3_New( 4.0, 0.0, 0.0 ) }
   e[ "weights" ] := { 1.0, 0.5, 0.5, 1.0 } ; e[ "fit_points" ] := { Vc3_New( 0.0, 0.0, 0.0 ), Vc3_New( 4.0, 0.0, 0.0 ) } ; e[ "begin_tangent" ] := Vc3_New( 1.0, 1.0, 0.0 )
   Doc_AddEntity( d, e )
   es := Doc_ModelSpaceEntities( RT( d ) )
   Chk( Len( es ) == 1 .AND. es[ 1 ][ "_type" ] == "SPLINE", "[extra] roundtrip spline presente" )
   IF Len( es ) == 1
      e := es[ 1 ]
      Chk( e[ "degree" ] == 3 .AND. Len( e[ "knots" ] ) == 8 .AND. Len( e[ "control_points" ] ) == 4 .AND. Len( e[ "fit_points" ] ) == 2 .AND. e[ "flags" ][ "rational" ] .AND. Near( e[ "weights" ][ 2 ], 0.5, 0.000000001 ) .AND. Near( e[ "control_points" ][ 3 ][ 1 ], 3.0, 0.000000001 ) .AND. Near( e[ "begin_tangent" ][ 2 ], 1.0, 0.000000001 ), "[extra] roundtrip spline" )
   ENDIF
   /* [extra] POLYLINE: 2D pesada, 2D (baja a LWPOLYLINE), 3D, polyface y malla poligonal */
   d := Doc_New()
   e := Pl2_New() ; e[ "flags" ] := 1 ; e[ "start_width" ] := 0.2 ; e[ "end_width" ] := 0.4
   x := Vx2_New( Vc3_New( 0.0, 0.0, 0.0 ) ) ; x[ "flags" ] := 1 ; x[ "bulge" ] := 0.5 ; AAdd( e[ "vertices" ], x )
   AAdd( e[ "vertices" ], Vx2_New( Vc3_New( 5.0, 0.0, 0.0 ) ) ) ; Doc_AddEntity( d, e )
   e := Pl2_New() ; e[ "flags" ] := 1 ; AAdd( e[ "vertices" ], Vx2_WithBulge( Vx2_New( Vc3_New( 0.0, 0.0, 0.0 ) ), 0.25 ) ) ; AAdd( e[ "vertices" ], Vx2_New( Vc3_New( 3.0, 0.0, 0.0 ) ) ) ; Doc_AddEntity( d, e )
   e := P3d_New() ; P3d_AddVertex( e, Vc3_New( 0.0, 0.0, 0.0 ) ) ; P3d_AddVertex( e, Vc3_New( 1.0, 2.0, 3.0 ) ) ; Doc_AddEntity( d, e )
   e := Epf_New() ; AAdd( e[ "vertices" ], Pfv_FromXyz( 0.0, 0.0, 0.0 ) ) ; AAdd( e[ "vertices" ], Pfv_FromXyz( 1.0, 0.0, 0.0 ) ) ; AAdd( e[ "vertices" ], Pfv_FromXyz( 0.0, 1.0, 0.0 ) )
   x := Pff_Quad( 1, 2, 3, 0 ) ; x[ "color" ] := Cl_Index( 3 ) ; AAdd( e[ "faces" ], x ) ; Doc_AddEntity( d, e )
   e := Epm_New() ; e[ "m_vertex_count" ] := 2 ; e[ "n_vertex_count" ] := 2 ; AAdd( e[ "vertices" ], Pmv_At( Vc3_New( 0.0, 0.0, 0.0 ) ) ) ; AAdd( e[ "vertices" ], Pmv_At( Vc3_New( 1.0, 0.0, 0.0 ) ) )
   AAdd( e[ "vertices" ], Pmv_At( Vc3_New( 0.0, 1.0, 0.0 ) ) ) ; AAdd( e[ "vertices" ], Pmv_At( Vc3_New( 1.0, 1.0, 1.0 ) ) ) ; Doc_AddEntity( d, e )
   s1 := Dxw_WriteString( d ) ; d2 := Dxr_ReadString( s1 )
   es := IIf( ValType( d2 ) == "H", Doc_ModelSpaceEntities( d2 ), {} )
   Chk( "SEQEND" $ s1 .AND. "AcDb2dVertex" $ s1 .AND. "AcDbPolyFaceMeshVertex" $ s1 .AND. "AcDbPolygonMeshVertex" $ s1, "[extra] escritura contiene VERTEX/SEQEND de cada tipo" )
   Chk( Len( es ) == 5, "[extra] roundtrip 5 polylineas (" + hb_ntos( Len( es ) ) + ")" )
   IF Len( es ) == 5
      Chk( es[ 1 ][ "_type" ] == "POLYLINE2D" .AND. Len( es[ 1 ][ "vertices" ] ) == 2 .AND. es[ 1 ][ "vertices" ][ 1 ][ "flags" ] == 1 .AND. Near( es[ 1 ][ "vertices" ][ 1 ][ "bulge" ], 0.5, 0.000000001 ) .AND. Near( es[ 1 ][ "vertices" ][ 2 ][ "end_width" ], 0.4, 0.000000001 ) .AND. es[ 1 ][ "flags" ] == 1, "[extra] roundtrip polyline 2D pesada (anchos por vertice)" )
      Chk( es[ 2 ][ "_type" ] == "LWPOLYLINE" .AND. es[ 2 ][ "is_closed" ] .AND. Near( es[ 2 ][ "vertices" ][ 1 ][ "bulge" ], 0.25, 0.000000001 ), "[extra] polyline 2D simple baja a LWPOLYLINE" )
      Chk( es[ 3 ][ "_type" ] == "POLYLINE3D" .AND. Len( es[ 3 ][ "vertices" ] ) == 2 .AND. Near( es[ 3 ][ "vertices" ][ 2 ][ "position" ][ 3 ], 3.0, 0.000000001 ), "[extra] roundtrip polyline 3D" )
      Chk( es[ 4 ][ "_type" ] == "POLYFACE_MESH" .AND. Len( es[ 4 ][ "vertices" ] ) == 3 .AND. Len( es[ 4 ][ "faces" ] ) == 1 .AND. es[ 4 ][ "faces" ][ 1 ][ "index3" ] == 3 .AND. es[ 4 ][ "faces" ][ 1 ][ "index4" ] == 0, "[extra] roundtrip polyface mesh" )
      Chk( es[ 5 ][ "_type" ] == "POLYGON_MESH" .AND. Len( es[ 5 ][ "vertices" ] ) == 4 .AND. es[ 5 ][ "m_vertex_count" ] == 2 .AND. Near( es[ 5 ][ "vertices" ][ 4 ][ "location" ][ 3 ], 1.0, 0.000000001 ), "[extra] roundtrip polygon mesh" )
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
      Chk( d[ "version" ] == Dxv_FromVersionString( "AC1015" ) .AND. d[ "header" ][ "handle_seed" ] >= 160 .AND. Near( d[ "header" ][ "linetype_scale" ], 2.0, 0.000000001 ) .AND. d[ "header" ][ "ortho_mode" ] .AND. d[ "header" ][ "current_layer_name" ] == "Muros" .AND. Near( d[ "header" ][ "model_space_insertion_base" ][ 1 ], 1.5, 0.000000001 ), "[extra] muestra: cabecera (version, $HANDSEED, $LTSCALE, $ORTHOMODE, $CLAYER, $INSBASE, var desconocida saltada)" )
      l := Tb_Get( d[ "layers" ], "Muros" )
      Chk( Tb_Len( d[ "layers" ] ) >= 2 .AND. l != NIL .AND. l[ "flags" ][ "off" ] .AND. l[ "flags" ][ "locked" ] .AND. Cl_Eq( l[ "color" ], Cl_Index( 3 ) ) .AND. Lw_GetValue( l[ "line_weight" ] ) == 50, "[extra] muestra: capa Muros (apagada, bloqueada, color 3, grosor 50)" )
      es := Doc_ModelSpaceEntities( d )
      Chk( Len( es ) == 8, "[extra] muestra: 8 entidades en modelo (7 + SPLINE minima) = " + hb_ntos( Len( es ) ) )
      IF Len( es ) == 8
         Chk( es[ 1 ][ "_type" ] == "LINE" .AND. Near( es[ 1 ][ "end" ][ 2 ], 5.0, 0.000000001 ) .AND. es[ 1 ][ "common" ][ "layer" ] == "Muros" .AND. Ent_Handle( es[ 1 ] ) == 112, "[extra] muestra: LINE con capa y handle 0x70" )
         Chk( es[ 2 ][ "_type" ] == "CIRCLE" .AND. Near( es[ 2 ][ "radius" ], 1.25, 0.000000001 ) .AND. Cl_Eq( es[ 2 ][ "common" ][ "color" ], Cl_Index( 1 ) ), "[extra] muestra: CIRCLE" )
         Chk( es[ 3 ][ "_type" ] == "ARC" .AND. Near( es[ 3 ][ "end_angle" ], OCX_PI / 2.0, 0.000000001 ), "[extra] muestra: ARC 90 grados -> pi/2" )
         Chk( es[ 4 ][ "_type" ] == "LWPOLYLINE" .AND. Len( es[ 4 ][ "vertices" ] ) == 3 .AND. Near( es[ 4 ][ "vertices" ][ 2 ][ "bulge" ], 0.5, 0.000000001 ) .AND. Near( es[ 4 ][ "vertices" ][ 1 ][ "bulge" ], 0.0, 0.000000001 ) .AND. es[ 4 ][ "is_closed" ], "[extra] muestra: LWPOLYLINE (bulge asignado al vertice previo)" )
         Chk( es[ 5 ][ "_type" ] == "TEXT" .AND. es[ 5 ][ "value" ] == "Hola mundo" .AND. Near( es[ 5 ][ "rotation" ], 45.0 * OCX_PI / 180.0, 0.000000001 ), "[extra] muestra: TEXT rotacion 45 grados" )
         Chk( es[ 6 ][ "_type" ] == "INSERT" .AND. es[ 6 ][ "block_name" ] == "CAJA" .AND. Near( es[ 6 ][ "x_scale" ], 2.0, 0.000000001 ) .AND. es[ 7 ][ "_type" ] == "POINT", "[extra] muestra: INSERT y POINT" )
      ENDIF
      x := Tb_Get( d[ "block_records" ], "CAJA" )
      Chk( x != NIL .AND. Len( x[ "entity_handles" ] ) == 1 .AND. x[ "block_entity_handle" ] == 97 .AND. x[ "block_end_handle" ] == 99, "[extra] muestra: bloque CAJA (LINE, handles BLOCK/ENDBLK)" )
      u := Ucs_FromOriginAxes( "Plano", Vc3_New( 1.0, 2.0, 3.0 ), Vc3_New( 0.0, 1.0, 0.0 ), Vc3_New( -1.0, 0.0, 0.0 ) )
      u[ "elevation" ] := 2.5 ; u[ "ortho_type" ] := 3 ; u[ "xref_dependent" ] := .T.
      u[ "handle" ] := Doc_AllocateHandle( d ) ; Tb_AddOrReplace( d[ "ucss" ], u )
      x := Viw_New( "Vista1" ) ; x[ "handle" ] := Doc_AllocateHandle( d ) ; x[ "height" ] := 12.5 ; x[ "width" ] := 20.0 ; x[ "twist_angle" ] := OCX_PI / 2.0
      x[ "center" ] := Vc3_New( 3.0, 4.0, 0.0 ) ; x[ "perspective" ] := .T. ; x[ "ucs_associated" ] := .T. ; x[ "ucs_origin" ] := Vc3_New( 5.0, 6.0, 7.0 )
      Tb_AddOrReplace( d[ "views" ], x )
      x := Dst_DxfDefaults( "Cota1" ) ; x[ "handle" ] := Doc_AllocateHandle( d ) ; x[ "dimscale" ] := 2.5 ; x[ "dimtxt" ] := 0.35 ; x[ "dimtol" ] := .T. ; x[ "dimdec" ] := 3
      x[ "dimpost" ] := "mm" ; x[ "annotative" ] := .T. ; x[ "dimclrd" ] := 5 ; x[ "dimlwd" ] := 25
      Tb_AddOrReplace( d[ "dim_styles" ], x )
      x := Vpt_New( "*Active" ) ; x[ "handle" ] := Doc_AllocateHandle( d ) ; x[ "view_height" ] := 33.5 ; x[ "view_center" ] := Vc2_New( 8.0, 9.0 ) ; x[ "snap_rotation" ] := OCX_PI
      x[ "grid_on" ] := .T. ; x[ "ucsfollow" ] := .T. ; x[ "ucs_origin" ] := Vc3_New( 1.0, 2.0, 3.0 ) ; x[ "grid_major" ] := 7
      Tb_AddAllowDuplicate( d[ "vports" ], x )
      s1 := Dxw_WriteString( d ) ; d2 := Dxr_ReadString( s1 )
      u := IIf( ValType( d2 ) == "H", Tb_Get( d2[ "ucss" ], "Plano" ), NIL )
      Chk( u != NIL .AND. Near( u[ "origin" ][ 3 ], 3.0, 0.000000001 ) .AND. Near( u[ "y_axis" ][ 1 ], -1.0, 0.000000001 ) .AND. Near( u[ "elevation" ], 2.5, 0.000000001 ) .AND. u[ "ortho_type" ] == 3 .AND. u[ "xref_dependent" ] .AND. ! u[ "xref_resolved" ], "[extra] tabla UCS: escribir y releer" )
      x := IIf( ValType( d2 ) == "H", Tb_Get( d2[ "views" ], "Vista1" ), NIL )
      Chk( x != NIL .AND. Near( x[ "height" ], 12.5, 0.000000001 ) .AND. Near( x[ "twist_angle" ], OCX_PI / 2.0, 0.000000001 ) .AND. Near( x[ "center" ][ 2 ], 4.0, 0.000000001 ) .AND. x[ "perspective" ] .AND. ! x[ "front_clipping" ] .AND. x[ "ucs_associated" ] .AND. Near( x[ "ucs_origin" ][ 3 ], 7.0, 0.000000001 ), "[extra] tabla VIEW: escribir y releer" )
      x := IIf( ValType( d2 ) == "H", Tb_Get( d2[ "dim_styles" ], "Cota1" ), NIL )
      Chk( x != NIL .AND. Near( x[ "dimscale" ], 2.5, 0.000000001 ) .AND. Near( x[ "dimtxt" ], 0.35, 0.000000001 ) .AND. x[ "dimtol" ] .AND. ! x[ "dimlim" ] .AND. x[ "dimdec" ] == 3 .AND. x[ "dimpost" ] == "mm" .AND. x[ "annotative" ] .AND. x[ "dimclrd" ] == 5 .AND. x[ "dimlwd" ] == 25, "[extra] tabla DIMSTYLE: escribir y releer" )
      IF ValType( d2 ) == "H"
         ok := Dxo_CountLayouts( d ) ; x := Dxo_CountLayouts( d2 )
         Chk( ok >= 1 .AND. ok == x, "[extra] OBJECTS: los LAYOUT sobreviven a escribir y releer (" + hb_ntos( ok ) + ")" )
         ok := d[ "objects" ][ Dxo_RootForTest( d ) ] ; x := d2[ "objects" ][ Dxo_RootForTest( d2 ) ]
         Chk( Len( x[ "entries" ] ) >= 1 .AND. Len( x[ "entries" ] ) <= Len( ok[ "entries" ] ), "[extra] OBJECTS: diccionario raiz conserva entradas escribibles" )
         x := Xrc_New() ; x[ "handle" ] := Doc_AllocateHandle( d ) ; x[ "owner" ] := d[ "header" ][ "named_objects_dict_handle" ]
         Xrc_AddString( x, 1, "hola" ) ; Xrc_AddDouble( x, 40, 2.5 ) ; Xrc_AddInt16( x, 70, 7 ) ; Xrc_AddInt32( x, 90, 70000 ) ; Xrc_AddBool( x, 290, .T. ) ; Xrc_AddPoint3d( x, 10, 1.0, 2.0, 3.0 )
         Xrc_AddHandle( x, 340, 12 ) ; AAdd( x[ "entries" ], Xre_New( 310, Xrv_New( "Chunk", Chr( 1 ) + Chr( 255 ) + Chr( 16 ) ) ) )
         d[ "objects" ][ x[ "handle" ] ] := x
         ok := Grp_New( "" ) ; ok[ "handle" ] := Doc_AllocateHandle( d ) ; ok[ "unnamed" ] := .T. ; ok[ "description" ] := "grp" ; AAdd( ok[ "entities" ], 112 ) ; ok[ "selectable" ] := .F.
         d[ "objects" ][ ok[ "handle" ] ] := ok
         d5 := Dxr_ReadString( Dxw_WriteString( d ) )
         x := IIf( ValType( d5 ) == "H", hb_HGetDef( d5[ "objects" ], x[ "handle" ], NIL ), NIL )
         ok := IIf( ValType( d5 ) == "H", hb_HGetDef( d5[ "objects" ], ok[ "handle" ], NIL ), NIL )
         Chk( x != NIL .AND. Len( x[ "entries" ] ) == 8 .AND. x[ "entries" ][ 1 ][ "value" ][ "value" ] == "hola" .AND. x[ "entries" ][ 3 ][ "value" ][ "_kind" ] == "Int16" .AND. x[ "entries" ][ 4 ][ "value" ][ "value" ] == 70000 ;
            .AND. x[ "entries" ][ 5 ][ "value" ][ "value" ] .AND. Near( x[ "entries" ][ 6 ][ "value" ][ "value" ][ 3 ], 3.0, 0.000000001 ) .AND. x[ "entries" ][ 7 ][ "value" ][ "value" ] == 12 .AND. x[ "entries" ][ 8 ][ "value" ][ "value" ] == Chr( 1 ) + Chr( 255 ) + Chr( 16 ) ;
            .AND. Len( x[ "object_references" ] ) == 1, "[extra] OBJECTS: XRECORD escribir y releer (tipos de valor)" )
         Chk( ok != NIL .AND. ok[ "unnamed" ] .AND. ! ok[ "selectable" ] .AND. ok[ "description" ] == "grp" .AND. Len( ok[ "entities" ] ) == 1, "[extra] OBJECTS: GROUP escribir y releer" )
         x := Mlsy_New( "Doble" ) ; x[ "handle" ] := Doc_AllocateHandle( d ) ; x[ "owner" ] := d[ "header" ][ "named_objects_dict_handle" ] ; x[ "description" ] := "dos lineas"
         x[ "start_angle" ] := OCX_PI / 2.0 ; x[ "end_angle" ] := OCX_PI ; x[ "fill_color" ] := Cl_FromIndex( 3 )
         Mlsy_AddElement( x, Mlse_Full( 0.25, Cl_FromIndex( 1 ), "CENTER" ) ) ; Mlsy_AddElement( x, Mlse_New( -0.25 ) )
         d[ "objects" ][ x[ "handle" ] ] := x
         d5 := Dxr_ReadString( Dxw_WriteString( d ) )
         x := IIf( ValType( d5 ) == "H", hb_HGetDef( d5[ "objects" ], x[ "handle" ], NIL ), NIL )
         Chk( x != NIL .AND. x[ "name" ] == "Doble" .AND. x[ "description" ] == "dos lineas" .AND. Near( x[ "end_angle" ], OCX_PI, 0.000000001 ) .AND. Len( x[ "elements" ] ) == 2 .AND. x[ "elements" ][ 1 ][ "linetype" ] == "CENTER" ;
            .AND. Near( x[ "elements" ][ 2 ][ "offset" ], -0.25, 0.000000001 ) .AND. x[ "elements" ][ 2 ][ "linetype" ] == "BYLAYER" .AND. Cl_Eq( x[ "fill_color" ], Cl_FromIndex( 3 ) ), "[extra] OBJECTS: MLINESTYLE escribir y releer" )
         x := Scl_New( "1:50", 1.0, 50.0 ) ; x[ "handle" ] := Doc_AllocateHandle( d ) ; x[ "owner_handle" ] := d[ "header" ][ "named_objects_dict_handle" ]
         d[ "objects" ][ x[ "handle" ] ] := x
         u := Dvr_New( "", "7" ) ; u[ "handle" ] := Doc_AllocateHandle( d ) ; u[ "owner_handle" ] := d[ "header" ][ "named_objects_dict_handle" ] ; u[ "schema_number" ] := 0
         d[ "objects" ][ u[ "handle" ] ] := u
         d5 := Dxr_ReadString( Dxw_WriteString( d ) )
         x := IIf( ValType( d5 ) == "H", hb_HGetDef( d5[ "objects" ], x[ "handle" ], NIL ), NIL )
         u := IIf( ValType( d5 ) == "H", hb_HGetDef( d5[ "objects" ], u[ "handle" ], NIL ), NIL )
         Chk( x != NIL .AND. x[ "name" ] == "1:50" .AND. Near( x[ "drawing_units" ], 50.0, 0.000000001 ) .AND. ! x[ "is_unit_scale" ] .AND. u != NIL .AND. u[ "value" ] == "7", "[extra] OBJECTS: SCALE y DICTIONARYVAR escribir y releer" )
         /* regresion: != con literal es prefijo-inexacto en Harbour (SET EXACT OFF); ahora se usa == negado */
         Chk( ! ( "ACADANNOTATIVE" == "ACAD" ) .AND. Ec_HasLinetype( hb_HSet( Ec_New(), "linetype", "ByLayerX" ) ), "[extra] comparacion de cadenas exacta (!= no es prefijo)" )
         x := Sot_ForBlock( 1 ) ; x[ "handle" ] := Doc_AllocateHandle( d ) ; x[ "owner_handle" ] := d[ "header" ][ "named_objects_dict_handle" ]
         Sot_AddEntry( x, 100, 900 ) ; Sot_AddEntry( x, 101, 800 )
         d[ "objects" ][ x[ "handle" ] ] := x
         d5 := Dxr_ReadString( Dxw_WriteString( d ) )
         u := IIf( ValType( d5 ) == "H", hb_HGetDef( d5[ "objects" ], x[ "handle" ], NIL ), NIL )
         Chk( u != NIL .AND. Sot_Len( u ) == 2 .AND. u[ "block_owner_handle" ] == 1 .AND. Sot_Contains( u, 100 ) .AND. Sot_Contains( u, 101 ) .AND. u[ "raw_dxf_codes" ] != NIL, "[extra] OBJECTS: SORTENTSTABLE escribir y releer (codigos crudos)" )
         u[ "raw_dxf_codes" ] := NIL
         d5 := Dxr_ReadString( Dxw_WriteString( d5 ) )
         u := IIf( ValType( d5 ) == "H", hb_HGetDef( d5[ "objects" ], x[ "handle" ], NIL ), NIL )
         Chk( u != NIL .AND. Sot_Len( u ) == 2 .AND. Sot_GetSortHandle( u, 100 ) > Sot_GetSortHandle( u, 101 ), "[extra] OBJECTS: SORTENTSTABLE sin codigos crudos reasigna handles en orden" )
         x := Imd_New( "foto.png" ) ; x[ "handle" ] := Doc_AllocateHandle( d ) ; x[ "owner" ] := d[ "header" ][ "named_objects_dict_handle" ]
         x[ "size_in_pixels" ] := { 640, 480 } ; x[ "pixel_size" ] := { 0.5, 0.25 } ; x[ "is_loaded" ] := .T.
         d[ "objects" ][ x[ "handle" ] ] := x
         d5 := Dxr_ReadString( Dxw_WriteString( d ) )
         u := IIf( ValType( d5 ) == "H", hb_HGetDef( d5[ "objects" ], x[ "handle" ], NIL ), NIL )
         Chk( u != NIL .AND. u[ "file_name" ] == "foto.png" .AND. u[ "size_in_pixels" ][ 1 ] == 640 .AND. u[ "size_in_pixels" ][ 2 ] == 480 .AND. Near( u[ "pixel_size" ][ 2 ], 0.25, 0.000000001 ) .AND. u[ "is_loaded" ], "[extra] OBJECTS: IMAGEDEF escribir y releer" )
         x := Udf_Dwf( "plano.dwf", "Hoja1" ) ; x[ "_type" ] := "UnderlayDefinition" ; x[ "handle" ] := Doc_AllocateHandle( d ) ; x[ "owner_handle" ] := d[ "header" ][ "named_objects_dict_handle" ]
         x[ "unloaded" ] := .T.
         d[ "objects" ][ x[ "handle" ] ] := x
         d5 := Dxr_ReadString( Dxw_WriteString( d ) )
         u := IIf( ValType( d5 ) == "H", hb_HGetDef( d5[ "objects" ], x[ "handle" ], NIL ), NIL )
         Chk( u != NIL .AND. u[ "underlay_type" ] == UTY_DWF .AND. u[ "file_path" ] == "plano.dwf" .AND. u[ "page_name" ] == "Hoja1" .AND. u[ "unloaded" ], "[extra] OBJECTS: DWFDEFINITION escribir y releer (NOLOAD)" )
         x := Mst_New( "Mio" ) ; x[ "handle" ] := Doc_AllocateHandle( d ) ; x[ "owner_handle" ] := d[ "header" ][ "named_objects_dict_handle" ]
         x[ "line_color" ] := Cl_FromIndex( 5 ) ; x[ "text_height" ] := 2.5 ; x[ "text_frame" ] := .T. ; x[ "content_type" ] := MST_CT_BLOCK ; x[ "line_weight" ] := Lw_Value( 50 ) ; x[ "text_style_handle" ] := 42
         d[ "objects" ][ x[ "handle" ] ] := x
         d5 := Dxr_ReadString( Dxw_WriteString( d ) )
         u := IIf( ValType( d5 ) == "H", hb_HGetDef( d5[ "objects" ], x[ "handle" ], NIL ), NIL )
         Chk( u != NIL .AND. u[ "name" ] == "Mio" .AND. Cl_Eq( u[ "line_color" ], Cl_FromIndex( 5 ) ) .AND. Near( u[ "text_height" ], 2.5, 0.000000001 ) .AND. u[ "text_frame" ] ;
            .AND. u[ "content_type" ] == MST_CT_BLOCK .AND. Lw_Eq( u[ "line_weight" ], Lw_Value( 50 ) ) .AND. u[ "text_style_handle" ] == 42, "[extra] OBJECTS: MLEADERSTYLE escribir y releer" )
      ENDIF
      x := NIL
      IF ValType( d2 ) == "H"
         FOR EACH e IN Tb_Values( d2[ "vports" ] )
            IF Near( e[ "view_height" ], 33.5, 0.000000001 ) ; x := e ; ENDIF
         NEXT
      ENDIF
      Chk( x != NIL .AND. Near( x[ "view_height" ], 33.5, 0.000000001 ) .AND. Near( x[ "view_center" ][ 2 ], 9.0, 0.000000001 ) .AND. Near( x[ "snap_rotation" ], OCX_PI, 0.000000001 ) .AND. x[ "grid_on" ] .AND. x[ "ucsfollow" ] .AND. ! x[ "snap_on" ] .AND. Near( x[ "ucs_origin" ][ 3 ], 3.0, 0.000000001 ), "[extra] tabla VPORT: escribir y releer" )
      Chk( ValType( d2 ) == "H" .AND. Len( Doc_ModelSpaceEntities( d2 ) ) == 8 .AND. Len( s1 ) == Len( Dxw_WriteString( d2 ) ), "[extra] muestra: escribir y releer conserva 8 entidades y es estable (HANDSEED puede subir)" )
   ENDIF
RETURN
