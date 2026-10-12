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

/* entities/multileader.rs: enums (valores enteros) */
#define MLC_NONE 0
#define MLC_BLOCK 1
#define MLC_MTEXT 2
#define MLC_TOLERANCE 3
#define MPT_INVISIBLE 0
#define MPT_STRAIGHT_LINE_SEGMENTS 1
#define MPT_SPLINE 2
#define TAT_TOP_OF_TOP_LINE 0
#define TAT_MIDDLE_OF_TOP_LINE 1
#define TAT_MIDDLE_OF_TEXT 2
#define TAT_MIDDLE_OF_BOTTOM_LINE 3
#define TAT_BOTTOM_OF_BOTTOM_LINE 4
#define TAT_BOTTOM_LINE 5
#define TAT_BOTTOM_OF_TOP_LINE_UNDERLINE_BOTTOM_LINE 6
#define TAT_BOTTOM_OF_TOP_LINE_UNDERLINE_TOP_LINE 7
#define TAT_BOTTOM_OF_TOP_LINE_UNDERLINE_ALL 8
#define TAT_CENTER_OF_TEXT 9
#define TAT_CENTER_OF_TEXT_OVERLINE 10
#define TAN_PARALLEL_TO_LAST_LEADER_LINE 0
#define TAN_HORIZONTAL 1
#define TAN_OPTIMIZED 2
#define BCC_BLOCK_EXTENTS 0
#define BCC_BASE_POINT 1
#define TAD_HORIZONTAL 0
#define TAD_VERTICAL 1
#define TAP_LEFT 1
#define TAP_CENTER 2
#define TAP_RIGHT 3
#define TAL_LEFT 0
#define TAL_CENTER 1
#define TAL_RIGHT 2
#define FDT_HORIZONTAL 1
#define FDT_VERTICAL 3
#define FDT_BY_STYLE 5
#define LSS_AT_LEAST 1   /* LSS_EXACTLY ya definido arriba (mtext), mismo valor 2 */
#define MPO_NONE 0
#define MPO_PATH_TYPE 1
#define MPO_LINE_COLOR 2
#define MPO_LEADER_LINE_TYPE 4
#define MPO_LEADER_LINE_WEIGHT 8
#define MPO_ENABLE_LANDING 16
#define MPO_LANDING_GAP 32
#define MPO_ENABLE_DOGLEG 64
#define MPO_LANDING_DISTANCE 128
#define MPO_ARROWHEAD 256
#define MPO_ARROWHEAD_SIZE 512
#define MPO_CONTENT_TYPE 1024
#define MPO_TEXT_STYLE 2048
#define MPO_TEXT_LEFT_ATTACHMENT 4096
#define MPO_TEXT_ANGLE 8192
#define MPO_TEXT_ALIGNMENT 16384
#define MPO_TEXT_COLOR 32768
#define MPO_TEXT_HEIGHT 65536
#define MPO_TEXT_FRAME 131072
#define MPO_ENABLE_USE_DEFAULT_MTEXT 262144
#define MPO_BLOCK_CONTENT 524288
#define MPO_BLOCK_CONTENT_COLOR 1048576
#define MPO_BLOCK_CONTENT_SCALE 2097152
#define MPO_BLOCK_CONTENT_ROTATION 4194304
#define MPO_BLOCK_CONTENT_CONNECTION 8388608
#define MPO_SCALE_FACTOR 16777216
#define MPO_TEXT_RIGHT_ATTACHMENT 33554432
#define MPO_TEXT_SWITCH_ALIGNMENT_TYPE 67108864
#define MPO_TEXT_ATTACHMENT_DIRECTION 134217728
#define MPO_TEXT_TOP_ATTACHMENT 268435456
#define MPO_TEXT_BOTTOM_ATTACHMENT 536870912
#define LLO_NONE 0
#define LLO_PATH_TYPE 1
#define LLO_LINE_COLOR 2
#define LLO_LINE_TYPE 4
#define LLO_LINE_WEIGHT 8
#define LLO_ARROWHEAD_SIZE 16
#define LLO_ARROWHEAD 32

