/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_poly3d.prg
   Origen Rust: opencadcodec/src/entities/polyline3d.rs (569, 10 tests)
              + translate_/transform_polyline3d. Licencia del original: MPL-2.0.
   Entidad = hash ("_type" "POLYLINE3D"; Ent_EntityType devuelve "POLYLINE"). Option -> NIL.
   Los indices de get_vertex/remove_vertex/insert_vertex son base 0 como en Rust.
   Prefijos: P3f_ (Polyline3DFlags), Ssd_ (SmoothSurfaceType: to/from dwg), V3p_ (Vertex3DPolyline), P3d_ (Polyline3D).
   with_layer/with_color (builders) no se portan: se asigna e["common"]["layer"] directamente.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION P3f_Polyline3d() ; RETURN hb_Hash( "closed", .F., "spline_fit", .F., "is_3d", .T., "is_3d_mesh", .F., "mesh_closed_n", .F., "is_polyface_mesh", .F., "linetype_continuous", .F. )
FUNCTION P3f_FromBits( n )
RETURN hb_Hash( "closed", hb_bitAnd( n, 1 ) != 0, "spline_fit", hb_bitAnd( n, 4 ) != 0, "is_3d", hb_bitAnd( n, 8 ) != 0, "is_3d_mesh", hb_bitAnd( n, 16 ) != 0, ;
                "mesh_closed_n", hb_bitAnd( n, 32 ) != 0, "is_polyface_mesh", hb_bitAnd( n, 64 ) != 0, "linetype_continuous", hb_bitAnd( n, 128 ) != 0 )
FUNCTION P3f_ToBits( f )
   LOCAL n := 0
   IF f[ "closed" ] ; n := hb_bitOr( n, 1 ) ; ENDIF
   IF f[ "spline_fit" ] ; n := hb_bitOr( n, 4 ) ; ENDIF
   IF f[ "is_3d" ] ; n := hb_bitOr( n, 8 ) ; ENDIF
   IF f[ "is_3d_mesh" ] ; n := hb_bitOr( n, 16 ) ; ENDIF
   IF f[ "mesh_closed_n" ] ; n := hb_bitOr( n, 32 ) ; ENDIF
   IF f[ "is_polyface_mesh" ] ; n := hb_bitOr( n, 64 ) ; ENDIF
   IF f[ "linetype_continuous" ] ; n := hb_bitOr( n, 128 ) ; ENDIF
RETURN n

/* SmoothSurfaceType (valores SST_*): from_value = Sst_From (ent_polyline.prg); to_value = identidad */
FUNCTION Ssd_FromDwgCode( n )
   DO CASE
   CASE n == 1 ; RETURN SST_QUADRATIC_BSPLINE
   CASE n == 2 ; RETURN SST_CUBIC_BSPLINE
   ENDCASE
RETURN SST_NONE
FUNCTION Ssd_ToDwgCode( n )
   DO CASE
   CASE n == SST_QUADRATIC_BSPLINE ; RETURN 1
   CASE n == SST_CUBIC_BSPLINE ; RETURN 2
   ENDCASE
RETURN 0

FUNCTION V3p_New( vPos ) ; RETURN hb_Hash( "handle", Hd_Null(), "layer", "0", "position", vPos, "flags", 32 )
FUNCTION V3p_FromXyz( x, y, z ) ; RETURN V3p_New( Vc3_New( x, y, z ) )

FUNCTION P3d_New()
RETURN hb_Hash( "_type", "POLYLINE3D", "common", Ec_New(), "flags", P3f_Polyline3d(), "smooth_type", SST_NONE, "default_start_width", 0.0, "default_end_width", 0.0, ;
                "mesh_m_count", 0, "mesh_n_count", 0, "smooth_m_density", 0, "smooth_n_density", 0, "elevation", 0.0, "normal", Vc3_UnitZ(), "vertices", {} )
FUNCTION P3d_AddVertex( e, vPos ) ; AAdd( e[ "vertices" ], V3p_New( vPos ) ) ; RETURN NIL
FUNCTION P3d_FromPoints( aPts )
   LOCAL e := P3d_New(), p
   FOR EACH p IN aPts
      P3d_AddVertex( e, p )
   NEXT
