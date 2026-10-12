/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/f64fmt.prg
   Formateo de f64 como Rust. No tiene fichero Rust propio: sustituye a ryu::Buffer::format
   (usado por binary_reader.rs) y al Display de f64 (usado por los writers DXF).
   Digitos mas cortos con round-trip por C (OCX_F64DIGITS).
     F64_Ryu( n )     -> "1.0", "1.5", "1e21", "1.5e-7", "NaN", "inf", "-inf", "-0.0"
     F64_Display( n ) -> como {} de Rust: nunca exponente ("1", "1.5", "0.0000001", "1000000000000000000000")
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION F64_Ryu( n )
   LOCAL a, cD, k, nL, kk, cS
   IF OCX_ISNAN( n ) ; RETURN "NaN" ; ENDIF
   IF ! OCX_ISFINITE( n ) ; RETURN IIf( n < 0, "-inf", "inf" ) ; ENDIF
   cS := IIf( OCX_COPYSIGN1( n ) < 0, "-", "" )
   IF n == 0 ; RETURN cS + "0.0" ; ENDIF
   a := OCX_F64DIGITS( n ) ; cD := a[ 1 ] ; k := a[ 2 ] ; nL := Len( cD ) ; kk := nL + k
   DO CASE
   CASE k >= 0 .AND. kk <= 16
      RETURN cS + cD + Replicate( "0", k ) + ".0"
   CASE kk > 0 .AND. kk <= 16
      RETURN cS + Left( cD, kk ) + "." + SubStr( cD, kk + 1 )
   CASE kk > -5 .AND. kk <= 0
      RETURN cS + "0." + Replicate( "0", -kk ) + cD
   ENDCASE
RETURN cS + Left( cD, 1 ) + IIf( nL > 1, "." + SubStr( cD, 2 ), "" ) + "e" + hb_ntos( kk - 1 )

FUNCTION F64_Display( n )
   LOCAL a, cD, k, nL, kk, cS
   IF OCX_ISNAN( n ) ; RETURN "NaN" ; ENDIF
   IF ! OCX_ISFINITE( n ) ; RETURN IIf( n < 0, "-inf", "inf" ) ; ENDIF
   cS := IIf( OCX_COPYSIGN1( n ) < 0, "-", "" )
   IF n == 0 ; RETURN cS + "0" ; ENDIF
   a := OCX_F64DIGITS( n ) ; cD := a[ 1 ] ; k := a[ 2 ] ; nL := Len( cD ) ; kk := nL + k
   IF k >= 0 ; RETURN cS + cD + Replicate( "0", k ) ; ENDIF
   IF kk > 0 ; RETURN cS + Left( cD, kk ) + "." + SubStr( cD, kk + 1 ) ; ENDIF
RETURN cS + "0." + Replicate( "0", -kk ) + cD
