/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/obj_visualstyle.prg
   Origen Rust: opencadcodec/src/objects/stub_objects.rs, lineas 1-441 y 589-596 (VisualStyle y VisualStyleProperty/Value). El fichero Rust no tiene #[test].
   Licencia del original: MPL-2.0. Prefijo: Vsy_ (propiedades: Vsp_).
   VisualStylePropertyValue = hash { "_kind": "Short"|"Long"|"Double"|"Bool"|"Color"|"Text", "value": x }; VisualStyleProperty = hash { value, enabled }.
   core_properties / extended_properties / legacy_properties / restore_post_2010_properties portados 1:1 (pub(crate) en Rust).
   Aritmetica: `as i32` / `as i16` de f64 -> Int() (trunca hacia cero; sin saturacion, igual en los rangos reales).
   NO portadas todavia (dependen de CadDocument): store_visual_style_roundtrip y restore_visual_style_roundtrip (lineas 442-588).
   El resto de stub_objects.rs (Material, GeoData, SpatialFilter, RasterVariables, BookColor, PlaceHolder, DictionaryWithDefault,
   WipeoutVariables y el trait StubObject) va en obj_stubs.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Vsp_Value( cKind, xVal ) ; RETURN hb_Hash( "_kind", cKind, "value", xVal )
FUNCTION Vsp_New( cKind, xVal, nEnabled ) ; RETURN hb_Hash( "value", Vsp_Value( cKind, xVal ), "enabled", nEnabled )

FUNCTION Vsy_New()
RETURN hb_Hash( "_type", "VisualStyle", "handle", Hd_Null(), "owner", Hd_Null(), "reactors", {}, "xdictionary_handle", NIL, "description", "", "style_type", 0, ;
   "face_lighting_model", 0, "face_lighting_quality", 0, "face_color_mode", 0, "face_modifier", 0, "edge_model", 0, "edge_style", 0, "internal_use_only", .F., ;
   "extended_lighting_model", 2, "properties", {} )
FUNCTION Vsy_Default() ; RETURN Vsy_New()

STATIC FUNCTION Vl( n ) ; RETURN Vsp_New( "Long", n, 1 )
STATIC FUNCTION Vd( n ) ; RETURN Vsp_New( "Double", n, 1 )
STATIC FUNCTION Vb( l ) ; RETURN Vsp_New( "Bool", l, 1 )
STATIC FUNCTION Vc( c, nEn ) ; RETURN Vsp_New( "Color", c, nEn )

STATIC FUNCTION Vsy_CloneProp( p ) ; RETURN Ent_Clone( p )

FUNCTION Vsy_CoreProperties( s )
   LOCAL v, a := s[ "properties" ], i, aMap, m, src, xNum, hNew, cK, nLegacy, nModern
   v := { Vl( s[ "face_lighting_model" ] ), Vl( s[ "face_lighting_quality" ] ), Vl( s[ "face_color_mode" ] ), Vl( s[ "face_modifier" ] ), ;
      Vd( 0.6 ), Vd( 30.0 ), Vc( Cl_Index( 7 ), 1 ), Vl( s[ "edge_model" ] ), Vl( s[ "edge_style" ] ), Vc( Cl_ByLayer(), 1 ), Vc( Cl_ByBlock(), 1 ), ;
      Vl( 1 ), Vl( 1 ), Vd( 1.0 ), Vl( 0 ), Vc( Cl_ByLayer(), 1 ), Vd( 1.0 ), Vl( 1 ), Vl( 6 ), Vl( 2 ), Vc( Cl_ByLayer(), 1 ), Vl( 5 ), Vl( 0 ), Vl( 0 ), Vb( .F. ), Vl( 1 ), Vd( 0.0 ), Vl( 0 ) }
   IF Len( a ) >= 28
      FOR i := 1 TO 28
         v[ i ] := Vsy_CloneProp( a[ i ] )
      NEXT
   ELSEIF Len( a ) == 24
      aMap := { { 0, 4 }, { 1, 5 }, { 2, 6 }, { 3, 9 }, { 4, 10 }, { 5, 11 }, { 6, 13 }, { 7, 14 }, { 8, 15 }, { 9, 16 }, { 10, 17 }, { 11, 18 }, { 12, 19 }, ;
         { 13, 20 }, { 14, 21 }, { 15, 22 }, { 16, 23 }, { 17, 24 }, { 19, 12 }, { 20, 25 }, { 21, 26 }, { 22, 27 } }
      FOR EACH m IN aMap
         nLegacy := m[ 1 ] ; nModern := m[ 2 ]
         src := a[ nLegacy + 1 ]
         xNum := NIL
         cK := src[ "value" ][ "_kind" ]
         IF cK == "Short" .OR. cK == "Long" .OR. cK == "Double"
            xNum := src[ "value" ][ "value" ]
         ELSEIF cK == "Bool"
            xNum := iif( src[ "value" ][ "value" ], 1, 0 )
         ENDIF
         cK := v[ nModern + 1 ][ "value" ][ "_kind" ]
         IF cK == "Long" .AND. xNum != NIL
            hNew := Vsp_Value( "Long", Int( xNum ) )
         ELSEIF cK == "Double" .AND. xNum != NIL .AND. ( nModern == 4 .OR. nModern == 5 )
            hNew := Vsp_Value( "Double", Abs( xNum ) )
         ELSEIF cK == "Double" .AND. xNum != NIL
            hNew := Vsp_Value( "Double", xNum )
         ELSEIF cK == "Bool" .AND. xNum != NIL
            hNew := Vsp_Value( "Bool", xNum != 0 )
         ELSE
            hNew := Ent_Clone( src[ "value" ] )
         ENDIF
         v[ nModern + 1 ] := hb_Hash( "value", hNew, "enabled", src[ "enabled" ] )
      NEXT
   ELSE
      FOR i := 1 TO Min( Len( a ), 28 )
         v[ i ] := Vsy_CloneProp( a[ i ] )
      NEXT
   ENDIF
   v[ 1 ][ "value" ] := Vsp_Value( "Long", s[ "face_lighting_model" ] )
   v[ 2 ][ "value" ] := Vsp_Value( "Long", s[ "face_lighting_quality" ] )
   v[ 3 ][ "value" ] := Vsp_Value( "Long", s[ "face_color_mode" ] )
   v[ 4 ][ "value" ] := Vsp_Value( "Long", s[ "face_modifier" ] )
   v[ 8 ][ "value" ] := Vsp_Value( "Long", s[ "edge_model" ] )
   v[ 9 ][ "value" ] := Vsp_Value( "Long", s[ "edge_style" ] )
