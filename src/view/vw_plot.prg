/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_plot.prg
   Fase 2 / B14: trazado a PDF vectorial (equivalente reducido de src/io/pdf_export.rs y
   paper_catalog.rs; los stubs de src/io quedan como espejo). Logica pura, sin FiveWin.
   Plot_PaperSize( cName, lLandscape ) -> { ancho_mm, alto_mm } o NIL
   Plot_Pdf( oScene, cPaper, lLandscape, nMarginMm, lMono ) -> cadena PDF (1 pagina, extension
     del dibujo ajustada al papel, lineas con color y estilo, HATCH relleno, textos en Helvetica).
   Estilos de linea: 0 continua, 1 guiones, 2 puntos, 3 raya-punto.
   No portado: fuentes TrueType del dibujo, estilos CTB/STB, layouts multiples, imagenes.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Plot_PaperSize( cName, lLand )
   LOCAL h := hb_Hash( "A0", { 841, 1189 }, "A1", { 594, 841 }, "A2", { 420, 594 }, "A3", { 297, 420 }, "A4", { 210, 297 }, "A5", { 148, 210 }, ;
                       "LETTER", { 216, 279 }, "LEGAL", { 216, 356 }, "TABLOID", { 279, 432 }, "ARCH-A", { 229, 305 }, "ARCH-B", { 305, 457 }, ;
                       "ARCH-C", { 457, 610 }, "ARCH-D", { 610, 914 } ), a
   cName := Upper( AllTrim( cName ) )
   IF ! hb_HHasKey( h, cName ) ; RETURN NIL ; ENDIF
   a := h[ cName ]
   IF lLand == .T. ; RETURN { a[ 2 ], a[ 1 ] } ; ENDIF
RETURN { a[ 1 ], a[ 2 ] }

STATIC FUNCTION Pl_F( n ) ; RETURN hb_ntos( Round( n, 3 ) )

STATIC FUNCTION Pl_Col( nRgb, lMono )
   LOCAL r := nRgb % 256, g := Int( nRgb / 256 ) % 256, b := Int( nRgb / 65536 ) % 256
   // los colores de pantalla oscura que serian invisibles sobre papel blanco se pasan a negro
   IF lMono .OR. ( r > 235 .AND. g > 235 .AND. b > 235 ) ; RETURN "0 0 0" ; ENDIF
RETURN Pl_F( r / 255.0 ) + " " + Pl_F( g / 255.0 ) + " " + Pl_F( b / 255.0 )

STATIC FUNCTION Pl_Esc( c )
   LOCAL s := "", i, ch
   FOR i := 1 TO Len( c )
      ch := SubStr( c, i, 1 )
      IF ch == "(" .OR. ch == ")" .OR. ch == "\" ; s += "\" + ch
      ELSEIF Asc( ch ) < 32 .OR. Asc( ch ) > 126 ; s += "?"
      ELSE ; s += ch ; ENDIF
   NEXT
RETURN s

