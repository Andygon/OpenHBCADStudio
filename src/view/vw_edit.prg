/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/view/vw_edit.prg
   Fase 2 / bloque B10 (edicion basica). Origen Rust: src/app/model_ops.rs +
   history.rs (simplificado: deshacer por pila de operaciones).
   Logica pura sobre el documento del codec (Doc_AddEntity, Doc_RemoveEntity,
   Ent_Translate, Ent_Clone). Sesion: ver vw_cmd.prg (clave "undo" = pila).
   Operaciones de la pila: { "add", nHandle } | { "del", entClon } | { "mod", nHandle, entClon }
   Un paso de deshacer puede agrupar varias: cada elemento de la pila es un array de operaciones.
----------------------------------------------------------------------------*/
#include "ocx.ch"

STATIC FUNCTION Vwe_Push( s, aOps )
   IF ! hb_HHasKey( s, "undo" ) ; s[ "undo" ] := {} ; ENDIF
   IF Len( aOps ) > 0 ; AAdd( s[ "undo" ], aOps ) ; ENDIF
RETURN NIL

FUNCTION Vwe_Layer( s ) ; RETURN IIf( hb_HHasKey( s, "clayer" ), s[ "clayer" ], "0" )

/* anade una entidad al modelo con la capa actual; devuelve el handle numerico */
FUNCTION Vwe_Add( s, e )
   LOCAL h
   e[ "common" ][ "layer" ] := Vwe_Layer( s )
   h := Doc_AddEntity( s[ "doc" ], e )
   Vwe_Push( s, { { "add", h } } )
   VwS_Rebuild( s )
RETURN h

FUNCTION Vwe_Line( s, p1, p2 )
   LOCAL e := Eln_New()
   e[ "start" ] := { p1[ 1 ], p1[ 2 ], 0.0 } ; e[ "end" ] := { p2[ 1 ], p2[ 2 ], 0.0 }
RETURN Vwe_Add( s, e )

FUNCTION Vwe_Circle( s, p, r )
   LOCAL e := Eci_New()
   e[ "center" ] := { p[ 1 ], p[ 2 ], 0.0 } ; e[ "radius" ] := r
RETURN Vwe_Add( s, e )

/* arco antihorario centro, radio, angulos en grados */
FUNCTION Vwe_Arc( s, p, r, nA1, nA2 )
   LOCAL e := Ear_New()
   e[ "center" ] := { p[ 1 ], p[ 2 ], 0.0 } ; e[ "radius" ] := r
   e[ "start_angle" ] := nA1 * OCX_PI / 180.0 ; e[ "end_angle" ] := nA2 * OCX_PI / 180.0
RETURN Vwe_Add( s, e )

FUNCTION Vwe_Point( s, p )
   LOCAL e := Ept_New()
   e[ "location" ] := { p[ 1 ], p[ 2 ], 0.0 }
RETURN Vwe_Add( s, e )

FUNCTION Vwe_Pline( s, aPts, lClosed )
   LOCAL e := Elw_FromPoints( aPts )
   e[ "is_closed" ] := lClosed
RETURN Vwe_Add( s, e )

/* handles (numericos) de la seleccion actual */
STATIC FUNCTION Vwe_SelHandles( s )
   LOCAL a := {}, k
   FOR EACH k IN hb_HKeys( s[ "sel" ] )
      AAdd( a, Val( k ) )
   NEXT
RETURN a

FUNCTION Vwe_Erase( s )
   LOCAL aOps := {}, h, e, n := 0
   FOR EACH h IN Vwe_SelHandles( s )
      e := Doc_GetEntity( s[ "doc" ], h )
      IF e != NIL
         AAdd( aOps, { "del", Ent_Clone( e ) } )
         Doc_RemoveEntity( s[ "doc" ], h )
         n++
      ENDIF
   NEXT
   Vwe_Push( s, aOps )
   s[ "sel" ] := hb_Hash()
   VwS_Rebuild( s )
RETURN n

/* mueve (lCopy = .F.) o copia (.T.) la seleccion; devuelve cuantas */
FUNCTION Vwe_MoveSel( s, nDx, nDy, lCopy )
   LOCAL aOps := {}, h, e, c, n := 0, hNew := hb_Hash()
   FOR EACH h IN Vwe_SelHandles( s )
      e := Doc_GetEntity( s[ "doc" ], h )
      IF e == NIL ; LOOP ; ENDIF
      IF lCopy
         c := Ent_Clone( e )
         c[ "common" ][ "handle" ] := Hd_Null()
         Ent_Translate( c, { nDx, nDy, 0.0 } )
         h := Doc_AddEntity( s[ "doc" ], c )
         AAdd( aOps, { "add", h } )
         hNew[ hb_ntos( h ) ] := .T.
      ELSE
         AAdd( aOps, { "mod", h, Ent_Clone( e ) } )
         e := Doc_GetEntityMut( s[ "doc" ], h )
         Ent_Translate( e, { nDx, nDy, 0.0 } )
         hNew[ hb_ntos( h ) ] := .T.
      ENDIF
      n++
   NEXT
   Vwe_Push( s, aOps )
   VwS_Rebuild( s )
   s[ "sel" ] := hNew
RETURN n