RETURN v

FUNCTION Vsy_ExtendedProperties( s )
   LOCAL a := s[ "properties" ], i, r := {}
   IF Len( a ) >= 58
      FOR i := 29 TO 58
         AAdd( r, Vsy_CloneProp( a[ i ] ) )
      NEXT
      RETURN r
   ENDIF
RETURN { Vb( .F. ), Vb( .T. ), Vb( .T. ), Vb( .F. ), Vb( .F. ), Vb( .F. ), Vb( .F. ), Vb( .F. ), Vb( .F. ), Vl( 50 ), Vd( 0.0 ), Vd( 1.0 ), Vl( 0 ), ;
   Vc( Cl_FromRgb( 0, 0, 0 ), 1 ), Vl( 50 ), Vl( 3 ), Vc( Cl_FromRgb( 0, 0, 255 ), 1 ), Vb( .F. ), Vl( 50 ), Vl( 50 ), Vl( 50 ), Vb( .F. ), Vl( 50 ), ;
   Vc( Cl_ByLayer(), 0 ), Vsp_New( "Double", 1.0, 0 ), Vl( 2 ), Vsp_New( "Text", "strokes_ogs.tif", 1 ), Vb( .F. ), Vd( 1.0 ), Vd( 1.0 ) }

STATIC FUNCTION Vsy_Signed( s, p, nBit )
   LOCAL c := Vsy_CloneProp( p ), n
   IF c[ "value" ][ "_kind" ] == "Double"
      n := c[ "value" ][ "value" ]
      c[ "value" ][ "value" ] := iif( hb_bitAnd( s[ "face_modifier" ], nBit ) != 0, Abs( n ), - Abs( n ) )
   ENDIF
RETURN c

FUNCTION Vsy_LegacyProperties( s )
   LOCAL c, r := {}, i, a := s[ "properties" ]
   IF Len( a ) == 24
      RETURN Ent_Clone( a )
   ENDIF
   c := Vsy_CoreProperties( s )
   AAdd( r, Vsy_Signed( s, c[ 5 ], 1 ) )
   AAdd( r, Vsy_Signed( s, c[ 6 ], 2 ) )
   FOR EACH i IN { 6, 9, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24 }
      AAdd( r, Vsy_CloneProp( c[ i + 1 ] ) )
   NEXT
   AAdd( r, Vsp_New( "Short", 0, 1 ) )
   FOR EACH i IN { 12, 25, 26, 27 }
      AAdd( r, Vsy_CloneProp( c[ i + 1 ] ) )
   NEXT
   AAdd( r, Vd( 0.0 ) )
RETURN r

/* "+"? y solo digitos -> entero, si no NIL (usize::parse) */
STATIC FUNCTION Vsy_ParseUsize( c )
   LOCAL i
   IF Left( c, 1 ) == "+" ; c := SubStr( c, 2 ) ; ENDIF
   IF Len( c ) == 0 ; RETURN NIL ; ENDIF
   FOR i := 1 TO Len( c )
      IF ! IsDigit( SubStr( c, i, 1 ) ) ; RETURN NIL ; ENDIF
   NEXT
