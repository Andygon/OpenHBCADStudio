/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/modules/draw/modify_cmds.prg
   Rust origen: src/modules/draw/modify/copy.rs + move(translate.rs) +
                rotate.rs + scale.rs + mirror.rs + offset.rs + fillet.rs +
                trim.rs + array.rs + delete.rs + match_prop (properties) +
                explode.rs (fase 2) + stretch.rs (fase 2)
----------------------------------------------------------------------------*/
#include "ohbcad.ch"
#include "FiveWin.ch"

//--- Base con selecci??n (Rust: selection.rs + select.rs) -------------------------
CLASS TCmdSel FROM TCmdBase
   DATA aSelH INIT {}
   DATA lSelPhase INIT .T.
   METHOD SelPrompt()
   METHOD SelPick( aPt, nFlags )
   METHOD UseSel()
ENDCLASS

METHOD SelPrompt() CLASS TCmdSel
RETURN "Designe entidades (Intro termina):"

METHOD UseSel() CLASS TCmdSel
   IF ! Empty( ::oDoc:aSel )
      ::aSelH := AClone( ::oDoc:aSel )
      ::oDoc:ClearSel()
      ::lSelPhase := .F.
      RETURN .T.
   ENDIF
RETURN .F.

METHOD SelPick( aPt, nFlags ) CLASS TCmdSel
   LOCAL o
   IF aPt == NIL
      ::lSelPhase := .F.
      RETURN .T.  // fin designaci??n
   ENDIF
   o := ::oView:PickEnt( aPt )
   IF o != NIL
      IF AScan( ::aSelH, o:cHandle ) == 0
         AAdd( ::aSelH, o:cHandle )
         ::oDoc:Select( o:cHandle )
         ::oView:Refresh()
      ENDIF
      OHB_CmdPrompt( LTrim( Str( Len( ::aSelH ), 0 ) ) + " entidades. " + ;
         ::SelPrompt() )
   ENDIF
RETURN .F.

