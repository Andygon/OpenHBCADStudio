/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_secsections.prg
   Origen Rust: opencadcodec/src/io/dxf/reader/section_reader.rs (parte 2: CLASSES, tablas,
   BLOCKS, ENTITIES) y io/dxf/reader.rs (bucle de secciones). Licencia del original: MPL-2.0.
   La cabecera y el flujo estan en dxf_secreader.prg. Prefijo Sr_ / Dxr_.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define DP_CODE 1
#define DP_VALUE 3

/* ---- utilidades de lectura ---- */
STATIC FUNCTION Sr_Deg( n ) ; RETURN n * OCX_PI / 180.0

STATIC FUNCTION Sr_Str2Num( c, nDef )
   LOCAL n
   c := AllTrim( c )
   IF Len( c ) == 0 ; RETURN nDef ; ENDIF
   n := Val( c )
   IF n == 0 .AND. ! ( Left( c, 1 ) $ "0.+-" ) ; RETURN nDef ; ENDIF
RETURN n

/* read_reactor_handles */
STATIC FUNCTION Sr_ReadReactorHandles( s )
   LOCAL a := {}, p, h
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 102 ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 330
         h := Sr_HexVal( p )
         IF h != NIL ; AAdd( a, h ) ; ENDIF
      ENDIF
   ENDDO
RETURN a

/* read_xdictionary_handle: handle o NIL */
STATIC FUNCTION Sr_ReadXDictHandle( s )
   LOCAL r := NIL, p, h
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 102 ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 360
         h := Sr_HexVal( p )
         IF h != NIL ; r := h ; ENDIF
      ENDIF
   ENDDO
RETURN r

STATIC PROCEDURE Sr_SkipDefinedGroup( s )
   LOCAL p
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 102 .AND. AllTrim( p[ DP_VALUE ] ) == "}" ; EXIT ; ENDIF
   ENDDO
RETURN

STATIC PROCEDURE Sr_SkipEntity( s )
   LOCAL p
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
   ENDDO
RETURN

/* read_extended_data: devuelve { xdata, nextPair } */
STATIC FUNCTION Sr_ReadExtendedData( s )
   LOCAL xd := Xd_New(), rec := NIL, pr := PR_New(), p, n, v, i, cB, nC, cH
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 1001
         IF rec != NIL ; Xd_AddRecord( xd, rec ) ; ENDIF
         rec := Xr_New( p[ DP_VALUE ] )
      CASE n == 1000 .AND. rec != NIL ; Xr_AddValue( rec, Xv_New( XV_STRING, p[ DP_VALUE ] ) )
      CASE n == 1002 .AND. rec != NIL ; Xr_AddValue( rec, Xv_New( XV_CONTROLSTRING, p[ DP_VALUE ] ) )
      CASE n == 1003 .AND. rec != NIL ; Xr_AddValue( rec, Xv_New( XV_LAYERNAME, p[ DP_VALUE ] ) )
      CASE n == 1004 .AND. rec != NIL
         cB := ""
         cH := p[ DP_VALUE ]
         FOR i := 1 TO Len( cH ) STEP 2
            nC := At( Upper( SubStr( cH, i, 1 ) ), "0123456789ABCDEF" ) - 1
            IF i + 1 <= Len( cH ) .AND. nC >= 0
               v := At( Upper( SubStr( cH, i + 1, 1 ) ), "0123456789ABCDEF" ) - 1
               IF v >= 0 ; cB += hb_BChar( nC * 16 + v ) ; ENDIF
            ENDIF
         NEXT
         Xr_AddValue( rec, Xv_New( XV_BINARYDATA, cB ) )
      CASE n == 1005 .AND. rec != NIL
         v := Sr_HexVal( p )
         IF v != NIL ; Xr_AddValue( rec, Xv_New( XV_HANDLE, v ) ) ; ENDIF
      CASE n == 1010 .OR. n == 1020 .OR. n == 1030 .OR. n == 1011 .OR. n == 1021 .OR. n == 1031 .OR. ;
           n == 1012 .OR. n == 1022 .OR. n == 1032 .OR. n == 1013 .OR. n == 1023 .OR. n == 1033
         IF rec != NIL
            IF n == 1010 .OR. n == 1011 .OR. n == 1012 .OR. n == 1013 ; PR_Reset( pr ) ; ENDIF
            PR_AddCoordinate( pr, p )
            IF n == 1030 .OR. n == 1031 .OR. n == 1032 .OR. n == 1033
               v := PR_GetPoint( pr )
               IF v != NIL
                  Xr_AddValue( rec, Xv_New( IIf( n == 1030, XV_POINT3D, IIf( n == 1031, XV_POSITION3D, IIf( n == 1032, XV_DISPLACEMENT3D, XV_DIRECTION3D ) ) ), v ) )
               ENDIF
               PR_Reset( pr )
            ENDIF
         ENDIF
      CASE n == 1040 .AND. rec != NIL
         v := Dp_AsDouble( p ) ; IF v != NIL ; Xr_AddValue( rec, Xv_New( XV_REAL, v ) ) ; ENDIF
      CASE n == 1041 .AND. rec != NIL
         v := Dp_AsDouble( p ) ; IF v != NIL ; Xr_AddValue( rec, Xv_New( XV_DISTANCE, v ) ) ; ENDIF
      CASE n == 1042 .AND. rec != NIL
         v := Dp_AsDouble( p ) ; IF v != NIL ; Xr_AddValue( rec, Xv_New( XV_SCALEFACTOR, v ) ) ; ENDIF
      CASE n == 1070 .AND. rec != NIL
         v := Dp_AsI16( p ) ; IF v != NIL ; Xr_AddValue( rec, Xv_New( XV_INTEGER16, v ) ) ; ENDIF
      CASE n == 1071 .AND. rec != NIL
         v := Dp_AsI32( p ) ; IF v != NIL ; Xr_AddValue( rec, Xv_New( XV_INTEGER32, v ) ) ; ENDIF
      CASE n >= 1000 .AND. n <= 1071 .AND. rec != NIL
         /* codigo xdata sin valor asociado: se ignora (como en el original, ramas con record=None) */
      OTHERWISE
         IF rec != NIL ; Xd_AddRecord( xd, rec ) ; ENDIF
         RETURN { xd, p }
      ENDCASE
   ENDDO
   IF rec != NIL ; Xd_AddRecord( xd, rec ) ; ENDIF
RETURN { xd, NIL }

/* Lee xdata empezando por el par 1001 ya leido; devuelve xdata y re-empuja el par siguiente */
STATIC FUNCTION Sr_XDataFrom( s, p1001 )
   LOCAL r
   Sr_PushBack( s, p1001 )
   r := Sr_ReadExtendedData( s )
   IF r[ 2 ] != NIL ; Sr_PushBack( s, r[ 2 ] ) ; ENDIF
RETURN r[ 1 ]

/* try_read_common_entity_code: .T. si consumio el codigo */
STATIC FUNCTION Sr_CommonCode( s, p, c )
   LOCAL n := p[ DP_CODE ], v, cV
   DO CASE
   CASE n == 5
      v := Sr_HexVal( p ) ; IF v != NIL ; c[ "handle" ] := v ; ENDIF
   CASE n == 6 ; c[ "linetype" ] := p[ DP_VALUE ]
   CASE n == 8 ; c[ "layer" ] := p[ DP_VALUE ]
   CASE n == 62
      v := Dp_AsI16( p ) ; IF v != NIL ; c[ "color" ] := Cl_FromIndex( v ) ; ENDIF
   CASE n == 370
      v := Dp_AsI16( p ) ; IF v != NIL ; c[ "line_weight" ] := Lw_FromValue( v ) ; ENDIF
   CASE n == 48
      v := Dp_AsDouble( p ) ; IF v != NIL ; c[ "linetype_scale" ] := v ; ENDIF
   CASE n == 60
      v := Dp_AsI16( p ) ; IF v != NIL ; c[ "invisible" ] := ( v != 0 ) ; ENDIF
   CASE n == 330
      v := Sr_HexVal( p ) ; IF v != NIL ; c[ "owner_handle" ] := v ; ENDIF
   CASE n == 348
      v := Sr_HexVal( p )
      IF v != NIL
         DO CASE
         CASE c[ "full_visual_style_handle" ] == NIL ; c[ "full_visual_style_handle" ] := v
         CASE c[ "face_visual_style_handle" ] == NIL ; c[ "face_visual_style_handle" ] := v
         CASE c[ "edge_visual_style_handle" ] == NIL ; c[ "edge_visual_style_handle" ] := v
         ENDCASE
      ENDIF
   CASE n == 102
      cV := AllTrim( p[ DP_VALUE ] )
      DO CASE
      CASE cV == "{ACAD_REACTORS" ; c[ "reactors" ] := Sr_ReadReactorHandles( s )
      CASE cV == "{ACAD_XDICTIONARY" ; c[ "xdictionary_handle" ] := Sr_ReadXDictHandle( s )
      CASE Left( cV, 1 ) == "{" ; Sr_SkipDefinedGroup( s )
      ENDCASE
   CASE n == 420
      v := Dp_AsI32Bits( p ) ; IF v != NIL ; c[ "color" ] := Cl_FromTrueColorValue( v ) ; ENDIF
   CASE n == 430 ; c[ "color_name" ] := p[ DP_VALUE ]
   CASE n == 440
      v := Dp_AsI32( p ) ; IF v != NIL ; c[ "transparency" ] := Tp_FromAlphaValue( IIf( v < 0, v + 4294967296, v ) ) ; ENDIF
   CASE n == 67
      IF Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 ; c[ "entity_mode" ] := 1 ; ENDIF
   CASE n == 1001
      c[ "extended_data" ] := Sr_XDataFrom( s, p )
   OTHERWISE
      RETURN .F.
   ENDCASE
