#include "ohbcad.ch"
#include "hbclass.ch"

FUNCTION Main()
   LOCAL aP, i, cFile := "C:\Users\Andres\AppData\Local\Temp\ohb_smoke.dxf"
   IF hb_argc() >= 1
      cFile := hb_argv( 1 )
   ENDIF
   OutStd( "scan-start" + hb_eol() )
   aP := OCX_DXFSCAN( cFile )
   OutStd( "scan-type=" + ValType( aP ) + hb_eol() )
   IF aP != NIL
      OutStd( "scan-len=" + LTrim( Str( Len( aP ), 0 ) ) + hb_eol() )
      FOR i := 1 TO Min( Len( aP ), 3 )
         OutStd( "el" + LTrim( Str( i, 0 ) ) + "-type=" + ValType( aP[ i ] ) + hb_eol() )
         IF ValType( aP[ i ] ) == "A"
            OutStd( "el" + LTrim( Str( i, 0 ) ) + "-len=" + ;
               LTrim( Str( Len( aP[ i ] ), 0 ) ) + hb_eol() )
            OutStd( "el" + LTrim( Str( i, 0 ) ) + "-0-type=" + ;
               ValType( aP[ i ][ 1 ] ) + hb_eol() )
            OutStd( "el" + LTrim( Str( i, 0 ) ) + "-0-val=" + ;
               hb_ValToStr( aP[ i ][ 1 ] ) + hb_eol() )
            OutStd( "el" + LTrim( Str( i, 0 ) ) + "-1-type=" + ;
               ValType( aP[ i ][ 2 ] ) + hb_eol() )
            OutStd( "el" + LTrim( Str( i, 0 ) ) + "-1-val=" + ;
               hb_ValToStr( aP[ i ][ 2 ] ) + hb_eol() )
         ELSE
            OutStd( "el" + LTrim( Str( i, 0 ) ) + "-val=" + ;
               hb_ValToStr( aP[ i ] ) + hb_eol() )
         ENDIF
      NEXT
   ENDIF
   OutStd( "scan-end" + hb_eol() )
RETURN NIL
