# SPDX-License-Identifier: MIT
# Copyright 2024 iris-GmbH infrared & intelligent sensors

# The release package for dbus which is used by openembedded already
# contains artifacts from a pre-run configure step.
# These are not relevant for license compliance.
OSSELOT_IGNORE_SOURCE_GLOBS += " \
    configure \
    aminclude_static.am \
    Makefile.in \
    config.h.in \
    aclocal.m4 \
    m4/ltversion.m4 \
    m4/ltoptions.m4 \
    m4/libtool.m4 \
    m4/lt~obsolete.m4 \
    m4/ltsugar.m4 \
    doc/Makefile.in \
    test/Makefile.in \
    test/name-test/Makefile.in \
    bus/Makefile.in \
    dbus/Makefile.in \
    tools/Makefile.in \
    build-aux/config.guess \
    build-aux/config.sub \
    build-aux/missing \
    build-aux/install-sh \
    build-aux/tap-driver.sh \
    build-aux/ltmain.sh \
    build-aux/depcomp \
    build-aux/compile \
    cmake/DBus1ConfigVersion.cmake \
    cmake/DBus1Config.cmake \
"

## Define equivalence between unpatched and patched source code files
## Unpatched hashes taken from dbus/1.14.8
# configure.ac
OSSELOT_HASH_EQUIVALENCE += "c84fb14d03d4542d04a34725a41ad28e:7e480ba3a0d09e77c20758a538ddae4d"