RETURN .T.

/* ---- clases ---- */
PROCEDURE Sr_ReadClasses( s, d )
   LOCAL pair, cl, cp, v
   DO WHILE ( pair := Sr_Next( s ) ) != NIL
      IF pair[ DP_CODE ] == 0 .AND. pair[ DP_VALUE ] == "ENDSEC" ; EXIT ; ENDIF
      IF pair[ DP_CODE ] == 0 .AND. pair[ DP_VALUE ] == "CLASS"
         cl := Dcl_New( "", "" )
         DO WHILE ( cp := Sr_Next( s ) ) != NIL
            IF cp[ DP_CODE ] == 0 ; Sr_PushBack( s, cp ) ; EXIT ; ENDIF
            DO CASE
            CASE cp[ DP_CODE ] == 1 ; cl[ "dxf_name" ] := cp[ DP_VALUE ]
            CASE cp[ DP_CODE ] == 2 ; cl[ "cpp_class_name" ] := cp[ DP_VALUE ]
            CASE cp[ DP_CODE ] == 3 ; cl[ "application_name" ] := cp[ DP_VALUE ]
            CASE cp[ DP_CODE ] == 90
               v := Dp_AsI32( cp ) ; IF v != NIL ; cl[ "proxy_flags" ] := v ; ENDIF
            CASE cp[ DP_CODE ] == 91
               v := Dp_AsI32( cp ) ; IF v != NIL ; cl[ "instance_count" ] := v ; ENDIF
            CASE cp[ DP_CODE ] == 280
               v := Dp_AsI16( cp ) ; IF v != NIL ; cl[ "was_zombie" ] := ( v != 0 ) ; ENDIF
            CASE cp[ DP_CODE ] == 281
               v := Dp_AsI16( cp )
               IF v != NIL
                  cl[ "is_an_entity" ] := ( v != 0 )
                  cl[ "item_class_id" ] := IIf( v != 0, 498, 499 )
               ENDIF
            ENDCASE
         ENDDO
         IF Len( cl[ "dxf_name" ] ) > 0 ; Dcc_AddOrUpdate( d[ "classes" ], cl ) ; ENDIF
      ENDIF
   ENDDO
RETURN

/* ---- tablas ---- */
STATIC FUNCTION Sr_LayerEntry( s, aOutXd )
   LOCAL l := Lyr_New( "0" ), p, v, n, x, rec, aV, i, nStr, bk
   aOutXd[ 1 ] := NIL
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; l[ "handle" ] := v ; ENDIF
      CASE n == 102 .AND. AllTrim( p[ DP_VALUE ] ) == "{ACAD_XDICTIONARY"
         aOutXd[ 1 ] := Sr_ReadXDictHandle( s )
      CASE n == 2 ; l[ "name" ] := p[ DP_VALUE ]
      CASE n == 62
         v := Dp_AsI16( p )
         IF v != NIL
            l[ "flags" ][ "off" ] := ( v < 0 )
            l[ "color" ] := Cl_FromIndex( Abs( v ) )
         ENDIF
      CASE n == 420
         v := Dp_AsI32Bits( p ) ; IF v != NIL ; l[ "color" ] := Cl_FromTrueColorValue( v ) ; ENDIF
      CASE n == 430
         bk := Dxm_SplitColorBookName( p[ DP_VALUE ] )
         l[ "book_name" ] := bk[ 1 ] ; l[ "color_name" ] := bk[ 2 ]
      CASE n == 6 ; l[ "line_type" ] := p[ DP_VALUE ]
      CASE n == 70
         v := Dp_AsI16( p )
         IF v != NIL
            l[ "flags" ][ "frozen" ] := hb_bitAnd( v, 1 ) != 0
            l[ "flags" ][ "frozen_in_new_viewport" ] := hb_bitAnd( v, 2 ) != 0
            l[ "flags" ][ "locked" ] := hb_bitAnd( v, 4 ) != 0
            l[ "flags" ][ "xref_dependent" ] := hb_bitAnd( v, 16 ) != 0
         ENDIF
      CASE n == 290
         v := Dp_AsBool( p ) ; IF v != NIL ; l[ "is_plottable" ] := v ; ENDIF
      CASE n == 370
         v := Dp_AsI16( p ) ; IF v != NIL ; l[ "line_weight" ] := Lw_FromValue( v ) ; ENDIF
      CASE n == 1001
         x := Sr_XDataFrom( s, p )
         rec := Xd_GetRecord( x, "AcCmTransparency" )
         IF rec != NIL
            FOR EACH v IN Xr_Values( rec )
               IF v[ 1 ] == XV_INTEGER32
                  l[ "transparency" ] := Tp_FromAlphaValue( IIf( v[ 2 ] < 0, v[ 2 ] + 4294967296, v[ 2 ] ) )
                  EXIT
               ENDIF
            NEXT
         ENDIF
         rec := Xd_GetRecord( x, Lyr_DescriptionApp() )
         IF rec != NIL
            aV := Xr_Values( rec ) ; nStr := 0 ; l[ "description" ] := ""
            FOR i := 1 TO Len( aV )
               IF aV[ i ][ 1 ] == XV_STRING
                  nStr++
                  IF nStr == 2 ; l[ "description" ] := aV[ i ][ 2 ] ; EXIT ; ENDIF
               ENDIF
            NEXT
         ENDIF
      ENDCASE
   ENDDO
RETURN l

STATIC PROCEDURE Sr_TableGeneric( s, d, cTable, cEntryName, cCtrlKey, bEntry, lDupName )
   LOCAL p, h, e, t := d[ cTable ]
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "ENDTAB" ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 5
         h := Sr_HexVal( p )
         IF h != NIL ; Tb_SetHandle( t, h ) ; d[ "header" ][ cCtrlKey ] := h ; ENDIF
      ELSEIF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == cEntryName
         e := Eval( bEntry )
         IF e != NIL
            IF lDupName .AND. Len( e[ "name" ] ) == 0
               Tb_AddAllowDuplicate( t, e )
            ELSE
               Tb_AddOrReplace( t, e )
            ENDIF
         ENDIF
      ENDIF
   ENDDO
RETURN

PROCEDURE Sr_ReadLayerTable( s, d )
   LOCAL t := d[ "layers" ], p, h, aXd := { NIL }, l, hTable := Tb_Handle( t ), hXd := NIL
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "ENDTAB" ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "LAYER"
         l := Sr_LayerEntry( s, aXd )
         IF aXd[ 1 ] != NIL ; d[ "xdic_by_handle" ][ l[ "handle" ] ] := aXd[ 1 ] ; ENDIF
         Tb_AddOrReplace( t, l )
      ELSEIF p[ DP_CODE ] == 5
         h := Sr_HexVal( p )
         IF h != NIL
            hTable := h ; Tb_SetHandle( t, h ) ; d[ "header" ][ "layer_control_handle" ] := h
         ENDIF
      ELSEIF p[ DP_CODE ] == 102 .AND. AllTrim( p[ DP_VALUE ] ) == "{ACAD_XDICTIONARY"
         hXd := Sr_ReadXDictHandle( s )
      ENDIF
   ENDDO
   IF hXd != NIL ; d[ "xdic_by_handle" ][ hTable ] := hXd ; ENDIF
RETURN

STATIC FUNCTION Sr_LtypeEntry( s )
   LOCAL l := Lty_New( "Continuous" ), p, v, n, last, c
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      last := IIf( Len( l[ "elements" ] ) > 0, ATail( l[ "elements" ] ), NIL )
      c := IIf( last != NIL, last[ "complex" ], NIL )
      DO CASE
      CASE n == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; l[ "handle" ] := v ; ENDIF
      CASE n == 2 ; l[ "name" ] := p[ DP_VALUE ]
      CASE n == 3 ; l[ "description" ] := p[ DP_VALUE ]
      CASE n == 70
         v := Dp_AsI16( p ) ; IF v != NIL ; l[ "xref_dependent" ] := hb_bitAnd( v, 16 ) != 0 ; ENDIF
      CASE n == 73 /* reserve: sin efecto observable */
      CASE n == 40
         v := Dp_AsDouble( p ) ; IF v != NIL ; l[ "pattern_length" ] := v ; ENDIF
      CASE n == 49
         v := Dp_AsDouble( p ) ; IF v != NIL ; AAdd( l[ "elements" ], hb_Hash( "length", v, "complex", NIL ) ) ; ENDIF
      CASE n == 9
         IF last != NIL .AND. c != NIL ; Ltc_SetText( c, p[ DP_VALUE ] ) ; ENDIF
      CASE n == 44
         v := Dp_AsDouble( p ) ; IF c != NIL .AND. v != NIL ; c[ "offset" ][ 1 ] := v ; ENDIF
      CASE n == 45
         v := Dp_AsDouble( p ) ; IF c != NIL .AND. v != NIL ; c[ "offset" ][ 2 ] := v ; ENDIF
      CASE n == 46
         IF c != NIL ; c[ "scale" ] := Sr_Str2Num( p[ DP_VALUE ], 1.0 ) ; ENDIF
      CASE n == 50
         IF c != NIL ; c[ "rotation" ] := Sr_Deg( Sr_Str2Num( p[ DP_VALUE ], 0.0 ) ) ; ENDIF
      CASE n == 74
         v := Dp_AsI16( p )
         IF last != NIL .AND. v != NIL .AND. v != 0 ; Ltc_ApplyDxfFlags( Lte_ComplexMut( last ), v ) ; ENDIF
      CASE n == 75
         IF c != NIL
            v := Dp_AsI16( p ) ; Ltc_SetShapeNumber( c, IIf( v == NIL, 0, v ) )
         ENDIF
      CASE n == 340
         v := Sr_HexVal( p ) ; IF c != NIL .AND. v != NIL ; c[ "style_handle" ] := v ; ENDIF
      ENDCASE
   ENDDO
