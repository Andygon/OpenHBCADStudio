/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_objreader.prg
   Origen Rust: opencadcodec/src/io/dxf/reader/section_reader.rs (read_objects, read_dictionary, read_layout).
   Licencia del original: MPL-2.0. Prefijo Dxo_.
   PENDIENTE: el resto de tipos de objeto (IMAGEDEF, MLEADERSTYLE, PLOTSETTINGS, TABLESTYLE, SCALE,
   SORTENTSTABLE, DICTIONARYVAR, VISUALSTYLE, MATERIAL, ...) se saltan; xdata de objetos tampoco.
   El original no tiene #[test] para estas funciones; los tests [extra] estan en t_dxf_rw.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"
#define DP_CODE 1
#define DP_VALUE 3

STATIC FUNCTION Dxo_LayoutDblMap()
   STATIC hM
   IF hM == NIL
      hM := { ;
         10 => { "min_limits", 1 }, ;
         20 => { "min_limits", 2 }, ;
         11 => { "max_limits", 1 }, ;
         21 => { "max_limits", 2 }, ;
         12 => { "insertion_base", 1 }, ;
         22 => { "insertion_base", 2 }, ;
         32 => { "insertion_base", 3 }, ;
         14 => { "min_extents", 1 }, ;
         24 => { "min_extents", 2 }, ;
         34 => { "min_extents", 3 }, ;
         15 => { "max_extents", 1 }, ;
         25 => { "max_extents", 2 }, ;
         35 => { "max_extents", 3 }, ;
         13 => { "ucs_origin", 1 }, ;
         23 => { "ucs_origin", 2 }, ;
         33 => { "ucs_origin", 3 }, ;
         16 => { "ucs_x_axis", 1 }, ;
         26 => { "ucs_x_axis", 2 }, ;
         36 => { "ucs_x_axis", 3 }, ;
         17 => { "ucs_y_axis", 1 }, ;
         27 => { "ucs_y_axis", 2 }, ;
         37 => { "ucs_y_axis", 3 }, ;
         146 => { "elevation", 0 } }
   ENDIF
RETURN hM

STATIC FUNCTION Dxo_PlotMap()
   STATIC hM
   IF hM == NIL
      hM := { ;
         1 => { "plot_page_name", "S" }, ;
         2 => { "plot_printer_name", "S" }, ;
         4 => { "paper_size", "S" }, ;
         6 => { "plot_view_name", "S" }, ;
         7 => { "plot_style_sheet", "S" }, ;
         40 => { "plot_margin_left", "D" }, ;
         41 => { "plot_margin_bottom", "D" }, ;
         42 => { "plot_margin_right", "D" }, ;
         43 => { "plot_margin_top", "D" }, ;
         44 => { "paper_width", "D" }, ;
         45 => { "paper_height", "D" }, ;
         46 => { "plot_origin_x", "D" }, ;
         47 => { "plot_origin_y", "D" }, ;
         48 => { "plot_window_min_x", "D" }, ;
         49 => { "plot_window_min_y", "D" }, ;
         140 => { "plot_window_max_x", "D" }, ;
         141 => { "plot_window_max_y", "D" }, ;
         142 => { "plot_scale_numerator", "D" }, ;
         143 => { "plot_scale_denominator", "D" }, ;
         147 => { "plot_scale_factor", "D" }, ;
         148 => { "paper_image_origin_x", "D" }, ;
         149 => { "paper_image_origin_y", "D" }, ;
         72 => { "plot_paper_units", "I" }, ;
         73 => { "plot_rotation", "I" }, ;
         74 => { "plot_type", "I" }, ;
         75 => { "plot_scale_type", "I" }, ;
         76 => { "shade_plot_mode", "I" }, ;
         77 => { "shade_plot_resolution", "I" }, ;
         78 => { "shade_plot_dpi", "I" } }
   ENDIF
RETURN hM

