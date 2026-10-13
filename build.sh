#!/bin/sh
# Verificacion headless en Linux (Harbour 3.2 + gcc). En Windows: ver csrc con cl.
# HBROOT = Harbour compilado (por defecto /tmp/hbsrc). Ejecutar desde la raiz del repo.
H=${HBROOT:-/tmp/hbsrc}; export HB_INSTALL_PREFIX=$H
T=$(ls tests/*.prg | grep -v -e smoke -e tscan)
$H/bin/linux/gcc/hbmk2 -gtstd -quiet -w3 -es2 -ku -iinclude -ot_ocx $T src/tessellation.prg src/space/*.prg src/geom2d/*.prg src/codec/*.prg src/view/*.prg csrc/ocx_math.c "$@" && ./t_ocx