RETURN l

STATIC FUNCTION Sr_StyleEntry( s )
   LOCAL st := Tst_New( "Standard" ), p, v, n, x, rec, i, aV, nLast, cFace
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; st[ "handle" ] := v ; ENDIF
      CASE n == 2 ; st[ "name" ] := p[ DP_VALUE ]
      CASE n == 70
         v := Dp_AsI16( p )
         IF v != NIL
            st[ "is_shape_file" ] := hb_bitAnd( v, 1 ) != 0
            st[ "is_vertical" ] := hb_bitAnd( v, 4 ) != 0
            st[ "xref_dependent" ] := hb_bitAnd( v, 16 ) != 0
         ENDIF
      CASE n == 3 ; st[ "font_file" ] := p[ DP_VALUE ]
      CASE n == 4 ; st[ "big_font_file" ] := p[ DP_VALUE ]
      CASE n == 40
         v := Dp_AsDouble( p ) ; IF v != NIL ; st[ "height" ] := v ; ENDIF
      CASE n == 41
         v := Dp_AsDouble( p ) ; IF v != NIL ; st[ "width_factor" ] := v ; ENDIF
      CASE n == 50
         v := Dp_AsDouble( p ) ; IF v != NIL ; st[ "oblique_angle" ] := Sr_Deg( v ) ; ENDIF
      CASE n == 71
         v := Dp_AsI16( p )
         IF v != NIL
            st[ "flags" ][ "backward" ] := hb_bitAnd( v, 2 ) != 0
            st[ "flags" ][ "upside_down" ] := hb_bitAnd( v, 4 ) != 0
         ENDIF
      CASE n == 42
         v := Dp_AsDouble( p ) ; IF v != NIL ; st[ "last_height" ] := v ; ENDIF
      CASE n == 1001
         x := Sr_XDataFrom( s, p )
         rec := Xd_GetRecord( x, "AcadAnnotative" )
         IF rec != NIL
            aV := Xr_Values( rec ) ; nLast := NIL
            FOR i := 1 TO Len( aV )
               IF aV[ i ][ 1 ] == XV_INTEGER16 ; nLast := aV[ i ][ 2 ] ; ENDIF
            NEXT
            st[ "annotative" ] := ( nLast != NIL .AND. nLast != 0 )
         ENDIF
         rec := Xd_GetRecord( x, "ACAD" )
         IF rec != NIL
            cFace := NIL
            FOR EACH v IN Xr_Values( rec )
               IF v[ 1 ] == XV_STRING ; cFace := v[ 2 ] ; EXIT ; ENDIF
            NEXT
            IF cFace != NIL ; st[ "true_type_font" ] := cFace ; ENDIF
         ENDIF
      ENDCASE
   ENDDO
RETURN st

STATIC FUNCTION Sr_AppIdEntry( s )
   LOCAL a := Aid_New( "ACAD" ), p, v
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; a[ "handle" ] := v ; ENDIF
      ELSEIF p[ DP_CODE ] == 2
         a[ "name" ] := p[ DP_VALUE ]
      ENDIF
   ENDDO
RETURN a

/* Parte de read_block_record_entry: sin xdata de DesignCenter extra ni 310 (preview): PENDIENTE */
STATIC FUNCTION Sr_BlockRecordEntry( s, aReactors )
   LOCAL br := Blk_New( "*Model_Space" ), p, v, n, cGroup := "", lUnitsSeen := .F., aDc := NIL
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 1001 ; aDc := NIL
      CASE n == 1000 .AND. p[ DP_VALUE ] == "DesignCenter Data" ; aDc := {}
      CASE n == 1070
         v := Dp_AsI16( p )
         IF aDc != NIL .AND. v != NIL
            AAdd( aDc, v )
            IF Len( aDc ) == 2 .AND. ! lUnitsSeen ; br[ "units" ] := v ; ENDIF
         ENDIF
      CASE n == 70 ; lUnitsSeen := .T.
      ENDCASE
      DO CASE
      CASE n == 102 ; cGroup := IIf( Left( p[ DP_VALUE ], 1 ) == "{", p[ DP_VALUE ], "" )
      CASE n == 330 .AND. cGroup == "{ACAD_REACTORS"
         v := Sr_HexVal( p ) ; IF v != NIL ; AAdd( aReactors, v ) ; ENDIF
      CASE n == 331 .AND. cGroup == "{BLKREFS"
         v := Sr_HexVal( p ) ; IF v != NIL ; AAdd( br[ "insert_handles" ], v ) ; ENDIF
      CASE n == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; br[ "handle" ] := v ; ENDIF
      CASE n == 2 ; br[ "name" ] := p[ DP_VALUE ]
      CASE n == 70
         v := Dp_AsI16( p ) ; IF v != NIL ; br[ "units" ] := v ; ENDIF
      CASE n == 280
         v := Dp_AsI16( p ) ; IF v != NIL ; br[ "explodable" ] := ( v != 0 ) ; ENDIF
      CASE n == 281
         v := Dp_AsI16( p ) ; IF v != NIL ; br[ "scale_uniformly" ] := ( v != 0 ) ; ENDIF
      CASE n == 340
         v := Sr_HexVal( p ) ; IF v != NIL ; br[ "layout" ] := v ; ENDIF
      ENDCASE
   ENDDO
RETURN br

PROCEDURE Sr_ReadBlockRecordTable( s, d )
   LOCAL hdr := d[ "header" ], t := d[ "block_records" ], p, h, br, aRe, ex, oldM := hdr[ "model_space_block_handle" ], oldP := hdr[ "paper_space_block_handle" ], o, k
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "ENDTAB" ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 5
         h := Sr_HexVal( p )
         IF h != NIL ; Tb_SetHandle( t, h ) ; hdr[ "block_control_handle" ] := h ; ENDIF
      ELSEIF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "BLOCK_RECORD"
         aRe := {}
         br := Sr_BlockRecordEntry( s, aRe )
         IF Len( aRe ) > 0 .AND. ! Hd_IsNull( br[ "handle" ] ) ; d[ "reactors_by_handle" ][ br[ "handle" ] ] := aRe ; ENDIF
         IF Tb_Add( t, Ent_Clone( br ) ) != NIL
            ex := Tb_Get( t, br[ "name" ] )
            IF ex != NIL
               IF ! Hd_IsNull( br[ "handle" ] ) ; ex[ "handle" ] := br[ "handle" ] ; ENDIF
               IF ! Hd_IsNull( br[ "layout" ] ) ; ex[ "layout" ] := br[ "layout" ] ; ENDIF
               ex[ "insert_handles" ] := Ent_Clone( br[ "insert_handles" ] )
               ex[ "units" ] := br[ "units" ]
               ex[ "flags" ] := Ent_Clone( br[ "flags" ] )
            ENDIF
         ENDIF
      ENDIF
   ENDDO
   br := Tb_Get( t, "*Model_Space" )
   IF br != NIL .AND. ! Hd_IsNull( br[ "handle" ] ) ; hdr[ "model_space_block_handle" ] := br[ "handle" ] ; ENDIF
   br := Tb_Get( t, "*Paper_Space" )
   IF br != NIL .AND. ! Hd_IsNull( br[ "handle" ] ) ; hdr[ "paper_space_block_handle" ] := br[ "handle" ] ; ENDIF
   IF oldM != hdr[ "model_space_block_handle" ] .OR. oldP != hdr[ "paper_space_block_handle" ]
      FOR EACH k IN hb_HKeys( d[ "objects" ] )
         o := d[ "objects" ][ k ]
         IF hb_HGetDef( o, "_type", "" ) == "Layout"
            IF o[ "block_record" ] == oldM
               o[ "block_record" ] := hdr[ "model_space_block_handle" ]
            ELSEIF o[ "block_record" ] == oldP
               o[ "block_record" ] := hdr[ "paper_space_block_handle" ]
            ENDIF
         ENDIF
      NEXT
   ENDIF
RETURN

STATIC PROCEDURE Sr_SkipToEndTab( s )
   LOCAL p
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "ENDTAB" ; EXIT ; ENDIF
   ENDDO
RETURN

PROCEDURE Sr_ReadTables( s, d )
   LOCAL pair, np, cN
   DO WHILE ( pair := Sr_Next( s ) ) != NIL
      IF pair[ DP_CODE ] == 0 .AND. pair[ DP_VALUE ] == "ENDSEC" ; EXIT ; ENDIF
      IF pair[ DP_CODE ] == 0 .AND. pair[ DP_VALUE ] == "TABLE"
         np := Sr_Next( s )
         IF np != NIL .AND. np[ DP_CODE ] == 2
            cN := np[ DP_VALUE ]
            DO CASE
            CASE cN == "LAYER" ; Sr_ReadLayerTable( s, d )
            CASE cN == "LTYPE" ; Sr_TableGeneric( s, d, "line_types", "LTYPE", "linetype_control_handle", {|| Sr_LtypeEntry( s ) }, .F. )
            CASE cN == "STYLE" ; Sr_TableGeneric( s, d, "text_styles", "STYLE", "style_control_handle", {|| Sr_StyleEntry( s ) }, .T. )
            CASE cN == "BLOCK_RECORD" ; Sr_ReadBlockRecordTable( s, d )
            CASE cN == "APPID" ; Sr_TableGeneric( s, d, "app_ids", "APPID", "appid_control_handle", {|| Sr_AppIdEntry( s ) }, .F. )
            OTHERWISE ; Sr_SkipToEndTab( s ) /* DIMSTYLE/VIEW/VPORT/UCS: PENDIENTE (se saltan) */
            ENDCASE
         ENDIF
      ENDIF
   ENDDO