STATIC FUNCTION Dxo_Num( c )
   LOCAL t := AllTrim( c )
   IF Len( t ) == 0 ; RETURN NIL ; ENDIF
   IF ! ( Left( t, 1 ) $ "0123456789.+-" ) ; RETURN NIL ; ENDIF
RETURN Val( t )

STATIC FUNCTION Dxo_Hex( c )
   LOCAL t := AllTrim( c ), i
   IF Len( t ) == 0 ; RETURN NIL ; ENDIF
   FOR i := 1 TO Len( t )
      IF ! ( SubStr( t, i, 1 ) $ "0123456789abcdefABCDEF" ) ; RETURN NIL ; ENDIF
   NEXT
RETURN hb_HexToNum( t )

STATIC FUNCTION Dxo_IntIn( c, nLo, nHi )
   LOCAL t := AllTrim( c ), i, ch
   IF Len( t ) == 0 ; RETURN NIL ; ENDIF
   FOR i := 1 TO Len( t )
      ch := SubStr( t, i, 1 )
      IF ! ( ch $ "0123456789" .OR. ( i == 1 .AND. ch $ "+-" .AND. Len( t ) > 1 ) ) ; RETURN NIL ; ENDIF
   NEXT
   IF Val( t ) < nLo .OR. Val( t ) > nHi ; RETURN NIL ; ENDIF
RETURN Int( Val( t ) )

