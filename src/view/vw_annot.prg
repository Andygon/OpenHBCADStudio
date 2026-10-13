/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_annot.prg
   Fase 2 / modules/annotate e insert sobre la sesion del visor:
   TEXT x,y altura texto... | MTEXT x,y altura texto... | INSERT bloque x,y [escala [giro]]
   DIMLINEAR x1,y1 x2,y2 ox,oy [h] | DIMALIGNED x1,y1 x2,y2 ox,oy [h]
   DIMRADIUS cx,cy px,py [h] | DIMDIAMETER cx,cy px,py [h]
   (h = altura del texto de cota; por defecto dimtxt * dimscale del estilo).
   Vwd_Geom genera la geometria de una cota sin bloque anonimo (lineas de
   referencia, linea de cota, flechas y texto) para dibujarla en el visor.
   No portado (N/A): leaders/mleader interactivos, tablas, revcloud, wipeout,
   escalas de anotacion, xref/underlay, content browser, ATTEDIT.
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION Va_Fmt( n )
   LOCAL c := AllTrim( Str( n, 16, 2 ) )
   IF At( ".", c ) > 0
      DO WHILE Right( c, 1 ) == "0" ; c := Left( c, Len( c ) - 1 ) ; ENDDO
      IF Right( c, 1 ) == "." ; c := Left( c, Len( c ) - 1 ) ; ENDIF
   ENDIF
RETURN c

STATIC FUNCTION Va_TxtH( d, e )
   LOCAL nH := 0.18, st
   IF hb_HHasKey( e[ "base" ], "text_height" ) .AND. e[ "base" ][ "text_height" ] > 0.0
      RETURN e[ "base" ][ "text_height" ]
   ENDIF
   IF hb_HHasKey( d, "dim_styles" )
      st := Tb_Get( d[ "dim_styles" ], e[ "base" ][ "style_name" ] )
      IF st != NIL .AND. hb_HHasKey( st, "dimtxt" ) .AND. hb_HHasKey( st, "dimscale" )
         nH := st[ "dimtxt" ] * IIf( st[ "dimscale" ] > 0.0, st[ "dimscale" ], 1.0 )
      ENDIF
   ENDIF
RETURN nH

STATIC FUNCTION Va_Arrow( aSegs, x, y, ux, uy, nS )
   // punta en (x,y) mirando hacia -u ; cola hacia +u
   AAdd( aSegs, { { x, y }, { x + ux * nS - uy * nS / 6.0, y + uy * nS + ux * nS / 6.0 } } )
   AAdd( aSegs, { { x, y }, { x + ux * nS + uy * nS / 6.0, y + uy * nS - ux * nS / 6.0 } } )
RETURN NIL

