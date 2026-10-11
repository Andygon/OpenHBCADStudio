/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/modules/draw/draw_cmds.prg
   Rust origen: src/modules/draw/draw/line.rs + circle.rs + arc.rs +
                polyline.rs + point.rs + shapes.rs + ray.rs +
                ellipse.rs + hatch.rs + mline.rs + sketch.rs +
                src/modules/annotate/dim*.rs (cota lineal)
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "FiveWin.ch"

//--- Ortogonal (Rust: drafting_settings ortho) ----------------------------------
FUNCTION OHB_ApplyOrtho( oView, aPt, aBase )
   LOCAL dx, dy
   IF ! oView:lOrtho .OR. aBase == NIL
      RETURN aPt
   ENDIF
   dx := Abs( aPt[ 1 ] - aBase[ 1 ] )
   dy := Abs( aPt[ 2 ] - aBase[ 2 ] )
   IF dx >= dy
      RETURN { aPt[ 1 ], aBase[ 2 ] }
   ENDIF
RETURN { aBase[ 1 ], aPt[ 2 ] }

//=========================== LINEA ==============================================
CLASS TCmdLine2 FROM TCmdBase
   DATA aHover INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
   METHOD OnHover( aPtW, oView )
   METHOD Preview( hDC, oView )
   METHOD Prompt()
ENDCLASS

METHOD New() CLASS TCmdLine2
   ::super:New( "LINEA" )
RETURN Self

METHOD Prompt() CLASS TCmdLine2
   IF ::nStep == 0
      RETURN "Precise punto inicial:"
   ENDIF
RETURN "Precise punto siguiente (Intro termina):"

METHOD OnPick( aPt, nFlags ) CLASS TCmdLine2
   LOCAL o
   IF aPt == NIL
      IF Len( ::aPts ) >= 2
         RETURN ::Finish()
      ENDIF
      RETURN ::Cancel()
   ENDIF
   aPt := OHB_ApplyOrtho( ::oView, aPt, ATail( ::aPts ) )
   AAdd( ::aPts, aPt )
   IF Len( ::aPts ) >= 2
      o := TEntLine():New()
      o:aP1 := AClone( ::aPts[ Len( ::aPts ) - 1 ] )
      o:aP2 := AClone( ATail( ::aPts ) )
      o:cLayer := ::oDoc:cCurLayer
      ::oDoc:AddEnt( o )
      ::oView:Refresh()
   ENDIF
   ::nStep := 1
   OHB_CmdPrompt( ::Prompt() )
RETURN OHB_CMD_NEED_POINT

METHOD OnHover( aPtW, oView ) CLASS TCmdLine2
   ::aHover := OHB_ApplyOrtho( oView, aPtW, ATail( ::aPts ) )
   oView:Refresh()
RETURN NIL

METHOD Preview( hDC, oView ) CLASS TCmdLine2
   IF ! Empty( ::aPts ) .AND. ::aHover != NIL
      MoveTo( hDC, oView:W2SX( ATail( ::aPts )[ 1 ] ), ;
                   oView:W2SY( ATail( ::aPts )[ 2 ] ) )
      LineTo( hDC, oView:W2SX( ::aHover[ 1 ] ), oView:W2SY( ::aHover[ 2 ] ) )
   ENDIF
RETURN NIL

//=========================== CIRCULO =============================================
CLASS TCmdCircle FROM TCmdBase
   DATA nRad INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
   METHOD Prompt()
ENDCLASS

METHOD New() CLASS TCmdCircle
   ::super:New( "CIRCULO" )
RETURN Self

METHOD Prompt() CLASS TCmdCircle
   IF ::nStep == 0
      RETURN "Precise centro:"
   ENDIF
RETURN "Precise radio o punto de la circunferencia:"

METHOD OnPick( aPt, nFlags ) CLASS TCmdCircle
   LOCAL o
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   IF ::nStep == 0
      AAdd( ::aPts, aPt )
      ::nStep := 1
      ::nRad := OC_AskNum( "Radio del c??rculo", 10.0 )
      IF ::nRad == NIL .OR. ::nRad <= 0
         RETURN ::Cancel()
      ENDIF
      o := TEntCircle():New()
      o:aCen := AClone( ::aPts[ 1 ] )
      o:nRad := ::nRad
      o:cLayer := ::oDoc:cCurLayer
      ::oDoc:AddEnt( o )
      RETURN ::Finish()
   ENDIF
RETURN ::Cancel()

//=========================== ARCO (3 puntos) =======================================
CLASS TCmdArc FROM TCmdBase
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
   METHOD Prompt()
ENDCLASS