RETURN Val( c )

/* entries = array de XRecordEntry (obj_xrecord.prg); devuelve .T./.F. y actualiza s["properties"] */
FUNCTION Vsy_RestorePost2010Properties( s, aEntries )
   LOCAL p, nCI := NIL, lFound := .F., i, key, v, flag, rest, nIdx, nDig, prop, xNum, hNew, nRaw, nIndex, cK, cTail
   IF Len( s[ "properties" ] ) != 24 ; RETURN .F. ; ENDIF
   p := Vsy_CoreProperties( s )
   FOR EACH i IN Vsy_ExtendedProperties( s )
      AAdd( p, i )
   NEXT
   FOR i := 1 TO Len( aEntries ) - 1
      key := Xrv_AsString( aEntries[ i ][ "value" ] )
      IF key == NIL ; LOOP ; ENDIF
      v := aEntries[ i + 1 ][ "value" ]
      flag := iif( v[ "_kind" ] == "Int16", v[ "value" ], NIL )
      IF Left( key, 14 ) == "RTVSPropertyOp"
         nIdx := Vsy_ParseUsize( SubStr( key, 15 ) )
         IF nIdx != NIL .AND. flag != NIL .AND. nIdx < Len( p )
            p[ nIdx + 1 ][ "enabled" ] := flag ; lFound := .T.
         ENDIF
         LOOP
      ENDIF
      IF Left( key, 18 ) == "RTVSPost2010PropOp"
         nIdx := Vsy_ParseUsize( SubStr( key, 19 ) )
         IF nIdx != NIL .AND. flag != NIL .AND. nIdx < Len( p )
            p[ nIdx + 1 ][ "enabled" ] := flag ; lFound := .T.
         ENDIF
         LOOP
      ENDIF
      IF ! Left( key, 16 ) == "RTVSPost2010Prop" ; LOOP ; ENDIF
      rest := SubStr( key, 17 )
      nDig := 0
      DO WHILE nDig < Len( rest ) .AND. IsDigit( SubStr( rest, nDig + 1, 1 ) )
         nDig++
      ENDDO
      IF nDig == 0 ; LOOP ; ENDIF
      nIdx := Val( Left( rest, nDig ) )
      IF nIdx >= Len( p ) ; LOOP ; ENDIF
      prop := p[ nIdx + 1 ]
      cTail := SubStr( rest, nDig + 1 )
      xNum := NIL
      cK := v[ "_kind" ]
      IF cK == "Byte" .OR. cK == "Int16" .OR. cK == "Int32" .OR. cK == "Double"
         xNum := v[ "value" ]
      ELSEIF cK == "Bool"
         xNum := iif( v[ "value" ], 1, 0 )
      ENDIF
      hNew := NIL
      IF cTail == "ColorIndex" .AND. xNum != NIL
         nCI := Int( xNum )
         LOOP
      ELSEIF cTail == "ColorRGB" .AND. xNum != NIL
         nRaw := hb_bitAnd( Int( xNum ), 4294967295 )
         nIndex := iif( nCI == NIL, 256, nCI )
         nCI := NIL
         IF nIndex == 0 .OR. nIndex == 256 .OR. nIndex == 257
            hNew := Vsp_Value( "Color", Cl_FromIndex( nIndex ) )
         ELSEIF hb_bitShift( nRaw, -24 ) == 0
            hNew := Vsp_Value( "Color", Cl_FromTrueColorValue( nRaw ) )
         ELSE
            hNew := Vsp_Value( "Color", Cl_FromIndex( nIndex ) )
         ENDIF
      ELSEIF cTail == "" .AND. prop[ "value" ][ "_kind" ] == "Bool" .AND. xNum != NIL
         hNew := Vsp_Value( "Bool", xNum != 0 )
      ELSEIF cTail == "" .AND. prop[ "value" ][ "_kind" ] == "Long" .AND. xNum != NIL
         hNew := Vsp_Value( "Long", Int( xNum ) )
      ELSEIF cTail == "" .AND. prop[ "value" ][ "_kind" ] == "Double" .AND. xNum != NIL
         hNew := Vsp_Value( "Double", xNum )
      ELSEIF cTail == "" .AND. prop[ "value" ][ "_kind" ] == "Text"
         IF Xrv_AsString( v ) == NIL ; LOOP ; ENDIF
         hNew := Vsp_Value( "Text", v[ "value" ] )
      ELSE
         LOOP
      ENDIF
      prop[ "value" ] := hNew
      lFound := .T.
   NEXT
   IF lFound
      s[ "properties" ] := p
   ENDIF
RETURN lFound
