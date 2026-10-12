/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/xdata.prg
   Origen Rust: opencadcodec/src/xdata/mod.rs (189 lineas, 2 tests en t_codec_entities.prg)
   Licencia del original: MPL-2.0.
   XDataValue = { nKind (XV_*), xValue }. ExtendedDataRecord = { cApplicationName, aValues }.
   ExtendedData = { aRecords, aRawDwgEed } (aRawDwgEed: { { nHandle, cBytes }, ... }).
   Option<T> -> NIL. Los clones del original son copias: use hb_Clone() si hay que duplicar.
----------------------------------------------------------------------------*/
#include "ocx.ch"

FUNCTION Xv_New( nKind, xValue ) ; RETURN { nKind, xValue }

FUNCTION Xr_New( cApp ) ; RETURN { cApp, {} }
FUNCTION Xr_ApplicationName( r ) ; RETURN r[ 1 ]
FUNCTION Xr_Values( r ) ; RETURN r[ 2 ]
FUNCTION Xr_AddValue( r, v ) ; AAdd( r[ 2 ], v ) ; RETURN NIL
FUNCTION Xr_Len( r ) ; RETURN Len( r[ 2 ] )
FUNCTION Xr_IsEmpty( r ) ; RETURN Len( r[ 2 ] ) == 0

FUNCTION Xd_New() ; RETURN { {}, {} }
FUNCTION Xd_AddRecord( x, r ) ; AAdd( x[ 1 ], r ) ; RETURN NIL
FUNCTION Xd_UpsertRecord( x, r )
   LOCAL n := AScan( x[ 1 ], {| e | e[ 1 ] == r[ 1 ] } )
   IF n > 0 ; x[ 1 ][ n ] := r ; ELSE ; AAdd( x[ 1 ], r ) ; ENDIF
RETURN NIL
/* remove_record: devuelve el registro quitado o NIL */
FUNCTION Xd_RemoveRecord( x, cApp )
   LOCAL n := AScan( x[ 1 ], {| e | e[ 1 ] == cApp } ), r
   IF n == 0 ; RETURN NIL ; ENDIF
   r := x[ 1 ][ n ] ; hb_ADel( x[ 1 ], n, .T. )
RETURN r
FUNCTION Xd_Records( x ) ; RETURN x[ 1 ]
FUNCTION Xd_GetRecord( x, cApp )
   LOCAL n := AScan( x[ 1 ], {| e | e[ 1 ] == cApp } )
RETURN IIf( n > 0, x[ 1 ][ n ], NIL )
FUNCTION Xd_Len( x ) ; RETURN Len( x[ 1 ] )
FUNCTION Xd_IsEmpty( x ) ; RETURN Len( x[ 1 ] ) == 0
FUNCTION Xd_Clear( x ) ; ASize( x[ 1 ], 0 ) ; RETURN NIL
