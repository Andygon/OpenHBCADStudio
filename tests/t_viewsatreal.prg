/* [extra] Fase 2 / B13b: lector SAT y teselado contra 3DSOLID reales (tests/fixtures/solids3d.dxf, de ezdxf/examples/acistools/3dsolids.dxf, MIT, creados con ODA/AutoCAD). */
#include "ocx.ch"

PROCEDURE T_ViewSatReal()
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
   Chk( nPl >= 2, "[extra] satreal: al menos 2 solidos totalmente planos se tesela completos (" + hb_ntos( nPl ) + ")" )
   OutStd( "satreal caras=" + hb_ntos( nF ) + " tris=" + hb_ntos( nT ) + " saltadas=" + hb_ntos( nSk ) + hb_eol() )
RETURN