/* entities/helix.rs HelixConstraint, polygon_mesh.rs SurfaceSmoothType y PolygonMeshFlags */
#define HXC_TURN_HEIGHT 0
#define HXC_TURNS       1
#define HXC_HEIGHT      2
#define PMF_CLOSED_M    1
#define PMF_CURVE_FIT   2
#define PMF_SPLINE_FIT  4
#define PMF_POLYGON_MESH 16
#define PMF_CLOSED_N    32
#define PMF_CONTINUOUS_LINETYPE 128

/* entities/ole2frame.rs OleObjectType */
#define OOT_LINK     1
#define OOT_EMBEDDED 2
#define OOT_STATIC   3
/* entities/centerline.rs */
#define CLS_LINE            0
#define CLS_LWPOLY_SEGMENT  1
#define CLS_POLY2D_SEGMENT  2
#define CMS_CIRCLE          0
#define CMS_ARC             1
#define CMS_LWPOLY_ARC_SEG  2
#define CMS_POLY2D_ARC_SEG  3

/* entities/underlay.rs UnderlayType y UnderlayDisplayFlags */
#define UTY_PDF 0
#define UTY_DWF 1
#define UTY_DGN 2
#define UDF_NONE 0
#define UDF_CLIPPING 1
#define UDF_ON 2
#define UDF_MONOCHROME 4
#define UDF_ADJUST_FOR_BACKGROUND 8
#define UDF_CLIP_INSIDE 16
#define UDF_DEFAULT 2

/* notification.rs: NotificationType */
#define NTY_NOT_IMPLEMENTED 0
#define NTY_NOT_SUPPORTED   1
#define NTY_WARNING         2
#define NTY_ERROR           3

/* classes/mod.rs: ProxyFlags */
#define PXF_NONE 0
#define PXF_ERASE_ALLOWED 1
#define PXF_TRANSFORM_ALLOWED 2
#define PXF_COLOR_CHANGE_ALLOWED 4
#define PXF_LAYER_CHANGE_ALLOWED 8
#define PXF_LINETYPE_CHANGE_ALLOWED 16
#define PXF_LINETYPE_SCALE_CHANGE_ALLOWED 32
#define PXF_VISIBILITY_CHANGE_ALLOWED 64
#define PXF_CLONING_ALLOWED 128
#define PXF_LINEWEIGHT_CHANGE_ALLOWED 256
#define PXF_PLOT_STYLE_NAME_CHANGE_ALLOWED 512
#define PXF_ALL_OPERATIONS_EXCEPT_CLONING 895
#define PXF_ALL_OPERATIONS_ALLOWED 1023
#define PXF_DISABLES_PROXY_WARNING_DIALOG 1024
#define PXF_R13_FORMAT_PROXY 32768

/* objects/plot_settings.rs: enums como enteros (codigo DXF) */
#define PPU_INCHES 0
#define PPU_MILLIMETERS 1
#define PPU_PIXELS 2
#define PRT_NONE 0
#define PRT_DEGREES90 1
#define PRT_DEGREES180 2
#define PRT_DEGREES270 3
#define PLT_LAST_SCREEN_DISPLAY 0
#define PLT_EXTENTS 1
#define PLT_LIMITS 2
#define PLT_VIEW 3
#define PLT_WINDOW 4
#define PLT_LAYOUT 5
#define SCT_SCALE_TO_FIT 0
#define SCT_CUSTOM_SCALE 1
#define SCT_ONE_TO_ONE 16
#define SCT_ONE_TO_TWO 17
#define SCT_ONE_TO_FOUR 18
#define SCT_ONE_TO_EIGHT 19
#define SCT_ONE_TO_TEN 20
#define SCT_ONE_TO_SIXTEEN 21
#define SCT_ONE_TO_TWENTY 22
#define SCT_ONE_TO_THIRTY 23
#define SCT_ONE_TO_FORTY 24
#define SCT_ONE_TO_FIFTY 25
#define SCT_ONE_TO_HUNDRED 26
#define SCT_TWO_TO_ONE 27
#define SCT_FOUR_TO_ONE 28
#define SCT_EIGHT_TO_ONE 29
#define SCT_TEN_TO_ONE 30
#define SCT_HUNDRED_TO_ONE 31
#define SPM_AS_DISPLAYED 0
#define SPM_WIREFRAME 1
#define SPM_HIDDEN 2
#define SPM_RENDERED 3
#define SPR_DRAFT 0
#define SPR_PREVIEW 1
#define SPR_NORMAL 2
#define SPR_PRESENTATION 3
#define SPR_MAXIMUM 4
#define SPR_CUSTOM 5