RETURN e
FUNCTION P3d_AddVertexFull( e, v ) ; AAdd( e[ "vertices" ], v ) ; RETURN NIL
FUNCTION P3d_VertexCount( e ) ; RETURN Len( e[ "vertices" ] )
FUNCTION P3d_IsClosed( e ) ; RETURN e[ "flags" ][ "closed" ]
FUNCTION P3d_Close( e ) ; e[ "flags" ][ "closed" ] := .T. ; RETURN NIL
FUNCTION P3d_Open( e ) ; e[ "flags" ][ "closed" ] := .F. ; RETURN NIL
/* Option<&Vertex>: NIL si el indice (base 0) no existe */
FUNCTION P3d_GetVertex( e, nIdx ) ; RETURN iif( nIdx >= 0 .AND. nIdx < Len( e[ "vertices" ] ), e[ "vertices" ][ nIdx + 1 ], NIL )
FUNCTION P3d_Length( e )
   LOCAL nTotal := 0.0, i, a := e[ "vertices" ]
   IF Len( a ) < 2 ; RETURN 0.0 ; ENDIF
   FOR i := 1 TO Len( a ) - 1
      nTotal += Vc3_Distance( a[ i ][ "position" ], a[ i + 1 ][ "position" ] )
   NEXT
   IF P3d_IsClosed( e ) .AND. Len( a ) >= 2
      nTotal += Vc3_Distance( ATail( a )[ "position" ], a[ 1 ][ "position" ] )
   ENDIF
RETURN nTotal
FUNCTION P3d_Centroid( e )
   LOCAL s := Vc3_Zero(), v
   IF Len( e[ "vertices" ] ) == 0 ; RETURN Vc3_Zero() ; ENDIF
   FOR EACH v IN e[ "vertices" ]
      s := Vc3_Add( s, v[ "position" ] )
   NEXT
RETURN Vc3_Mul( s, 1.0 / Len( e[ "vertices" ] ) )
FUNCTION P3d_Positions( e )
   LOCAL a := {}, v
   FOR EACH v IN e[ "vertices" ]
      AAdd( a, v[ "position" ] )
   NEXT
RETURN a
FUNCTION P3d_StartPoint( e ) ; RETURN iif( Len( e[ "vertices" ] ) > 0, e[ "vertices" ][ 1 ][ "position" ], NIL )
FUNCTION P3d_EndPoint( e ) ; RETURN iif( Len( e[ "vertices" ] ) > 0, ATail( e[ "vertices" ] )[ "position" ], NIL )
FUNCTION P3d_Reverse( e )
   LOCAL a := {}, i
   FOR i := Len( e[ "vertices" ] ) TO 1 STEP -1
      AAdd( a, e[ "vertices" ][ i ] )
   NEXT
   e[ "vertices" ] := a
RETURN NIL
FUNCTION P3d_RemoveVertex( e, nIdx )
   LOCAL v
   IF nIdx >= 0 .AND. nIdx < Len( e[ "vertices" ] )
      v := e[ "vertices" ][ nIdx + 1 ] ; hb_ADel( e[ "vertices" ], nIdx + 1, .T. )
      RETURN v
   ENDIF
RETURN NIL
FUNCTION P3d_InsertVertex( e, nIdx, vPos )
   IF nIdx >= 0 .AND. nIdx <= Len( e[ "vertices" ] ) ; hb_AIns( e[ "vertices" ], nIdx + 1, V3p_New( vPos ), .T. ) ; ENDIF
RETURN NIL
FUNCTION P3d_Clear( e ) ; e[ "vertices" ] := {} ; RETURN NIL
FUNCTION P3d_BoundingBox( e )
   LOCAL a := P3d_Positions( e )
   IF Len( a ) == 0 ; RETURN Bb3_Default() ; ENDIF
RETURN Bb3_FromPoints( a )
FUNCTION P3d_Translate( e, vOffset )
   LOCAL v
   FOR EACH v IN e[ "vertices" ]
      v[ "position" ] := Vc3_Add( v[ "position" ], vOffset )
   NEXT
RETURN NIL
FUNCTION P3d_Transform( e, t )
   LOCAL v
   FOR EACH v IN e[ "vertices" ]
      v[ "position" ] := Tf_Apply( t, v[ "position" ] )
   NEXT
RETURN NIL
