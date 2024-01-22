# SPDX-License-Identifier: MIT
# Copyright 2024 iris-GmbH infrared & intelligent sensors

OSSELOT_IGNORE_SOURCE_GLOBS += " \
    doc/history.pdf \
    doc/rluserman.pdf \
    doc/readline.pdf \
    examples/rlwrap-0.30.tar.gz \
"

## Define equivalence between unpatched and patched source code files
## Unpatched hashes taken from readline/8.1.2
# configure-ac
OSSELOT_HASH_EQUIVALENCE += "609493f43c6c3fd886c9b8269def6509:9c3be076962f255d90cbd59c2c060afa"
# support/shobj-conf
OSSELOT_HASH_EQUIVALENCE += "f7cf10a80e9072bb530de2c6abb53fa7:8477f85bac64a1a29dd632b547349396"
