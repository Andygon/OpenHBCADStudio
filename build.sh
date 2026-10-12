#!/bin/sh
# Verificacion headless en Linux (Harbour 3.2 + gcc). En Windows: ver csrc con cl.
H=${HBROOT:-/tmp/hbsrc}; export HB_INSTALL_PREFIX=$H
$H/bin/linux/gcc/hbmk2 -gtstd -quiet -w3 -es2 -ku -iinclude -ot_ocx tests/*.prg src/*.prg src/geom2d/*.prg csrc/ocx_math.c "$@" && ./t_ocx
