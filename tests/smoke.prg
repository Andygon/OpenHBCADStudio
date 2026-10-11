/*----------------------------------------------------------------------------
   OpenHBCADStudio - tests/smoke.prg
   Test de consola (sin GUI): n??cleo C MSVC22 + entidades + documento +
   roundtrip DXF. Salida: l??neas SMOKE-ok/fail. C??d. salida 0 = todo ok.
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "hbclass.ch"

STATIC s_nFail := 0

STATIC PROCEDURE chk( cName, lOk, xExtra )
   IF lOk
      OutStd( "SMOKE-ok   " + cName + hb_eol() )
   ELSE
      OutStd( "SMOKE-fail " + cName + " extra=" + hb_ValToStr( xExtra ) + hb_eol() )
      s_nFail++
   ENDIF
RETURN

FUNCTION Main()
   LOCAL oDoc, o, cTmp, oDoc2, aX, n
   OutStd( "OpenHBCADStudio smoke " + OHB_Version() + hb_eol() )
   // --- C: geometr??a ---
   chk( "dist335", Abs( OC_Dist2D( { 0, 0 }, { 3, 4 } ) - 5 ) < 0.000001 )
   chk( "angle90", Abs( OC_Ang2D( { 0, 0 }, { 0, 1 } ) - 1.5707963 ) < 0.0001 )
   aX := OC_IntersLL( { 0, 0 }, { 2, 2 }, { 0, 2 }, { 2, 0 }, .T. )
   chk( "inters11", aX != NIL .AND. Abs( aX[ 1 ] - 1 ) < 0.000001 .AND. ;
      Abs( aX[ 2 ] - 1 ) < 0.000001, aX )
   chk( "ptseg", Abs( OC_PtSeg( { 1, 1 }, { 0, 0 }, { 2, 0 } )[ 1 ] - 1 ) < 0.000001 )
   chk( "polyarea", Abs( OC_PolyArea( { { 0, 0 }, { 4, 0 }, { 4, 3 } } ) - 6 ) < 0.000001 )
   chk( "polylen", Abs( OC_PolyLen( { { 0, 0 }, { 3, 4 } }, .F. ) - 5 ) < 0.000001 )
   // --- Documento + entidades ---
   oDoc := TDocDrawing():New()
   o := TEntLine():New()
   o:aP1 := { 0, 0 }
   o:aP2 := { 10, 0 }
   oDoc:AddEnt( o )
   o := TEntCircle():New()
   o:aCen := { 5, 5 }
   o:nRad := 2
   oDoc:AddEnt( o )
   o := TEntArc():New()
   o:aCen := { 0, 0 }
   o:nRad := 5
   o:nA0 := 0
   o:nA1 := 3.14159265
   oDoc:AddEnt( o )
   o := TEntPoly():New()
   o:aVerts := { { 0, 0 }, { 1, 0 }, { 1, 1 } }
   o:lClosed := .T.
   oDoc:AddEnt( o )
   o := TEntText():New()
   o:aPt := { 2, 2 }
   o:cText := "HOLA"
   o:nH := 2.5
   oDoc:AddEnt( o )
   chk( "count5", oDoc:Count() == 5, oDoc:Count() )
   chk( "extents", Abs( oDoc:Extents()[ 3 ] - 10 ) < 0.000001, oDoc:Extents() )
   // undo
   oDoc:Undo()
   chk( "undo4", oDoc:Count() == 4, oDoc:Count() )
   o := TEntText():New()
   o:aPt := { 2, 2 }
   o:cText := "HOLA"
   o:nH := 2.5
   oDoc:AddEnt( o )
   // --- DXF roundtrip ---
   cTmp := hb_DirTemp() + "ohb_smoke.dxf"
   chk( "dxfsave", OC_DxfSave( oDoc, cTmp ), cTmp )
   oDoc2 := OC_DxfLoad( cTmp )
   chk( "dxfload", oDoc2 != NIL .AND. oDoc2:Count() == 5, ;
      If( oDoc2 == NIL, "NIL", oDoc2:Count() ) )
   IF oDoc2 != NIL
      n := 0
      AEval( oDoc2:aEnts, { | e | n += If( e:nType == OHB_ENT_LINE, 1, 0 ) } )
      chk( "dxfline", n == 1, n )
      n := 0
      AEval( oDoc2:aEnts, { | e | n += If( e:nType == OHB_ENT_TEXT, 1, 0 ) } )
      chk( "dxftext", n == 1, n )
   ENDIF
   FErase( cTmp )
   // --- Comandos: circuncentro + arco ---
   aX := OHB_Circ3P( { 0, 0 }, { 2, 0 }, { 1, 1 } )
   chk( "circ3p", aX != NIL .AND. Abs( aX[ 1 ] - 1 ) < 0.000001 .AND. ;
      Abs( aX[ 2 ] - 0 ) < 0.000001, aX )
   chk( "anginarc", OHB_AngInArc( 1.0, 0.0, 2.0 ) .AND. ;
      ! OHB_AngInArc( 3.0, 0.0, 2.0 ) )
   OutStd( If( s_nFail == 0, "SMOKE-ALL-OK", "SMOKE-FAILURES=" + ;
      LTrim( Str( s_nFail, 0 ) ) ) + hb_eol() )
   ErrorLevel( If( s_nFail == 0, 0, 1 ) )
RETURN NIL
