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

/* entities/polyline.rs: PolylineFlags (u16), VertexFlags (u8), SmoothSurfaceType (discriminantes Rust) */
#define PF_CLOSED 1
#define PF_CURVE_FIT 2
#define PF_SPLINE_FIT 4
#define PF_POLYLINE_3D 8
#define PF_POLYGON_MESH 16
#define PF_CLOSED_N 32
#define PF_POLYFACE_MESH 64
#define PF_LINETYPE_CONTINUOUS 128
#define VF_EXTRA_VERTEX 1
#define VF_CURVE_FIT_TANGENT 2
#define VF_SPLINE_VERTEX 8
#define VF_SPLINE_CONTROL 16
#define VF_POLYLINE_3D 32
#define VF_POLYGON_MESH 64
#define VF_POLYFACE_FACE 128
#define SST_NONE 0
#define SST_QUADRATIC_BSPLINE 5
#define SST_CUBIC_BSPLINE 6
#define SST_BEZIER 8

/* entities/attribute_definition.rs: MTextFlag (HorizontalAlignment/VerticalAlignment usan los mismos valores que TXH_/TXV_) */
#define MTF_SINGLELINE 0
#define MTF_MULTILINE 2
#define MTF_CONSTANTMULTILINE 4

/* entities/dimension.rs: DimensionType y AttachmentPointType */
#define DMT_LINEAR       0
#define DMT_ALIGNED      1
#define DMT_ANGULAR      2
#define DMT_DIAMETER     3
#define DMT_RADIUS       4
#define DMT_ANGULAR3PT   5
#define DMT_ORDINATE     6
#define DMT_ARCLENGTH    8
#define DMT_LARGERADIAL  9
#define DAP_TOPLEFT      1
#define DAP_TOPCENTER    2
#define DAP_TOPRIGHT     3
#define DAP_MIDDLELEFT   4
#define DAP_MIDDLECENTER 5
#define DAP_MIDDLERIGHT  6
#define DAP_BOTTOMLEFT   7
#define DAP_BOTTOMCENTER 8
#define DAP_BOTTOMRIGHT  9

/* entities/leader.rs */
#define LPT_STRAIGHT 0
#define LPT_SPLINE   1
#define LCT_WITHTEXT      0
#define LCT_WITHTOLERANCE 1
#define LCT_WITHBLOCK     2
#define LCT_NOANNOTATION  3

/* entities/tolerance.rs: gdt_symbols (caracteres) */
#define GDT_STRAIGHTNESS      "a"
#define GDT_FLATNESS          "c"
#define GDT_CIRCULARITY       "g"
#define GDT_CYLINDRICITY      "e"
#define GDT_LINE_PROFILE      "k"
#define GDT_SURFACE_PROFILE   "d"
#define GDT_PARALLELISM       "h"
#define GDT_PERPENDICULARITY  "j"
#define GDT_ANGULARITY        "n"
#define GDT_POSITION          "p"
#define GDT_CONCENTRICITY     "u"
#define GDT_SYMMETRY          "i"
#define GDT_CIRCULAR_RUNOUT   "r"
#define GDT_TOTAL_RUNOUT      "t"
#define GDT_DIAMETER          "n"
#define GDT_MMC               "m"
#define GDT_LMC               "l"
#define GDT_RFS               "s"

/* entities/shape.rs: standard_shapes y gdt_shapes */
#define SHP_BOX       "BOX"
#define SHP_CIRC      "CIRC"
#define SHP_HEX       "HEX"
#define SHP_CROSS     "CROSS"
#define SHP_ARROW     "ARROW"
#define SHP_PLUS      "PLUS"
#define SHP_DIAMOND   "DIAMOND"
#define SHP_TRIANGLE  "TRIANGLE"
#define SHP_SQUARE    "SQUARE"
#define GDS_STRAIGHTNESS      110
#define GDS_FLATNESS          111
#define GDS_CIRCULARITY       112
#define GDS_CYLINDRICITY      113
#define GDS_POSITION          114
#define GDS_CONCENTRICITY     115
#define GDS_SYMMETRY          116
#define GDS_PARALLELISM       117
#define GDS_PERPENDICULARITY  118
#define GDS_ANGULARITY        119
#define GDS_LINE_PROFILE      120
#define GDS_SURFACE_PROFILE   121
#define GDS_CIRCULAR_RUNOUT   122
#define GDS_TOTAL_RUNOUT      123

/* entities/mline.rs: MLineFlags y MLineStyleFlags */
#define MLF_HAS_VERTICES  1
#define MLF_CLOSED        2
#define MLF_NO_START_CAPS 4
#define MLF_NO_END_CAPS   8
#define MLS_NONE                  0
#define MLS_FILL_ON               1
#define MLS_DISPLAY_JOINTS        2
#define MLS_START_SQUARE_CAP      16
#define MLS_START_INNER_ARCS_CAP  32
#define MLS_START_ROUND_CAP       64
#define MLS_END_SQUARE_CAP        256
#define MLS_END_INNER_ARCS_CAP    512
#define MLS_END_ROUND_CAP         1024

/* entities/viewport.rs: ViewportRenderMode y StandardView */
#define VRM_WIREFRAME2D              0
#define VRM_WIREFRAME3D              1
#define VRM_HIDDEN_LINE              2
#define VRM_FLAT_SHADED              3
#define VRM_GOURAUD_SHADED           4
#define VRM_FLAT_SHADED_WITH_EDGES   5
#define VRM_GOURAUD_SHADED_WITH_EDGES 6
#define SV_TOP           0
#define SV_BOTTOM        1
#define SV_FRONT         2
#define SV_BACK          3
#define SV_LEFT          4
#define SV_RIGHT         5
#define SV_SW_ISOMETRIC  6
#define SV_SE_ISOMETRIC  7
#define SV_NE_ISOMETRIC  8
#define SV_NW_ISOMETRIC  9

/* entities/wipeout.rs: WipeoutDisplayFlags, WipeoutClipType, WipeoutClipMode */
#define WDF_NONE                  0
#define WDF_SHOW_IMAGE            1
#define WDF_SHOW_NOT_ALIGNED      2
#define WDF_USE_CLIPPING_BOUNDARY 4
#define WDF_TRANSPARENCY_ON       8
#define WDF_DEFAULT               7
#define WCT_RECTANGULAR  1
#define WCT_POLYGONAL    2
#define WCM_OUTSIDE      0
#define WCM_INSIDE       1

/* entities/raster_image.rs: ClipMode, ResolutionUnit, ImageDisplayQuality, ImageDisplayFlags (ClipType = WCT_*) */
#define CLM_OUTSIDE 0
#define CLM_INSIDE  1
#define RU_NONE        0
#define RU_CENTIMETERS 2
#define RU_INCHES      5
#define IDQ_DRAFT 0
#define IDQ_HIGH  1
#define IDF_NONE                  0
#define IDF_SHOW_IMAGE            1
#define IDF_SHOW_NOT_ALIGNED      2
#define IDF_USE_CLIPPING_BOUNDARY 4
#define IDF_TRANSPARENCY_ON       8
