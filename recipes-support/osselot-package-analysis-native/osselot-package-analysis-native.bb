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
OSSELOT_DATA_TOPDIR ?= "${S}/analysed-packages"
OSSELOT_DATA_VERSION_PREFIX ?= "version-"

python () {
    if not bb.data.inherits_class("osselot", d):
        raise bb.parse.SkipRecipe("Skip recipe when osselot class is not loaded.")
}

python do_osselot_collect_packages () {
    # backport str.removeprefix (needs Python 3.9) to Python 3.8
    # this function is licensed under:
    # SPDX-License-Identifier: CC0-1.0
    # see: https://peps.python.org/pep-0616/#copyright
    def py38_remove_prefix(fullstring, prefix):
        if fullstring.startswith(prefix):
            return fullstring[len(prefix):]
        else:
            return fullstring[:]

    from pathlib import Path

    osselot_data_topdir = d.getVar("OSSELOT_DATA_TOPDIR")
    osselot_data_version_prefix = d.getVar("OSSELOT_DATA_VERSION_PREFIX")
    osselot_package_json = d.getVar("OSSELOT_PACKAGE_JSON")

    osselot_packages = {
        version_dir.parent.name: {
            "package_path": version_dir.parent.as_posix(), "versions": {
                py38_remove_prefix(package_version_dir.name, osselot_data_version_prefix): package_version_dir.as_posix()
                for package_version_dir in Path(version_dir.parent).glob(f"{osselot_data_version_prefix}*")
                if package_version_dir.is_dir()
            }
        }
        for version_dir in Path(osselot_data_topdir).rglob(f"{osselot_data_version_prefix}*")
        if version_dir.is_dir()
    }
    write_json(osselot_package_json, osselot_packages)
}
addtask osselot_collect_packages after do_patch

def write_json(path, content):
    import json
    from pathlib import Path
    Path(path).write_text(json.dumps(content, indent=2))
