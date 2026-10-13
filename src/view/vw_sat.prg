/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_sat.prg
   Fase 2 / B13 (opcion B): lector de texto ACIS SAT (version 700 o anterior, la que
   llevan los 3DSOLID / REGION / BODY de los DXF). No es el lector del crate
   opencadcodec (acis::SatDocument) ni el kernel B-rep del Rust: es un lector propio
   reducido para teselar caras analiticas en el visor.
   Sat_FromEntity( e )  -> texto SAT de una entidad UNKNOWN 3DSOLID/REGION/BODY (codigos 1 y 3)
   Sat_Parse( cTexto )  -> { "version", "records" => { { "i", "type", "tok" }, ... } } o NIL
   Sat_Ptr( cTok )      -> indice de registro (0 ...) o -1 para "$-1"; NIL si no es puntero
   Sat_Rec( sat, nPtr ) -> registro apuntado o NIL
   Sat_Num( cTok )      -> numero de un token (Val)
   Sat_Find( sat, cTipo [, nDesde] ) -> posiciones de los registros de ese tipo
   N/A: SAB (binario de DWG), registros con atributos propietarios (se conservan como tokens).
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Sat_FromEntity( e )
   LOCAL c := "", r, aL := {}
   IF ! ( ValType( e ) == "H" ) .OR. ! hb_HHasKey( e, "raw_dxf_codes" ) .OR. e[ "raw_dxf_codes" ] == NIL ; RETURN "" ; ENDIF
   FOR EACH r IN e[ "raw_dxf_codes" ]
      IF r[ 1 ] == 1
         AAdd( aL, hb_CStr( r[ 2 ] ) )
      ELSEIF r[ 1 ] == 3 .AND. Len( aL ) > 0
         aL[ Len( aL ) ] += hb_CStr( r[ 2 ] )
      ENDIF
   NEXT
   FOR EACH r IN aL
      c += r + Chr( 10 )
   NEXT
RETURN c

STATIC FUNCTION Sat_Split( c )
   LOCAL a := {}, n
   c := StrTran( StrTran( c, Chr( 13 ), " " ), Chr( 9 ), " " )
   DO WHILE ! Empty( c )
      c := LTrim( c )
      IF Empty( c ) ; EXIT ; ENDIF
      n := At( " ", c )
      IF n == 0 ; AAdd( a, c ) ; EXIT ; ENDIF
      AAdd( a, Left( c, n - 1 ) )
      c := SubStr( c, n + 1 )
   ENDDO
RETURN a

STATIC FUNCTION Sat_IsInt( c )
   LOCAL i, n := Len( c )
   IF n == 0 ; RETURN .F. ; ENDIF
   FOR i := 1 TO n
      IF ! ( SubStr( c, i, 1 ) $ "0123456789" .OR. ( i == 1 .AND. SubStr( c, i, 1 ) == "-" .AND. n > 1 ) ) ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.

FUNCTION Sat_Parse( cText )
   LOCAL aL, nVer, nEnd, cBody := "", i, aRec := {}, aR, aT, n, nI
   IF ! ( ValType( cText ) == "C" ) .OR. Empty( cText ) ; RETURN NIL ; ENDIF
   aL := hb_ATokens( StrTran( cText, Chr( 13 ), "" ), Chr( 10 ) )
   IF Len( aL ) < 4 ; RETURN NIL ; ENDIF
   aT := Sat_Split( aL[ 1 ] )
   IF Len( aT ) < 1 .OR. ! Sat_IsInt( aT[ 1 ] ) ; RETURN NIL ; ENDIF
   nVer := Int( Val( aT[ 1 ] ) )
   nEnd := Len( aL )
   FOR i := 4 TO Len( aL )
      IF "End-of-ACIS-data" $ aL[ i ] ; nEnd := i - 1 ; EXIT ; ENDIF
   NEXT
   FOR i := 4 TO nEnd
      cBody += aL[ i ] + " "
   NEXT
   FOR EACH aR IN hb_ATokens( cBody, "#" )
      aT := Sat_Split( aR )
      IF Len( aT ) == 0 ; LOOP ; ENDIF
      nI := Len( aRec )
      IF Len( aT ) >= 2 .AND. Sat_IsInt( aT[ 1 ] ) .AND. Left( aT[ 1 ], 1 ) == "-" .AND. ! Sat_IsInt( aT[ 2 ] )
         nI := - Int( Val( aT[ 1 ] ) )
         hb_ADel( aT, 1, .T. )
      ENDIF
      AAdd( aRec, hb_Hash( "i", nI, "type", aT[ 1 ], "tok", hb_ADel( aT, 1, .T. ) ) )
   NEXT
   n := Len( aRec )
   IF n == 0 ; RETURN NIL ; ENDIF
RETURN hb_Hash( "version", nVer, "records", aRec )

FUNCTION Sat_Ptr( cTok )
   IF ! ( ValType( cTok ) == "C" ) .OR. Len( cTok ) < 2 .OR. Left( cTok, 1 ) != "$" ; RETURN NIL ; ENDIF
RETURN Int( Val( SubStr( cTok, 2 ) ) )

FUNCTION Sat_Rec( sat, nPtr )
   IF nPtr == NIL .OR. nPtr < 0 .OR. nPtr >= Len( sat[ "records" ] ) ; RETURN NIL ; ENDIF
RETURN sat[ "records" ][ nPtr + 1 ]

FUNCTION Sat_Num( cTok ) ; RETURN Val( cTok )

FUNCTION Sat_Find( sat, cTipo )
   LOCAL a := {}, i
   FOR i := 1 TO Len( sat[ "records" ] )
      IF sat[ "records" ][ i ][ "type" ] == cTipo ; AAdd( a, i - 1 ) ; ENDIF
   NEXT
RETURN a