STATIC FUNCTION Dxo_ReadXRecord( s )
   LOCAL x := Xrc_New(), p, v, cGroup := "", lOwner := .F., lClone := .F., n, nT, xv, q, q2, nY, nZ, hx, cBytes, i, hi, lo, nKind
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      n := p[ DP_CODE ]
      DO CASE
      CASE n == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; x[ "handle" ] := v ; ENDIF
      CASE n == 100 .AND. p[ DP_VALUE ] == "AcDbXrecord"
      CASE n == 102 .AND. ( p[ DP_VALUE ] == "{ACAD_REACTORS" .OR. p[ DP_VALUE ] == "{ACAD_XDICTIONARY" )
         cGroup := p[ DP_VALUE ]
      CASE n == 102 .AND. Len( cGroup ) > 0 .AND. p[ DP_VALUE ] == "}"
         cGroup := ""
      CASE n == 330 .AND. cGroup == "{ACAD_REACTORS"
         v := Dxo_Hex( p[ DP_VALUE ] ) ; AAdd( x[ "reactors" ], IIf( v == NIL, 0, v ) )
      CASE n == 360 .AND. cGroup == "{ACAD_XDICTIONARY"
         v := Dxo_Hex( p[ DP_VALUE ] ) ; x[ "xdictionary_handle" ] := IIf( v == NIL, 0, v )
      CASE n == 330 .AND. ! lOwner .AND. Len( cGroup ) == 0
         v := Dxo_Hex( p[ DP_VALUE ] ) ; x[ "owner" ] := IIf( v == NIL, 0, v ) ; lOwner := .T.
      CASE n == 280 .AND. ! lClone
         lClone := .T.
         v := Dp_AsI16( p ) ; IF v != NIL ; x[ "cloning_flags" ] := Dcf_FromValue( v ) ; ENDIF
      OTHERWISE
         nT := Xvt_FromCode( n )
         DO CASE
         CASE nT == XVT_STRING ; xv := Xrv_New( "String", p[ DP_VALUE ] )
         CASE nT == XVT_POINT3D
            v := Dxo_Num( p[ DP_VALUE ] ) ; IF v == NIL ; v := 0.0 ; ENDIF
            nY := 0.0 ; nZ := 0.0
            q := Sr_Next( s )
            IF q != NIL
               IF q[ DP_CODE ] == n + 10
                  nY := Dxo_Num( q[ DP_VALUE ] ) ; IF nY == NIL ; nY := 0.0 ; ENDIF
                  q2 := Sr_Next( s )
                  IF q2 != NIL
                     IF q2[ DP_CODE ] == n + 20
                        nZ := Dxo_Num( q2[ DP_VALUE ] ) ; IF nZ == NIL ; nZ := 0.0 ; ENDIF
                     ELSE
                        Sr_PushBack( s, q2 )
                     ENDIF
                  ENDIF
               ELSE
                  Sr_PushBack( s, q )
               ENDIF
            ENDIF
            xv := Xrv_New( "Point3D", { v, nY, nZ } )
         CASE nT == XVT_DOUBLE
            v := Dxo_Num( p[ DP_VALUE ] ) ; xv := IIf( v != NIL, Xrv_New( "Double", v ), Xrv_New( "String", p[ DP_VALUE ] ) )
         CASE nT == XVT_INT16
            v := Dxo_IntIn( p[ DP_VALUE ], -32768, 32767 ) ; xv := IIf( v != NIL, Xrv_New( "Int16", v ), Xrv_New( "String", p[ DP_VALUE ] ) )
         CASE nT == XVT_INT32
            v := Dxo_IntIn( p[ DP_VALUE ], -2147483648, 2147483647 ) ; xv := IIf( v != NIL, Xrv_New( "Int32", v ), Xrv_New( "String", p[ DP_VALUE ] ) )
         CASE nT == XVT_INT64
            v := Dxo_IntIn( p[ DP_VALUE ], -9223372036854775807, 9223372036854775807 ) ; xv := IIf( v != NIL, Xrv_New( "Int64", v ), Xrv_New( "String", p[ DP_VALUE ] ) )
         CASE nT == XVT_BYTE
            v := Dxo_IntIn( p[ DP_VALUE ], 0, 255 ) ; xv := IIf( v != NIL, Xrv_New( "Byte", v ), Xrv_New( "String", p[ DP_VALUE ] ) )
         CASE nT == XVT_BOOL
            v := Dxo_IntIn( p[ DP_VALUE ], -2147483648, 2147483647 ) ; xv := IIf( v != NIL, Xrv_New( "Bool", v != 0 ), Xrv_New( "String", p[ DP_VALUE ] ) )
         CASE nT == XVT_HANDLE .OR. nT == XVT_OBJECT_ID
            v := Dxo_Hex( p[ DP_VALUE ] ) ; xv := IIf( v != NIL, Xrv_New( "Handle", v ), Xrv_New( "String", p[ DP_VALUE ] ) )
         CASE nT == XVT_CHUNK
            hx := AllTrim( p[ DP_VALUE ] ) ; cBytes := "" ; i := 1
            DO WHILE i + 1 <= Len( hx )
               hi := SubStr( hx, i, 1 ) ; lo := SubStr( hx, i + 1, 1 )
               IF hi $ "0123456789abcdefABCDEF" .AND. lo $ "0123456789abcdefABCDEF"
                  cBytes += Chr( hb_HexToNum( hi + lo ) )
               ENDIF
               i += 2
            ENDDO
            x[ "raw_data" ] += cBytes
            xv := Xrv_New( "Chunk", cBytes )
         OTHERWISE
            x[ "entries_complete" ] := .F.
            xv := Xrv_New( "String", p[ DP_VALUE ] )
         ENDCASE
         IF n >= 330 .AND. n <= 369 .AND. xv[ "_kind" ] == "Handle"
            DO CASE
            CASE n <= 339 ; nKind := PRK_SOFT_POINTER
            CASE n <= 349 ; nKind := PRK_HARD_POINTER
            CASE n <= 359 ; nKind := PRK_SOFT_OWNERSHIP
            OTHERWISE ; nKind := PRK_HARD_OWNERSHIP
            ENDCASE
            AAdd( x[ "object_references" ], Ppr_NewRef( xv[ "value" ], nKind ) )
         ENDIF
         AAdd( x[ "entries" ], Xre_New( n, xv ) )
      ENDCASE
   ENDDO
RETURN x