RETURN

/* ---- entidades ---- */
/* Lee los codigos comunes basicos (8, 62, 370 y resto via Sr_CommonCode). Devuelve .T. si lo consumio */
STATIC FUNCTION Sr_EntBase( s, p, e )
RETURN Sr_CommonCode( s, p, e[ "common" ] )

STATIC FUNCTION Sr_ReadPoint( s )
   LOCAL e := Ept_New(), loc := PR_New(), nor := PR_New(), p, v, n, pt
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( loc, p )
      CASE n == 39
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "thickness" ] := v ; ENDIF
      CASE n == 50
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "x_axis_angle" ] := v ; ENDIF
      CASE n == 210 .OR. n == 220 .OR. n == 230 ; PR_AddCoordinate( nor, p )
      OTHERWISE ; Sr_EntBase( s, p, e )
      ENDCASE
   ENDDO
   pt := PR_GetPoint( loc ) ; IF pt != NIL ; e[ "location" ] := pt ; ENDIF
   pt := PR_GetPoint( nor ) ; IF pt != NIL ; e[ "normal" ] := pt ; ENDIF
RETURN e

STATIC FUNCTION Sr_ReadLine( s )
   LOCAL e := Eln_New(), st := PR_New(), en := PR_New(), nor := PR_New(), p, v, n, pt
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( st, p )
      CASE n == 11 .OR. n == 21 .OR. n == 31 ; PR_AddCoordinate( en, p )
      CASE n == 39
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "thickness" ] := v ; ENDIF
      CASE n == 210 .OR. n == 220 .OR. n == 230 ; PR_AddCoordinate( nor, p )
      OTHERWISE ; Sr_EntBase( s, p, e )
      ENDCASE
   ENDDO
   pt := PR_GetPoint( st ) ; IF pt != NIL ; e[ "start" ] := pt ; ENDIF
   pt := PR_GetPoint( en ) ; IF pt != NIL ; e[ "end" ] := pt ; ENDIF
   pt := PR_GetPoint( nor ) ; IF pt != NIL ; e[ "normal" ] := pt ; ENDIF
RETURN e

STATIC FUNCTION Sr_ReadCircArc( s, lArc )
   LOCAL e := IIf( lArc, Ear_New(), Eci_New() ), c := PR_New(), nor := PR_New(), p, v, n, pt
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( c, p )
      CASE n == 40
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "radius" ] := v ; ENDIF
      CASE n == 50 .AND. lArc
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "start_angle" ] := Sr_Deg( v ) ; ENDIF
      CASE n == 51 .AND. lArc
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "end_angle" ] := Sr_Deg( v ) ; ENDIF
      CASE n == 39
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "thickness" ] := v ; ENDIF
      CASE n == 210 .OR. n == 220 .OR. n == 230 ; PR_AddCoordinate( nor, p )
      OTHERWISE ; Sr_EntBase( s, p, e )
      ENDCASE
   ENDDO
   pt := PR_GetPoint( c ) ; IF pt != NIL ; e[ "center" ] := pt ; ENDIF
   pt := PR_GetPoint( nor ) ; IF pt != NIL ; e[ "normal" ] := pt ; ENDIF
RETURN e

STATIC FUNCTION Sr_ReadLwPoly( s )
   LOCAL e := Elw_New(), nor := PR_New(), aV := {}, nX := NIL, p, v, n, pt, last
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      last := IIf( Len( aV ) > 0, ATail( aV ), NIL )
      DO CASE
      CASE n == 70
         v := Dp_AsI16( p )
         IF v != NIL
            e[ "is_closed" ] := hb_bitAnd( v, 1 ) != 0
            e[ "plinegen" ] := hb_bitAnd( v, 128 ) != 0
         ENDIF
      CASE n == 38
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "elevation" ] := v ; ENDIF
      CASE n == 39
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "thickness" ] := v ; ENDIF
      CASE n == 43
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "constant_width" ] := v ; ENDIF
      CASE n == 10
         v := Dp_AsDouble( p ) ; IF v != NIL ; nX := v ; ENDIF
      CASE n == 20
         v := Dp_AsDouble( p )
         IF nX != NIL .AND. v != NIL
            AAdd( aV, Elv_FromCoords( nX, v ) )
         ENDIF
         nX := NIL
      CASE n == 42
         v := Dp_AsDouble( p ) ; IF last != NIL .AND. v != NIL ; last[ "bulge" ] := v ; ENDIF
      CASE n == 91
         v := Dp_AsI32( p ) ; IF last != NIL .AND. v != NIL ; last[ "vertex_id" ] := v ; ENDIF
      CASE n == 40
         v := Dp_AsDouble( p ) ; IF last != NIL .AND. v != NIL ; last[ "start_width" ] := v ; ENDIF
      CASE n == 41
         v := Dp_AsDouble( p ) ; IF last != NIL .AND. v != NIL ; last[ "end_width" ] := v ; ENDIF
      CASE n == 210 .OR. n == 220 .OR. n == 230 ; PR_AddCoordinate( nor, p )
      OTHERWISE ; Sr_EntBase( s, p, e )
      ENDCASE
   ENDDO
   e[ "vertices" ] := aV
   pt := PR_GetPoint( nor ) ; IF pt != NIL ; e[ "normal" ] := pt ; ENDIF
RETURN e

STATIC FUNCTION Sr_ReadText( s )
   LOCAL e := Etx_New(), ins := PR_New(), al := PR_New(), nor := PR_New(), lAl := .F., p, v, n, pt
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( ins, p )
      CASE n == 11 .OR. n == 21 .OR. n == 31 ; PR_AddCoordinate( al, p ) ; lAl := .T.
      CASE n == 1 ; e[ "value" ] := p[ DP_VALUE ]
      CASE n == 40
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "height" ] := v ; ENDIF
      CASE n == 50
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "rotation" ] := Sr_Deg( v ) ; ENDIF
      CASE n == 41
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "width_factor" ] := v ; ENDIF
      CASE n == 51
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "oblique_angle" ] := Sr_Deg( v ) ; ENDIF
      CASE n == 39
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "thickness" ] := v ; ENDIF
      CASE n == 71
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "generation_flags" ] := v ; ENDIF
      CASE n == 72
         v := Dp_AsI16( p )
         IF v != NIL
            e[ "horizontal_alignment" ] := IIf( v >= 1 .AND. v <= 5, v, TXH_LEFT )
         ENDIF
      CASE n == 73
         v := Dp_AsI16( p )
         IF v != NIL
            e[ "vertical_alignment" ] := IIf( v >= 1 .AND. v <= 3, v, TXV_BASELINE )
         ENDIF
      CASE n == 7 ; e[ "style" ] := p[ DP_VALUE ]
      CASE n == 210 .OR. n == 220 .OR. n == 230 ; PR_AddCoordinate( nor, p )
      OTHERWISE ; Sr_EntBase( s, p, e )
      ENDCASE
   ENDDO
   pt := PR_GetPoint( ins ) ; IF pt != NIL ; e[ "insertion_point" ] := pt ; ENDIF
   IF lAl ; e[ "alignment_point" ] := PR_GetPoint( al ) ; ENDIF
   pt := PR_GetPoint( nor ) ; IF pt != NIL ; e[ "normal" ] := pt ; ENDIF
RETURN e