//=========================== BORRA ================================================
CLASS TCmdErase FROM TCmdSel
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdErase
   ::super:New( "BORRA" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdErase
   LOCAL cH
   IF ::lSelPhase
      IF ::UseSel()
         // selecci??n previa
      ELSEIF ::SelPick( aPt, nFlags )
         IF Empty( ::aSelH )
            RETURN ::Cancel()
         ENDIF
      ELSE
         RETURN OHB_CMD_NEED_SELECT
      ENDIF
   ENDIF
   FOR EACH cH IN ::aSelH
      ::oDoc:DelEnt( cH )
   NEXT
   ::oDoc:ClearSel()
RETURN ::Finish()

//=========================== MUEVE ================================================
CLASS TCmdMove FROM TCmdSel
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdMove
   ::super:New( "MUEVE" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdMove
   LOCAL cH, o
   IF ::lSelPhase
      IF ! ::UseSel()
         IF ! ::SelPick( aPt, nFlags )
            RETURN OHB_CMD_NEED_SELECT
         ENDIF
         IF Empty( ::aSelH )
            RETURN ::Cancel()
         ENDIF
      ENDIF
      ::lSelPhase := .F.
      OHB_CmdPrompt( "Precise punto base:" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   AAdd( ::aPts, aPt )
   IF Len( ::aPts ) == 1
      OHB_CmdPrompt( "Precise segundo punto:" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   FOR EACH cH IN ::aSelH
      o := ::oDoc:FindEnt( cH )
      IF o != NIL
         o:MoveBy( ::aPts[ 1 ], ::aPts[ 2 ] )
      ENDIF
   NEXT
   ::oDoc:MarkDirty()
RETURN ::Finish()

//=========================== COPIA ================================================
CLASS TCmdCopy FROM TCmdMove
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdCopy
   ::super:New( "COPIA" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdCopy
   LOCAL cH, o, o2
   IF ::lSelPhase
      IF ! ::UseSel()
         IF ! ::SelPick( aPt, nFlags )
            RETURN OHB_CMD_NEED_SELECT
         ENDIF
         IF Empty( ::aSelH )
            RETURN ::Cancel()
         ENDIF
      ENDIF
      ::lSelPhase := .F.
      OHB_CmdPrompt( "Precise punto base:" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   AAdd( ::aPts, aPt )
   IF Len( ::aPts ) == 1
      OHB_CmdPrompt( "Precise segundo punto:" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   FOR EACH cH IN ::aSelH
      o := ::oDoc:FindEnt( cH )
      IF o != NIL
         o2 := o:Clone()
         o2:cHandle := ""
         o2:MoveBy( ::aPts[ 1 ], ::aPts[ 2 ] )
         ::oDoc:AddEnt( o2 )
      ENDIF
   NEXT
RETURN ::Finish()

//=========================== GIRA ==================================================
CLASS TCmdRotate FROM TCmdSel
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdRotate
   ::super:New( "GIRA" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdRotate
   LOCAL cH, o, nA
   IF ::lSelPhase
      IF ! ::UseSel()
         IF ! ::SelPick( aPt, nFlags )
            RETURN OHB_CMD_NEED_SELECT
         ENDIF
         IF Empty( ::aSelH )
            RETURN ::Cancel()
         ENDIF
      ENDIF
      ::lSelPhase := .F.
      OHB_CmdPrompt( "Precise punto base:" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   AAdd( ::aPts, aPt )
   IF Len( ::aPts ) == 1
      nA := OC_AskNum( "??ngulo (grados)", 90.0 )
      IF nA == NIL
         RETURN ::Cancel()
      ENDIF
      FOR EACH cH IN ::aSelH
         o := ::oDoc:FindEnt( cH )
         IF o != NIL
            o:Transform( OC_RotM( OC_Deg2Rad( nA ), ::aPts[ 1 ] ) )
         ENDIF
      NEXT
      ::oDoc:MarkDirty()
      RETURN ::Finish()
   ENDIF
RETURN OHB_CMD_ERROR

//=========================== ESCALA ================================================
CLASS TCmdScale FROM TCmdSel
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdScale
   ::super:New( "ESCALA" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdScale
   LOCAL cH, o, nF
   IF ::lSelPhase
      IF ! ::UseSel()
         IF ! ::SelPick( aPt, nFlags )
            RETURN OHB_CMD_NEED_SELECT
         ENDIF
         IF Empty( ::aSelH )
            RETURN ::Cancel()
         ENDIF
      ENDIF
      ::lSelPhase := .F.
      OHB_CmdPrompt( "Precise punto base:" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   AAdd( ::aPts, aPt )
   nF := OC_AskNum( "Factor de escala", 2.0 )
   IF nF == NIL .OR. nF <= 0
      RETURN ::Cancel()
   ENDIF
   FOR EACH cH IN ::aSelH
      o := ::oDoc:FindEnt( cH )
      IF o != NIL
         o:Transform( OC_ScaleM( nF, nF, ::aPts[ 1 ] ) )
      ENDIF
   NEXT
   ::oDoc:MarkDirty()
RETURN ::Finish()

//=========================== SIMETRIA ===============================================
CLASS TCmdMirror FROM TCmdSel
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdMirror
   ::super:New( "SIMETRIA" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdMirror
   LOCAL cH, o, aM, lDel
   IF ::lSelPhase
      IF ! ::UseSel()
         IF ! ::SelPick( aPt, nFlags )
            RETURN OHB_CMD_NEED_SELECT
         ENDIF
         IF Empty( ::aSelH )
            RETURN ::Cancel()
         ENDIF
      ENDIF
      ::lSelPhase := .F.
      OHB_CmdPrompt( "Precise primer punto del eje:" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   AAdd( ::aPts, aPt )
   IF Len( ::aPts ) == 1
      OHB_CmdPrompt( "Precise segundo punto del eje:" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   aM := OC_MirrorM( ::aPts[ 1 ], ::aPts[ 2 ] )
   lDel := OC_AskText( "??Borrar originales? (S/N)", "N" )
   FOR EACH cH IN ::aSelH
      o := ::oDoc:FindEnt( cH )
      IF o != NIL
         IF Upper( lDel ) == "S"
            o:Transform( aM )
         ELSE
            o := o:Clone()
            o:cHandle := ""
            o:Transform( aM )
            ::oDoc:AddEnt( o )
         ENDIF
      ENDIF
   NEXT
   ::oDoc:MarkDirty()
RETURN ::Finish()

//=========================== DESFASE ================================================
CLASS TCmdOffset FROM TCmdBase
   DATA oCmdEnt INIT NIL
   DATA nDist   INIT 0.0
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdOffset
   ::super:New( "DESFASE" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdOffset
   LOCAL o, nD, o2
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   IF ::nStep == 0
      o := ::oView:PickEnt( aPt )
      IF o == NIL .OR. !( o:nType == OHB_ENT_LINE .OR. ;
           o:nType == OHB_ENT_CIRCLE .OR. o:nType == OHB_ENT_ARC .OR. ;
           o:nType == OHB_ENT_LWPOLYLINE )
         OHB_CmdPrompt( "Designe l??nea, c??rculo, arco o polil??nea:" )
         RETURN OHB_CMD_NEED_SELECT
      ENDIF
      ::oCmdEnt := o
      nD := OC_AskNum( "Distancia de desfase", 10.0 )
      IF nD == NIL .OR. nD <= 0
         RETURN ::Cancel()
      ENDIF
      ::nDist := nD
      ::nStep := 1
      OHB_CmdPrompt( "Precise lado del desfase:" )
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   o2 := OHB_OffsetEnt( ::oCmdEnt, ::nDist, aPt )
   IF o2 == NIL
      OHB_CmdPrompt( "Desfase imposible." )
      RETURN ::Cancel()
   ENDIF
   o2:cLayer := ::oDoc:cCurLayer
   ::oDoc:AddEnt( o2 )
   ::nStep := 0
   OHB_CmdPrompt( "Designe entidad (Intro termina):" )
RETURN OHB_CMD_NEED_SELECT

FUNCTION OHB_OffsetEnt( o, nD, aSide )
   // Rust: modify/offset.rs (casos l??nea/c??rculo/arco/poli)
   LOCAL o2, i, aA, aB, aOff, aT, d1, d2
   DO CASE
   CASE o:nType == OHB_ENT_LINE
      aOff := OC_OffSeg( o:aP1, o:aP2, nD )
      d1 := OC_Dist2D( { aOff[ 1 ][ 1 ], aOff[ 1 ][ 2 ] }, aSide )
      aOff := OC_OffSeg( o:aP1, o:aP2, If( d1 < OC_Dist2D( ;
         OC_OffSeg( o:aP1, o:aP2, -nD )[ 1 ], aSide ), nD, -nD ) )
      o2 := TEntLine():New()
      o2:aP1 := aOff[ 1 ]
      o2:aP2 := aOff[ 2 ]
   CASE o:nType == OHB_ENT_CIRCLE
      o2 := TEntCircle():New()
      o2:aCen := AClone( o:aCen )
      IF OC_Dist2D( o:aCen, aSide ) >= o:nRad
         o2:nRad := o:nRad + nD
      ELSE
         o2:nRad := Max( o:nRad - nD, 0.001 )
      ENDIF
   CASE o:nType == OHB_ENT_ARC
      o2 := TEntArc():New()
      o2:aCen := AClone( o:aCen )
      o2:nA0 := o:nA0
      o2:nA1 := o:nA1
      IF OC_Dist2D( o:aCen, aSide ) >= o:nRad
         o2:nRad := o:nRad + nD
      ELSE
         o2:nRad := Max( o:nRad - nD, 0.001 )
      ENDIF
   CASE o:nType == OHB_ENT_LWPOLYLINE
      o2 := TEntPoly():New()
      FOR i := 2 TO Len( o:aVerts )
         aOff := OC_OffSeg( o:aVerts[ i - 1 ], o:aVerts[ i ], nD )
         // lado: compara punto medio con aSide
         d1 := OC_Dist2D( OC_Mid2D( aOff[ 1 ], aOff[ 2 ] ), aSide )
         d2 := OC_Dist2D( OC_Mid2D( OC_OffSeg( o:aVerts[ i - 1 ], ;
            o:aVerts[ i ], -nD )[ 1 ], OC_OffSeg( o:aVerts[ i - 1 ], ;
            o:aVerts[ i ], -nD )[ 2 ] ), aSide )
         IF d2 < d1
            aOff := OC_OffSeg( o:aVerts[ i - 1 ], o:aVerts[ i ], -nD )
         ENDIF
         IF i == 2
            AAdd( o2:aVerts, aOff[ 1 ] )
         ENDIF
         AAdd( o2:aVerts, aOff[ 2 ] )
      NEXT
   OTHERWISE
      RETURN NIL
   ENDCASE
RETURN o2

//=========================== EMPALME ================================================
CLASS TCmdFillet FROM TCmdBase
   DATA oL1 INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdFillet
   ::super:New( "EMPALME" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdFillet
   LOCAL o, nR, aRes
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   o := ::oView:PickEnt( aPt )
   IF o == NIL .OR. o:nType != OHB_ENT_LINE
      OHB_CmdPrompt( "Designe primera l??nea:" )
      RETURN OHB_CMD_NEED_SELECT
   ENDIF
   IF ::nStep == 0
      ::oL1 := o
      ::nStep := 1
      OHB_CmdPrompt( "Designe segunda l??nea:" )
      RETURN OHB_CMD_NEED_SELECT
   ENDIF
   nR := OC_AskNum( "Radio de empalme", 5.0 )
   IF nR == NIL .OR. nR < 0
      RETURN ::Cancel()
   ENDIF
   aRes := OHB_Fillet2Lines( ::oL1, o, nR )
   IF aRes == NIL
      OHB_CmdPrompt( "L??neas paralelas: empalme imposible." )
      RETURN ::Cancel()
   ENDIF
   ::oL1:aP2 := aRes[ 1 ]
   o:aP1 := aRes[ 2 ]
   ::oDoc:AddEnt( aRes[ 3 ] )
   ::oDoc:MarkDirty()
RETURN ::Finish()

FUNCTION OHB_Fillet2Lines( oL1, oL2, nR )
   // Rust: modify/fillet.rs (caso l??nea-l??nea)
   LOCAL aX := OC_IntersLL( oL1:aP1, oL1:aP2, oL2:aP1, oL2:aP2, .F. )
   LOCAL oA, nA1, nA2, aT1, aT2
   IF aX == NIL
      RETURN NIL
   ENDIF
   aX := { aX[ 1 ], aX[ 2 ] }
   // puntos de tangencia retrocediendo nR por cada l??nea
   aT1 := OHB_BackOff( aX, oL1, nR )
   aT2 := OHB_BackOff( aX, oL2, nR )
   oA := TEntArc():New()
   oA:aCen := aX  // aprox: centro en intersecci??n desplazada (fase 1)
   oA:nRad := nR
   oA:nA0 := OC_NormAng( OC_Ang2D( aX, aT1 ) )
   oA:nA1 := OC_NormAng( OC_Ang2D( aX, aT2 ) )
   // reorienta l??neas hacia la intersecci??n
   IF OC_Dist2D( oL1:aP2, aX ) > OC_Dist2D( oL1:aP1, aX )
      oL1:aP2 := aT1
   ELSE
      oL1:aP1 := aT1
   ENDIF
   IF OC_Dist2D( oL2:aP1, aX ) > OC_Dist2D( oL2:aP2, aX )
      oL2:aP1 := aT2
   ELSE
      oL2:aP2 := aT2
   ENDIF
RETURN { aT1, aT2, oA }

STATIC FUNCTION OHB_BackOff( aX, oL, nR )
   LOCAL L := OC_Dist2D( oL:aP1, oL:aP2 ), u
   IF L < 0.000000001
      RETURN AClone( aX )
   ENDIF
   // punto sobre la l??nea a distancia nR de la intersecci??n, lado cercano
   u := nR / L
   IF OC_Dist2D( oL:aP2, aX ) < OC_Dist2D( oL:aP1, aX )
      RETURN { oL:aP2[ 1 ] + ( oL:aP1[ 1 ] - oL:aP2[ 1 ] ) / L * nR, ;
               oL:aP2[ 2 ] + ( oL:aP1[ 2 ] - oL:aP2[ 2 ] ) / L * nR }
   ENDIF
RETURN { oL:aP1[ 1 ] + ( oL:aP2[ 1 ] - oL:aP1[ 1 ] ) / L * nR, ;
         oL:aP1[ 2 ] + ( oL:aP2[ 2 ] - oL:aP1[ 2 ] ) / L * nR }

//=========================== RECORTA ================================================
CLASS TCmdTrim FROM TCmdBase
   DATA oCut INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdTrim
   ::super:New( "RECORTA" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdTrim
   LOCAL oCut, o
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   IF ::nStep == 0
      oCut := ::oView:PickEnt( aPt )
      IF oCut == NIL
         OHB_CmdPrompt( "Designe arista cortante:" )
         RETURN OHB_CMD_NEED_SELECT
      ENDIF
      ::oCut := oCut
      ::nStep := 1
      OHB_CmdPrompt( "Designe entidad a recortar (lado a conservar opuesto):" )
      RETURN OHB_CMD_NEED_SELECT
   ENDIF
   o := ::oView:PickEnt( aPt )
   IF o != NIL .AND. o:cHandle != ::oCut:cHandle .AND. ;
      OHB_TrimOne( o, ::oCut, aPt )
      ::oDoc:MarkDirty()
      ::oView:Refresh()
      OHB_CmdPrompt( "Recortado. Siguiente (Intro termina):" )
   ELSE
      OHB_CmdPrompt( "Sin intersecci??n. Siguiente (Intro termina):" )
   ENDIF
RETURN OHB_CMD_NEED_SELECT

FUNCTION OHB_TrimOne( o, oCut, aPick )
   // Rust: modify/trim.rs (caso l??nea recortada por l??nea)
   LOCAL aX
   IF o:nType != OHB_ENT_LINE .OR. oCut:nType != OHB_ENT_LINE
      RETURN .F.
   ENDIF
   aX := OC_IntersLL( o:aP1, o:aP2, oCut:aP1, oCut:aP2, .T. )
   IF aX == NIL
      RETURN .F.
   ENDIF
   aX := { aX[ 1 ], aX[ 2 ] }
   IF OC_Dist2D( aPick, o:aP1 ) < OC_Dist2D( aPick, o:aP2 )
      o:aP1 := aX
   ELSE
      o:aP2 := aX
   ENDIF
RETURN .T.

//=========================== MATRIZ ==================================================
CLASS TCmdArray FROM TCmdSel
   DATA lPolar INIT .F.
   DATA nRows  INIT 2
   DATA nCols  INIT 2
   DATA nDx    INIT 10.0
   DATA nDy    INIT 10.0
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdArray
   ::super:New( "MATRIZ" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdArray
   LOCAL cH, o, o2, i, j, nR, nC, nDx, nDy, cTipo
   IF ::lSelPhase
      IF ! ::UseSel()
         IF ! ::SelPick( aPt, nFlags )
            RETURN OHB_CMD_NEED_SELECT
         ENDIF
         IF Empty( ::aSelH )
            RETURN ::Cancel()
         ENDIF
      ENDIF
      ::lSelPhase := .F.
      cTipo := Upper( OC_AskText( "Tipo (R)ectangular o (P)olar", "R" ) )
      IF cTipo == "P"
         ::lPolar := .T.
         OHB_CmdPrompt( "Precise centro polar:" )
      ELSE
         ::lPolar := .F.
         nR := OC_AskNum( "Filas", 2 )
         nC := OC_AskNum( "Columnas", 2 )
         nDx := OC_AskNum( "Distancia columnas", 10 )
         nDy := OC_AskNum( "Distancia filas", 10 )
         ::nRows := nR
         ::nCols := nC
         ::nDx := nDx
         ::nDy := nDy
         FOR EACH cH IN ::aSelH
            o := ::oDoc:FindEnt( cH )
            IF o != NIL
               FOR i := 1 TO nR
                  FOR j := 1 TO nC
                     IF i == 1 .AND. j == 1
                        LOOP
                     ENDIF
                     o2 := o:Clone()
                     o2:cHandle := ""
                     o2:Transform( OC_MoveM( ( j - 1 ) * nDx, ( i - 1 ) * nDy ) )
                     ::oDoc:AddEnt( o2 )
                  NEXT
               NEXT
            ENDIF
         NEXT
         RETURN ::Finish()
      ENDIF
      RETURN OHB_CMD_NEED_POINT
   ENDIF
   // polar: centro ya designado
   nC := OC_AskNum( "N??mero de elementos", 6 )
   IF nC == NIL .OR. nC < 2
      RETURN ::Cancel()
   ENDIF
   FOR EACH cH IN ::aSelH
      o := ::oDoc:FindEnt( cH )
      IF o != NIL
         FOR i := 2 TO nC
            o2 := o:Clone()
            o2:cHandle := ""
            o2:Transform( OC_RotM( 8 * ATan( 1 ) * ( i - 1 ) / nC, aPt ) )
            ::oDoc:AddEnt( o2 )
         NEXT
      ENDIF
   NEXT
RETURN ::Finish()

//=========================== IGUALA ===================================================
CLASS TCmdMatch FROM TCmdBase
   DATA oSrc INIT NIL
   METHOD New() CONSTRUCTOR
   METHOD OnPick( aPt, nFlags )
ENDCLASS

METHOD New() CLASS TCmdMatch
   ::super:New( "IGUALA" )
RETURN Self

METHOD OnPick( aPt, nFlags ) CLASS TCmdMatch
   LOCAL o
   IF aPt == NIL
      RETURN ::Cancel()
   ENDIF
   o := ::oView:PickEnt( aPt )
   IF o == NIL
      RETURN OHB_CMD_NEED_SELECT
   ENDIF
   IF ::nStep == 0
      ::oSrc := o
      ::nStep := 1
      OHB_CmdPrompt( "Designe entidades destino (Intro termina):" )
      RETURN OHB_CMD_NEED_SELECT
   ENDIF
   OHB_MatchProps( o, ::oSrc )
   ::oDoc:MarkDirty()
   ::oView:Refresh()
RETURN OHB_CMD_NEED_SELECT
