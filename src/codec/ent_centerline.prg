/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/ent_centerline.prg
   Origen Rust: opencadcodec/src/entities/centerline.rs (277, SIN tests en Rust). Licencia del original: MPL-2.0.
   Prefijos: Cla_ (CenterLineAssociation), Cma_ (CenterMarkAssociation). Los enums son enteros CLS_ y CMS_ (codigo = valor).
   read( ExtendedData ) devuelve hash o NIL (None). write/remove modifican el ExtendedData (xdata.prg).
   Tests [extra] en t_codec_misc2.prg.
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define CENTERLINE_XDATA_APPLICATION "OCS_CENTERLINE"
#define CENTERMARK_XDATA_APPLICATION "OCS_CENTERMARK"
#define CL_SIGNATURE      "CENTERLINE_ASSOCIATION"
#define CL_MARK_SIGNATURE "CENTERMARK_ASSOCIATION"
#define CL_VERSION        1

STATIC FUNCTION Cl_KindsMatch( aV, aKinds )
   LOCAL i
   IF Len( aV ) != Len( aKinds ) ; RETURN .F. ; ENDIF
   FOR i := 1 TO Len( aV )
      IF aV[ i ][ 1 ] != aKinds[ i ] ; RETURN .F. ; ENDIF
   NEXT
RETURN .T.

FUNCTION Cls_FromCode( n ) ; RETURN iif( n >= 0 .AND. n <= 2, n, NIL )
FUNCTION Cms_FromCode( n ) ; RETURN iif( n >= 0 .AND. n <= 3, n, NIL )
FUNCTION Cla_ApplicationName() ; RETURN CENTERLINE_XDATA_APPLICATION
FUNCTION Cma_ApplicationName() ; RETURN CENTERMARK_XDATA_APPLICATION

FUNCTION Cla_Read( x )
   LOCAL r := Xd_GetRecord( x, CENTERLINE_XDATA_APPLICATION ), v, k1, k2
   IF r == NIL ; RETURN NIL ; ENDIF
   v := Xr_Values( r )
   IF ! Cl_KindsMatch( v, { XV_STRING, XV_INTEGER16, XV_HANDLE, XV_INTEGER16, XV_INTEGER32, XV_POINT3D, XV_HANDLE, XV_INTEGER16, XV_INTEGER32, XV_POINT3D, XV_POINT3D, XV_DIRECTION3D, XV_DIRECTION3D, ;
      XV_DISTANCE, XV_DISTANCE, XV_DISTANCE, XV_DISTANCE, XV_INTEGER16 } ) ; RETURN NIL ; ENDIF
   IF ! ( v[ 1 ][ 2 ] == CL_SIGNATURE ) .OR. v[ 2 ][ 2 ] != CL_VERSION ; RETURN NIL ; ENDIF
   k1 := Cls_FromCode( v[ 4 ][ 2 ] ) ; IF k1 == NIL ; RETURN NIL ; ENDIF
   k2 := Cls_FromCode( v[ 8 ][ 2 ] ) ; IF k2 == NIL ; RETURN NIL ; ENDIF
RETURN hb_Hash( "first", hb_Hash( "handle", v[ 3 ][ 2 ], "kind", k1, "segment_index", v[ 5 ][ 2 ], "pick_point", v[ 6 ][ 2 ] ), ;
   "second", hb_Hash( "handle", v[ 7 ][ 2 ], "kind", k2, "segment_index", v[ 9 ][ 2 ], "pick_point", v[ 10 ][ 2 ] ), ;
   "plane_origin", v[ 11 ][ 2 ], "plane_x", v[ 12 ][ 2 ], "plane_y", v[ 13 ][ 2 ], "start_extension", v[ 14 ][ 2 ], "end_extension", v[ 15 ][ 2 ], ;
   "start_length_adjustment", v[ 16 ][ 2 ], "end_length_adjustment", v[ 17 ][ 2 ], "associated", hb_bitAnd( v[ 18 ][ 2 ], 1 ) != 0 )

FUNCTION Cla_Write( a, x )
   LOCAL r := Xr_New( CENTERLINE_XDATA_APPLICATION )
   Xr_AddValue( r, Xv_New( XV_STRING, CL_SIGNATURE ) ) ; Xr_AddValue( r, Xv_New( XV_INTEGER16, CL_VERSION ) )
   Xr_AddValue( r, Xv_New( XV_HANDLE, a[ "first" ][ "handle" ] ) ) ; Xr_AddValue( r, Xv_New( XV_INTEGER16, a[ "first" ][ "kind" ] ) )
   Xr_AddValue( r, Xv_New( XV_INTEGER32, a[ "first" ][ "segment_index" ] ) ) ; Xr_AddValue( r, Xv_New( XV_POINT3D, a[ "first" ][ "pick_point" ] ) )
   Xr_AddValue( r, Xv_New( XV_HANDLE, a[ "second" ][ "handle" ] ) ) ; Xr_AddValue( r, Xv_New( XV_INTEGER16, a[ "second" ][ "kind" ] ) )
   Xr_AddValue( r, Xv_New( XV_INTEGER32, a[ "second" ][ "segment_index" ] ) ) ; Xr_AddValue( r, Xv_New( XV_POINT3D, a[ "second" ][ "pick_point" ] ) )
   Xr_AddValue( r, Xv_New( XV_POINT3D, a[ "plane_origin" ] ) ) ; Xr_AddValue( r, Xv_New( XV_DIRECTION3D, a[ "plane_x" ] ) ) ; Xr_AddValue( r, Xv_New( XV_DIRECTION3D, a[ "plane_y" ] ) )
   Xr_AddValue( r, Xv_New( XV_DISTANCE, a[ "start_extension" ] ) ) ; Xr_AddValue( r, Xv_New( XV_DISTANCE, a[ "end_extension" ] ) )
   Xr_AddValue( r, Xv_New( XV_DISTANCE, a[ "start_length_adjustment" ] ) ) ; Xr_AddValue( r, Xv_New( XV_DISTANCE, a[ "end_length_adjustment" ] ) )
   Xr_AddValue( r, Xv_New( XV_INTEGER16, iif( a[ "associated" ], 1, 0 ) ) )
   Xd_UpsertRecord( x, r )