STATIC FUNCTION Sr_ReadInsert( s )
   LOCAL e, ins := PR_New(), nor := PR_New(), cBlk := "", nSx := 1.0, nSy := 1.0, nSz := 1.0, nRot := 0.0, nCols := 1, nRows := 1, ;
         nCsp := 0.0, nRsp := 0.0, lAtt := .F., lVr := .F., hVr := NIL, c := Ec_New(), p, v, n, pt, cEn
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 100 ; lVr := Lower( AllTrim( p[ DP_VALUE ] ) ) == "acdbviewrepblockreference"
      CASE n == 330 .AND. lVr ; hVr := Sr_HexVal( p )
      CASE n == 2 ; cBlk := p[ DP_VALUE ]
      CASE n == 66 ; lAtt := ( Dp_AsI16( p ) != NIL .AND. Dp_AsI16( p ) == 1 )
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( ins, p )
      CASE n == 41
         v := Dp_AsDouble( p ) ; IF v != NIL ; nSx := v ; ENDIF
      CASE n == 42
         v := Dp_AsDouble( p ) ; IF v != NIL ; nSy := v ; ENDIF
      CASE n == 43
         v := Dp_AsDouble( p ) ; IF v != NIL ; nSz := v ; ENDIF
      CASE n == 50
         v := Dp_AsDouble( p ) ; IF v != NIL ; nRot := Sr_Deg( v ) ; ENDIF
      CASE n == 70
         v := Dp_AsI16( p ) ; IF v != NIL ; nCols := Max( v, 1 ) ; ENDIF
      CASE n == 71
         v := Dp_AsI16( p ) ; IF v != NIL ; nRows := Max( v, 1 ) ; ENDIF
      CASE n == 44
         v := Dp_AsDouble( p ) ; IF v != NIL ; nCsp := v ; ENDIF
      CASE n == 45
         v := Dp_AsDouble( p ) ; IF v != NIL ; nRsp := v ; ENDIF
      CASE n == 210 .OR. n == 220 .OR. n == 230 ; PR_AddCoordinate( nor, p )
      OTHERWISE ; Sr_CommonCode( s, p, c )
      ENDCASE
   ENDDO
   pt := PR_GetPoint( ins )
   e := Ein_New( cBlk, IIf( pt == NIL, Vc3_Zero(), pt ) )
   e[ "common" ] := c
   Ein_SetXScale( e, nSx ) ; Ein_SetYScale( e, nSy ) ; Ein_SetZScale( e, nSz )
   e[ "rotation" ] := nRot ; e[ "column_count" ] := nCols ; e[ "row_count" ] := nRows
   e[ "column_spacing" ] := nCsp ; e[ "row_spacing" ] := nRsp ; e[ "view_rep_handle" ] := hVr
   pt := PR_GetPoint( nor ) ; IF pt != NIL ; e[ "normal" ] := pt ; ENDIF
   IF lAtt
      DO WHILE ( p := Sr_Next( s ) ) != NIL
         IF p[ DP_CODE ] == 0
            cEn := Upper( AllTrim( p[ DP_VALUE ] ) )
            IF cEn == "ATTRIB"
               AAdd( e[ "attributes" ], Sr_ReadAttdefAttrib( s, .F. ) )
               LOOP
            ELSEIF cEn == "SEQEND"
               Sr_SkipEntity( s )
            ELSE
               Sr_PushBack( s, p )
            ENDIF
            EXIT
         ENDIF
         Sr_PushBack( s, p ) ; EXIT
      ENDDO
   ENDIF
RETURN e

/* Despacha un tipo de entidad ya leido (par 0). Devuelve entidad o NIL (y salta lo desconocido) */
/* Cuenta "\P" (matches("\P") del original) */
STATIC FUNCTION Sr_CountP( c )
   LOCAL n := 0, i := 1, k
   DO WHILE ( k := hb_At( "\P", c, i ) ) > 0
      n++ ; i := k + 2
   ENDDO
RETURN n

/* read_attdef (lDef=.T.) / read_attrib (lDef=.F.). El MTEXT embebido (101, R2018+) se consume
   pero no se interpreta: PENDIENTE (read_attrib_embedded_mtext). */
STATIC FUNCTION Sr_ReadAttdefAttrib( s, lDef )
   LOCAL e := IIf( lDef, Ead_New( "", "", "" ), Eat_New( "", "" ) ), ip := PR_New(), al := PR_New(), nor := PR_New()
   LOCAL p, v, n, pt, lSub := .F., lSeen := .F., cV := IIf( lDef, "default_value", "value" ), lEmb := .F.
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 100
         IF p[ DP_VALUE ] == IIf( lDef, "AcDbAttributeDefinition", "AcDbAttribute" ) ; lSub := .T. ; ENDIF
      CASE n == 1 ; e[ cV ] := p[ DP_VALUE ]
      CASE n == 2 ; e[ "tag" ] := p[ DP_VALUE ] ; lSeen := .T.
      CASE ( n == 11 .OR. n == 21 .OR. n == 31 .OR. n == 72 ) .AND. lSub
         IF n == 72 .AND. Dp_AsI16( p ) != NIL
            e[ "horizontal_alignment" ] := Ha_FromValue( Dp_AsI16( p ) )
         ENDIF
      CASE n == 3 .AND. lDef ; e[ "prompt" ] := p[ DP_VALUE ]
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( ip, p )
      CASE n == 7 ; e[ "text_style" ] := p[ DP_VALUE ]
      CASE n == 11 .OR. n == 21 .OR. n == 31 ; PR_AddCoordinate( al, p )
      CASE ( n == 210 .OR. n == 220 .OR. n == 230 ) .AND. lDef ; PR_AddCoordinate( nor, p )
      CASE n == 41
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "width_factor" ] := v ; ENDIF
      CASE n == 51
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "oblique_angle" ] := Sr_Deg( v ) ; ENDIF
      CASE n == 70
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "flags" ] := Taf_FromBits( v ) ; ENDIF
      CASE n == 71
         v := Dp_AsI16( p )
         IF v != NIL
            IF lSub
               e[ "mtext_flag" ] := IIf( lDef, Mtf_FromValue( v ), IIf( v == 2, MTF_MULTILINE, IIf( v == 4, MTF_CONSTANTMULTILINE, MTF_SINGLELINE ) ) )
               IF ! lDef ; e[ "is_multiline" ] := ( e[ "mtext_flag" ] != MTF_SINGLELINE ) ; ENDIF
            ELSE
               e[ "text_generation_flags" ] := v
            ENDIF
         ENDIF
      CASE n == 72
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "horizontal_alignment" ] := Ha_FromValue( v ) ; ENDIF
      CASE n == 73 .AND. lDef
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "field_length" ] := v ; ENDIF
      CASE n == 74
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "vertical_alignment" ] := Va_FromValue( v ) ; ENDIF
      CASE n == 40
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "height" ] := v ; ENDIF
      CASE n == 50
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "rotation" ] := Sr_Deg( v ) ; ENDIF
      CASE n == 280
         IF lSeen
            v := Dp_AsI16( p ) ; IF v != NIL ; e[ "lock_position" ] := ( v != 0 ) ; ENDIF
         ENDIF
      CASE n == 101
         lEmb := .T.
         DO WHILE ( p := Sr_Next( s ) ) != NIL
            IF p[ DP_CODE ] == 0 .OR. p[ DP_CODE ] >= 1000 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
         ENDDO
      OTHERWISE ; Sr_EntBase( s, p, e )
      ENDCASE
   ENDDO
   pt := PR_GetPoint( ip ) ; e[ "insertion_point" ] := IIf( pt != NIL, pt, Vc3_Zero() )
   pt := PR_GetPoint( al ) ; IF pt != NIL .OR. ! lDef ; e[ "alignment_point" ] := IIf( pt != NIL, pt, Vc3_Zero() ) ; ENDIF
   IF lDef
      pt := PR_GetPoint( nor ) ; IF pt != NIL ; e[ "normal" ] := pt ; ENDIF
      e[ "is_multiline" ] := ( e[ "mtext_flag" ] != MTF_SINGLELINE .OR. lEmb )
   ELSEIF lEmb
      e[ "is_multiline" ] := .T.
   ENDIF
   e[ "line_count" ] := Sr_CountP( e[ cV ] ) + 1
RETURN e

/* true_color_bits: acepta ambas grafias (con o sin signo); NIL si no es entero de 32 bits */
STATIC FUNCTION Sr_TrueColorBits( c )
   LOCAL n
   c := AllTrim( c )
   IF Len( c ) == 0 .OR. ! hb_RegexLike( "^[+-]?[0-9]+$", c ) ; RETURN NIL ; ENDIF
   n := Val( c )
   IF n >= -2147483648 .AND. n <= 2147483647 ; RETURN n ; ENDIF
   IF n >= 0 .AND. n <= 4294967295 ; RETURN n - 4294967296 ; ENDIF
RETURN NIL

/* read_mtext_embedded_object (R2018+): codigos 71-74/44-46 -> Mcd */
STATIC FUNCTION Sr_ReadMtextEmbedded( s )
   LOCAL col := Mcd_New(), p, v, n
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 .OR. p[ DP_CODE ] >= 1000 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 71 ; v := Dp_AsI16( p ) ; IF v != NIL ; col[ "column_type" ] := v ; ENDIF
      CASE n == 72 ; v := Dp_AsI16( p ) ; IF v != NIL ; col[ "column_count" ] := v ; ENDIF
      CASE n == 73 ; v := Dp_AsI16( p ) ; IF v != NIL ; col[ "auto_height" ] := ( v != 0 ) ; ENDIF
      CASE n == 74 ; v := Dp_AsI16( p ) ; IF v != NIL ; col[ "flow_reversed" ] := ( v != 0 ) ; ENDIF
      CASE n == 44 ; v := Dp_AsDouble( p ) ; IF v != NIL ; col[ "width" ] := v ; ENDIF
      CASE n == 45 ; v := Dp_AsDouble( p ) ; IF v != NIL ; col[ "gutter" ] := v ; ENDIF
      CASE n == 46 ; v := Dp_AsDouble( p ) ; IF v != NIL ; AAdd( col[ "heights" ], v ) ; ENDIF
      ENDCASE
   ENDDO
RETURN col

