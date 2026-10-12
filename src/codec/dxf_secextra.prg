/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/dxf_secextra.prg
   Origen Rust: opencadcodec/src/io/dxf/reader/section_reader.rs: read_unknown_entity (L11330), read_light_entity (L18756).
   Fichero aparte (dxf_secsections.prg es demasiado grande para el editor web). Licencia del original: MPL-2.0.
   Los tests [extra] estan en tests/t_dxf_reader.prg (el Rust no tiene #[test] para estas funciones).
----------------------------------------------------------------------------*/
#include "ocx.ch"
#define DP_CODE 1
#define DP_VALUE 3

/* read_unknown_entity: codigos comunes al common; el resto se guarda como raw_dxf_codes para el roundtrip */
FUNCTION Sr_ReadUnknown( s, cName )
   LOCAL e := Eun_New( cName ), p, aRaw := {}
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      IF p[ DP_CODE ] == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      IF ! Sr_EntBaseP( s, p, e )
         AAdd( aRaw, { p[ DP_CODE ], p[ DP_VALUE ] } )
      ENDIF
   ENDDO
   IF Len( aRaw ) > 0 ; e[ "raw_dxf_codes" ] := aRaw ; ENDIF
RETURN e

/* read_light_entity */
FUNCTION Sr_ReadLight( s )
   LOCAL e := Elt_New(), ph := Lpd_New(), p, v, n, lPh := .F., cSub := "", nPg := 0, cPg := ""
   LOCAL prPos := PR_New(), prTgt := PR_New(), prWeb := PR_New()
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      n := p[ DP_CODE ]
      IF n == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      IF n == 100 ; cSub := p[ DP_VALUE ] ; LOOP ; ENDIF
      DO CASE
      CASE ( n == 92 .OR. n == 160 ) .AND. cSub == "AcDbEntity"
         v := Dp_AsInt( p ) ; nPg := Max( 0, IIf( v == NIL, 0, v ) )
      CASE n == 310 .AND. cSub == "AcDbEntity" ; cPg := Sr_AppendHex( cPg, p[ DP_VALUE ] )
      CASE n == 1 .AND. ! lPh ; e[ "name" ] := p[ DP_VALUE ]
      CASE n == 90 .AND. ! lPh ; v := Dp_AsI32( p ) ; IF v != NIL ; e[ "class_version" ] := v ; ENDIF
      CASE n == 70 .AND. ! lPh ; v := Dp_AsI32( p ) ; IF v != NIL ; e[ "light_type" ] := v ; ENDIF
      CASE n == 290 .AND. ! lPh ; v := Dp_AsI16( p ) ; e[ "status" ] := ( IIf( v == NIL, 0, v ) != 0 )
      CASE n == 63 .AND. ! lPh ; v := Dp_AsI16( p ) ; e[ "light_color" ] := Cl_FromIndex( IIf( v == NIL, 256, v ) )
      CASE n == 421 ; v := Dp_AsI32Bits( p ) ; e[ "light_color" ] := Cl_FromTrueColorValue( IIf( v == NIL, 0, v ) )
      CASE n == 291 ; v := Dp_AsI16( p ) ; e[ "plot_glyph" ] := ( IIf( v == NIL, 0, v ) != 0 )
      CASE n == 40 .AND. ! lPh ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "intensity" ] := v ; ENDIF
      CASE n == 10 .OR. n == 20 .OR. n == 30 ; PR_AddCoordinate( prPos, p )
      CASE n == 11 .OR. n == 21 .OR. n == 31 ; PR_AddCoordinate( prTgt, p )
      CASE n == 72 .AND. ! lPh ; v := Dp_AsI32( p ) ; IF v != NIL ; e[ "attenuation_type" ] := v ; ENDIF
      CASE n == 292 ; v := Dp_AsI16( p ) ; e[ "use_attenuation_limits" ] := ( IIf( v == NIL, 0, v ) != 0 )
      CASE n == 41 .AND. ! lPh ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "attenuation_start_limit" ] := v ; ENDIF
      CASE n == 42 .AND. ! lPh ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "attenuation_end_limit" ] := v ; ENDIF
      CASE n == 50 .AND. ! lPh ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "hotspot_angle" ] := v ; ENDIF
      CASE n == 51 .AND. ! lPh ; v := Dp_AsDouble( p ) ; IF v != NIL ; e[ "falloff_angle" ] := v ; ENDIF
      CASE n == 293 ; v := Dp_AsI16( p ) ; e[ "cast_shadows" ] := ( IIf( v == NIL, 0, v ) != 0 )
      CASE n == 73 .AND. ! lPh ; v := Dp_AsI32( p ) ; IF v != NIL ; e[ "shadow_type" ] := v ; ENDIF
      CASE n == 91 ; v := Dp_AsI16( p ) ; IF v != NIL ; e[ "shadow_map_size" ] := v ; ENDIF
      CASE n == 280 .AND. ! lPh ; v := Dp_AsI16( p ) ; e[ "shadow_map_softness" ] := Max( 0, Min( 255, IIf( v == NIL, 0, v ) ) )
      CASE n == 295 ; lPh := .T. ; e[ "photometric_mode" ] := .T.
      CASE n == 290 .AND. lPh ; v := Dp_AsI16( p ) ; ph[ "has_web_file" ] := ( IIf( v == NIL, 0, v ) != 0 )
      CASE n == 300 .AND. lPh ; ph[ "web_file" ] := p[ DP_VALUE ]
      CASE n == 70 .AND. lPh ; v := Dp_AsI16( p ) ; ph[ "physical_intensity_method" ] := IIf( v == NIL, 0, v )
      CASE n == 40 .AND. lPh ; v := Dp_AsDouble( p ) ; ph[ "physical_intensity" ] := IIf( v == NIL, 0.0, v )
      CASE n == 41 .AND. lPh ; v := Dp_AsDouble( p ) ; ph[ "illuminance_distance" ] := IIf( v == NIL, 0.0, v )
      CASE n == 71 .AND. lPh ; v := Dp_AsI16( p ) ; ph[ "lamp_color_type" ] := IIf( v == NIL, 0, v )
      CASE n == 42 .AND. lPh ; v := Dp_AsDouble( p ) ; ph[ "lamp_color_temperature" ] := IIf( v == NIL, 0.0, v )
      CASE n == 72 .AND. lPh ; v := Dp_AsI16( p ) ; ph[ "lamp_color_preset" ] := IIf( v == NIL, 0, v )
      CASE ( n == 43 .OR. n == 53 .OR. n == 63 ) .AND. lPh ; PR_AddCoordinate( prWeb, p )
      CASE n == 73 .AND. lPh ; v := Dp_AsI16( p ) ; ph[ "extended_light_shape" ] := IIf( v == NIL, 0, v )
      CASE n == 46 .AND. lPh ; v := Dp_AsDouble( p ) ; ph[ "extended_light_length" ] := IIf( v == NIL, 0.0, v )
      CASE n == 47 .AND. lPh ; v := Dp_AsDouble( p ) ; ph[ "extended_light_width" ] := IIf( v == NIL, 0.0, v )
      CASE n == 48 .AND. lPh ; v := Dp_AsDouble( p ) ; ph[ "extended_light_radius" ] := IIf( v == NIL, 0.0, v )
      CASE n == 74 .AND. lPh ; v := Dp_AsI16( p ) ; ph[ "web_file_type" ] := IIf( v == NIL, 0, v )
      CASE n == 75 .AND. lPh ; v := Dp_AsI16( p ) ; ph[ "web_symmetry" ] := IIf( v == NIL, 0, v )
      CASE n == 76 .AND. lPh ; v := Dp_AsI16( p ) ; ph[ "has_target_grip" ] := IIf( v == NIL, 0, v )
      CASE n == 49 .AND. lPh ; v := Dp_AsDouble( p ) ; ph[ "web_flux" ] := IIf( v == NIL, 0.0, v )
      CASE n >= 50 .AND. n <= 54 .AND. lPh ; v := Dp_AsDouble( p ) ; ph[ "web_angles" ][ n - 49 ] := IIf( v == NIL, 0.0, v )
      CASE n == 77 .AND. lPh ; v := Dp_AsI16( p ) ; ph[ "glyph_display_type" ] := IIf( v == NIL, 0, v )
      OTHERWISE ; Sr_EntBaseP( s, p, e )
      ENDCASE
   ENDDO
   v := PR_GetPoint( prPos ) ; e[ "position" ] := IIf( v == NIL, Vc3_Zero(), v )
   v := PR_GetPoint( prTgt ) ; e[ "target" ] := IIf( v == NIL, Vc3_Zero(), v )
   IF lPh
      v := PR_GetPoint( prWeb ) ; ph[ "web_rotation" ] := IIf( v == NIL, Vc3_New( 1.0, 1.0, 1.0 ), v )
      e[ "photometric_data" ] := ph
   ENDIF
   IF nPg != 0 .OR. Len( cPg ) > 0 ; e[ "common" ][ "graphic_data" ] := hb_BLeft( cPg, nPg ) ; ENDIF
