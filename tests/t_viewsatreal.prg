/* [extra] Fase 2 / B13b: lector SAT y teselado contra 3DSOLID reales (tests/fixtures/solids3d.dxf, de ezdxf/examples/acistools/3dsolids.dxf, MIT, creados con ODA/AutoCAD). */
#include "ocx.ch"

PROCEDURE T_ViewSatReal()
   LOCAL ps, pt, pc, bad := 0, i, ex := { 1.0, 0.0, 0.0 }, ey := { 0.0, 1.0, 0.0 }, ez := { 0.0, 0.0, 1.0 }, dd
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
   OutStd( "satreal caras=" + hb_ntos( nF ) + " tris=" + hb_ntos( nT ) + " saltadas=" + hb_ntos( nSk ) + hb_eol() )
RETURN
