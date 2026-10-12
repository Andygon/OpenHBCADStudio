/* Port de tests de group_code_value.rs (4) y types/mod.rs DxfVersion (3); dxf_code.rs no tiene tests -> [extra] */
#include "ocx.ch"
#include "dxfcode.ch"
PROCEDURE T_CodecDxf()
   LOCAL h, lOk, n, aA
   Chk( Gv_FromCode( DXF_START ) == GVT_STRING .AND. Gv_FromCode( DXF_TEXT ) == GVT_STRING .AND. Gv_FromCode( DXF_XCOORDINATE ) == GVT_DOUBLE .AND. Gv_FromCode( DXF_INT70 ) == GVT_INT16 .AND. Gv_FromCode( DXF_INT90 ) == GVT_INT32 .AND. Gv_FromCode( DXF_INT160 ) == GVT_INT64 .AND. Gv_FromCode( DXF_BOOL290 ) == GVT_BOOL .AND. Gv_FromCode( DXF_BINARYDATA310 ) == GVT_BINARYDATA .AND. Gv_FromCode( DXF_SOFTPOINTERID330 ) == GVT_HANDLE, "gcv: test_value_type_from_code" )
   Chk( Gv_IsCoordinate( DXF_XCOORDINATE ) .AND. Gv_IsCoordinate( DXF_YCOORDINATE ) .AND. Gv_IsCoordinate( DXF_ZCOORDINATE ) .AND. Gv_IsCoordinate( DXF_EXTRUSIONX ) .AND. ! Gv_IsCoordinate( DXF_REAL40 ) .AND. ! Gv_IsCoordinate( DXF_INT70 ), "gcv: test_is_coordinate" )
   Chk( Gv_CoordinateAxis( DXF_XCOORDINATE ) == 0 .AND. Gv_CoordinateAxis( DXF_YCOORDINATE ) == 1 .AND. Gv_CoordinateAxis( DXF_ZCOORDINATE ) == 2 .AND. Gv_CoordinateAxis( DXF_REAL40 ) == NIL, "gcv: test_coordinate_axis" )
   Chk( Gv_CoordinateGroup( DXF_XCOORDINATE ) == 0 .AND. Gv_CoordinateGroup( DXF_XCOORDINATE1 ) == 1 .AND. Gv_CoordinateGroup( DXF_XCOORDINATE2 ) == 2 .AND. Gv_CoordinateGroup( DXF_EXTRUSIONX ) == 21, "gcv: test_coordinate_group" )
   // DxfVersion
   Chk( Dxv_AsStr( 1015 ) == "AC1015" .AND. Dxv_AsStr( 1032 ) == "AC1032", "dxfversion: test_version_string" )
   Chk( Dxv_Parse( "AC1018" ) == 1018 .AND. Dxv_Parse( "INVALID" ) == NIL, "dxfversion: test_version_parse" )
   Chk( Dxv_VersionCode( 1021 ) == 1021, "dxfversion: test_version_code" )
   // [extra]
   Chk( Dxv_Parse( "AD1009" ) == 1009 .AND. Dxv_FromVersionString( "zzz" ) == 0 .AND. Dxv_AsStr( 0 ) == "UNKNOWN" .AND. Dxv_FromVersionCode( 1014 ) == 1014 .AND. Dxv_FromVersionCode( 1 ) == 0, "[extra] dxfversion: AD*, unknown" )
   // [extra] dxf_code: de i32 a variante coincide con el valor salvo la anomalia conocida del fuente (1032)
   lOk := .T. ; aA := Dxc_Anomalies()
   Chk( Len( aA ) == 1 .AND. aA[1][1] == 1032 .AND. aA[1][2] == 1031 .AND. Dxc_FromI32( 1032 ) == 1031, "[extra] dxf_code: from_i32(1032) devuelve 1031 como el original (anomalia)" )
   FOR EACH n IN { -9999, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 7, 8, 9, 10, 20, 30, 40, 70, 90, 160, 290, 310, 330, 999, 1000, 1001, 1010, 1020, 1030, 1070, 1071 }
      IF Dxc_FromI32( n ) != n ; lOk := .F. ; ENDIF
   NEXT
   Chk( lOk, "[extra] dxf_code: from_i32 identidad en codigos conocidos" )
   Chk( Dxc_FromI32( 5000 ) == DXF_INVALID .AND. Dxc_ToI32( DXF_LAYERNAME ) == 8 .AND. DXF_EXTRUSIONX == 210, "[extra] dxf_code: desconocido -> Invalid; to_i32" )
   h := Gv_FromRawCode( 450 ) ; HB_SYMBOL_UNUSED( h )
RETURN