/* { aSegs, aTexts } de una cota LINEAR / ALIGNED / RADIUS / DIAMETER; NIL si no se sabe */
FUNCTION Vwd_Geom( d, e )
   LOCAL cT := e[ "_type" ], aS := {}, aT := {}, nH := Va_TxtH( d, e ), nA, nR, u, n, p1, p2, df, nD1, nD2, a1, a2, nM, cTxt, nAng, nLen
   LOCAL nEx, c, q, v
   df := e[ "definition_point" ]
   DO CASE
   CASE cT == "DIMENSION_LINEAR" .OR. cT == "DIMENSION_ALIGNED"
      p1 := e[ "first_point" ] ; p2 := e[ "second_point" ]
      IF cT == "DIMENSION_ALIGNED"
         nLen := Sqrt( ( p2[ 1 ] - p1[ 1 ] ) ^ 2 + ( p2[ 2 ] - p1[ 2 ] ) ^ 2 )
         IF nLen <= 0.0 ; RETURN NIL ; ENDIF
         u := { ( p2[ 1 ] - p1[ 1 ] ) / nLen, ( p2[ 2 ] - p1[ 2 ] ) / nLen }
      ELSE
         u := { OCX_COS( e[ "rotation" ] ), OCX_SIN( e[ "rotation" ] ) }
      ENDIF
      n := { - u[ 2 ], u[ 1 ] }
      nD1 := ( df[ 1 ] - p1[ 1 ] ) * n[ 1 ] + ( df[ 2 ] - p1[ 2 ] ) * n[ 2 ]
      nD2 := ( df[ 1 ] - p2[ 1 ] ) * n[ 1 ] + ( df[ 2 ] - p2[ 2 ] ) * n[ 2 ]
      a1 := { p1[ 1 ] + n[ 1 ] * nD1, p1[ 2 ] + n[ 2 ] * nD1 }
      a2 := { p2[ 1 ] + n[ 1 ] * nD2, p2[ 2 ] + n[ 2 ] * nD2 }
      nM := Abs( ( p2[ 1 ] - p1[ 1 ] ) * u[ 1 ] + ( p2[ 2 ] - p1[ 2 ] ) * u[ 2 ] )
      nEx := nH / 2.0
      FOR EACH c IN { { p1, a1, nD1 }, { p2, a2, nD2 } }
         v := IIf( c[ 3 ] >= 0.0, 1.0, -1.0 )
         AAdd( aS, { { c[ 1 ][ 1 ] + n[ 1 ] * v * nH / 4.0, c[ 1 ][ 2 ] + n[ 2 ] * v * nH / 4.0 }, { c[ 2 ][ 1 ] + n[ 1 ] * v * nEx, c[ 2 ][ 2 ] + n[ 2 ] * v * nEx } } )
      NEXT
      AAdd( aS, { a1, a2 } )
      nLen := Sqrt( ( a2[ 1 ] - a1[ 1 ] ) ^ 2 + ( a2[ 2 ] - a1[ 2 ] ) ^ 2 )
      IF nLen > 0.0
         q := { ( a2[ 1 ] - a1[ 1 ] ) / nLen, ( a2[ 2 ] - a1[ 2 ] ) / nLen }
         Va_Arrow( aS, a1[ 1 ], a1[ 2 ], q[ 1 ], q[ 2 ], nH )
         Va_Arrow( aS, a2[ 1 ], a2[ 2 ], - q[ 1 ], - q[ 2 ], nH )
         nAng := OCX_ATAN2( q[ 2 ], q[ 1 ] )
      ELSE
         nAng := 0.0
         q := { 1.0, 0.0 }
      ENDIF
      IF q[ 1 ] < - 0.000001 .OR. ( Abs( q[ 1 ] ) <= 0.000001 .AND. q[ 2 ] < 0.0 ) ; nAng += OCX_PI ; ENDIF
      cTxt := IIf( Empty( e[ "base" ][ "text" ] ), Va_Fmt( nM ), StrTran( e[ "base" ][ "text" ], "<>", Va_Fmt( nM ) ) )
      nR := nAng
      nA := nH * Len( cTxt ) * 0.3
      AAdd( aT, { ( a1[ 1 ] + a2[ 1 ] ) / 2.0 - OCX_COS( nR ) * nA - OCX_SIN( nR ) * nH * 0.4, ;
                  ( a1[ 2 ] + a2[ 2 ] ) / 2.0 - OCX_SIN( nR ) * nA + OCX_COS( nR ) * nH * 0.4, nH, nR, cTxt } )
   CASE cT == "DIMENSION_RADIUS" .OR. cT == "DIMENSION_DIAMETER"
      c := e[ "angle_vertex" ] ; q := df
      nLen := Sqrt( ( q[ 1 ] - c[ 1 ] ) ^ 2 + ( q[ 2 ] - c[ 2 ] ) ^ 2 )
      IF nLen <= 0.0 ; RETURN NIL ; ENDIF
      u := { ( q[ 1 ] - c[ 1 ] ) / nLen, ( q[ 2 ] - c[ 2 ] ) / nLen }
      IF cT == "DIMENSION_DIAMETER"
         AAdd( aS, { q, c } )
         Va_Arrow( aS, q[ 1 ], q[ 2 ], - u[ 1 ], - u[ 2 ], nH )
         nM := nLen * 2.0
         cTxt := "%%c" + Va_Fmt( nM )
      ELSE
         AAdd( aS, { c, q } )
         Va_Arrow( aS, q[ 1 ], q[ 2 ], - u[ 1 ], - u[ 2 ], nH )
         nM := nLen
         cTxt := "R" + Va_Fmt( nM )
      ENDIF
      IF ! Empty( e[ "base" ][ "text" ] ) ; cTxt := e[ "base" ][ "text" ] ; ENDIF
      AAdd( aT, { q[ 1 ] + u[ 1 ] * nH * 0.6, q[ 2 ] + u[ 2 ] * nH * 0.6, nH, 0.0, cTxt } )
   OTHERWISE
      RETURN NIL
   ENDCASE
