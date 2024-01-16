# SPDX-License-Identifier: MIT
# Copyright 2023 iris-GmbH infrared & intelligent sensors

SUMMARY = "Fetches the osselot package analysis data"
DESCRIPTION = "Osselot is a project which aims to ease the pain around package license clearance. For more detail, visit their website at https://www.osselot.org/"

INHIBIT_DEFAULT_DEPS = "1"

inherit native

deltask do_configure
deltask do_compile
deltask do_install
deltask do_populate_sysroot

SRC_URI = "${OSSELOT_SRC_URI}"
SRCREV = "${OSSELOT_SRCREV}"
PV = "${OSSELOT_PV}"

LICENSE = "CC0-1.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=0fba65e23f03aef2e3401a972aeef9dd"

WORKDIR = "${OSSELOT_DATA_WORKDIR}"
# Download existing package analysis data into the data topdir
S = "${OSSELOT_DATA_S_DIR}"

python () {
    if not bb.data.inherits_class("osselot", d):
        raise bb.parse.SkipRecipe("Skip recipe when osselot class is not loaded.")
}