METHOD New() CLASS TCmdArc
   ::super:New( "ARCO" )
RETURN Self

METHOD Prompt() CLASS TCmdArc
   DO CASE
   CASE ::nStep == 0 ; RETURN "Precise punto inicial del arco:"
   CASE ::nStep == 1 ; RETURN "Precise segundo punto:"
   CASE ::nStep == 2 ; RETURN "Precise punto final:"
   ENDCASE
RETURN "ARCO:"

METHOD OnPick( aPt, nFlags ) CLASS TCmdArc
   LOCAL o, aC, nR
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   AAdd( ::aPts, aPt )
   ::nStep++
   IF Len( ::aPts ) == 3
      aC := OHB_Circ3P( ::aPts[ 1 ], ::aPts[ 2 ], ::aPts[ 3 ] )
      IF aC == NIL
         OHB_CmdPrompt( "Puntos alineados: arco imposible." )
         RETURN ::Cancel()
      ENDIF
      nR := OC_Dist2D( aC, ::aPts[ 1 ] )
      o := TEntArc():New()
      o:aCen := aC
      o:nRad := nR
      o:nA0 := OC_NormAng( OC_Ang2D( aC, ::aPts[ 1 ] ) )
      o:nA1 := OC_NormAng( OC_Ang2D( aC, ::aPts[ 3 ] ) )
      // sentido antihorario pasando por P2
      IF ! OHB_AngInArc( OC_Ang2D( aC, ::aPts[ 2 ] ), o:nA0, o:nA1 )
         o:nA0 := OC_NormAng( OC_Ang2D( aC, ::aPts[ 3 ] ) )
         o:nA1 := OC_NormAng( OC_Ang2D( aC, ::aPts[ 1 ] ) )
      ENDIF
      o:cLayer := ::oDoc:cCurLayer
      ::oDoc:AddEnt( o )
      RETURN ::Finish()
   ENDIF
   OHB_CmdPrompt( ::Prompt() )
RETURN OHB_CMD_NEED_POINT

FUNCTION OHB_Circ3P( aA, aB, aC )
   // circuncentro (Rust: draw/apollonius.rs, caso 3 puntos)
   LOCAL d := 2 * ( aA[ 1 ] * ( aB[ 2 ] - aC[ 2 ] ) + ;
                    aB[ 1 ] * ( aC[ 2 ] - aA[ 2 ] ) + ;
                    aC[ 1 ] * ( aA[ 2 ] - aB[ 2 ] ) )
   LOCAL a2 := aA[ 1 ] ^ 2 + aA[ 2 ] ^ 2
   LOCAL b2 := aB[ 1 ] ^ 2 + aB[ 2 ] ^ 2
   LOCAL c2 := aC[ 1 ] ^ 2 + aC[ 2 ] ^ 2
   IF Abs( d ) < 0.000000000001
      RETURN NIL
   ENDIF
RETURN { ( a2 * ( aB[ 2 ] - aC[ 2 ] ) + b2 * ( aC[ 2 ] - aA[ 2 ] ) + ;
           c2 * ( aA[ 2 ] - aB[ 2 ] ) ) / d, ;
         ( a2 * ( aC[ 1 ] - aB[ 1 ] ) + b2 * ( aA[ 1 ] - aC[ 1 ] ) + ;
           c2 * ( aB[ 1 ] - aA[ 1 ] ) ) / d }

FUNCTION OHB_AngInArc( nA, nA0, nA1 )
   nA := OC_NormAng( nA )
   IF nA1 >= nA0
      RETURN nA >= nA0 .AND. nA <= nA1
   ENDIF
RETURN nA >= nA0 .OR. nA <= nA1

//=========================== POLILINEA ============================================
CLASS TCmdPline FROM TCmdBase
   DATA aHover INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
   METHOD OnHover( aPtW, oView )
   METHOD Preview( hDC, oView )
   METHOD Prompt()
ENDCLASS

METHOD New() CLASS TCmdPline
   ::super:New( "POL" )
RETURN Self

METHOD Prompt() CLASS TCmdPline
   IF ::nStep == 0
      RETURN "Precise punto inicial de polil??nea:"
   ENDIF
RETURN "Precise punto siguiente (Intro cierra/termina):"

METHOD OnPick( aPt, nFlags ) CLASS TCmdPline
   LOCAL o
   IF aPt == NIL
      IF Len( ::aPts ) >= 2
         o := TEntPoly():New()
         AEval( ::aPts, { | p | AAdd( o:aVerts, AClone( p ) ) } )
         o:cLayer := ::oDoc:cCurLayer
         ::oDoc:AddEnt( o )
         RETURN ::Finish()
      ENDIF
      RETURN ::Cancel()
   ENDIF
   AAdd( ::aPts, OHB_ApplyOrtho( ::oView, aPt, ATail( ::aPts ) ) )
   ::nStep := 1
   OHB_CmdPrompt( ::Prompt() )
   ::oView:Refresh()