/* objects/block_visibility.rs: BlockEvalValue = { nKind, xValue } */
#define BEV_NONE 0
#define BEV_REAL 1
#define BEV_POINT 2
#define BEV_TEXT 3
#define BEV_LONG 4
#define BEV_HANDLE 5
#define BEV_SHORT 6

#define RSU_NONE        0
#define RSU_CENTIMETERS 2
#define RSU_INCHES      5

#define PPE_BYTES 0
#define PPE_BITS  1
#define PRK_UNDEFINED      0
#define PRK_SOFT_OWNERSHIP 1
#define PRK_HARD_OWNERSHIP 2
#define PRK_SOFT_POINTER   3
#define PRK_HARD_POINTER   4

#define DLT_SYMBOL   1
#define DLT_COMPOUND 2
#define DLT_STROKE   3
#define DLT_POINT    4
#define DLT_INTERNAL 6
#define DLP_DISTANCE 0
#define DLP_FRACTION 1
#define DLP_CENTERED 2
#define DLP_RESERVED 3

#define XRK_LAYER_VIEWPORT_ALPHA_OVERRIDE    0
#define XRK_LAYER_VIEWPORT_COLOR_OVERRIDE    1
#define XRK_LAYER_VIEWPORT_LINETYPE_OVERRIDE 2
#define XRK_LAYER_VIEWPORT_LINEWEIGHT_OVERRIDE 3
#define XRK_LAYER_RECONCILED                 4
#define XRK_LAYER_STATE_ANNOTATION_SCALE     5
#define XRK_ANNOTATION_SCALE                 6
#define XRK_MESH_TEXTURE_COORDINATES         7
#define XRK_XRECORD_ROUND_TRIP               8
#define XRK_MTEXT_ROUND_TRIP                 9
#define XRK_HEADER_ROUND_TRIP                10
#define XRK_RECOMPOSE_DATA                   11
#define XRK_DYNAMIC_BLOCK_HISTORY            12
#define XRK_LAYOUT_THUMBNAIL                 13
#define XRK_VIEW_TRANSITION                  14
#define XRK_PHOTOMETRIC_LIGHT                15
#define XRK_LAST_SAVED_VERSION               16
#define XRK_PREVIOUS_PRODUCT_INFO            17
#define XRK_DRAWING_PROPERTIES               18
#define XRK_FINGERPRINT_GUID                 19
#define XRK_DIMENSION_STYLE_DATA             20
#define XRK_UCS_DATA                         21
#define XRK_PLOT_DATA                        22
#define XRK_HYPERLINK                        23
#define XRK_ADVANCED_MATERIAL                24
#define XRK_MATERIAL_ASSET                   25
#define XRK_METADATA                         26
#define XRK_UNKNOWN                          27
#define XVT_STRING                           0
#define XVT_POINT3D                          1
#define XVT_DOUBLE                           2
#define XVT_BYTE                             3
#define XVT_INT16                            4
#define XVT_INT32                            5
#define XVT_INT64                            6
#define XVT_HANDLE                           7
#define XVT_OBJECT_ID                        8
#define XVT_BOOL                             9
#define XVT_CHUNK                            10
#define XVT_UNKNOWN                          11

