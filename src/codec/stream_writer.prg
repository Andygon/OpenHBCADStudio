/*----------------------------------------------------------------------------
   OpenHBCADStudio - src/codec/stream_writer.prg
   Origen Rust: opencadcodec/src/io/dxf/writer/stream_writer.rs (124 lineas, sin tests).
   Licencia del original: MPL-2.0.
   Los traits DxfStreamWriter/DxfStreamWriterExt pasan a funciones Sw_* que despachan por modo del
   writer: w = { nMode, cBuf, nFH }; nMode 1 = texto, 2 = binario. Salida en memoria (Sw_Output) o,
   si se da nFH, volcada a fichero por bloques. Todas las escrituras devuelven NIL si van bien o
   una cadena de error (como el Err de Rust).
----------------------------------------------------------------------------*/
#include "ocx.ch"

#define SW_BIN( w ) ( w[ 1 ] == 2 )

FUNCTION Sw_IsBinary( w ) ; RETURN SW_BIN( w )
FUNCTION Sw_Output( w ) ; RETURN w[ 2 ]

/* anade bytes al buffer; con fichero asociado vuelca al pasar de 64 KB */
FUNCTION Sw_Put( w, c )
   w[ 2 ] += c
   IF w[ 3 ] != NIL .AND. hb_BLen( w[ 2 ] ) > 65536
      FWrite( w[ 3 ], w[ 2 ] ) ; w[ 2 ] := ""
   ENDIF
RETURN NIL

FUNCTION Sw_WriteString( w, nCode, c ) ; RETURN IIf( SW_BIN( w ), BnW_String( w, nCode, c ), TxW_String( w, nCode, c ) )
FUNCTION Sw_WriteXRecordString( w, nCode, c ) ; RETURN IIf( SW_BIN( w ), BnW_XRecordString( w, nCode, c ), TxW_XRecordString( w, nCode, c ) )
FUNCTION Sw_WriteByte( w, nCode, n ) ; RETURN IIf( SW_BIN( w ), BnW_Byte( w, nCode, n ), TxW_Byte( w, nCode, n ) )
FUNCTION Sw_WriteI16( w, nCode, n ) ; RETURN IIf( SW_BIN( w ), BnW_I16( w, nCode, n ), TxW_I16( w, nCode, n ) )
FUNCTION Sw_WriteI32( w, nCode, n ) ; RETURN IIf( SW_BIN( w ), BnW_I32( w, nCode, n ), TxW_I32( w, nCode, n ) )
FUNCTION Sw_WriteI64( w, nCode, n ) ; RETURN IIf( SW_BIN( w ), BnW_I64( w, nCode, n ), TxW_I64( w, nCode, n ) )
FUNCTION Sw_WriteDouble( w, nCode, n ) ; RETURN IIf( SW_BIN( w ), BnW_Double( w, nCode, n ), TxW_Double( w, nCode, n ) )
FUNCTION Sw_WriteBool( w, nCode, l ) ; RETURN IIf( SW_BIN( w ), BnW_Bool( w, nCode, l ), TxW_Bool( w, nCode, l ) )
FUNCTION Sw_WriteHandle( w, nCode, h ) ; RETURN IIf( SW_BIN( w ), BnW_Handle( w, nCode, h ), TxW_Handle( w, nCode, h ) )
FUNCTION Sw_WriteBinary( w, nCode, cData ) ; RETURN IIf( SW_BIN( w ), BnW_Binary( w, nCode, cData ), TxW_Binary( w, nCode, cData ) )
FUNCTION Sw_Flush( w )
   IF w[ 3 ] != NIL .AND. hb_BLen( w[ 2 ] ) > 0 ; FWrite( w[ 3 ], w[ 2 ] ) ; w[ 2 ] := "" ; ENDIF
RETURN NIL

/* --- DxfStreamWriterExt --- */
FUNCTION Sw_WritePoint2d( w, nXCode, v )
   LOCAL e := Sw_WriteDouble( w, nXCode, v[ 1 ] )
   IF e != NIL ; RETURN e ; ENDIF
RETURN Sw_WriteDouble( w, nXCode + 10, v[ 2 ] )
FUNCTION Sw_WritePoint3d( w, nXCode, v )
   LOCAL e := Sw_WriteDouble( w, nXCode, v[ 1 ] )
   IF e != NIL ; RETURN e ; ENDIF
   e := Sw_WriteDouble( w, nXCode + 10, v[ 2 ] )
   IF e != NIL ; RETURN e ; ENDIF
RETURN Sw_WriteDouble( w, nXCode + 20, v[ 3 ] )
FUNCTION Sw_WriteColor( w, nCode, c )
   DO CASE
   CASE c[ 1 ] == CK_BYLAYER ; RETURN Sw_WriteI16( w, nCode, 256 )
   CASE c[ 1 ] == CK_NONE ; RETURN Sw_WriteI16( w, nCode, 257 )
   CASE c[ 1 ] == CK_BYBLOCK ; RETURN Sw_WriteI16( w, nCode, 0 )
   CASE c[ 1 ] == CK_INDEX ; RETURN Sw_WriteI16( w, nCode, c[ 2 ] )   // index as i16
   ENDCASE
RETURN Sw_WriteI16( w, nCode, Cl_ApproximateIndex( c ) )
FUNCTION Sw_WriteEntityType( w, c ) ; RETURN Sw_WriteString( w, 0, c )
FUNCTION Sw_WriteSubclass( w, c ) ; RETURN Sw_WriteString( w, 100, c )
FUNCTION Sw_WriteSectionStart( w, c )
   LOCAL e := Sw_WriteString( w, 0, "SECTION" )
   IF e != NIL ; RETURN e ; ENDIF
RETURN Sw_WriteString( w, 2, c )
FUNCTION Sw_WriteSectionEnd( w ) ; RETURN Sw_WriteString( w, 0, "ENDSEC" )
FUNCTION Sw_WriteEof( w ) ; RETURN Sw_WriteString( w, 0, "EOF" )
FUNCTION Sw_ValueTypeForCode( nCode ) ; RETURN Gv_FromCode( Dxc_FromI32( nCode ) )
