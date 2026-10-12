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
#endif
