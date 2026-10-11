/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/ui/cad_canvas.prg
   Rust origen: src/scene/view/*.rs (camera, render, transform) +
                src/scene/pipeline/*.rs (GPU->aqu?? GDI) +
                src/ui/overlay.rs + src/snap.rs + src/input/*.rs +
                src/scene/pick/*.rs (hit_test, quadtree->barrido simple).
   Controlador del lienzo CAD sobre ventana MDICHILD FiveWin:
   dibujo GDI, zoom/pan, snap, selecci??n.
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "FiveWin.ch"

CLASS TCadCanvas
   DATA oWnd
   DATA oDoc
   DATA nScale   INIT 10.0     // p??xeles por unidad de dibujo
   DATA aCenW    INIT { 0, 0 } // centro mundo visible
   DATA oCmd               // comando activo (OnPick/Preview/OnHover)
   DATA bOnPick            // bloque comando: Eval( aPtW, nFlags )
   DATA nSnapMode INIT 0
   DATA lGrid   INIT .T.
   DATA lOrtho  INIT .F.
   DATA oBgBrush
   DATA oGripBrush

   METHOD New( oDoc ) CONSTRUCTOR
   METHOD Attach( oWnd )
   METHOD W2SX( nX )
   METHOD W2SY( nY )
   METHOD W2SL( nL ) INLINE Int( nL * ::nScale )
   METHOD S2WX( nX )
   METHOD S2WY( nY )
   METHOD S2WL( nPx ) INLINE nPx / ::nScale
   METHOD ClientSize()   // { w, h } cliente en px
   METHOD ClientCen()
   METHOD Zoom( nF, aAtS )
   METHOD ZoomExt()
   METHOD PanPx( nDx, nDy )
   METHOD Refresh() INLINE If( ::oWnd != NIL, ::oWnd:Refresh(), NIL )
   METHOD SetFocus() INLINE If( ::oWnd != NIL, ::oWnd:SetFocus(), NIL )
   METHOD DoPaint( hDC )
   METHOD DrawGrid( hDC, nW, nH )
   METHOD DrawGrips( hDC, o )
   METHOD OnLClick( nRow, nCol, nFlags )
   METHOD OnRClick( nRow, nCol, nFlags )
   METHOD OnMove( nRow, nCol, nFlags )
   METHOD TolW()   // tolerancia de captura en unidades mundo
   METHOD PickEnt( aPtW )
   METHOD SnapPt( aPtW )
ENDCLASS

METHOD New( oDoc ) CLASS TCadCanvas
   ::oDoc := oDoc
   ::oBgBrush := TBrush():New( , RGB( 0, 0, 0 ) )
   ::oGripBrush := TBrush():New( , RGB( 0, 0, 255 ) )
RETURN Self

METHOD Attach( oWnd ) CLASS TCadCanvas
   ::oWnd := oWnd
   oWnd:bPainted := { | hDC | ::DoPaint( hDC ) }
   oWnd:bLClicked := { | nR, nC, nF | ::OnLClick( nR, nC, nF ) }
   oWnd:bRClicked := { | nR, nC, nF | ::OnRClick( nR, nC, nF ) }
   oWnd:bMMoved := { | nR, nC, nF | ::OnMove( nR, nC, nF ) }
RETURN Self

METHOD ClientSize() CLASS TCadCanvas
   LOCAL aR := GetClientRect( ::oWnd:hWnd )
RETURN { aR[ 4 ] - aR[ 2 ], aR[ 3 ] - aR[ 1 ] }

METHOD ClientCen() CLASS TCadCanvas
   LOCAL aS := ::ClientSize()
RETURN { aS[ 1 ] / 2, aS[ 2 ] / 2 }

METHOD W2SX( nX ) CLASS TCadCanvas
RETURN Int( ::ClientCen()[ 1 ] + ( nX - ::aCenW[ 1 ] ) * ::nScale )

METHOD W2SY( nY ) CLASS TCadCanvas
RETURN Int( ::ClientCen()[ 2 ] - ( nY - ::aCenW[ 2 ] ) * ::nScale )

METHOD S2WX( nX ) CLASS TCadCanvas
RETURN ::aCenW[ 1 ] + ( nX - ::ClientCen()[ 1 ] ) / ::nScale

METHOD S2WY( nY ) CLASS TCadCanvas
RETURN ::aCenW[ 2 ] - ( nY - ::ClientCen()[ 2 ] ) / ::nScale

METHOD Zoom( nF, aAtS ) CLASS TCadCanvas
   LOCAL aW
   IF aAtS != NIL
      aW := { ::S2WX( aAtS[ 1 ] ), ::S2WY( aAtS[ 2 ] ) }
   ENDIF
   ::nScale *= nF
   ::nScale := Max( OHB_ZOOM_MIN_FACTOR, Min( OHB_ZOOM_MAX_FACTOR, ::nScale ) )
   IF aAtS != NIL
      ::aCenW[ 1 ] := aW[ 1 ] - ( aAtS[ 1 ] - ::ClientCen()[ 1 ] ) / ::nScale
      ::aCenW[ 2 ] := aW[ 2 ] + ( aAtS[ 2 ] - ::ClientCen()[ 2 ] ) / ::nScale
   ENDIF
   ::Refresh()
RETURN NIL

METHOD ZoomExt() CLASS TCadCanvas
   LOCAL aE := ::oDoc:Extents(), aS := ::ClientSize()
   LOCAL w := Max( aE[ 3 ] - aE[ 1 ], 0.001 ), h := Max( aE[ 4 ] - aE[ 2 ], 0.001 )
   ::nScale := Min( ( aS[ 1 ] * 0.9 ) / w, ( aS[ 2 ] * 0.9 ) / h )
   ::aCenW := { ( aE[ 1 ] + aE[ 3 ] ) / 2, ( aE[ 2 ] + aE[ 4 ] ) / 2 }
   ::Refresh()
RETURN NIL

METHOD PanPx( nDx, nDy ) CLASS TCadCanvas
   ::aCenW[ 1 ] -= nDx / ::nScale
   ::aCenW[ 2 ] += nDy / ::nScale
   ::Refresh()
RETURN NIL

METHOD TolW() CLASS TCadCanvas
RETURN 6 / ::nScale

METHOD PickEnt( aPtW ) CLASS TCadCanvas
   LOCAL o, nT := ::TolW(), i, lHit
   FOR i := Len( ::oDoc:aEnts ) TO 1 STEP -1
      o := ::oDoc:aEnts[ i ]
      IF ! o:lErased
         lHit := o:HitTest( aPtW, nT, Self )
         IF lHit != NIL .AND. lHit
            RETURN o
         ENDIF
      ENDIF
   NEXT
RETURN NIL

METHOD SnapPt( aPtW ) CLASS TCadCanvas
   // Rust: snap.rs ??? END/MID/CEN/QUA/NOD sobre entidades visibles
   LOCAL o, nT := ::TolW(), aBest := AClone( aPtW ), nBest := nT
   LOCAL aG, aP, d
   IF ::nSnapMode == OHB_SNAP_OFF
      RETURN aBest
   ENDIF
   FOR EACH o IN ::oDoc:aEnts
      IF o:lErased
         LOOP
      ENDIF
      aG := o:GripPoints()
      IF aG != NIL
         FOR EACH aP IN aG
            d := OC_Dist2D( aPtW, aP )
            IF d < nBest
               nBest := d
               aBest := AClone( aP )
            ENDIF
         NEXT
      ENDIF
   NEXT
RETURN aBest

METHOD DoPaint( hDC ) CLASS TCadCanvas
   LOCAL o, aS := ::ClientSize(), oPen, nClr, nSel
   FillRect( hDC, { 0, 0, aS[ 2 ], aS[ 1 ] }, ::oBgBrush:hBrush )
   IF ::lGrid
      ::DrawGrid( hDC, aS[ 1 ], aS[ 2 ] )
   ENDIF
   FOR EACH o IN ::oDoc:aEnts
      IF o:lErased
         LOOP
      ENDIF
      nClr := OHB_AciRgb( OHB_EffColor( o, ::oDoc ), 0 )
      oPen := TPen():New( 0, 1, nClr )
      SelectObject( hDC, oPen:hPen )
      o:Draw( hDC, Self )
      SelectObject( hDC, GetStockObject( 0 ) )
      oPen:End()
   NEXT
   FOR EACH nSel IN ::oDoc:aSel
      o := ::oDoc:FindEnt( nSel )
      IF o != NIL
         ::DrawGrips( hDC, o )
      ENDIF
   NEXT
   IF ::oCmd != NIL
      ::oCmd:Preview( hDC, Self )
   ENDIF
RETURN NIL

METHOD DrawGrid( hDC, nW, nH ) CLASS TCadCanvas
   LOCAL nStep := 10 * ::nScale, x, oPen
   IF nStep < 8 .OR. nStep > 400
      RETURN NIL
   ENDIF
   oPen := TPen():New( 0, 1, RGB( 40, 40, 40 ) )
   SelectObject( hDC, oPen:hPen )
   // l??neas verticales ancladas al origen mundo
   x := ::W2SX( 0 ) % Int( nStep )
   DO WHILE x < nW
      MoveTo( hDC, x, 0 )
      LineTo( hDC, x, nH )
      x += Int( nStep )
   ENDDO
   x := ::W2SY( 0 ) % Int( nStep )
   DO WHILE x < nH
      MoveTo( hDC, 0, x )
      LineTo( hDC, nW, x )
      x += Int( nStep )
   ENDDO
   SelectObject( hDC, GetStockObject( 0 ) )
   oPen:End()
RETURN NIL

METHOD DrawGrips( hDC, o ) CLASS TCadCanvas
   LOCAL aG := o:GripPoints(), aP, x, y
   IF aG == NIL
      RETURN NIL
   ENDIF
   FOR EACH aP IN aG
      x := ::W2SX( aP[ 1 ] )
      y := ::W2SY( aP[ 2 ] )
      FillRect( hDC, { y - 3, x - 3, y + 3, x + 3 }, ::oGripBrush:hBrush )
   NEXT
RETURN NIL

METHOD OnLClick( nRow, nCol, nFlags ) CLASS TCadCanvas
   LOCAL aW := { ::S2WX( nCol ), ::S2WY( nRow ) }
   LOCAL o
   aW := ::SnapPt( aW )
   IF ::bOnPick != NIL
      Eval( ::bOnPick, aW, nFlags )
   ELSE
      o := ::PickEnt( aW )
      ::oDoc:ClearSel()
      IF o != NIL
         ::oDoc:Select( o:cHandle )
      ENDIF
      ::Refresh()
      OHB_PropRefresh()
   ENDIF
RETURN NIL

METHOD OnRClick( nRow, nCol, nFlags ) CLASS TCadCanvas
   IF ::bOnPick != NIL
      Eval( ::bOnPick, NIL, nFlags )
   ENDIF
RETURN NIL

METHOD OnMove( nRow, nCol, nFlags ) CLASS TCadCanvas
   // lo cablea la ventana principal (coordenadas + hover)
RETURN NIL

//--- Color ACI -> RGB (Rust: codec types::Color) ---------------------------------
FUNCTION OHB_AciRgb( nAci, nBg )
   LOCAL aTab := { ;
      { 255, 0, 0 }, { 255, 255, 0 }, { 0, 255, 0 }, { 0, 255, 255 }, ;
      { 0, 0, 255 }, { 255, 0, 255 }, { 255, 255, 255 }, { 128, 128, 128 } }
   hb_default( @nBg, 0 )
   IF nAci >= 1 .AND. nAci <= 7
      RETURN RGB( aTab[ nAci ][ 1 ], aTab[ nAci ][ 2 ], aTab[ nAci ][ 3 ] )
   ENDIF
RETURN RGB( 255, 255, 255 )