/* mueve un grip (indice como Vwp_Grips) de la entidad cHandle a (x,y); .T. si se pudo */
FUNCTION Vwe_GripMove( s, cHandle, nIdx, x, y )
   LOCAL h := Val( cHandle ), e := Doc_GetEntity( s[ "doc" ], h ), cT, old, g, c, nA
   IF e == NIL ; RETURN .F. ; ENDIF
   cT := e[ "_type" ]
   g := Vwp_Grips( e )
   IF nIdx < 1 .OR. nIdx > Len( g ) ; RETURN .F. ; ENDIF
   IF ( cT == "CIRCLE" .OR. cT == "ARC" .OR. cT == "LWPOLYLINE" .OR. cT == "ELLIPSE" ) .AND. Abs( e[ "normal" ][ 3 ] ) < 0.999
      RETURN .F.                                      // solo planos XY
   ENDIF
   old := Ent_Clone( e )
   e := Doc_GetEntityMut( s[ "doc" ], h )
   DO CASE
   CASE cT == "LINE"
      IF nIdx == 1
         e[ "start" ] := { x, y, e[ "start" ][ 3 ] }
      ELSEIF nIdx == 3
         e[ "end" ] := { x, y, e[ "end" ][ 3 ] }
      ELSE
         Ent_Translate( e, { x - g[ 2 ][ 1 ], y - g[ 2 ][ 2 ], 0.0 } )
      ENDIF
   CASE cT == "CIRCLE"
      c := e[ "center" ]
      IF nIdx == 1
         Ent_Translate( e, { x - c[ 1 ], y - c[ 2 ], 0.0 } )
      ELSE
         e[ "radius" ] := Max( 0.000001, Sqrt( ( x - c[ 1 ] ) ^ 2 + ( y - c[ 2 ] ) ^ 2 ) )
      ENDIF
   CASE cT == "ARC"
      c := e[ "center" ]
      nA := OCX_ATAN2( y - c[ 2 ], x - c[ 1 ] )
      IF nIdx == 1
         e[ "start_angle" ] := nA
      ELSEIF nIdx == 3
         e[ "end_angle" ] := nA
      ELSEIF nIdx == 2
         e[ "radius" ] := Max( 0.000001, Sqrt( ( x - c[ 1 ] ) ^ 2 + ( y - c[ 2 ] ) ^ 2 ) )
      ELSE
         Ent_Translate( e, { x - c[ 1 ], y - c[ 2 ], 0.0 } )
      ENDIF
   CASE cT == "LWPOLYLINE"
      e[ "vertices" ][ nIdx ][ "location" ] := { x, y }
   CASE cT == "ELLIPSE"
      c := e[ "center" ]
      IF nIdx == 1
         Ent_Translate( e, { x - c[ 1 ], y - c[ 2 ], 0.0 } )
      ELSEIF nIdx == 2 .OR. nIdx == 3
         nA := Sqrt( ( x - c[ 1 ] ) ^ 2 + ( y - c[ 2 ] ) ^ 2 )
         IF nA < 0.000001
            Doc_ReplaceEntityArc( s[ "doc" ], h, old )
            RETURN .F.
         ENDIF
         e[ "major_axis" ] := { IIf( nIdx == 2, x - c[ 1 ], c[ 1 ] - x ), IIf( nIdx == 2, y - c[ 2 ], c[ 2 ] - y ), e[ "major_axis" ][ 3 ] }
      ELSE
         nA := Sqrt( e[ "major_axis" ][ 1 ] ^ 2 + e[ "major_axis" ][ 2 ] ^ 2 )
         e[ "minor_axis_ratio" ] := Max( 0.0001, Min( 1.0, Sqrt( ( x - c[ 1 ] ) ^ 2 + ( y - c[ 2 ] ) ^ 2 ) / Max( nA, 0.000001 ) ) )
      ENDIF
   CASE cT == "SPLINE"
      c := IIf( Len( e[ "fit_points" ] ) >= 2, "fit_points", "control_points" )
      e[ c ][ nIdx ] := { x, y, e[ c ][ nIdx ][ 3 ] }
   CASE cT == "POINT"
      e[ "location" ] := { x, y, e[ "location" ][ 3 ] }
   CASE cT == "TEXT" .OR. cT == "MTEXT"
      e[ "insertion_point" ] := { x, y, e[ "insertion_point" ][ 3 ] }
   CASE cT == "INSERT"
      e[ "insert_point" ] := { x, y, e[ "insert_point" ][ 3 ] }
   CASE cT == "SOLID" .OR. cT == "3DFACE"
      c := { "first_corner", "second_corner", "third_corner", "fourth_corner" }[ nIdx ]
      e[ c ] := { x, y, e[ c ][ 3 ] }
   OTHERWISE
      Doc_ReplaceEntityArc( s[ "doc" ], h, old )     // sin soporte: deja la entidad como estaba
      RETURN .F.
   ENDCASE
   Vwe_Push( s, { { "mod", h, old } } )
   VwS_Rebuild( s )
RETURN .T.

/* deshace el ultimo paso; devuelve .F. si no hay nada */
FUNCTION Vwe_Undo( s )
   LOCAL aOps, i, o, d := s[ "doc" ]
   IF ! hb_HHasKey( s, "undo" ) .OR. Len( s[ "undo" ] ) == 0 ; RETURN .F. ; ENDIF
   aOps := ATail( s[ "undo" ] )
   ASize( s[ "undo" ], Len( s[ "undo" ] ) - 1 )
   FOR i := Len( aOps ) TO 1 STEP -1
      o := aOps[ i ]
      DO CASE
      CASE o[ 1 ] == "add"
         Doc_RemoveEntity( d, o[ 2 ] )
      CASE o[ 1 ] == "del"
         Doc_RestoreEntityArc( d, o[ 2 ] )
      CASE o[ 1 ] == "mod"
         Doc_ReplaceEntityArc( d, o[ 2 ], o[ 3 ] )
      ENDCASE
   NEXT
   s[ "sel" ] := hb_Hash()
   VwS_Rebuild( s )
RETURN .T.
