/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_sectsym.prg
   Origen Rust: opencadcodec/src/entities/section_symbol.rs (266, SIN tests en Rust). Licencia del original: MPL-2.0.
   Prefijos: Ssp_ (SectionSymbolPoint), Esy_ (SectionSymbol, _type "SECTIONLINE"), Svs_ (SectionViewStyle).
   end_a/end_b: arrays {x,y}. Nota: el despachador EntityType de translate/transform ignora SectionSymbol (no-op); los metodos Esy_Translate/Esy_Transform son los del trait Entity.
   Tests [extra] en t_codec_misc2.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Ssp_New() ; RETURN hb_Hash( "point", Vc3_Zero(), "bulge", 0.0, "label", "", "label_offset", Vc3_Zero(), "raw_flag_280", 0 )
FUNCTION Esy_New()
RETURN hb_Hash( "_type", "SECTIONLINE", "common", Ec_New(), "view_symbol_version", 0, "style_handle", Hd_Null(), "symbol_scale", 1.0, "view_rep_handle", Hd_Null(), "raw_view_symbol_70", 0, ;
   "version", 0, "raw_point_count_90", 0, "raw_flags_90", 0, "raw_point_record_count", 0, "points", {}, "end_a", { 0.0, 0.0 }, "end_b", { 0.0, 0.0 }, "tick_a", 0.0, "tick_b", 0.0, "label", "" )
FUNCTION Esy_SyncDisplayFields( e )
   LOCAL p := e[ "points" ], f, l, i
   IF Len( p ) == 0 ; RETURN NIL ; ENDIF
   f := p[ 1 ] ; l := p[ Len( p ) ]
   e[ "end_a" ] := { f[ "point" ][ 1 ], f[ "point" ][ 2 ] }
   e[ "end_b" ] := { l[ "point" ][ 1 ], l[ "point" ][ 2 ] }
   e[ "tick_a" ] := f[ "label_offset" ][ 2 ] ; e[ "tick_b" ] := l[ "label_offset" ][ 2 ]
   e[ "label" ] := ""
   FOR i := 1 TO Len( p )
      IF ! Empty( p[ i ][ "label" ] ) ; e[ "label" ] := p[ i ][ "label" ] ; EXIT ; ENDIF
   NEXT
RETURN NIL
FUNCTION Esy_BoundingBox( e )
   LOCAL a := {}, p, b
   IF Len( e[ "points" ] ) == 0
      a := { Vc3_New( e[ "end_a" ][ 1 ], e[ "end_a" ][ 2 ], 0.0 ), Vc3_New( e[ "end_b" ][ 1 ], e[ "end_b" ][ 2 ], 0.0 ) }
   ELSE
      FOR EACH p IN e[ "points" ] ; AAdd( a, p[ "point" ] ) ; NEXT
   ENDIF
   b := Bb3_FromPoints( a )
RETURN iif( b == NIL, Bb3_FromPoint( Vc3_Zero() ), b )
FUNCTION Esy_Translate( e, vOff )
   LOCAL p
   FOR EACH p IN e[ "points" ] ; p[ "point" ] := Vc3_Add( p[ "point" ], vOff ) ; NEXT
   e[ "end_a" ][ 1 ] += vOff[ 1 ] ; e[ "end_a" ][ 2 ] += vOff[ 2 ]
   e[ "end_b" ][ 1 ] += vOff[ 1 ] ; e[ "end_b" ][ 2 ] += vOff[ 2 ]
RETURN NIL
FUNCTION Esy_Transform( e, t )
   LOCAL p, vOrig, vTr, vOe, a, b
   FOR EACH p IN e[ "points" ]
      vOrig := p[ "point" ] ; vTr := Tf_Apply( t, vOrig ) ; vOe := Tf_Apply( t, Vc3_Add( vOrig, p[ "label_offset" ] ) )
      p[ "point" ] := vTr ; p[ "label_offset" ] := Vc3_Sub( vOe, vTr )
   NEXT
   a := Tf_Apply( t, Vc3_New( e[ "end_a" ][ 1 ], e[ "end_a" ][ 2 ], 0.0 ) )
   b := Tf_Apply( t, Vc3_New( e[ "end_b" ][ 1 ], e[ "end_b" ][ 2 ], 0.0 ) )
   e[ "end_a" ] := { a[ 1 ], a[ 2 ] } ; e[ "end_b" ] := { b[ 1 ], b[ 2 ] }
RETURN NIL
/* SectionViewStyle: solo la estructura (sin constructor en el original) */
FUNCTION Svs_New()
RETURN hb_Hash( "show_arrows", .F., "show_plane_line", .F., "show_end_lines", .F., "arrow_size", 0.0, "arrow_extension", 0.0, "label_height", 0.0, "label_offset", 0.0, "label_position", 0, ;
   "arrow_position", 0, "end_line_length", 0.0, "end_line_overshoot", 0.0, "arrow_start_handle", 0, "arrow_end_handle", 0, "arrow_is_default", .F. )