STATIC FUNCTION Sr_ReadMText( s )
   LOCAL e := Emt_New(), ins := PR_New(), nor := PR_New(), xd := PR_New(), p, v, n, pt, lCol := .F., col, cv
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( ins, p )
      CASE n == 1 .OR. n == 3 ; e[ "value" ] += p[ DP_VALUE ]
      CASE n == 40 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "height" ] := v ; ENDIF
      CASE n == 41 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "rectangle_width" ] := v ; ENDIF
      CASE n == 42 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "extents_width" ] := v ; ENDIF
      CASE n == 43 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "extents_height" ] := v ; ENDIF
      CASE n == 50
         v := Dp_AsDouble( p )
         IF v != NIL
            IF lCol
               col := e[ "column_data" ]
               IF col[ "column_type" ] == 2 .AND. ! col[ "auto_height" ] .AND. Len( col[ "heights" ] ) < Max( col[ "column_count" ], 0 )
                  AAdd( col[ "heights" ], v )
               ENDIF
            ELSE
               e[ "rotation" ] := Sr_Deg( v )
            ENDIF
         ENDIF
      CASE n == 71
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "attachment_point" ] := IIf( v >= 2 .AND. v <= 9, v, MTA_TOPLEFT ) ; ENDIF
      CASE n == 72
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "drawing_direction" ] := IIf( v == 3 .OR. v == 5, v, MTD_LEFTTORIGHT ) ; ENDIF
      CASE n == 44 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "line_spacing_factor" ] := v ; ENDIF
      CASE n == 75
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "column_data" ][ "column_type" ] := v ; lCol := ( v != 0 ) ; ENDIF
      CASE n == 76 .AND. lCol
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "column_data" ][ "column_count" ] := v ; ENDIF
      CASE n == 78 .AND. lCol
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "column_data" ][ "flow_reversed" ] := ( v != 0 ) ; ENDIF
      CASE n == 79 .AND. lCol
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "column_data" ][ "auto_height" ] := ( v != 0 ) ; ENDIF
      CASE n == 48 .AND. lCol ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "column_data" ][ "width" ] := v ; ENDIF
      CASE n == 49 .AND. lCol ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "column_data" ][ "gutter" ] := v ; ENDIF
      CASE n == 73
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "line_spacing_style" ] := Lss_From( v ) ; ENDIF
      CASE n == 7 ; e[ "style" ] := p[ DP_VALUE ]
      CASE n == 11 .OR. n == 21 .OR. n == 31 ; PR_AddCoordinate( xd, p )
      CASE n == 46
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "rectangle_height" ] := IIf( v != 0.0, v, NIL ) ; ENDIF
      CASE n == 90 ; v := Dp_AsI32( p ) ; IF v != NIL ; e[ "background_fill_flags" ] := v ; ENDIF
      CASE n == 45 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "background_scale" ] := v ; ENDIF
      CASE n == 63
         cv := AllTrim( p[ DP_VALUE ] )
         IF hb_RegexLike( "^[+-]?[0-9]+$", cv ) ; e[ "background_color" ] := Cl_FromIndex( Val( cv ) ) ; ENDIF
      CASE n == 421
         v := Sr_TrueColorBits( p[ DP_VALUE ] ) ; IF v != NIL ; e[ "background_color" ] := Cl_FromTrueColorValue( v ) ; ENDIF
      CASE n == 441 ; v := Dp_AsI32( p ) ; IF v != NIL ; e[ "background_transparency" ] := v ; ENDIF
      CASE n == 210 .OR. n == 220 .OR. n == 230 ; PR_AddCoordinate( nor, p )
      CASE n == 101
         e[ "column_data" ] := Sr_ReadMtextEmbedded( s ) ; lCol := .F.
      OTHERWISE ; Sr_EntBase( s, p, e )
      ENDCASE
   ENDDO
   pt := PR_GetPoint( ins ) ; IF pt != NIL ; e[ "insertion_point" ] := pt ; ENDIF
   pt := PR_GetPoint( nor ) ; IF pt != NIL ; e[ "normal" ] := pt ; ENDIF
   pt := PR_GetPoint( xd )
   IF pt != NIL .AND. ( pt[ 1 ] != 0.0 .OR. pt[ 2 ] != 0.0 ) ; e[ "rotation" ] := OCX_ATAN2( pt[ 2 ], pt[ 1 ] ) ; ENDIF
RETURN e

STATIC FUNCTION Sr_ReadSpline( s )
   LOCAL e := Esp_New(), nor := PR_New(), cp := PR_New(), fp := PR_New(), bt := PR_New(), et := PR_New(), p, v, n, pt, lC := .F., lF := .F.
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 70 ; v := Dp_AsI16( p ) ; IF v != NIL ; Spf_Read( e, v ) ; ENDIF
      CASE n == 71 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "degree" ] := v ; ENDIF
      CASE n == 40 ; v := Dp_AsDouble( p ) ; IF v != NIL ; AAdd( e[ "knots" ], v ) ; ENDIF
      CASE n == 41 ; v := Dp_AsDouble( p ) ; IF v != NIL ; AAdd( e[ "weights" ], v ) ; ENDIF
      CASE n == 42 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "knot_tolerance" ] := v ; ENDIF
      CASE n == 43 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "control_tolerance" ] := v ; ENDIF
      CASE n == 44 ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "fit_tolerance" ] := v ; ENDIF
      CASE n == 12 .OR. n == 22 .OR. n == 32 ; PR_AddCoordinate( bt, p )
      CASE n == 13 .OR. n == 23 .OR. n == 33 ; PR_AddCoordinate( et, p )
      CASE n == 10 .OR. n == 20 .OR. n == 30
         IF n == 10
            IF lC
               pt := PR_GetPoint( cp ) ; IF pt != NIL ; AAdd( e[ "control_points" ], pt ) ; ENDIF
            ENDIF
            cp := PR_New() ; lC := .T.
         ENDIF
         PR_AddCoordinate( cp, p )
      CASE n == 11 .OR. n == 21 .OR. n == 31
         IF n == 11
            IF lF
               pt := PR_GetPoint( fp ) ; IF pt != NIL ; AAdd( e[ "fit_points" ], pt ) ; ENDIF
            ENDIF
            fp := PR_New() ; lF := .T.
         ENDIF
         PR_AddCoordinate( fp, p )
      CASE n == 210 .OR. n == 220 .OR. n == 230 ; PR_AddCoordinate( nor, p )
      OTHERWISE ; Sr_EntBase( s, p, e )
      ENDCASE
   ENDDO
   IF lC
      pt := PR_GetPoint( cp ) ; IF pt != NIL ; AAdd( e[ "control_points" ], pt ) ; ENDIF
   ENDIF
   IF lF
      pt := PR_GetPoint( fp ) ; IF pt != NIL ; AAdd( e[ "fit_points" ], pt ) ; ENDIF
   ENDIF
   pt := PR_GetPoint( nor ) ; IF pt != NIL ; e[ "normal" ] := pt ; ENDIF
   pt := PR_GetPoint( bt ) ; IF pt != NIL ; e[ "begin_tangent" ] := pt ; ENDIF
   pt := PR_GetPoint( et ) ; IF pt != NIL ; e[ "end_tangent" ] := pt ; ENDIF
RETURN e

/* read_polyline_entity: POLYLINE segun flags (70): 64 polyface, 16 malla poligonal, 8 3D, resto 2D.
   Mascaras = bits conocidos de bitflags (from_bits_truncate) del original. */