RETURN { aS, aT }

/* ---- creacion ---------------------------------------------------------------- */
FUNCTION Vwe_Text( s, cT, p, nH, cStr )
   LOCAL e := IIf( cT == "MTEXT", Emt_New(), Etx_New() )
   e[ "value" ] := cStr ; e[ "insertion_point" ] := { p[ 1 ], p[ 2 ], 0.0 } ; e[ "height" ] := nH
RETURN Vwe_Add( s, e )

FUNCTION Vwe_Insert( s, cName, p, nSc, nRot )
   LOCAL e
   IF Tb_Get( s[ "doc" ][ "block_records" ], cName ) == NIL ; RETURN 0 ; ENDIF
   e := Ein_New( cName, { p[ 1 ], p[ 2 ], 0.0 } )
   e[ "x_scale" ] := nSc ; e[ "y_scale" ] := nSc ; e[ "z_scale" ] := nSc ; e[ "rotation" ] := nRot * OCX_PI / 180.0
RETURN Vwe_Add( s, e )

/* cK: DIMLINEAR DIMALIGNED (p1,p2,pOff) | DIMRADIUS DIMDIAMETER (c,p) ; nH = 0 -> estilo */
FUNCTION Vwe_Dim( s, cK, aP, nH )
   LOCAL e, v1, v2, v3
   v1 := { aP[ 1 ][ 1 ], aP[ 1 ][ 2 ], 0.0 } ; v2 := { aP[ 2 ][ 1 ], aP[ 2 ][ 2 ], 0.0 }
   DO CASE
   CASE cK == "DIMLINEAR" .OR. cK == "DIMALIGNED"
      v3 := { aP[ 3 ][ 1 ], aP[ 3 ][ 2 ], 0.0 }
      e := IIf( cK == "DIMLINEAR", Dli_New( v1, v2 ), Dal_New( v1, v2 ) )
      IF cK == "DIMLINEAR"
         // horizontal si el desplazamiento es sobre todo vertical, vertical en caso contrario
         IF Abs( v3[ 1 ] - ( v1[ 1 ] + v2[ 1 ] ) / 2.0 ) > Abs( v3[ 2 ] - ( v1[ 2 ] + v2[ 2 ] ) / 2.0 ) .AND. Abs( v2[ 2 ] - v1[ 2 ] ) > 0.0
            e[ "rotation" ] := OCX_PI / 2.0
            e[ "base" ][ "actual_measurement" ] := Abs( v2[ 2 ] - v1[ 2 ] )
         ELSE
            e[ "base" ][ "actual_measurement" ] := Abs( v2[ 1 ] - v1[ 1 ] )
         ENDIF
      ENDIF
      e[ "definition_point" ] := v3 ; e[ "base" ][ "definition_point" ] := v3
   CASE cK == "DIMRADIUS"
      e := Dra_New( v1, v2 )
   OTHERWISE
      e := Ddi_New( v1, v2 )
   ENDCASE
   IF nH > 0.0 ; e[ "base" ][ "text_height" ] := nH ; ENDIF
RETURN Vwe_Add( s, e )

