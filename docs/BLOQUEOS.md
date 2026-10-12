# Modulos bloqueados por dependencias externas (Rust)

| Modulo Rust | Lineas | Dependencia | Estado | Motivo |
|---|---|---|---|---|
| geom2d/offset.rs | 424 | cavalier_contours =0.7.0 (usa internos pline_offset) | PENDIENTE DE DECISION | No hay equivalente en Harbour. Opciones: portar la parte usada de cavalier_contours, o sustituto propio con tests de propiedades (sin paridad 1:1). |
| geom2d/constrained.rs (y B-rep) | 171 | spade =2.15.1 (Delaunay con restricciones) | PENDIENTE DE DECISION | Igual: portar spade o escribir un CDT propio. |

Los demas modulos de geom2d se portan primero. Decision a tomar con el usuario.