STATIC FUNCTION Sr_ReadPolyline( s )
   LOCAL com := Ec_New(), nFl := 0, nElev := 0.0, nTh := 0.0, nSw := 0.0, nEw := 0.0, nM := 0, nN := 0, nDm := 0, nDn := 0, nSm := 0
   LOCAL nor := PR_New(), aGeom := {}, aPv := {}, aPf := {}, p, v, n, vp, e, g, lHs, lHe, lAny, vtx
   LOCAL vl, vf, vsw, vew, vb, vt, v1, v2, v3, v4, vc, vh, vly, vh2
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0
         IF p[ DP_VALUE ] == "VERTEX"
            vl := Vc3_Zero() ; vf := 0 ; vsw := 0.0 ; vew := 0.0 ; lHs := .F. ; lHe := .F. ; vb := 0.0 ; vt := 0.0
            v1 := 0 ; v2 := 0 ; v3 := 0 ; v4 := 0 ; vc := NIL ; vh := 0 ; vly := "0"
            DO WHILE ( vp := Sr_Next( s ) ) != NIL
               IF vp[ DP_CODE ] == 0 ; Sr_PushBack( s, vp ) ; EXIT ; ENDIF
               n := vp[ DP_CODE ]
               DO CASE
               CASE n == 5 ; v := Sr_HexVal( vp ) ; IF v != NIL ; vh := v ; ENDIF
               CASE n == 8 ; vly := vp[ DP_VALUE ]
               CASE n == 10 ; v := Dp_AsDouble( vp ) ; IF v != NIL ; vl := Vc3_New( v, vl[ 2 ], vl[ 3 ] ) ; ENDIF
               CASE n == 20 ; v := Dp_AsDouble( vp ) ; IF v != NIL ; vl := Vc3_New( vl[ 1 ], v, vl[ 3 ] ) ; ENDIF
               CASE n == 30 ; v := Dp_AsDouble( vp ) ; IF v != NIL ; vl := Vc3_New( vl[ 1 ], vl[ 2 ], v ) ; ENDIF
               CASE n == 40 ; v := Dp_AsDouble( vp ) ; IF v != NIL ; vsw := v ; lHs := .T. ; ENDIF
               CASE n == 41 ; v := Dp_AsDouble( vp ) ; IF v != NIL ; vew := v ; lHe := .T. ; ENDIF
               CASE n == 42 ; v := Dp_AsDouble( vp ) ; IF v != NIL ; vb := v ; ENDIF
               CASE n == 50 ; v := Dp_AsDouble( vp ) ; IF v != NIL ; vt := Sr_Deg( v ) ; ENDIF
               CASE n == 62 ; v := Dp_AsI16( vp ) ; IF v != NIL ; vc := Cl_FromIndex( v ) ; ENDIF
               CASE n == 420 ; v := Dp_AsI32Bits( vp ) ; IF v != NIL ; vc := Cl_FromTrueColorValue( v ) ; ENDIF
               CASE n == 70 ; v := Dp_AsI16( vp ) ; IF v != NIL ; vf := v ; ENDIF
               CASE n == 71 ; v := Dp_AsI16( vp ) ; IF v != NIL ; v1 := v ; ENDIF
               CASE n == 72 ; v := Dp_AsI16( vp ) ; IF v != NIL ; v2 := v ; ENDIF
               CASE n == 73 ; v := Dp_AsI16( vp ) ; IF v != NIL ; v3 := v ; ENDIF
               CASE n == 74 ; v := Dp_AsI16( vp ) ; IF v != NIL ; v4 := v ; ENDIF
               ENDCASE
            ENDDO
            vh2 := vh
            IF hb_bitAnd( vf, 64 ) != 0
               vtx := Pfv_New( vl ) ; vtx[ "flags" ] := hb_bitAnd( vf, 219 ) ; vtx[ "bulge" ] := 0.0 ; AAdd( aPv, vtx )
            ELSEIF hb_bitAnd( vf, 128 ) != 0
               vtx := Pff_Quad( v1, v2, v3, v4 ) ; vtx[ "flags" ] := hb_bitAnd( vf, 219 ) ; vtx[ "color" ] := vc ; AAdd( aPf, vtx )
            ELSE
               AAdd( aGeom, { vl, vf, vsw, vew, lHs, lHe, vb, vt, vh2, vly } )
            ENDIF
         ELSEIF p[ DP_VALUE ] == "SEQEND"
            DO WHILE ( vp := Sr_Next( s ) ) != NIL
               IF vp[ DP_CODE ] == 0 ; Sr_PushBack( s, vp ) ; EXIT ; ENDIF
            ENDDO
            EXIT
         ELSE
            Sr_PushBack( s, p ) ; EXIT
         ENDIF
      ELSE
         n := p[ DP_CODE ]
         DO CASE
         CASE n == 70 ; v := Dp_AsI16( p ) ; IF v != NIL ; nFl := v ; ENDIF
         CASE n == 30 ; v := Dp_AsDouble( p ) ; IF v != NIL ; nElev := v ; ENDIF
         CASE n == 39 ; v := Dp_AsDouble( p ) ; IF v != NIL ; nTh := v ; ENDIF
         CASE n == 40 ; v := Dp_AsDouble( p ) ; IF v != NIL ; nSw := v ; ENDIF
         CASE n == 41 ; v := Dp_AsDouble( p ) ; IF v != NIL ; nEw := v ; ENDIF
         CASE n == 71 ; v := Dp_AsI16( p ) ; IF v != NIL ; nM := v ; ENDIF
         CASE n == 72 ; v := Dp_AsI16( p ) ; IF v != NIL ; nN := v ; ENDIF
         CASE n == 73 ; v := Dp_AsI16( p ) ; IF v != NIL ; nDm := v ; ENDIF
         CASE n == 74 ; v := Dp_AsI16( p ) ; IF v != NIL ; nDn := v ; ENDIF
         CASE n == 75 ; v := Dp_AsI16( p ) ; IF v != NIL ; nSm := v ; ENDIF
         CASE n == 210 .OR. n == 220 .OR. n == 230 ; PR_AddCoordinate( nor, p )
         OTHERWISE ; Sr_CommonCode( s, p, com )
         ENDCASE
      ENDIF
   ENDDO
   vp := PR_GetPoint( nor ) ; IF vp == NIL ; vp := Vc3_UnitZ() ; ENDIF
   IF hb_bitAnd( nFl, 64 ) != 0 .OR. Len( aPv ) > 0 .OR. Len( aPf ) > 0
      e := Epf_New() ; e[ "common" ] := com ; e[ "flags" ] := hb_bitAnd( nFl, 247 ) ; e[ "elevation" ] := nElev
      e[ "vertices" ] := aPv ; e[ "faces" ] := aPf
   ELSEIF hb_bitAnd( nFl, 16 ) != 0
      e := Epm_New() ; e[ "common" ] := com ; e[ "flags" ] := hb_bitAnd( nFl, 183 ) ; e[ "m_vertex_count" ] := nM ; e[ "n_vertex_count" ] := nN
      e[ "m_smooth_density" ] := nDm ; e[ "n_smooth_density" ] := nDn ; e[ "smooth_type" ] := Sst_FromI16( nSm )
      e[ "elevation" ] := nElev ; e[ "normal" ] := vp
      FOR EACH g IN aGeom
         vtx := Pmv_At( g[ 1 ] ) ; vtx[ "flags" ] := g[ 2 ] ; AAdd( e[ "vertices" ], vtx )
      NEXT
   ELSEIF hb_bitAnd( nFl, 8 ) != 0
      e := P3d_New() ; e[ "common" ] := com ; e[ "flags" ] := P3f_FromBits( nFl ) ; e[ "smooth_type" ] := Sst_FromI16( nSm )
      e[ "default_start_width" ] := nSw ; e[ "default_end_width" ] := nEw ; e[ "elevation" ] := nElev ; e[ "normal" ] := vp
      FOR EACH g IN aGeom
         vtx := V3p_New( g[ 1 ] ) ; vtx[ "flags" ] := g[ 2 ] ; vtx[ "handle" ] := g[ 9 ] ; vtx[ "layer" ] := g[ 10 ] ; AAdd( e[ "vertices" ], vtx )
      NEXT
   ELSE
      e := Pl2_New() ; e[ "common" ] := com ; e[ "flags" ] := nFl ; e[ "smooth_surface" ] := Sst_From( nSm ) ; e[ "thickness" ] := nTh
      e[ "elevation" ] := nElev ; e[ "normal" ] := vp ; lAny := .F.
      FOR EACH g IN aGeom
         vtx := Vx2_New( g[ 1 ] ) ; vtx[ "flags" ] := hb_bitAnd( g[ 2 ], 255 )
         vtx[ "start_width" ] := IIf( g[ 5 ], g[ 3 ], nSw ) ; vtx[ "end_width" ] := IIf( g[ 6 ], g[ 4 ], nEw )
         vtx[ "bulge" ] := g[ 7 ] ; vtx[ "curve_tangent" ] := g[ 8 ] ; AAdd( e[ "vertices" ], vtx )
         IF g[ 5 ] .OR. g[ 6 ] ; lAny := .T. ; ENDIF
      NEXT
      IF lAny
         e[ "start_width" ] := 0.0 ; e[ "end_width" ] := 0.0
      ELSE
         e[ "start_width" ] := nSw ; e[ "end_width" ] := nEw
      ENDIF
   ENDIF
RETURN e

STATIC FUNCTION Sr_ReadEllipse( s )
   LOCAL e := Eel_New(), c := PR_New(), ma := PR_New(), nor := PR_New(), p, v, n, pt
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( c, p )
      CASE n == 11 .OR. n == 21 .OR. n == 31 ; PR_AddCoordinate( ma, p )
      CASE n == 40
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "minor_axis_ratio" ] := v ; ENDIF
      CASE n == 41
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "start_parameter" ] := v ; ENDIF
      CASE n == 42
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "end_parameter" ] := v ; ENDIF
      CASE n == 210 .OR. n == 220 .OR. n == 230 ; PR_AddCoordinate( nor, p )
      OTHERWISE ; Sr_EntBase( s, p, e )
      ENDCASE
   ENDDO
   pt := PR_GetPoint( c ) ; IF pt != NIL ; e[ "center" ] := pt ; ENDIF
   pt := PR_GetPoint( ma ) ; IF pt != NIL ; e[ "major_axis" ] := pt ; ENDIF
   pt := PR_GetPoint( nor ) ; IF pt != NIL ; e[ "normal" ] := pt ; ENDIF
RETURN e

/* read_solid (SOLID y TRACE) / read_face3d / read_ray / read_xline. Nota: en el original 8/62/370
   se guardan en variables locales y se vuelcan al final (si 420 dio color verdadero gana sobre 62);
   aqui van directo a common via Sr_CommonCode (difiere solo si 62 llega despues de 420). */
STATIC FUNCTION Sr_ReadSolidFace( s, lFace )
   LOCAL e := IIf( lFace, Ef3_New( Vc3_Zero(), Vc3_Zero(), Vc3_Zero(), Vc3_Zero() ), Eso_New( Vc3_Zero(), Vc3_Zero(), Vc3_Zero(), Vc3_Zero() ) )
   LOCAL cr := { PR_New(), PR_New(), PR_New(), PR_New() }, nor := PR_New(), p, v, n, pt, a := { NIL, NIL, NIL, NIL }, i
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE ( n >= 10 .AND. n <= 13 ) .OR. ( n >= 20 .AND. n <= 23 ) .OR. ( n >= 30 .AND. n <= 33 )
         PR_AddCoordinate( cr[ n % 10 + 1 ], p )
      CASE n == 39 .AND. ! lFace
         v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "thickness" ] := v ; ENDIF
      CASE n == 70 .AND. lFace
         v := Dp_AsI16( p ) ; IF v != NIL ; e[ "invisible_edges" ] := hb_bitAnd( v, 15 ) ; ENDIF
      CASE ( n == 210 .OR. n == 220 .OR. n == 230 ) .AND. ! lFace ; PR_AddCoordinate( nor, p )
      OTHERWISE ; Sr_EntBase( s, p, e )
      ENDCASE
   ENDDO
   FOR i := 1 TO 4
      a[ i ] := PR_GetPoint( cr[ i ] )
      IF a[ i ] == NIL .AND. i < 4 ; a[ i ] := Vc3_Zero() ; ENDIF
   NEXT
   IF a[ 4 ] == NIL ; a[ 4 ] := a[ 3 ] ; ENDIF
   e[ "first_corner" ] := a[ 1 ] ; e[ "second_corner" ] := a[ 2 ] ; e[ "third_corner" ] := a[ 3 ] ; e[ "fourth_corner" ] := a[ 4 ]
   pt := PR_GetPoint( nor ) ; IF pt != NIL ; e[ "normal" ] := pt ; ENDIF