RETURN e

STATIC FUNCTION Sx_H( p )
   LOCAL v := Sr_HexVal( p )
RETURN IIf( v == NIL, Hd_Null(), v )

STATIC FUNCTION Sx_D( p )
   LOCAL v := Dp_AsDouble( p )
RETURN IIf( v == NIL, 0.0, v )

/* read_section_symbol_dxf (SECTIONLINE) */
FUNCTION Sr_ReadSectionSymbol( s )
   LOCAL e := Esy_New(), p, n, v, cSub := "", n70 := 0, n90 := 0, pt, lPt := .F.
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      n := p[ DP_CODE ]
      IF n == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      IF n == 100 ; cSub := p[ DP_VALUE ] ; LOOP ; ENDIF
      IF cSub == "AcDbViewSymbol"
         DO CASE
         CASE n == 70
            v := Dp_AsI16( p ) ; v := IIf( v == NIL, 0, v )
            IF n70 == 0 ; e[ "view_symbol_version" ] := v ; ELSEIF n70 == 1 ; e[ "raw_view_symbol_70" ] := v ; ENDIF
            n70++
         CASE n == 340 ; e[ "style_handle" ] := Sx_H( p )
         CASE n == 40 ; v := Dp_AsDouble( p ) ; e[ "symbol_scale" ] := IIf( v == NIL, 1.0, v )
         CASE n == 330 ; e[ "view_rep_handle" ] := Sx_H( p )
         ENDCASE
      ELSEIF cSub == "AcDbSectionSymbol"
         DO CASE
         CASE n == 70 ; v := Dp_AsI16( p ) ; e[ "version" ] := IIf( v == NIL, 0, v )
         CASE n == 90
            v := Dp_AsI32( p ) ; v := IIf( v == NIL, 0, v )
            IF n90 == 0 ; e[ "raw_point_count_90" ] := v ; ELSEIF n90 == 1 ; e[ "raw_flags_90" ] := v ; ELSEIF n90 == 2 ; e[ "raw_point_record_count" ] := v ; ENDIF
            n90++
         CASE n == 10
            pt := Ssp_New() ; pt[ "point" ][ 1 ] := Sx_D( p ) ; AAdd( e[ "points" ], pt ) ; lPt := .T.
         CASE ! lPt
            /* sin punto abierto: se ignora */
         CASE n == 20 ; ATail( e[ "points" ] )[ "point" ][ 2 ] := Sx_D( p )
         CASE n == 30 ; ATail( e[ "points" ] )[ "point" ][ 3 ] := Sx_D( p )
         CASE n == 40 ; ATail( e[ "points" ] )[ "bulge" ] := Sx_D( p )
         CASE n == 1 ; ATail( e[ "points" ] )[ "label" ] := p[ DP_VALUE ]
         CASE n == 11 ; ATail( e[ "points" ] )[ "label_offset" ][ 1 ] := Sx_D( p )
         CASE n == 21 ; ATail( e[ "points" ] )[ "label_offset" ][ 2 ] := Sx_D( p )
         CASE n == 31 ; ATail( e[ "points" ] )[ "label_offset" ][ 3 ] := Sx_D( p )
         CASE n == 280 ; v := Dp_AsI16( p ) ; ATail( e[ "points" ] )[ "raw_flag_280" ] := IIf( v == NIL, 0, v )
         ENDCASE
      ELSE
         Sr_EntBaseP( s, p, e )
      ENDIF
   ENDDO
   Esy_SyncDisplayFields( e )
