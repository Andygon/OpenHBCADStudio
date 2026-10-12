/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/tb_table.prg
   Origen Rust: opencadcodec/src/tables/mod.rs (445 lineas, 7 tests en t_codec_tables.prg): normalize_name, key_matches, trait TableEntry, Table<T>. Licencia del original: MPL-2.0.
   Table = hash { "handle", "entries" } con "entries" = hash ordenado (orden de insercion, como IndexMap) clave normalizada -> entrada.
   Una entrada es un hash con al menos "handle" y "name" (trait TableEntry: handle/set_handle/name/set_name son acceso directo a esas claves; is_standard por tipo en cada tabla).
   Result<(),String>: NIL = Ok, cadena = Err. Option<T>: NIL = None. rename/resync reconstruyen el hash para conservar posiciones (shift_insert).
   DIVERGENCIA: normalize_name usa to_uppercase Unicode; aqui Upper() con la pagina UTF8EX (supone cadenas en UTF-8; ver decision code_page pendiente). No expande 'ss' alemana (Rust: "STRASSE").
----------------------------------------------------------------------------*/
#include "ocx.ch"

REQUEST HB_CODEPAGE_UTF8EX

FUNCTION Tb_NormalizeName( cName )
   LOCAL cOld := hb_cdpSelect( "UTF8EX" ), cUp := Upper( cName )
   hb_cdpSelect( cOld )
RETURN cUp

STATIC FUNCTION Tb_KeyMatches( cKey, cName )
   LOCAL cN := Tb_NormalizeName( cName ), cRest
   IF Left( cKey, Len( cN ) ) != cN ; RETURN .F. ; ENDIF
   cRest := SubStr( cKey, Len( cN ) + 1 )
RETURN Len( cRest ) == 0 .OR. Left( cRest, 1 ) == Chr( 0 )

FUNCTION Tb_New() ; RETURN hb_Hash( "handle", Hd_Null(), "entries", hb_Hash() )
FUNCTION Tb_WithHandle( h ) ; LOCAL t := Tb_New() ; t[ "handle" ] := h ; RETURN t
FUNCTION Tb_Handle( t ) ; RETURN t[ "handle" ]
FUNCTION Tb_SetHandle( t, h ) ; t[ "handle" ] := h ; RETURN NIL
FUNCTION Tb_Add( t, e )
   LOCAL k := Tb_NormalizeName( e[ "name" ] )
   IF hb_HHasKey( t[ "entries" ], k ) ; RETURN "Entry '" + e[ "name" ] + "' already exists in table" ; ENDIF
   t[ "entries" ][ k ] := e
RETURN NIL
FUNCTION Tb_AddOrReplace( t, e ) ; t[ "entries" ][ Tb_NormalizeName( e[ "name" ] ) ] := e ; RETURN NIL
FUNCTION Tb_AddAllowDuplicate( t, e )
   LOCAL cName := Tb_NormalizeName( e[ "name" ] ), hE := t[ "entries" ], h := e[ "handle" ], k, n := 1
   IF ! hb_HHasKey( hE, cName ) ; hE[ cName ] := e ; RETURN NIL ; ENDIF
   IF Hd_IsValid( h )
      k := cName + Chr( 0 ) + Hd_UpperHex( h )
   ELSE
      k := cName + Chr( 0 ) + hb_ntos( Len( hE ) )
   ENDIF
   DO WHILE hb_HHasKey( hE, k )
      k := cName + Chr( 0 ) + hb_ntos( Hd_Value( h ) ) + "-" + hb_ntos( n )
      n++
   ENDDO
   hE[ k ] := e
RETURN NIL
FUNCTION Tb_Get( t, cName )
   LOCAL k := Tb_NormalizeName( cName )
RETURN iif( hb_HHasKey( t[ "entries" ], k ), t[ "entries" ][ k ], NIL )
FUNCTION Tb_Remove( t, cName )
   LOCAL k := Tb_NormalizeName( cName ), e
   IF ! hb_HHasKey( t[ "entries" ], k ) ; RETURN NIL ; ENDIF
   e := t[ "entries" ][ k ] ; hb_HDel( t[ "entries" ], k )