STATIC FUNCTION Dxo_ReadGroup( s )
   LOCAL g := Grp_New( "" ), p, v
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      DO CASE
      CASE p[ DP_CODE ] == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; g[ "handle" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 330
         v := Sr_HexVal( p ) ; IF v != NIL ; g[ "owner" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 300 ; g[ "description" ] := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 70
         v := Dp_AsI16( p ) ; IF v != NIL ; g[ "unnamed" ] := v != 0 ; ENDIF
      CASE p[ DP_CODE ] == 71
         v := Dp_AsI16( p ) ; IF v != NIL ; g[ "selectable" ] := v != 0 ; ENDIF
      CASE p[ DP_CODE ] == 340
         v := Sr_HexVal( p ) ; IF v != NIL ; AAdd( g[ "entities" ], v ) ; ENDIF
      ENDCASE
   ENDDO
RETURN g

STATIC FUNCTION Dxo_ReadMLineStyle( s )
   LOCAL st := Mlsy_New( "" ), p, v, nL
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      nL := Len( st[ "elements" ] )
      DO CASE
      CASE p[ DP_CODE ] == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; st[ "handle" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 330
         v := Sr_HexVal( p ) ; IF v != NIL ; st[ "owner" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 2 ; st[ "name" ] := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 3 ; st[ "description" ] := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 51
         v := Dp_AsDouble( p ) ; IF v != NIL ; st[ "start_angle" ] := v * OCX_PI / 180.0 ; ENDIF
      CASE p[ DP_CODE ] == 52
         v := Dp_AsDouble( p ) ; IF v != NIL ; st[ "end_angle" ] := v * OCX_PI / 180.0 ; ENDIF
      CASE p[ DP_CODE ] == 62
         v := Dp_AsI16( p )
         IF v != NIL
            IF nL > 0 ; st[ "elements" ][ nL ][ "color" ] := Cl_FromIndex( v ) ; ELSE ; st[ "fill_color" ] := Cl_FromIndex( v ) ; ENDIF
         ENDIF
      CASE p[ DP_CODE ] == 49
         v := Dp_AsDouble( p ) ; IF v != NIL ; AAdd( st[ "elements" ], Mlse_New( v ) ) ; ENDIF
      CASE p[ DP_CODE ] == 6
         IF nL > 0 ; st[ "elements" ][ nL ][ "linetype" ] := p[ DP_VALUE ] ; ENDIF
      ENDCASE
   ENDDO
RETURN st

STATIC FUNCTION Dxo_ReadScale( s )
   LOCAL sc := Scl_New( "1:1", 1.0, 1.0 ), p, v
   sc[ "is_unit_scale" ] := .T.
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      DO CASE
      CASE p[ DP_CODE ] == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; sc[ "handle" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 330
         v := Sr_HexVal( p ) ; IF v != NIL ; sc[ "owner_handle" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 300 ; sc[ "name" ] := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 140
         v := Dp_AsDouble( p ) ; IF v != NIL ; sc[ "paper_units" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 141
         v := Dp_AsDouble( p ) ; IF v != NIL ; sc[ "drawing_units" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 290
         v := Dp_AsBool( p ) ; IF v != NIL ; sc[ "is_unit_scale" ] := v ; ENDIF
      ENDCASE
   ENDDO
RETURN sc

STATIC FUNCTION Dxo_ReadDictVar( s )
   LOCAL dv := Dvr_New( "", "" ), p, v
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      DO CASE
      CASE p[ DP_CODE ] == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; dv[ "handle" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 330
         v := Sr_HexVal( p ) ; IF v != NIL ; dv[ "owner_handle" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 280
         v := Dp_AsI16( p ) ; IF v != NIL ; dv[ "schema_number" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 1 ; dv[ "value" ] := p[ DP_VALUE ]
      ENDCASE
   ENDDO
RETURN dv

STATIC FUNCTION Dxo_ReadSortEnts( s, nVer )
   LOCAL t := Sot_New(), p, v, nEnt := NIL, aRaw := {}, lGroup := .F., lTable := .F.
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      AAdd( aRaw, { p[ DP_CODE ], p[ DP_VALUE ] } )
      DO CASE
      CASE p[ DP_CODE ] == 102 ; lGroup := Left( AllTrim( p[ DP_VALUE ] ), 1 ) == "{"
      CASE p[ DP_CODE ] == 100 ; lTable := AllTrim( p[ DP_VALUE ] ) == "AcDbSortentsTable"
      CASE p[ DP_CODE ] == 330 .AND. ! lGroup .AND. ! lTable
         v := Sr_HexVal( p ) ; IF v != NIL ; t[ "owner_handle" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 5
         v := Sr_HexVal( p )
         IF v != NIL
            IF Hd_IsNull( t[ "handle" ] )
               t[ "handle" ] := v
            ELSEIF nEnt != NIL
               Sot_AddEntry( t, nEnt, v ) ; nEnt := NIL
            ENDIF
         ENDIF
      CASE p[ DP_CODE ] == 330 .AND. lTable
         v := Sr_HexVal( p ) ; IF v != NIL ; t[ "block_owner_handle" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 331
         v := Sr_HexVal( p ) ; IF v != NIL ; nEnt := v ; ENDIF
      ENDCASE
   ENDDO
   t[ "raw_dxf_codes" ] := aRaw ; t[ "raw_dxf_version" ] := nVer
RETURN t

STATIC FUNCTION Dxo_ReadImageDef( s )
   LOCAL df := Imd_New( "" ), p, v
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      DO CASE
      CASE p[ DP_CODE ] == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; df[ "handle" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 330
         v := Sr_HexVal( p ) ; IF v != NIL ; df[ "owner" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 1 ; df[ "file_name" ] := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 10
         v := Dp_AsDouble( p ) ; IF v != NIL ; df[ "size_in_pixels" ][ 1 ] := Dxo_U32( v ) ; ENDIF
      CASE p[ DP_CODE ] == 20
         v := Dp_AsDouble( p ) ; IF v != NIL ; df[ "size_in_pixels" ][ 2 ] := Dxo_U32( v ) ; ENDIF
      CASE p[ DP_CODE ] == 11
         v := Dp_AsDouble( p ) ; IF v != NIL ; df[ "pixel_size" ][ 1 ] := v ; ENDIF
      CASE p[ DP_CODE ] == 21
         v := Dp_AsDouble( p ) ; IF v != NIL ; df[ "pixel_size" ][ 2 ] := v ; ENDIF
      CASE p[ DP_CODE ] == 280
         v := Dp_AsI16( p ) ; IF v != NIL ; df[ "is_loaded" ] := ( v != 0 ) ; ENDIF
      ENDCASE
   ENDDO
RETURN df

/* f64 as u32 de Rust: satura en 0 y 4294967295, NaN -> 0 */
STATIC FUNCTION Dxo_U32( n )
   IF OCX_ISNAN( n ) .OR. n <= 0.0 ; RETURN 0 ; ENDIF
   IF n >= 4294967295.0 ; RETURN 4294967295 ; ENDIF
RETURN Int( n )

STATIC FUNCTION Dxo_ReadDictionary( s )
   LOCAL d := Dic_New(), p, cKey := NIL, v
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      DO CASE
      CASE p[ DP_CODE ] == 5
         v := Sr_HexVal( p ) ; IF v != NIL ; d[ "handle" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 102
         DO CASE
         CASE AllTrim( p[ DP_VALUE ] ) == "{ACAD_REACTORS" ; d[ "reactors" ] := Sr_ReadReactorHandles( s )
         CASE AllTrim( p[ DP_VALUE ] ) == "{ACAD_XDICTIONARY" ; d[ "xdictionary_handle" ] := Sr_ReadXDictHandle( s )
         CASE Left( AllTrim( p[ DP_VALUE ] ), 1 ) == "{" ; Sr_SkipDefinedGroup( s )
         ENDCASE
      CASE p[ DP_CODE ] == 330
         v := Sr_HexVal( p ) ; IF v != NIL ; d[ "owner" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 281
         v := Dp_AsI16( p ) ; IF v != NIL ; d[ "duplicate_cloning" ] := v ; ENDIF
      CASE p[ DP_CODE ] == 280
         v := Dp_AsI16( p ) ; IF v != NIL ; d[ "hard_owner" ] := v != 0 ; ENDIF
      CASE p[ DP_CODE ] == 3
         cKey := p[ DP_VALUE ]
      CASE p[ DP_CODE ] == 350 .OR. p[ DP_CODE ] == 360
         IF cKey != NIL
            v := Sr_HexVal( p )
            IF v != NIL
               IF p[ DP_CODE ] == 360 .OR. d[ "hard_owner" ] .OR. Dic_IsCanonicalHardOwnerKey( cKey )
                  Dic_SetEntryHardOwner( d, cKey, .T. )
               ENDIF
               Dic_AddEntry( d, cKey, v )
            ENDIF
            cKey := NIL
         ENDIF
      ENDCASE
   ENDDO
RETURN d

STATIC FUNCTION Dxo_ReadLayout( s )
   LOCAL l := Lyo_New( "" ), p, v, m, nSec := 0, aPs := {}, lOwner := .F., x, q, n, t
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 100
         IF p[ DP_VALUE ] == "AcDbPlotSettings" ; nSec := 1 ; ELSEIF p[ DP_VALUE ] == "AcDbLayout" ; nSec := 2 ; ENDIF
         LOOP
      ENDIF
      IF p[ DP_CODE ] == 102
         IF p[ DP_VALUE ] == "{ACAD_XDICTIONARY"
            DO WHILE ( q := Sr_Next( s ) ) != NIL
               IF q[ DP_CODE ] == 360
                  v := Sr_HexVal( q ) ; IF v != NIL ; l[ "xdictionary_handle" ] := v ; ENDIF
               ENDIF
               IF q[ DP_CODE ] == 102 ; EXIT ; ENDIF
            ENDDO
         ELSEIF p[ DP_VALUE ] == "{ACAD_REACTORS"
            DO WHILE ( q := Sr_Next( s ) ) != NIL
               IF q[ DP_CODE ] == 102 ; EXIT ; ENDIF
               IF q[ DP_CODE ] == 330
                  v := Sr_HexVal( q ) ; IF v != NIL ; AAdd( l[ "reactors" ], v ) ; ENDIF
               ENDIF
            ENDDO
         ENDIF
         LOOP
      ENDIF
      DO CASE
      CASE nSec == 0
         IF p[ DP_CODE ] == 5
            v := Sr_HexVal( p ) ; IF v != NIL ; l[ "handle" ] := v ; ENDIF
         ELSEIF p[ DP_CODE ] == 330 .AND. ! lOwner
            v := Sr_HexVal( p ) ; IF v != NIL ; l[ "owner" ] := v ; ENDIF
            lOwner := .T.
         ENDIF
      CASE nSec == 1
         AAdd( aPs, { p[ DP_CODE ], p[ DP_VALUE ] } )
      CASE nSec == 2
         n := p[ DP_CODE ]
         m := hb_HGetDef( Dxo_LayoutDblMap(), n, NIL )
         IF m != NIL
            v := Dp_AsDouble( p )
            IF v != NIL
               IF m[ 2 ] == 0 ; l[ m[ 1 ] ] := v ; ELSE ; l[ m[ 1 ] ][ m[ 2 ] ] := v ; ENDIF
            ENDIF
         ELSE
            DO CASE
            CASE n == 1 ; l[ "name" ] := p[ DP_VALUE ]
            CASE n == 70
               v := Dp_AsI16( p ) ; IF v != NIL ; l[ "flags" ] := v ; ENDIF
            CASE n == 71
               v := Dp_AsI16( p ) ; IF v != NIL ; l[ "tab_order" ] := v ; ENDIF
            CASE n == 76
               v := Dp_AsI16( p ) ; IF v != NIL ; l[ "ucs_ortho_type" ] := v ; ENDIF
            CASE n == 330
               v := Sr_HexVal( p ) ; IF v != NIL ; l[ "block_record" ] := v ; ENDIF
            CASE n == 331
               v := Sr_HexVal( p ) ; IF v != NIL ; l[ "viewport" ] := v ; ENDIF
            CASE n == 345
               v := Sr_HexVal( p ) ; IF v != NIL ; l[ "named_ucs" ] := v ; ENDIF
            CASE n == 346
               v := Sr_HexVal( p ) ; IF v != NIL ; l[ "base_ucs" ] := v ; ENDIF
            ENDCASE
         ENDIF
      ENDCASE
   ENDDO
   IF Len( aPs ) > 0
      FOR EACH x IN aPs
         t := x[ 2 ]
         m := hb_HGetDef( Dxo_PlotMap(), x[ 1 ], NIL )
         IF m != NIL
            IF m[ 2 ] == "S"
               l[ m[ 1 ] ] := t
            ELSE
               v := Dxo_Num( t )
               IF v != NIL
                  IF m[ 2 ] == "I" ; v := Int( v ) ; ENDIF
                  l[ m[ 1 ] ] := v
               ENDIF
            ENDIF
         ELSEIF x[ 1 ] == 70
            v := Dxo_Num( t ) ; IF v != NIL ; l[ "plot_flags" ] := Pfl_FromBits( Int( v ) ) ; ENDIF
         ELSEIF x[ 1 ] == 333
            v := Dxo_Hex( t ) ; IF v != NIL ; l[ "visual_style_handle" ] := v ; ENDIF
         ENDIF
      NEXT
      l[ "raw_plot_settings_codes" ] := aPs
   ENDIF
RETURN l

/* read_objects: parcial (ver cabecera) */
PROCEDURE Dxo_ReadObjects( s, d )
   LOCAL p, o
   d[ "objects" ] := hb_Hash()
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 .AND. p[ DP_VALUE ] == "ENDSEC" ; EXIT ; ENDIF
      IF p[ DP_CODE ] == 0
         DO CASE
         CASE p[ DP_VALUE ] == "DICTIONARY"
            o := Dxo_ReadDictionary( s ) ; d[ "objects" ][ o[ "handle" ] ] := o
         CASE p[ DP_VALUE ] == "LAYOUT"
            o := Dxo_ReadLayout( s ) ; d[ "objects" ][ o[ "handle" ] ] := o
         CASE p[ DP_VALUE ] == "XRECORD"
            o := Dxo_ReadXRecord( s ) ; d[ "objects" ][ o[ "handle" ] ] := o
         CASE p[ DP_VALUE ] == "MLINESTYLE"
            o := Dxo_ReadMLineStyle( s ) ; d[ "objects" ][ o[ "handle" ] ] := o
         CASE p[ DP_VALUE ] == "SCALE"
            o := Dxo_ReadScale( s ) ; d[ "objects" ][ o[ "handle" ] ] := o
         CASE p[ DP_VALUE ] == "DICTIONARYVAR"
            o := Dxo_ReadDictVar( s ) ; d[ "objects" ][ o[ "handle" ] ] := o
         CASE p[ DP_VALUE ] == "SORTENTSTABLE"
            o := Dxo_ReadSortEnts( s, d[ "version" ] ) ; d[ "objects" ][ o[ "handle" ] ] := o
         CASE p[ DP_VALUE ] == "IMAGEDEF"
            o := Dxo_ReadImageDef( s ) ; d[ "objects" ][ o[ "handle" ] ] := o
         CASE p[ DP_VALUE ] == "GROUP"
            o := Dxo_ReadGroup( s ) ; d[ "objects" ][ o[ "handle" ] ] := o
         OTHERWISE
            Sr_SkipEntity( s )
         ENDCASE
      ENDIF
   ENDDO
RETURN