/* ---- comandos ---------------------------------------------------------------- */
FUNCTION VwA_Cmd( s, cK, aTok )
   LOCAL i := 2, p, aP := {}, nH := 0.0, cStr := "", nSc := 1.0, nRot := 0.0, cName, h, nNeed
   IF VwC_Is3D( s[ "cam" ] )
      RETURN Vk_Res( "Vuelva a la planta (VISTA SUP) para dibujar o editar" )
   ENDIF
   IF cK == "INSERT"
      IF Len( aTok ) < 2 ; RETURN Vk_Res( "Uso: INSERT bloque x,y [escala [giro]]" ) ; ENDIF
      cName := aTok[ 2 ] ; i := 3
   ENDIF
   p := Vk_Pt( aTok, i )
   IF p == NIL
      RETURN Vk_Res( "Uso: " + { "TEXT" => "TEXT x,y altura texto", "MTEXT" => "MTEXT x,y altura texto", "INSERT" => "INSERT bloque x,y [escala [giro]]", ;
                                  "DIMLINEAR" => "DIMLINEAR x1,y1 x2,y2 ox,oy [h]", "DIMALIGNED" => "DIMALIGNED x1,y1 x2,y2 ox,oy [h]", ;
                                  "DIMRADIUS" => "DIMRADIUS cx,cy px,py [h]", "DIMDIAMETER" => "DIMDIAMETER cx,cy px,py [h]" }[ cK ] )
   ENDIF
   IF cK == "TEXT" .OR. cK == "MTEXT"
      i += IIf( At( ",", aTok[ i ] ) > 0, 1, 2 )
      IF Len( aTok ) < i + 1 .OR. ! Vk_IsNum( aTok[ i ] ) .OR. Val( aTok[ i ] ) <= 0.0
         RETURN Vk_Res( "Uso: " + cK + " x,y altura texto" )
      ENDIF
      nH := Val( aTok[ i ] ) ; i++
      DO WHILE i <= Len( aTok )
         cStr += IIf( Empty( cStr ), "", " " ) + aTok[ i ] ; i++
      ENDDO
      Vwe_Text( s, cK, p, nH, cStr )
      RETURN Vk_Res( IIf( cK == "TEXT", "Texto creado", "Texto multilinea creado" ), , .T. )
   ENDIF
   IF cK == "INSERT"
      i += IIf( At( ",", aTok[ i ] ) > 0, 1, 2 )
      IF Len( aTok ) >= i .AND. Vk_IsNum( aTok[ i ] ) ; nSc := Val( aTok[ i ] ) ; i++ ; ENDIF
      IF Len( aTok ) >= i .AND. Vk_IsNum( aTok[ i ] ) ; nRot := Val( aTok[ i ] ) ; ENDIF
      IF nSc <= 0.0 ; RETURN Vk_Res( "INSERT: escala no valida" ) ; ENDIF
      h := Vwe_Insert( s, cName, p, nSc, nRot )
      IF h == 0 ; RETURN Vk_Res( "INSERT: no existe el bloque " + cName ) ; ENDIF
      RETURN Vk_Res( "Bloque insertado", , .T. )
   ENDIF
   nNeed := IIf( cK == "DIMLINEAR" .OR. cK == "DIMALIGNED", 3, 2 )
   DO WHILE Len( aP ) < nNeed
      p := Vk_Pt( aTok, i )
      IF p == NIL ; RETURN Vk_Res( "Uso: " + cK + " con " + hb_ntos( nNeed ) + " puntos x,y" ) ; ENDIF
      AAdd( aP, p ) ; i += IIf( At( ",", aTok[ i ] ) > 0, 1, 2 )
   ENDDO
   IF Len( aTok ) >= i .AND. Vk_IsNum( aTok[ i ] ) ; nH := Val( aTok[ i ] ) ; ENDIF
   IF Abs( aP[ 1 ][ 1 ] - aP[ 2 ][ 1 ] ) + Abs( aP[ 1 ][ 2 ] - aP[ 2 ][ 2 ] ) <= 0.0 ; RETURN Vk_Res( cK + ": puntos coincidentes" ) ; ENDIF
   Vwe_Dim( s, cK, aP, nH )
RETURN Vk_Res( "Cota creada", , .T. )
