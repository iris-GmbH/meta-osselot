# SPDX-License-Identifier: MIT
# Copyright 2024 iris-GmbH infrared & intelligent sensors

# testsuite not relevant for target executable, thus not relevant for license compliance
OSSELOT_IGNORE_SOURCE_GLOBS += "testsuite/**/*"

## Define equivalence between unpatched and patched source code files
## Unpatched hashes taken from busybox/1.35.0
# Makefile
OSSELOT_HASH_EQUIVALENCE += "271da9018932e46cb4e0757f14d8119a:9db794f038630d80148d6b85225bebe7"
# procps/sysctl.c
OSSELOT_HASH_EQUIVALENCE += "9b40d18fc7b0f1c43d22fd5a00e139de:add19f2024a8fb92a55642103b8837ef"
# miscutils/devmem.c
OSSELOT_HASH_EQUIVALENCE += "32de9331f6216f8ef553dc9958de5534:09c11422596b0d5841b47b54a58ed3f3"
# networking/ifupdown.c
OSSELOT_HASH_EQUIVALENCE += "91e3bd3adf62db2bca0e0de9732474c4:6789ebbb84969af205e58df265be9751"
# networking/nslookup.c
OSSELOT_HASH_EQUIVALENCE += "bac44c4d2d4bba6d2980f83488aab7e9:4e3cff18984f4caad2522b93f4df40e2"
# networking/udhcp/dhcpc.c
OSSELOT_HASH_EQUIVALENCE += "db729afc8caf44498e278758c3e0e8d0:522c948b56c22d9504060443ece95f4d"
# libbb/xconnect.c
OSSELOT_HASH_EQUIVALENCE += "18f6850c74d678dc585376e43a350e84:78212a1f4e9b95a967a0ddc7df3fe1d3"
# modutils/depmod.c
OSSELOT_HASH_EQUIVALENCE += "b2e582961a5d298d9d08bafb7c345c5a:4dbce9a32b6a947cef8900401d6c3f50"
# editors/awk.c
OSSELOT_HASH_EQUIVALENCE += "44967a0f86ad3c8b0cb5d83f3336a954:93e110ed88e47fea29a1e0083833afe6"
# scripts/kconfig/lxdialog/check-lxdialog.sh
OSSELOT_HASH_EQUIVALENCE += "eb7560fd629942f2e6a00058b76e8be7:f001356977e390611882e94bab23a4ae"
# scripts/kconfig/lxdialog/Makefile
OSSELOT_HASH_EQUIVALENCE += "9d43837d261f5d9dc9aae75b659859a3:6ebb26728c31814ceaeef25643c7b982"
# util-linux/mount.c
OSSELOT_HASH_EQUIVALENCE += "21a733d29709533f1304c00810857f8e:a54c96039bdd559013cef2761502174b"
# shell/math.c
OSSELOT_HASH_EQUIVALENCE += "76124a8b464a73e219ab5451ac107c47:042769494316975ab6b2be72ea703cc5"