#define MST_CT_NONE                                     0
#define MST_CT_BLOCK                                    1
#define MST_CT_MTEXT                                   2
#define MST_CT_TOLERANCE                                3
#define MST_PT_INVISIBLE                                0
#define MST_PT_STRAIGHT_LINE_SEGMENTS                   1
#define MST_PT_SPLINE                                   2
#define MST_TA_TOP_OF_TOP_LINE                          0
#define MST_TA_MIDDLE_OF_TOP_LINE                       1
#define MST_TA_MIDDLE_OF_TEXT                           2
#define MST_TA_MIDDLE_OF_BOTTOM_LINE                    3
#define MST_TA_BOTTOM_OF_BOTTOM_LINE                    4
#define MST_TA_BOTTOM_LINE                              5
#define MST_TA_BOTTOM_OF_TOP_LINE_UNDERLINE_BOTTOM_LINE 6
#define MST_TA_BOTTOM_OF_TOP_LINE_UNDERLINE_TOP_LINE    7
#define MST_TA_BOTTOM_OF_TOP_LINE_UNDERLINE_ALL         8
#define MST_TA_CENTER_OF_TEXT                           9
#define MST_TA_CENTER_OF_TEXT_OVERLINE                  10
#define MST_TD_HORIZONTAL                               0
#define MST_TD_VERTICAL                                 1
#define MST_TL_LEFT                                     0
#define MST_TL_CENTER                                   1
#define MST_TL_RIGHT                                    2
#define MST_TG_PARALLEL_TO_LAST_LEADER_LINE             0
#define MST_TG_HORIZONTAL                               1
#define MST_TG_OPTIMIZED                                2
#define MST_BC_BLOCK_EXTENTS                            0
#define MST_BC_BASE_POINT                               1
#define MST_LD_LEADER_HEAD_FIRST                        0
#define MST_LD_LEADER_TAIL_FIRST                        1
#define MST_MD_CONTENT_FIRST                            0
#define MST_MD_LEADER_FIRST                             1
#define MST_PO_NONE                                     0
#define MST_PO_PATH_TYPE                                0x1
#define MST_PO_LINE_COLOR                               0x2
#define MST_PO_LEADER_LINE_TYPE                         0x4
#define MST_PO_LEADER_LINE_WEIGHT                       0x8
#define MST_PO_ENABLE_LANDING                           0x10
#define MST_PO_LANDING_GAP                              0x20
#define MST_PO_ENABLE_DOGLEG                            0x40
#define MST_PO_LANDING_DISTANCE                         0x80
#define MST_PO_ARROWHEAD                                0x100
#define MST_PO_ARROWHEAD_SIZE                           0x200
#define MST_PO_CONTENT_TYPE                             0x400
#define MST_PO_TEXT_STYLE                               0x800
#define MST_PO_TEXT_LEFT_ATTACHMENT                     0x1000
#define MST_PO_TEXT_ANGLE                               0x2000
#define MST_PO_TEXT_ALIGNMENT                           0x4000
#define MST_PO_TEXT_COLOR                               0x8000
#define MST_PO_TEXT_HEIGHT                              0x10000
#define MST_PO_TEXT_FRAME                               0x20000
#define MST_PO_ENABLE_USE_DEFAULT_MTEXT                 0x40000
#define MST_PO_BLOCK_CONTENT                            0x80000
#define MST_PO_BLOCK_CONTENT_COLOR                      0x100000
#define MST_PO_BLOCK_CONTENT_SCALE                      0x200000
#define MST_PO_BLOCK_CONTENT_ROTATION                   0x400000
#define MST_PO_BLOCK_CONTENT_CONNECTION                 0x800000
#define MST_PO_SCALE_FACTOR                             0x1000000
#define MST_PO_TEXT_RIGHT_ATTACHMENT                    0x2000000
#define MST_PO_TEXT_SWITCH_ALIGNMENT_TYPE               0x4000000
#define MST_PO_TEXT_ATTACHMENT_DIRECTION                0x8000000
#define MST_PO_TEXT_TOP_ATTACHMENT                      0x10000000
#define MST_PO_TEXT_BOTTOM_ATTACHMENT                   0x20000000
#define MST_LL_NONE                                     0
#define MST_LL_PATH_TYPE                                1
#define MST_LL_LINE_COLOR                               2
#define MST_LL_LINE_TYPE                                4
#define MST_LL_LINE_WEIGHT                              8
#define MST_LL_ARROWHEAD_SIZE                           16
#define MST_LL_ARROWHEAD                                32