FUNCTION Plot_Pdf( oS, cPaper, lLand, nMargin, lMono )
   LOCAL aP := Plot_PaperSize( cPaper, lLand ), aE := oS[ "ext" ], nW, nH, nSc, nOx, nOy, c := "", w, p, i, f, aL, t, nPt := 72.0 / 25.4
   LOCAL aDash := { "[] 0 d", "[4 2] 0 d", "[0.5 2] 0 d", "[4 2 0.5 2] 0 d" }, aObj := {}, nPos, cOut, aOff := {}, nX, nY, nRot, nH2
   IF aP == NIL ; RETURN NIL ; ENDIF
   IF nMargin == NIL ; nMargin := 10.0 ; ENDIF
   IF lMono == NIL ; lMono := .F. ; ENDIF
   IF aE == NIL ; aE := { 0.0, 0.0, 1.0, 1.0 } ; ENDIF
   nW := aP[ 1 ] * nPt ; nH := aP[ 2 ] * nPt
   nMargin *= nPt
   nSc := Min( ( nW - 2 * nMargin ) / Max( aE[ 3 ] - aE[ 1 ], 0.000001 ), ( nH - 2 * nMargin ) / Max( aE[ 4 ] - aE[ 2 ], 0.000001 ) )
   nOx := ( nW - ( aE[ 3 ] - aE[ 1 ] ) * nSc ) / 2.0 - aE[ 1 ] * nSc
   nOy := ( nH - ( aE[ 4 ] - aE[ 2 ] ) * nSc ) / 2.0 - aE[ 2 ] * nSc
   c += "0.25 w 1 J 1 j" + hb_eol()
   FOR EACH f IN oS[ "fills" ]
      c += Pl_Col( f[ 1 ], lMono ) + " rg" + hb_eol()
      FOR EACH aL IN f[ 2 ]
         FOR i := 1 TO Len( aL )
            c += Pl_F( aL[ i ][ 1 ] * nSc + nOx ) + " " + Pl_F( aL[ i ][ 2 ] * nSc + nOy ) + IIf( i == 1, " m", " l" ) + hb_eol()
         NEXT
         c += "h" + hb_eol()
      NEXT
      c += "f*" + hb_eol()
   NEXT
   FOR EACH w IN oS[ "wires" ]
      IF Len( w[ 3 ] ) < 2 ; LOOP ; ENDIF
      c += Pl_Col( w[ 1 ], lMono ) + " RG " + aDash[ Min( 3, Max( 0, w[ 5 ] ) ) + 1 ] + hb_eol()
      FOR i := 1 TO Len( w[ 3 ] )
         p := w[ 3 ][ i ]
         c += Pl_F( p[ 1 ] * nSc + nOx ) + " " + Pl_F( p[ 2 ] * nSc + nOy ) + IIf( i == 1, " m", " l" ) + hb_eol()
      NEXT
      c += "S" + hb_eol()
   NEXT
   c += "[] 0 d" + hb_eol()
   FOR EACH t IN oS[ "texts" ]
      nH2 := t[ 3 ] * nSc
      IF nH2 < 1.0 ; LOOP ; ENDIF
      nRot := t[ 4 ] * OCX_PI / 180.0
      nX := t[ 1 ] * nSc + nOx ; nY := t[ 2 ] * nSc + nOy
      c += "BT /F1 " + Pl_F( nH2 ) + " Tf " + Pl_Col( t[ 6 ], lMono ) + " rg " + Pl_F( OCX_COS( nRot ) ) + " " + Pl_F( OCX_SIN( nRot ) ) + " " + ;
           Pl_F( - OCX_SIN( nRot ) ) + " " + Pl_F( OCX_COS( nRot ) ) + " " + Pl_F( nX ) + " " + Pl_F( nY ) + " Tm (" + Pl_Esc( t[ 5 ] ) + ") Tj ET" + hb_eol()
   NEXT
   AAdd( aObj, "<< /Type /Catalog /Pages 2 0 R >>" )
   AAdd( aObj, "<< /Type /Pages /Kids [3 0 R] /Count 1 >>" )
   AAdd( aObj, "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 " + Pl_F( nW ) + " " + Pl_F( nH ) + "] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>" )
   AAdd( aObj, "<< /Length " + hb_ntos( Len( c ) ) + " >>" + hb_eol() + "stream" + hb_eol() + c + "endstream" )
   AAdd( aObj, "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>" )
   cOut := "%PDF-1.4" + hb_eol()
   FOR i := 1 TO Len( aObj )
      AAdd( aOff, Len( cOut ) )
      cOut += hb_ntos( i ) + " 0 obj" + hb_eol() + aObj[ i ] + hb_eol() + "endobj" + hb_eol()
   NEXT
   nPos := Len( cOut )
   cOut += "xref" + hb_eol() + "0 " + hb_ntos( Len( aObj ) + 1 ) + hb_eol() + "0000000000 65535 f " + hb_eol()
   FOR i := 1 TO Len( aOff )
      cOut += PadL( hb_ntos( aOff[ i ] ), 10, "0" ) + " 00000 n " + hb_eol()
   NEXT
   cOut += "trailer << /Size " + hb_ntos( Len( aObj ) + 1 ) + " /Root 1 0 R >>" + hb_eol() + "startxref" + hb_eol() + hb_ntos( nPos ) + hb_eol() + "%%EOF" + hb_eol()
RETURN cOut
