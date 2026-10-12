/* [extra] Validacion con DXF reales del repo original (OpenCADStudio/tests/fixtures): lee -> escribe -> relee.
   Comprueba que se conservan entidades, objetos y tablas (los tipos diferidos viajan como Unknown/raw). */
#include "ocx.ch"

STATIC FUNCTION Rl_Cnt( h, c ) ; h[ c ] := IIf( hb_HHasKey( h, c ), h[ c ] + 1, 1 ) ; RETURN NIL

STATIC FUNCTION Rl_Summ( d )
   LOCAL s := hb_Hash(), e, o, k
   FOR EACH e IN d[ "entities" ] ; Rl_Cnt( s, "E:" + e[ "_type" ] ) ; NEXT
   FOR EACH o IN hb_HValues( d[ "objects" ] ) ; Rl_Cnt( s, "O:" + o[ "_type" ] ) ; NEXT
   FOR EACH k IN { "layers", "line_types", "text_styles", "block_records", "dim_styles", "app_ids", "views", "vports", "ucss" }
      s[ "T:" + k ] := Len( Tb_Values( d[ k ] ) )
   NEXT
RETURN s

/* cuenta tipos del fichero crudo: seccion:tipo (sin CLASSES/TABLES, que el escritor completa; OBJECTS solo si lObj: el escritor anade DICTIONARY/LAYOUT raiz) */
STATIC FUNCTION Rl_Raw( c, lObj )
   LOCAL a := hb_ATokens( StrTran( c, Chr( 13 ), "" ), Chr( 10 ) ), i, s := hb_Hash(), sec := "", t
   FOR i := 1 TO Len( a ) - 1 STEP 2
      IF AllTrim( a[ i ] ) == "0"
         t := AllTrim( a[ i + 1 ] )
         IF t == "SECTION" ; sec := AllTrim( a[ i + 3 ] ) ; ENDIF
         IF ! t $ "SECTION ENDSEC EOF TABLE ENDTAB ENDBLK" .AND. ( sec $ "ENTITIES BLOCKS" .OR. ( lObj .AND. sec == "OBJECTS" ) )
            Rl_Cnt( s, sec + ":" + t )
         ENDIF
      ENDIF
   NEXT
RETURN s

STATIC FUNCTION Rl_Same( a, b )
   LOCAL k
   IF Len( a ) != Len( b ) ; RETURN .F. ; ENDIF
   FOR EACH k IN hb_HKeys( a )
      IF ! hb_HHasKey( b, k ) .OR. ! a[ k ] == b[ k ] ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.

STATIC PROCEDURE Rl_One( cF, nEnt, nObj, lStrictObj )
   LOCAL c := hb_MemoRead( cF ), d, d2, w
   IF Empty( c ) ; Chk( .F., "dxf real: no se encuentra " + cF ) ; RETURN ; ENDIF
   d := Dxr_ReadString( c )
   IF ! Chk( ValType( d ) == "H", "dxf real " + cF + ": lectura" ) ; RETURN ; ENDIF
   Chk( Len( d[ "entities" ] ) == nEnt, "dxf real " + cF + ": entidades=" + hb_ntos( nEnt ) )
   Chk( Len( d[ "objects" ] ) == nObj, "dxf real " + cF + ": objetos=" + hb_ntos( nObj ) )
   w := Dxw_WriteString( d )
   Chk( Rl_Same( Rl_Raw( c, lStrictObj ), Rl_Raw( w, lStrictObj ) ), "dxf real " + cF + ": ENTITIES/BLOCKS/OBJECTS conservados al escribir" )
   d2 := Dxr_ReadString( w )
   IF ! Chk( ValType( d2 ) == "H", "dxf real " + cF + ": relectura" ) ; RETURN ; ENDIF
   Chk( Rl_Same( Rl_Summ( d ), Rl_Summ( d2 ) ), "dxf real " + cF + ": leido == releido" )
RETURN

PROCEDURE T_DxfReal()
   Rl_One( "tests/fixtures/embedded-image-print.dxf", 10, 48, .T. )
   Rl_One( "tests/fixtures/viewport_associations.dxf", 16, 11, .F. )
   Rl_One( "tests/fixtures/page-setups-metric.dxf", 38, 139, .T. )
RETURN
