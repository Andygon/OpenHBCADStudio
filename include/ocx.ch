/* OpenHBCADStudio - include/ocx.ch  (UTF-8, sin BOM)
   Constantes comunes. Origen: std::f64::consts y literales de geom2d. */
#ifndef _OCX_CH
#define _OCX_CH
#define OCX_PI        3.14159265358979323846
#define OCX_TAU       6.28318530717958647692
#define OCX_FRAC_PI_2 1.57079632679489661923
#define OCX_EPS300    ( 10.0 ^ -300 )   /* Harbour no admite literales con exponente (1e-300) */
#define OCX_V2_X      1
#define OCX_V2_Y      2
#define OCX_1E_20     0.00000000000000000001
#define OCX_MIN_POSITIVE OCX_MINPOS()   /* f64::MIN_POSITIVE (DBL_MIN), via C: Harbour no admite literales con exponente */
/* indices de Ellipse {centre, major_radius, minor_radius, major_axis} */
#define ELL_CENTRE     1
#define ELL_MAJOR_R    2
#define ELL_MINOR_R    3
#define ELL_MAJOR_AXIS 4
/* BulgeArc {center, radius, start_angle, end_angle, sweep} */
#define BA_CENTER 1
#define BA_RADIUS 2
#define BA_START  3
#define BA_END    4
#define BA_SWEEP  5
/* PolylineVertex {position, bulge}; Polyline {aVertices, lClosed}
   NOTA: indices de la API publica (segment_arc, source_index...) son BASE 0 como en Rust;
   los arrays de Harbour son base 1 (se suma 1 solo al acceder). */
#define PV_POS   1
#define PV_BULGE 2
#define PL_VERTS  1
#define PL_CLOSED 2
#define OCX_PI_24 0.130899693899574718269    /* PI/24 */
#define OCX_PI_9  0.349065850398865915384    /* PI/9  */
#define OCX_PI_36 0.087266462599716478846    /* PI/36 */
/* Curve = { nKind, aData }. Kinds y campos de cada forma (curve.rs) */
#define CV_LINE     1
#define CV_CIRCLE   2
#define CV_ARC      3
#define CV_ELLIPSE  4
#define CV_POLYLINE 5
#define CV_NURBS    6
#define CV_RAY      7
#define CV_XLINE    8
#define CV_KIND 1
#define CV_DATA 2
#define LN_START 1
#define LN_END   2
#define CI_CENTRE 1
#define CI_RADIUS 2
#define AR_CENTRE 1
#define AR_RADIUS 2
#define AR_START  3
#define AR_END    4
#define EA_ELLIPSE 1
#define EA_START   2
#define EA_END     3
#define RY_ORIGIN 1
#define RY_DIR    2
#define XL_BASE   1
#define XL_DIR    2
#define EXT_BOUNDED  1
#define EXT_FORWARD  2
#define EXT_INFINITE 3
/* NurbsCurve = { nDegree, aKnots, aCtrl, aWeights } */
#define NC_DEGREE  1
#define NC_KNOTS   2
#define NC_CTRL    3
#define NC_WEIGHTS 4
#define OCX_MAX_ANGLE_DEFAULT_SEGS 20.0
#define OCX_SQRT2_2 0.70710678118654752440
/* Transform = { aXAxis, aYAxis, aOrigin } */
#define TR_X 1
#define TR_Y 2
#define TR_O 3
/* Fillet = { aTangent1, aTangent2, aCentre, nStartAngle, nEndAngle } */
#define FL_T1 1
#define FL_T2 2
#define FL_C  3
#define FL_S  4
#define FL_E  5
/* Crossing = { aPoint, nTA, nTB } */
#define CR_POINT 1
#define CR_TA    2
#define CR_TB    3
/* Closest = { nT, aPoint, nDistance } */
#define CL_T 1
#define CL_P 2
#define CL_D 3
/* SnapKind y SnapPoint = { nKind, aPoint, nT } */
#define SK_ENDPOINT 1
#define SK_MIDPOINT 2
#define SK_CENTRE 3
#define SK_QUADRANT 4
#define SK_PERPENDICULAR 5
#define SK_TANGENT 6
#define SP_KIND 1
#define SP_POINT 2
#define SP_T 3
#define PZ_UNIFORM 0
#define PZ_CENTRIPETAL 1
#define PZ_CHORD 2
#define IK_COINCIDENT 1
#define IK_COLLINEAR 2
#define IK_PARALLEL 3
#define IK_PERPENDICULAR 4
#define IK_TANGENT 5
#define IK_CONCENTRIC 6
#define IK_HORIZONTAL 7
#define IK_VERTICAL 8
#define IK_EQUAL 9
#define IC_KIND 1
#define IC_FIRST 2
#define IC_SECOND 3
#define IC_FIRSTEP 4
#define IC_SECONDEP 5
#define SX_NONE 0
#define SX_POINT 1
#define SX_OVERLAP 2
/* codec Color kinds: {nKind, a, b, c} */
#define CK_BYLAYER 0
#define CK_NONE    1
#define CK_BYBLOCK 2
#define CK_INDEX   3
#define CK_RGB     4
/* codec Transparency {nKind, nAlpha} y LineWeight {nKind, nValue} */
#define TK_BYLAYER  0
#define TK_BYBLOCK  1
#define TK_EXPLICIT 2
#define LK_BYLAYER 0
#define LK_BYBLOCK 1
#define LK_DEFAULT 2
#define LK_VALUE   3
/* codec GroupCodeValueType */
#define GVT_NONE 0
#define GVT_STRING 1
#define GVT_BOOL 2
#define GVT_BYTE 3
#define GVT_INT16 4
#define GVT_INT32 5
#define GVT_INT64 6
#define GVT_DOUBLE 7
#define GVT_POINT3D 8
#define GVT_BINARYDATA 9
#define GVT_HANDLE 10
#endif

/* XDataValue (opencadcodec xdata/mod.rs): { nKind, xValue } */
#define XV_STRING 1
#define XV_CONTROLSTRING 2
#define XV_LAYERNAME 3
#define XV_BINARYDATA 4
#define XV_HANDLE 5
#define XV_POINT3D 6
#define XV_POSITION3D 7
#define XV_DISPLACEMENT3D 8
#define XV_DIRECTION3D 9
#define XV_REAL 10
#define XV_DISTANCE 11
#define XV_SCALEFACTOR 12
#define XV_INTEGER16 13
#define XV_INTEGER32 14

/* entities/text.rs: TextHorizontalAlignment / TextVerticalAlignment (orden del enum) */
#define TXH_LEFT 0
#define TXH_CENTER 1
#define TXH_RIGHT 2
#define TXH_ALIGNED 3
#define TXH_MIDDLE 4
#define TXH_FIT 5
#define TXV_BASELINE 0
#define TXV_BOTTOM 1
#define TXV_MIDDLE 2
#define TXV_TOP 3
/* entities/mtext.rs: AttachmentPoint, DrawingDirection; multileader.rs: LineSpacingStyle (discriminantes Rust) */
#define MTA_TOPLEFT 1
#define MTA_TOPCENTER 2
#define MTA_TOPRIGHT 3
#define MTA_MIDDLELEFT 4
#define MTA_MIDDLECENTER 5
#define MTA_MIDDLERIGHT 6
#define MTA_BOTTOMLEFT 7
#define MTA_BOTTOMCENTER 8
#define MTA_BOTTOMRIGHT 9
#define MTD_LEFTTORIGHT 1
#define MTD_TOPTOBOTTOM 3
#define MTD_BYSTYLE 5
#define LSS_ATLEAST 1
#define LSS_EXACTLY 2