RETURN OHB_CMD_NEED_POINT

METHOD OnHover( aPtW, oView ) CLASS TCmdPline
   ::aHover := OHB_ApplyOrtho( oView, aPtW, ATail( ::aPts ) )
   oView:Refresh()
RETURN NIL

METHOD Preview( hDC, oView ) CLASS TCmdPline
   LOCAL i
   FOR i := 2 TO Len( ::aPts )
      MoveTo( hDC, oView:W2SX( ::aPts[ i - 1 ][ 1 ] ), ;
                   oView:W2SY( ::aPts[ i - 1 ][ 2 ] ) )
      LineTo( hDC, oView:W2SX( ::aPts[ i ][ 1 ] ), ;
                   oView:W2SY( ::aPts[ i ][ 2 ] ) )
   NEXT
   IF ! Empty( ::aPts ) .AND. ::aHover != NIL
      MoveTo( hDC, oView:W2SX( ATail( ::aPts )[ 1 ] ), ;
                   oView:W2SY( ATail( ::aPts )[ 2 ] ) )
      LineTo( hDC, oView:W2SX( ::aHover[ 1 ] ), oView:W2SY( ::aHover[ 2 ] ) )
   ENDIF
RETURN NIL

//=========================== PUNTO ================================================
CLASS TCmdPoint FROM TCmdBase
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdPoint
   ::super:New( "PUNTO" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdPoint
   LOCAL o
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   o := TEntPoint():New()
   o:aPt := AClone( aPt )
   o:cLayer := ::oDoc:cCurLayer
   ::oDoc:AddEnt( o )
   ::oView:Refresh()
   OHB_CmdPrompt( "Punto creado. Siguiente punto (Intro termina):" )
RETURN OHB_CMD_NEED_POINT

//=========================== TEXTO ================================================
CLASS TCmdText FROM TCmdBase
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdText
   ::super:New( "TEXTO" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdText
   LOCAL o, cT, nH
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   cT := OC_AskText( "Texto", "" )
   IF cT == NIL
      RETURN ::Cancel()
   ENDIF
   nH := OC_AskNum( "Altura", 2.5 )
   IF nH == NIL .OR. nH <= 0
      RETURN ::Cancel()
   ENDIF
   o := TEntText():New()
   o:aPt := AClone( aPt )
   o:cText := cT
   o:nH := nH
   o:cLayer := ::oDoc:cCurLayer
   ::oDoc:AddEnt( o )
   RETURN ::Finish()

//=========================== RAYO / LINEAX ==========================================
CLASS TCmdRay FROM TCmdBase
   DATA lX INIT .F.
   METHOD New( lX ) CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New( lX ) CLASS TCmdRay
   ::super:New( If( lX == .T., "LINEAX", "RAYO" ) )
   ::lX := ( lX == .T. )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdRay
   LOCAL o, aD
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   AAdd( ::aPts, aPt )
   IF Len( ::aPts ) == 2
      aD := { ::aPts[ 2 ][ 1 ] - ::aPts[ 1 ][ 1 ], ;
              ::aPts[ 2 ][ 2 ] - ::aPts[ 1 ][ 2 ] }
      o := TEntRay():New()
      o:lXline := ::lX
      o:aPt := AClone( ::aPts[ 1 ] )
      o:aDir := aD
      o:cLayer := ::oDoc:cCurLayer
      ::oDoc:AddEnt( o )
      RETURN ::Finish()
   ENDIF
   OHB_CmdPrompt( "Precise direcci??n:" )
RETURN OHB_CMD_NEED_POINT

CLASS TCmdXline FROM TCmdRay
   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS TCmdXline
   ::super:New( .T. )
RETURN Self

//=========================== ELIPSE ================================================
CLASS TCmdEllipse FROM TCmdBase
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdEllipse
   ::super:New( "ELIPSE" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdEllipse
   LOCAL o, aAx, nR
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   AAdd( ::aPts, aPt )
   ::nStep++
   DO CASE
   CASE Len( ::aPts ) == 1
      OHB_CmdPrompt( "Precise extremo del eje mayor:" )
   CASE Len( ::aPts ) == 2
      nR := OC_AskNum( "Relaci??n eje menor/mayor (0..1)", 0.5 )
      IF nR == NIL .OR. nR <= 0 .OR. nR > 1
         RETURN ::Cancel()
      ENDIF
      aAx := { ( ::aPts[ 2 ][ 1 ] - ::aPts[ 1 ][ 1 ] ) / 2, ;
               ( ::aPts[ 2 ][ 2 ] - ::aPts[ 1 ][ 2 ] ) / 2 }
      o := TEntEllipse():New()
      o:aCen := OC_Mid2D( ::aPts[ 1 ], ::aPts[ 2 ] )
      o:aAxis := aAx
      o:nRatio := nR
      o:cLayer := ::oDoc:cCurLayer
      ::oDoc:AddEnt( o )
      RETURN ::Finish()
   ENDCASE
RETURN OHB_CMD_NEED_POINT

//=========================== SOMBREADO ==============================================
CLASS TCmdHatch FROM TCmdBase
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdHatch
   ::super:New( "SOMBREADO" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdHatch
   LOCAL o, cP
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   // contorno: usa la entidad cerrada bajo el cursor o pide ventana
   o := ::oView:PickEnt( aPt )
   IF o == NIL .OR. ! ( o:nType == OHB_ENT_LWPOLYLINE .OR. ;
        o:nType == OHB_ENT_CIRCLE .OR. o:nType == OHB_ENT_POLYLINE )
      OHB_CmdPrompt( "Designe un contorno cerrado (polil??nea/c??rculo):" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   cP := OC_AskText( "Patr??n", "ANSI31" )
   IF cP == NIL
      RETURN ::Cancel()
   ENDIF
   o := OHB_HatchFromEnt( o, cP )
   IF o == NIL
      OHB_CmdPrompt( "Contorno no cerrado." )
      RETURN ::Cancel()
   ENDIF
   o:cLayer := ::oDoc:cCurLayer
   ::oDoc:AddEnt( o )
   RETURN ::Finish()

FUNCTION OHB_HatchFromEnt( oSrc, cPat )
   LOCAL o := TEntHatch():New(), aT
   o:cPat := cPat
   DO CASE
   CASE oSrc:nType == OHB_ENT_CIRCLE
      aT := OC_TessArc( oSrc:aCen, oSrc:nRad, 0, 8 * ATan( 1 ), ;
                        oSrc:nRad * 0.02 )
      o:aLoop := aT
   CASE oSrc:nType == OHB_ENT_LWPOLYLINE .OR. oSrc:nType == OHB_ENT_POLYLINE
      IF Len( oSrc:aVerts ) < 3
         RETURN NIL
      ENDIF
      o:aLoop := {}
      AEval( oSrc:aVerts, { | p | AAdd( o:aLoop, AClone( p ) ) } )
   OTHERWISE
      RETURN NIL
   ENDCASE
RETURN o

//=========================== COTA LINEAL =============================================
CLASS TCmdDimLin FROM TCmdBase
   DATA aHover INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
   METHOD OnHover( aPtW, oView )
   METHOD Preview( hDC, oView )
ENDCLASS

METHOD New() CLASS TCmdDimLin
   ::super:New( "COTLIN" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdDimLin
   LOCAL o
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   AAdd( ::aPts, aPt )
   ::nStep++
   DO CASE
   CASE Len( ::aPts ) == 1
      OHB_CmdPrompt( "Precise segundo punto de origen:" )
   CASE Len( ::aPts ) == 2
      OHB_CmdPrompt( "Precise posici??n de la l??nea de cota:" )
   CASE Len( ::aPts ) == 3
      o := TEntDim():New()
      o:nKind := 0
      o:aP1 := AClone( ::aPts[ 1 ] )
      o:aP2 := AClone( ::aPts[ 2 ] )
      o:aPl := AClone( ::aPts[ 3 ] )
      o:cLayer := ::oDoc:cCurLayer
      ::oDoc:AddEnt( o )
      RETURN ::Finish()
   ENDCASE
RETURN OHB_CMD_NEED_POINT

METHOD OnHover( aPtW, oView ) CLASS TCmdDimLin
   ::aHover := AClone( aPtW )
   oView:Refresh()
RETURN NIL

METHOD Preview( hDC, oView ) CLASS TCmdDimLin
   LOCAL n := Len( ::aPts )
   IF n >= 1 .AND. ::aHover != NIL
      MoveTo( hDC, oView:W2SX( ATail( ::aPts )[ 1 ] ), ;
                   oView:W2SY( ATail( ::aPts )[ 2 ] ) )
      LineTo( hDC, oView:W2SX( ::aHover[ 1 ] ), oView:W2SY( ::aHover[ 2 ] ) )
   ENDIF
RETURN NIL
