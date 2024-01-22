# SPDX-License-Identifier: MIT
# Copyright 2024 iris-GmbH infrared & intelligent sensors

# doc, test and example folders are not relevant for license compliance,
# as they are not part of the target executable
OSSELOT_IGNORE_SOURCE_GLOBS += " \
    doc/**/*.pdf \
    examples/**/* \
    tests/**/* \
"

## Define equivalence between unpatched and patched source code files
## Unpatched hashes taken from bash/5.1.16
# general.c
OSSELOT_HASH_EQUIVALENCE += "690e70576a93b0b78bfd0b3fa2fbc12b:cf9cbadbd09a91ea36e7eba54c4872e1"
# subst.c
OSSELOT_HASH_EQUIVALENCE += "70d59aae8bb9889e062deaeedf662c78:f479373d0a3a4ac36104dddc8b84abaf"
# Makefile.in
OSSELOT_HASH_EQUIVALENCE += "a035fd019eb781fc0f29c2502ece94a0:6b3d2e9156267716e8d101179d0be8e4"
# configure.ac
OSSELOT_HASH_EQUIVALENCE += "35628d2c5cecd8e590fe93bfb8472008:ecbab4e6670915cbb666817ad38a7ece"
# jobs.c
OSSELOT_HASH_EQUIVALENCE += "1a8264d1f446f5fccc55843010be1e9c:95e82393f396b4b7961d2e7ce492eba0"
# execute_cmd.c
OSSELOT_HASH_EQUIVALENCE += "ae8ecb011dadc0d7ddb31a17ca197d83:f0a43271afe65cdc1610841e6b1c2640"
# builtins/mkbuiltins.c
OSSELOT_HASH_EQUIVALENCE += "307f20bfea6fcf5c96372e0cf75f3f59:ca4936e308b98181dbbe09994d217b62"
# builtins/Makefile.in
OSSELOT_HASH_EQUIVALENCE += "08a9149ac671429c456c319bcc7e6e83:d7c994f5a1f967a34ec0453a30b34ced"