RETURN e
FUNCTION Tb_Contains( t, cName ) ; RETURN hb_HHasKey( t[ "entries" ], Tb_NormalizeName( cName ) )

/* reemplaza la clave de la posicion nIdx (base 1) manteniendo el orden de todas las demas */
STATIC FUNCTION Tb_RekeyAt( t, nIdx, cNewKey, e )
   LOCAL hN := hb_Hash(), hO := t[ "entries" ], i, n := Len( hO )
   FOR i := 1 TO n
      IF i == nIdx
         hN[ cNewKey ] := e
      ELSE
         hN[ hb_HKeyAt( hO, i ) ] := hb_HValueAt( hO, i )
      ENDIF
   NEXT
   t[ "entries" ] := hN
RETURN NIL
FUNCTION Tb_Rename( t, cOld, cNew )
   LOCAL kOld := Tb_NormalizeName( cOld ), kNew := Tb_NormalizeName( cNew ), nIdx := hb_HPos( t[ "entries" ], kOld ), e
   IF nIdx == 0 ; RETURN "Entry '" + cOld + "' does not exist in table" ; ENDIF
   IF kOld != kNew .AND. hb_HHasKey( t[ "entries" ], kNew ) ; RETURN "Entry '" + cNew + "' already exists in table" ; ENDIF
   e := hb_HValueAt( t[ "entries" ], nIdx )
   IF kOld == kNew ; e[ "name" ] := cNew ; RETURN NIL ; ENDIF
   e[ "name" ] := cNew
   Tb_RekeyAt( t, nIdx, kNew, e )
RETURN NIL
FUNCTION Tb_HasStaleKeys( t )
   LOCAL hE := t[ "entries" ], i
   FOR i := 1 TO Len( hE )
      IF ! Tb_KeyMatches( hb_HKeyAt( hE, i ), hb_HValueAt( hE, i )[ "name" ] ) ; RETURN .T. ; ENDIF
   NEXT
RETURN .F.
/* devuelve array de { claveAntigua, nombreNuevo } */
FUNCTION Tb_ResyncKeys( t )
   LOCAL aStale := {}, aRen := {}, hE := t[ "entries" ], i, nIdx, cKey, e, cNew, cName, cTarget, h, n, hRest
   FOR i := 1 TO Len( hE )
      IF ! Tb_KeyMatches( hb_HKeyAt( hE, i ), hb_HValueAt( hE, i )[ "name" ] ) ; AAdd( aStale, i ) ; ENDIF
   NEXT
   FOR EACH nIdx IN aStale
      hE := t[ "entries" ]
      cKey := hb_HKeyAt( hE, nIdx ) ; e := hb_HValueAt( hE, nIdx )
      cNew := e[ "name" ] ; cName := Tb_NormalizeName( cNew )
      hRest := hb_HClone( hE ) ; hb_HDel( hRest, cKey )
      IF hb_HHasKey( hRest, cName )
         h := e[ "handle" ] ; cTarget := cName + Chr( 0 ) + Hd_UpperHex( h ) ; n := 1
         DO WHILE hb_HHasKey( hRest, cTarget )
            cTarget := cName + Chr( 0 ) + Hd_UpperHex( h ) + "-" + hb_ntos( n )
            n++
         ENDDO
      ELSE
         cTarget := cName
      ENDIF
      Tb_RekeyAt( t, nIdx, cTarget, e )
      AAdd( aRen, { cKey, cNew } )
   NEXT
RETURN aRen
FUNCTION Tb_Len( t ) ; RETURN Len( t[ "entries" ] )
FUNCTION Tb_IsEmpty( t ) ; RETURN Len( t[ "entries" ] ) == 0
FUNCTION Tb_Values( t ) ; RETURN hb_HValues( t[ "entries" ] )
FUNCTION Tb_Names( t )
   LOCAL a := {}, e
   FOR EACH e IN hb_HValues( t[ "entries" ] ) ; AAdd( a, e[ "name" ] ) ; NEXT
RETURN a
FUNCTION Tb_Clear( t ) ; t[ "entries" ] := hb_Hash() ; RETURN NIL
