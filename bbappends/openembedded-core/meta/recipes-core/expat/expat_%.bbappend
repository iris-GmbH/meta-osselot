# SPDX-License-Identifier: MIT
# Copyright 2023 iris-GmbH infrared & intelligent sensors

OSSELOT_NAME ?= "libexpat"
OSSELOT_VERSION ?= "R_${@d.getVar('PV').replace('.', '_')}"

# The GitHub release package for libexpat which is used by openembedded already
# contains artifacts from a pre-run configure step.
# These are not relevant for license compliance.
OSSELOT_IGNORE_SOURCE_GLOBS += " \
    expat_config.h.in \
    configure \
    Makefile.in \
    aclocal.m4 \
    expat_config.h \
    m4/ltversion.m4 \
    m4/ltoptions.m4 \
    m4/libtool.m4 \
    m4/lt~obsolete.m4 \
    m4/ltsugar.m4 \
    doc/Makefile.in \
    doc/xmlwf.1 \
    examples/Makefile.in \
    tests/Makefile.in \
    tests/benchmark/Makefile.in \
    conftools/config.guess \
    conftools/config.sub \
    conftools/missing \
    conftools/install-sh \
    conftools/ar-lib \
    conftools/ltmain.sh \
    conftools/depcomp \
    conftools/compile \
    conftools/test-driver \
    xmlwf/Makefile.in \
    lib/Makefile.in \
"