#define TST_FD_DOWN                           0
#define TST_FD_UP                             1
#define TST_CA_TOP_LEFT                       1
#define TST_CA_TOP_CENTER                     2
#define TST_CA_TOP_RIGHT                      3
#define TST_CA_MIDDLE_LEFT                    4
#define TST_CA_MIDDLE_CENTER                  5
#define TST_CA_MIDDLE_RIGHT                   6
#define TST_CA_BOTTOM_LEFT                    7
#define TST_CA_BOTTOM_CENTER                  8
#define TST_CA_BOTTOM_RIGHT                   9
#define TST_BT_SINGLE                         1
#define TST_BT_DOUBLE                         2
#define TST_CP_NONE                           0x0
#define TST_CP_DATA_TYPE                      0x1
#define TST_CP_DATA_FORMAT                    0x2
#define TST_CP_ROTATION                       0x4
#define TST_CP_BLOCK_SCALE                    0x8
#define TST_CP_ALIGNMENT                      0x10
#define TST_CP_CONTENT_COLOR                  0x20
#define TST_CP_TEXT_STYLE                     0x40
#define TST_CP_TEXT_HEIGHT                    0x80
#define TST_CP_AUTO_SCALE                     0x100
#define TST_CP_BACKGROUND_COLOR               0x200
#define TST_CP_MARGIN_LEFT                    0x400
#define TST_CP_MARGIN_TOP                     0x800
#define TST_CP_MARGIN_RIGHT                   0x1000
#define TST_CP_MARGIN_BOTTOM                  0x2000
#define TST_CP_CONTENT_LAYOUT                 0x4000
#define TST_CP_MERGE_ALL                      0x8000
#define TST_CP_FLOW_DIRECTION_BOTTOM_TO_TOP   0x10000
#define TST_CP_MARGIN_HORIZONTAL_SPACING      0x20000
#define TST_CP_MARGIN_VERTICAL_SPACING        0x40000
#define TST_BP_NONE                           0x0
#define TST_BP_LINE_WEIGHT                    0x1
#define TST_BP_LINE_TYPE                      0x2
#define TST_BP_COLOR                          0x4
#define TST_BP_VISIBILITY                     0x8
#define TST_BP_DOUBLE_LINE_SPACING            0x10
#define TST_SF_NONE                           0
#define TST_SF_TITLE_SUPPRESSED               1
#define TST_SF_HEADER_SUPPRESSED              2

/* associative.rs: AssocEvalValue, AssocCurveValue y enums simples (valores = orden de declaracion en Rust) */
#define AEV_NONE    0
#define AEV_REAL    1
#define AEV_LONG    2
#define AEV_SHORT   3
#define AEV_BYTE    4
#define AEV_TEXT    5
#define AEV_HANDLE  6
#define ACV_BOOL    0
#define ACV_INT     1
#define ACV_REAL    2
#define ACV_POINT   3
#define ASK_PLANE 0
#define ASK_EXTEND 1
#define ASK_EXTRUDED 2
#define ASK_LOFTED 3
#define ASK_NETWORK 4
#define ASK_OFFSET 5
#define ASK_REVOLVED 6
#define ASK_TRIM 7
#define ASK_BLEND 8
#define ASK_PATCH 9
#define ASK_FILLET 10
#define ASK_SWEPT 11
#define ASK_EDGECHAMFER 12
#define ASK_EDGEFILLET 13
#define AAK_RESTOREENTITYSTATE 0
#define AAK_MLEADER 1
#define AAK_ALIGNEDDIMENSION 2
#define AAK_THREEPOINTANGULARDIMENSION 3
#define AAK_ORDINATEDIMENSION 4
#define AAK_ROTATEDDIMENSION 5
#define AVK_VIEWBORDER 0
#define AVK_VIEWREP 1
#define AVK_VIEWSYMBOL 2
#define AVK_VIEWSTYLE 3
#define ASC_NONE 0
#define ASC_ARC 1
#define ASC_ELLIPSE 2
#define ASC_LINE 3
#define ASC_LINESEGMENT3D 4
#define ASC_NURB3D 5
#define ASC_CURVE3D 6

/* document.rs: PreviewFormat */
#define PVF_BMP 0
#define PVF_WMF 1
#define PVF_PNG 2