RETURN e

/* read_view_border_dxf (DRAWINGVIEW) */
FUNCTION Sr_ReadViewBorder( s )
   LOCAL e := Evb_New(), p, n, v, cSub := "", nPt := 0, nD := 0
   DO WHILE ( p := Sr_Next( s ) ) != NIL
      n := p[ DP_CODE ]
      IF n == 0 ; Sr_PushBack( s, p ) ; EXIT ; ENDIF
      IF n == 100 ; cSub := p[ DP_VALUE ] ; LOOP ; ENDIF
      IF cSub == "AcDbViewBorder"
         DO CASE
         CASE n == 70 ; v := Dp_AsI16( p ) ; e[ "version" ] := IIf( v == NIL, 0, v )
         CASE n == 10
            IF nPt == 0 ; e[ "min" ][ 1 ] := Sx_D( p ) ; ELSEIF nPt == 1 ; e[ "max" ][ 1 ] := Sx_D( p ) ; ENDIF
         CASE n == 20
            IF nPt == 0 ; e[ "min" ][ 2 ] := Sx_D( p ) ; ELSEIF nPt == 1 ; e[ "max" ][ 2 ] := Sx_D( p ) ; ENDIF
            nPt++
         CASE n == 330 ; e[ "active_viewport" ] := Sx_H( p )
         CASE n == 40
            v := Sx_D( p )
            DO CASE
            CASE nD == 0 ; e[ "scale" ] := v
            CASE nD == 1 ; e[ "rotation_angle" ] := v
            CASE nD == 2 ; e[ "center" ][ 1 ] := v
            CASE nD == 3 ; e[ "center" ][ 2 ] := v
            ENDCASE
            nD++
         CASE n == 340 ; e[ "scale_handle" ] := Sx_H( p )
         ENDCASE
      ELSE
         Sr_EntBaseP( s, p, e )
      ENDIF
   ENDDO
RETURN e