RETURN NIL
FUNCTION Cla_Remove( x ) ; Xd_RemoveRecord( x, CENTERLINE_XDATA_APPLICATION ) ; RETURN NIL

FUNCTION Cma_Read( x )
   LOCAL r := Xd_GetRecord( x, CENTERMARK_XDATA_APPLICATION ), v, k, f, aK := { XV_STRING, XV_INTEGER16, XV_HANDLE, XV_INTEGER16, XV_INTEGER32, XV_POINT3D, XV_POINT3D, XV_DIRECTION3D, XV_DIRECTION3D, XV_POINT3D }, i
   IF r == NIL ; RETURN NIL ; ENDIF
   v := Xr_Values( r )
   FOR i := 1 TO 12 ; AAdd( aK, XV_DISTANCE ) ; NEXT
   AAdd( aK, XV_INTEGER16 )
   IF ! Cl_KindsMatch( v, aK ) ; RETURN NIL ; ENDIF
   IF ! ( v[ 1 ][ 2 ] == CL_MARK_SIGNATURE ) .OR. v[ 2 ][ 2 ] != CL_VERSION ; RETURN NIL ; ENDIF
   k := Cms_FromCode( v[ 4 ][ 2 ] ) ; IF k == NIL ; RETURN NIL ; ENDIF
   f := v[ 23 ][ 2 ]
RETURN hb_Hash( "source", hb_Hash( "handle", v[ 3 ][ 2 ], "kind", k, "segment_index", v[ 5 ][ 2 ], "pick_point", v[ 6 ][ 2 ] ), ;
   "plane_origin", v[ 7 ][ 2 ], "plane_x", v[ 8 ][ 2 ], "plane_y", v[ 9 ][ 2 ], "center", v[ 10 ][ 2 ], "radius", v[ 11 ][ 2 ], "cross_size", v[ 12 ][ 2 ], "cross_gap", v[ 13 ][ 2 ], ;
   "extension_length", v[ 14 ][ 2 ], "length_adjustments", { v[ 15 ][ 2 ], v[ 16 ][ 2 ], v[ 17 ][ 2 ], v[ 18 ][ 2 ] }, "overshoots", { v[ 19 ][ 2 ], v[ 20 ][ 2 ], v[ 21 ][ 2 ], v[ 22 ][ 2 ] }, ;
   "show_extensions", hb_bitAnd( f, 1 ) != 0, "associated", hb_bitAnd( f, 2 ) != 0, "cross_size_relative", hb_bitAnd( f, 4 ) != 0, "cross_gap_relative", hb_bitAnd( f, 8 ) != 0 )

FUNCTION Cma_Write( a, x )
   LOCAL r := Xr_New( CENTERMARK_XDATA_APPLICATION ), i, nF
   Xr_AddValue( r, Xv_New( XV_STRING, CL_MARK_SIGNATURE ) ) ; Xr_AddValue( r, Xv_New( XV_INTEGER16, CL_VERSION ) )
   Xr_AddValue( r, Xv_New( XV_HANDLE, a[ "source" ][ "handle" ] ) ) ; Xr_AddValue( r, Xv_New( XV_INTEGER16, a[ "source" ][ "kind" ] ) )
   Xr_AddValue( r, Xv_New( XV_INTEGER32, a[ "source" ][ "segment_index" ] ) ) ; Xr_AddValue( r, Xv_New( XV_POINT3D, a[ "source" ][ "pick_point" ] ) )
   Xr_AddValue( r, Xv_New( XV_POINT3D, a[ "plane_origin" ] ) ) ; Xr_AddValue( r, Xv_New( XV_DIRECTION3D, a[ "plane_x" ] ) ) ; Xr_AddValue( r, Xv_New( XV_DIRECTION3D, a[ "plane_y" ] ) )
   Xr_AddValue( r, Xv_New( XV_POINT3D, a[ "center" ] ) ) ; Xr_AddValue( r, Xv_New( XV_DISTANCE, a[ "radius" ] ) ) ; Xr_AddValue( r, Xv_New( XV_DISTANCE, a[ "cross_size" ] ) )
   Xr_AddValue( r, Xv_New( XV_DISTANCE, a[ "cross_gap" ] ) ) ; Xr_AddValue( r, Xv_New( XV_DISTANCE, a[ "extension_length" ] ) )
   FOR i := 1 TO 4 ; Xr_AddValue( r, Xv_New( XV_DISTANCE, a[ "length_adjustments" ][ i ] ) ) ; NEXT
   FOR i := 1 TO 4 ; Xr_AddValue( r, Xv_New( XV_DISTANCE, a[ "overshoots" ][ i ] ) ) ; NEXT
   nF := iif( a[ "show_extensions" ], 1, 0 ) + iif( a[ "associated" ], 2, 0 ) + iif( a[ "cross_size_relative" ], 4, 0 ) + iif( a[ "cross_gap_relative" ], 8, 0 )
   Xr_AddValue( r, Xv_New( XV_INTEGER16, nF ) )
   Xd_UpsertRecord( x, r )
RETURN NIL
FUNCTION Cma_Remove( x ) ; Xd_RemoveRecord( x, CENTERMARK_XDATA_APPLICATION ) ; RETURN NIL
