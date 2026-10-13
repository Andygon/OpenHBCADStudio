/* [extra] Fase 2 / B13b: lector SAT y teselado contra 3DSOLID reales (tests/fixtures/solids3d.dxf, de ezdxf/examples/acistools/3dsolids.dxf, MIT, creados con ODA/AutoCAD). */
#include "ocx.ch"

PROCEDURE T_ViewSatReal()
   LOCAL oSc, cPdf, nXr
   LOCAL cam, aAll := {}, sh, k, ok := .T., nBack, ps, pt, pc, bad := 0, i, ex := { 1.0, 0.0, 0.0 }, ey := { 0.0, 1.0, 0.0 }, ez := { 0.0, 0.0, 1.0 }, dd
   LOCAL c := hb_MemoRead( "tests/fixtures/solids3d.dxf" ), d, e, nS := 0, sat, r, nF := 0, nT := 0, nSk := 0, nOk := 0, nPl := 0, cs
   IF Empty( c ) ; Chk( .F., "[extra] satreal: no se encuentra tests/fixtures/solids3d.dxf" ) ; RETURN ; ENDIF
   d := Dxr_ReadString( c )
   IF ! Chk( ValType( d ) == "H", "[extra] satreal: lectura del DXF" ) ; RETURN ; ENDIF
   FOR EACH e IN d[ "entities" ]
      cs := Sat_FromEntity( e )
      IF Empty( cs ) ; LOOP ; ENDIF
      nS++
      sat := Sat_Parse( cs )
      IF sat == NIL ; LOOP ; ENDIF
      IF Len( Sat_Find( sat, "face" ) ) > 0 .AND. Len( Sat_Find( sat, "coedge" ) ) > 0 ; nOk++ ; ENDIF
      r := Sat_Tess( sat )
      AEval( r[ "tris" ], {| t | AAdd( aAll, t ) } )
      IF r[ "skipped" ] == 0 .AND. Len( r[ "tris" ] ) > 0 ; nPl++ ; ENDIF
      nF += r[ "faces" ] ; nT += Len( r[ "tris" ] ) ; nSk += r[ "skipped" ]
   NEXT
   Chk( nS == 5, "[extra] satreal: 5 3DSOLID con datos SAT (" + hb_ntos( nS ) + ")" )
   Chk( nOk == 5, "[extra] satreal: los 5 se parsean con caras y coedges (" + hb_ntos( nOk ) + ")" )
   Chk( nF > 0 .AND. nT > 0, "[extra] satreal: se tesela alguna cara (caras=" + hb_ntos( nF ) + " tris=" + hb_ntos( nT ) + " saltadas=" + hb_ntos( nSk ) + ")" )
   Chk( nSk == 0, "[extra] satreal: B13b2 sin caras saltadas (cono/cilindro) (" + hb_ntos( nSk ) + ")" )
   Chk( nPl >= 4, "[extra] satreal: al menos 4 solidos se tesela completos (" + hb_ntos( nPl ) + ")" )
   Chk( nPl >= 2, "[extra] satreal: al menos 2 solidos totalmente planos se tesela completos (" + hb_ntos( nPl ) + ")" )
   // B13b2: evaluadores de esfera/toro/cono sobre la superficie
   FOR i := 1 TO 20
      ps := Sat_SpherePt( { 1.0, 2.0, 3.0 }, 4.0, ex, ey, ez, i * 0.7, -1.2 + i * 0.1 )
      dd := Sqrt( ( ps[ 1 ][ 1 ] - 1 ) ^ 2 + ( ps[ 1 ][ 2 ] - 2 ) ^ 2 + ( ps[ 1 ][ 3 ] - 3 ) ^ 2 )
      IF Abs( dd - 4.0 ) > 0.000001 ; bad++ ; ENDIF
      pt := Sat_TorusPt( { 0.0, 0.0, 0.0 }, ez, ex, ey, 5.0, 1.0, i * 0.7, i * 0.9 )
      dd := Sqrt( ( Sqrt( pt[ 1 ][ 1 ] ^ 2 + pt[ 1 ][ 2 ] ^ 2 ) - 5.0 ) ^ 2 + pt[ 1 ][ 3 ] ^ 2 )
      IF Abs( dd - 1.0 ) > 0.000001 ; bad++ ; ENDIF
      pc := Sat_ConePt( { 0.0, 0.0, 0.0 }, ez, ex, ey, 2.0, 0.5, 1.0, i * 0.5, i * 0.3 )
      dd := Sqrt( pc[ 1 ][ 1 ] ^ 2 + pc[ 1 ][ 2 ] ^ 2 )
      IF Abs( dd - ( 2.0 + 0.5 * i * 0.3 ) ) > 0.000001 .OR. Abs( pc[ 1 ][ 3 ] - i * 0.3 ) > 0.000001 ; bad++ ; ENDIF
   NEXT
   Chk( bad == 0, "[extra] satreal: evaluadores esfera/toro/cono caen en su superficie (" + hb_ntos( bad ) + ")" )
   // B13c: sombreado painter
   cam := VwC_New() ; cam[ "pitch" ] := 0.6 ; cam[ "yaw" ] := 0.4 ; cam[ "scale" ] := 5.0
   sh := VwS_Shade( cam, aAll ) ; nBack := Len( VwS_Shade( cam, aAll, .F. ) )
   FOR k := 2 TO Len( sh )
      IF sh[ k ][ 5 ] < sh[ k - 1 ][ 5 ] ; ok := .F. ; ENDIF
   NEXT
   FOR k := 1 TO Len( sh )
      IF sh[ k ][ 4 ] < 0.25 - 0.000001 .OR. sh[ k ][ 4 ] > 1.000001 ; ok := .F. ; ENDIF
   NEXT
   Chk( Len( sh ) > 0 .AND. Len( sh ) < nBack .AND. ok, "[extra] shade: ordenado lejos->cerca, sombra en 0.25..1 y se descartan caras traseras (" + hb_ntos( Len( sh ) ) + "/" + hb_ntos( nBack ) + ")" )
   sh := VwS_Shade( VwC_New(), { { { 0.0, 0.0, 0.0 }, { 1.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, { 0.0, 0.0, 1.0 } }, { { 0.0, 0.0, 0.0 }, { 1.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, { 0.0, 0.0, -1.0 } } } )
   Chk( Len( sh ) == 1 .AND. Abs( sh[ 1 ][ 4 ] - 1.0 ) < 0.000001, "[extra] shade: en planta la normal +Z mira a la camara (sombra 1.0) y -Z se descarta" )
   Chk( VwS_Color( 0.5, 200 + 100 * 256 + 50 * 65536 ) == 100 + 50 * 256 + 25 * 65536, "[extra] shade: VwS_Color oscurece" )
   // B14: PDF
   oSc := hb_Hash( "wires", { { 255, "0", { { 0.0, 0.0 }, { 10.0, 5.0 } }, {}, 1, "A" } }, "texts", { { 1.0, 1.0, 2.0, 0.0, "Hola (x)", 0 } }, "fills", {}, "ext", { 0.0, 0.0, 10.0, 5.0 } )
   cPdf := Plot_Pdf( oSc, "a4", .T., 10.0, .F. )
   Chk( Plot_PaperSize( "A4", .F. )[ 1 ] == 210 .AND. Plot_PaperSize( "a3", .T. )[ 1 ] == 420 .AND. Plot_PaperSize( "zz", .F. ) == NIL, "[extra] plot: tamanos de papel" )
   Chk( Left( cPdf, 8 ) == "%PDF-1.4" .AND. "%%EOF" $ cPdf .AND. "/MediaBox [0 0 841.890 595.276]" $ cPdf .AND. "(Hola \(x\)) Tj" $ cPdf, "[extra] plot: PDF con cabecera, MediaBox A4 apaisado y texto escapado" )
   nXr := Val( SubStr( cPdf, At( "startxref", cPdf ) + 10, 8 ) )
   Chk( SubStr( cPdf, nXr + 1, 4 ) == "xref" .AND. SubStr( cPdf, Val( SubStr( cPdf, nXr + 1 + Len( "xref" + hb_eol() + "0 6" + hb_eol() + "0000000000 65535 f " + hb_eol() ), 10 ) ) + 1, 7 ) == "1 0 obj", "[extra] plot: xref apunta a los objetos" )
   OutStd( "satreal caras=" + hb_ntos( nF ) + " tris=" + hb_ntos( nT ) + " saltadas=" + hb_ntos( nSk ) + hb_eol() )
RETURN