RETURN e

STATIC FUNCTION Sr_ReadRayXline( s, lRay )
   LOCAL e := IIf( lRay, Ery_Default(), Exl_Default() ), b := PR_New(), d := PR_New(), p, n, pt
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( b, p )
      CASE n == 11 .OR. n == 21 .OR. n == 31 ; PR_AddCoordinate( d, p )
      OTHERWISE ; Sr_EntBase( s, p, e )
      ENDCASE
   ENDDO
   pt := PR_GetPoint( b ) ; IF pt != NIL ; e[ "base_point" ] := pt ; ENDIF
   pt := PR_GetPoint( d ) ; IF pt != NIL ; e[ "direction" ] := Vc3_Normalize( pt ) ; ENDIF
RETURN e

STATIC FUNCTION Sr_ReadEntityOfType( s, cT )
   LOCAL p
   DO CASE
   CASE cT == "POINT" ; RETURN Sr_ReadPoint( s )
   CASE cT == "LINE" .OR. cT == "3DLINE" ; RETURN Sr_ReadLine( s )
   CASE cT == "CIRCLE" ; RETURN Sr_ReadCircArc( s, .F. )
   CASE cT == "ARC" ; RETURN Sr_ReadCircArc( s, .T. )
   CASE cT == "LWPOLYLINE" ; RETURN Sr_ReadLwPoly( s )
   CASE cT == "TEXT" ; RETURN Sr_ReadText( s )
   CASE cT == "INSERT" ; RETURN Sr_ReadInsert( s )
   CASE cT == "ATTDEF" ; RETURN Sr_ReadAttdefAttrib( s, .T. )
   CASE cT == "MTEXT" ; RETURN Sr_ReadMText( s )
   CASE cT == "SPLINE" ; RETURN Sr_ReadSpline( s )
   CASE cT == "POLYLINE" ; RETURN Sr_ReadPolyline( s )
   CASE cT == "ELLIPSE" ; RETURN Sr_ReadEllipse( s )
   CASE cT == "SOLID" ; RETURN Sr_ReadSolidFace( s, .F. )
   CASE cT == "TRACE"
      p := Sr_ReadSolidFace( s, .F. ) ; p[ "is_trace" ] := .T. ; RETURN p
   CASE cT == "3DFACE" ; RETURN Sr_ReadSolidFace( s, .T. )
   CASE cT == "RAY" ; RETURN Sr_ReadRayXline( s, .T. )
   CASE cT == "XLINE" ; RETURN Sr_ReadRayXline( s, .F. )
   ENDCASE
   Sr_SkipEntity( s ) /* PENDIENTE: resto de tipos (original: read_unknown_entity / lectores propios) */
RETURN NIL

PROCEDURE Sr_ReadEntities( s, d )
   LOCAL p, e
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "ENDSEC" ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 0
         e := Sr_ReadEntityOfType( s, p[ DP_VALUE ] )
         IF e != NIL ; Doc_AddEntity( d, e ) ; ENDIF
      ENDIF
   ENDDO
RETURN

/* ---- bloques ---- */
STATIC FUNCTION Sr_ReadBlockEnd( s )
   LOCAL e := Ebe_New(), p, v, cLay := "0", h := Hd_Null()
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; h := v ; ENDIF
      ELSEIF p[ DP_CODE ] == 8
         cLay := p[ DP_VALUE ]
      ENDIF
   ENDDO
   e[ "common" ][ "handle" ] := h ; e[ "common" ][ "layer" ] := cLay
RETURN e

STATIC FUNCTION Sr_ReadBlock( s, d )
   LOCAL cName := "", cAlt := "", vBase := Vc3_Zero(), cDesc := "", cXref := "", cLay := "0", h := Hd_Null(), nFl := 0, pr := PR_New(), ;
         p, v, cCan, aEnts := {}, lDone := .F., e, br, aHs, en, nIdx, bEnd, hh, pt
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      DO CASE
      CASE p[ DP_CODE ] == 2 ; cName := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 3 ; cAlt := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 4 ; cDesc := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 1 ; cXref := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; h := v ; ENDIF
      CASE p[ DP_CODE ] == 8 ; cLay := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 10 .OR. p[ DP_CODE ] == 20 .OR. p[ DP_CODE ] == 30
         PR_AddCoordinate( pr, p )
         pt := PR_GetPoint( pr ) ; IF pt != NIL ; vBase := pt ; ENDIF
      CASE p[ DP_CODE ] == 70
         v := Dp_AsI16( p ) ; IF v != NIL ; nFl := v ; ENDIF
      ENDCASE
   ENDDO
   IF Len( cName ) == 0 ; cName := cAlt ; ENDIF
   cCan := NIL
   IF Upper( cName ) == "$MODEL_SPACE" ; cCan := "*Model_Space" ; ELSEIF Upper( cName ) == "$PAPER_SPACE" ; cCan := "*Paper_Space" ; ENDIF
   IF cCan != NIL
      IF Len( cAlt ) > 0 .AND. Upper( cAlt ) == Upper( cCan ) .AND. Tb_Get( d[ "block_records" ], cAlt ) != NIL
         cName := cAlt
      ELSEIF Tb_Get( d[ "block_records" ], cCan ) != NIL
         cName := cCan
      ENDIF
   ENDIF
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0
         IF p[ DP_VALUE ] == "ENDBLK"
            bEnd := Sr_ReadBlockEnd( s )
            aHs := {}
            FOR EACH en IN aEnts
               IF Hd_IsNull( en[ "common" ][ "handle" ] ) ; en[ "common" ][ "handle" ] := Doc_AllocateHandle( d ) ; ENDIF
               hh := en[ "common" ][ "handle" ]
               AAdd( aHs, hh )
               nIdx := Len( d[ "entities" ] )
               AAdd( d[ "entities" ], en )
               d[ "entity_index" ][ hh ] := nIdx
            NEXT
            IF Tb_Get( d[ "block_records" ], cName ) == NIL
               br := Blk_New( cName ) ; br[ "handle" ] := Doc_AllocateHandle( d )
               Tb_AddOrReplace( d[ "block_records" ], br )
            ENDIF
            br := Tb_Get( d[ "block_records" ], cName )
            br[ "entity_handles" ] := aHs
            br[ "xref_path" ] := cXref ; br[ "base_point" ] := vBase ; br[ "description" ] := cDesc
            br[ "flags" ][ "anonymous" ] := hb_bitAnd( nFl, 1 ) != 0
            br[ "flags" ][ "has_attributes" ] := hb_bitAnd( nFl, 2 ) != 0
            br[ "flags" ][ "is_xref" ] := hb_bitAnd( nFl, 4 ) != 0
            br[ "flags" ][ "is_xref_overlay" ] := hb_bitAnd( nFl, 8 ) != 0
            br[ "block_entity_handle" ] := h
            br[ "block_end_handle" ] := bEnd[ "common" ][ "handle" ]
            lDone := .T.
            EXIT
         ENDIF
         e := Sr_ReadEntityOfType( s, p[ DP_VALUE ] )
         IF e != NIL ; AAdd( aEnts, e ) ; ENDIF
      ENDIF
   ENDDO
   HB_SYMBOL_UNUSED( cLay )
RETURN lDone

PROCEDURE Sr_ReadBlocks( s, d )
   LOCAL p
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "ENDSEC" ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "BLOCK" ; Sr_ReadBlock( s, d ) ; ENDIF
   ENDDO
RETURN

/* reader.rs: bucle de secciones. Devuelve documento, o cadena de error */
FUNCTION Dxr_ReadString( cData )
   LOCAL s, d := Doc_New(), p, np, cSec
   s := Sr_NewText( cData )
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "EOF" ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "SECTION"
         np := Sr_Next( s )
         IF np != NIL .AND. np[ DP_CODE ] == 2
            cSec := np[ DP_VALUE ]
            DO CASE
            CASE cSec == "HEADER" ; Sr_ReadHeader( s, d )
            CASE cSec == "CLASSES" ; Sr_ReadClasses( s, d )
            CASE cSec == "TABLES" ; Sr_ReadTables( s, d )
            CASE cSec == "BLOCKS" ; Sr_ReadBlocks( s, d )
            CASE cSec == "ENTITIES" ; Sr_ReadEntities( s, d )
            OTHERWISE ; Sr_SkipSection( s ) /* OBJECTS/ACDSDATA/THUMBNAILIMAGE: PENDIENTE */
            ENDCASE
         ENDIF
      ENDIF
   ENDDO
   IF Sr_Error( s ) != NIL ; RETURN Sr_Error( s ) ; ENDIF
   Doc_SynchronizeHandleAllocator( d )
   Doc_ResolveReferences( d )
   Doc_EnsureModelLayout( d )
RETURN d

STATIC PROCEDURE Sr_SkipSection( s )
   LOCAL p
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "ENDSEC" ; EXIT ; ENDIF
   ENDDO
RETURN
