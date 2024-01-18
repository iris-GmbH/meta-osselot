# SPDX-License-Identifier: MIT
# Copyright 2023 iris-GmbH infrared & intelligent sensors

OSSELOT_NAME ??= "${BPN}"
OSSELOT_VERSION ??= "${PV}"
# The hash algorithm used to verify file equality between source code and curated data
OSSELOT_HASH_ALGORITHM ?= "md5"
# The osselot deploydir, where results from all recipes are commulated
OSSELOT_DEPLOYDIR ?= "${DEPLOY_DIR}/osselot"
# The bitbake src_uri configuration for fetching osselot data (see osselot-package-analysis-native recipe)
OSSELOT_SRC_URI ?= "git://github.com/Open-Source-Compliance/package-analysis.git;protocol=https;branch=main"
# The source revision to use from the osselot data repository (defaults to latest)
OSSELOT_SRCREV ?= "${AUTOREV}"
OSSELOT_PV ?= "1.0+git${SRCPV}"
OSSELOT_IGNORE ?= "0"
OSSELOT_IGNORE_LICENSES = "CLOSED"
OSSELOT_IGNORE_SOURCE_GLOBS = ".pc/**/* patches/series .git/**/*"
OSSELOT_DATA_WORKDIR = "${TMPDIR}/osselot-data"
OSSELOT_DATA_S_DIR = "${OSSELOT_DATA_WORKDIR}/git"
OSSELOT_S_CHECKSUMS_DIR = "${WORKDIR}/osselot-checksums/s"
OSSELOT_SPDX_CHECKSUMS_DIR = "${WORKDIR}/osselot-checksums/spdx"
OSSELOT_WORKDIR = "${WORKDIR}/osselot"
OSSELOT_PACKAGE_META_FILE = "${OSSELOT_WORKDIR}/${PN}-${PV}-meta.json"
OSSELOT_PACKAGE_JSON = "${OSSELOT_DATA_WORKDIR}/packages.json"

python do_osselot_populate_workdir() {
    import os
    import shutil
    import gzip
    from pathlib import Path
    from difflib import get_close_matches

    osselot_name = d.getVar("OSSELOT_NAME")
    osselot_version = d.getVar("OSSELOT_VERSION")
    osselot_workdir = d.getVar("OSSELOT_WORKDIR")
    osselot_package_meta_file = d.getVar("OSSELOT_PACKAGE_META_FILE")
    osselot_package_json = d.getVar("OSSELOT_PACKAGE_JSON")

    ignored, reason = osselot_ignore_package(d)
    if ignored:
        bb.debug(2, f"Ignoring {osselot_name}: {reason}")
        write_json(osselot_package_meta_file, 
            {
                "package_status": "ignored",
                "reason": reason
            }
        )
        return

    available_osselot_packages = read_json(osselot_package_json)

    bb.debug(2, f"Attempting to find osselot package data in available osselot packages")
    if not osselot_name in available_osselot_packages:
        warn = f"Package {osselot_name} not found in osselot database. Skipping."
        similar_package_names = get_close_matches(osselot_name, available_osselot_packages)
        if similar_package_names:
            similar_package_names_string = " ".join(similar_package_names)
            warn = f"{warn} Close matches: {similar_package_names_string}"
        bb.warn(warn)
        write_json(osselot_package_meta_file, 
            {
                "package_status": "not_found",
                "reason": warn
            }
        )
        return

    best_version_match = find_best_version_match(osselot_version, available_osselot_packages[osselot_name]["versions"])
    if best_version_match == osselot_version:
        reason = f"{osselot_name}/{osselot_version} available in osselot database"
        bb.debug(2, reason)
        write_json(osselot_package_meta_file, 
            {
                "package_status": "found",
                "reason": reason
            }
        )
    else:
        warn = f"{osselot_name}/{osselot_version} not available in osselot database. Using version {osselot_name}/{best_version_match}"
        bb.warn(warn)
        write_json(osselot_package_meta_file, 
            {
                "package_status": "version_mismatch",
                "reason": warn
            }
        )

    versioned_package_data_srcdir = available_osselot_packages[osselot_name]["versions"][best_version_match]
    versioned_package_data_destdir = os.path.join(osselot_workdir, Path(versioned_package_data_srcdir).name)
    bb.debug(2, f"Copying versioned package data from {versioned_package_data_srcdir} to osselot workdir at {versioned_package_data_destdir}")
    shutil.copytree(versioned_package_data_srcdir, versioned_package_data_destdir)

    # find and extract archived osselot files
    # TODO: use a universal extractor tool such as https://www.nongnu.org/atool/ or https://tracker.debian.org/pkg/unp
    for gz in Path(versioned_package_data_destdir).rglob("*.gz"):
        bb.debug(2, f"Extracting archive {gz.as_posix()}")
        with gzip.open(gz) as f_in:
            with open(os.path.join(gz.parent, gz.stem), 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
        os.remove(gz)
    for tgz in Path(versioned_package_data_destdir).rglob("*.tgz"):
        shutil.unpack_archive(tgz, tgz.parent)
        os.remove(tgz)
}
do_osselot_populate_workdir[cleandirs] = "${OSSELOT_WORKDIR}"


# Create checksums for all files within a packages "S" dir for validation
# against the spdx file provided by osselot.
python do_osselot_create_s_checksums() {
    import hashlib
    import os

    s = d.getVar("S")
    pn = d.getVar("PN")
    pv = d.getVar("PV")
    osselot_s_checksums_dir = d.getVar("OSSELOT_S_CHECKSUMS_DIR")
    osselot_hash_algorithm = d.getVar("OSSELOT_HASH_ALGORITHM")

    ignored, reason = osselot_ignore_package(d)
    if ignored is True:
        bb.debug(2, f"Ignoring {pn}: {reason}")
        return

    for item in scantree(s):
        if item.is_file(follow_symlinks=False):
            bb.debug(2, f"Creating {osselot_hash_algorithm} checksum for file {item.path}")
            with open(item.path, "rb") as fb:
                digest = hashlib.file_digest(fb, osselot_hash_algorithm).hexdigest()
                hash_file_path = os.path.join(osselot_s_checksums_dir, f"{os.path.relpath(item.path, s)}.{osselot_hash_algorithm}")
                write_checksum_file(hash_file_path, digest)
}
do_osselot_create_s_checksums[cleandirs] = "${OSSELOT_S_CHECKSUMS_DIR}"


# Extract file checksum information from SPDX files
python do_osselot_create_spdx_checksums() {
    import os
    from pathlib import Path, PurePath

    s = d.getVar("S")
    pn = d.getVar("PN")
    bpn = d.getVar("BPN")
    pv = d.getVar("PV")
    osselot_name = d.getVar("OSSELOT_NAME")
    osselot_workdir = d.getVar("OSSELOT_WORKDIR")
    osselot_spdx_checksums_dir = d.getVar("OSSELOT_SPDX_CHECKSUMS_DIR")
    osselot_hash_algorithm = d.getVar("OSSELOT_HASH_ALGORITHM")

    ignored, reason = osselot_ignore_package(d)
    if ignored is True:
        bb.debug(2, f"Ignoring {pn}: {reason}")
        return

    bb.debug(2, f"Looking for SPDX JSON files in {osselot_workdir}")
    spdx_files = Path(osselot_workdir).glob(f"*/*.json")
    for spdx_file in spdx_files:
        bb.debug(2, f"Processing SPDX JSON file found at {spdx_file}") 
        # TODO: Take multiple SPDX standards into account
        files = read_json(spdx_file)["files"]
        # sort files based on path length (long > short), eliminate edge cases where false mismatches could occur
        files.sort(key=lambda s: len(s["fileName"]), reverse=True)
        for file in files:
            filename = match_spdx_file_to_source_file(file["fileName"], s)
            if not filename:
                continue
            # extract correct checksum
            checksum = next((c["checksumValue"] for c in file["checksums"] if c["algorithm"].lower() == osselot_hash_algorithm.lower()), None)

            if not checksum:
                bb.fatal(f"Could not find {osselot_hash_algorithm} checksum data for {file}")

            checksum_file = os.path.join(osselot_spdx_checksums_dir, f"{filename}.{osselot_hash_algorithm}")
            write_checksum_file(checksum_file, checksum)
}
do_osselot_create_spdx_checksums[cleandirs] = "${OSSELOT_SPDX_CHECKSUMS_DIR}"


python do_osselot_compare_checksums() {
    import os
    from pathlib import Path, PurePath

    s = d.getVar("S")
    pn = d.getVar("PN")
    osselot_name = d.getVar("OSSELOT_NAME")
    osselot_workdir = d.getVar("OSSELOT_WORKDIR")
    osselot_s_checksums_dir = d.getVar("OSSELOT_S_CHECKSUMS_DIR")
    osselot_spdx_checksums_dir = d.getVar("OSSELOT_SPDX_CHECKSUMS_DIR")
    osselot_hash_algorithm = d.getVar("OSSELOT_HASH_ALGORITHM")
    osselot_ignore_source_globs = d.getVar("OSSELOT_IGNORE_SOURCE_GLOBS").split() or []
    osselot_package_meta_file = d.getVar("OSSELOT_PACKAGE_META_FILE")

    meta = read_json(osselot_package_meta_file)

    package_status = meta["package_status"]
    if package_status in ["ignored", "not_found"]:
        bb.debug(2, f"Package status is {package_status}. Skipping...")
        return

    osselot_file_ignore_list = [ 
        os.path.relpath(file, s)
        for source_glob in osselot_ignore_source_globs
        for file in Path(s).glob(source_glob) 
    ]

    s_checksum_files = Path(osselot_s_checksums_dir).rglob(f"*.{osselot_hash_algorithm}")
    meta["spdx_checksum_data_missing"] = []
    meta["spdx_checksum_data_mismatch"] = []
    meta["spdx_checksum_data_match"] = []
    meta["ignored_files"] = []
    for s_checksum_file in s_checksum_files:
        bb.debug(2, f"Processing checksum file {s_checksum_file}")

        source_file = os.path.relpath(s_checksum_file, osselot_s_checksums_dir).removesuffix(f".{osselot_hash_algorithm}")
        bb.debug(2, f"Source file is {source_file}")

        spdx_checksum_file = os.path.join(osselot_spdx_checksums_dir, os.path.relpath(s_checksum_file, osselot_s_checksums_dir))
        bb.debug(2, f"SPDX checksum file is {spdx_checksum_file}")

        if source_file in osselot_file_ignore_list:
            bb.debug(2, f"Excluding ignored file {source_file}")
            meta["ignored_files"].append(source_file)
            continue

        if not os.path.isfile(spdx_checksum_file):
            bb.debug(2, f"Missing SPDX checksum data for file {source_file}")
            meta["spdx_checksum_data_missing"].append(source_file)
            continue

        bb.debug(2, "Comparing {s_checksum_file} against {spdx_checksum_file}")
        with open (s_checksum_file, "r") as f:
            s_checksum = f.readline() 
        with open (spdx_checksum_file, "r") as f:
            spdx_checksum = f.readline() 
        if s_checksum != spdx_checksum:
            bb.debug(2, f"Checksum mismatch: {source_file}")
            meta["spdx_checksum_data_mismatch"].append(source_file)
        else:
            bb.debug(2, f"Checksum match: {source_file}")
            meta["spdx_checksum_data_match"].append(source_file)
    write_json(osselot_package_meta_file, meta)
}

SSTATETASKS += "do_deploy_osselot"
do_deploy_osselot() {
    bbnote "Deploying osselot files from ${OSSELOT_WORKDIR} to ${OSSELOT_DEPLOYDIR}"
}
python do_deploy_osselot_setscene() {
    sstate_setscene(d)
}

addtask osselot_populate_workdir after do_patch
do_osselot_populate_workdir[depends] = " \
    osselot-package-analysis-native:do_osselot_collect_packages \
"
addtask osselot_create_spdx_checksums after do_osselot_populate_workdir
addtask osselot_create_s_checksums after do_patch
addtask osselot_compare_checksums after do_patch
do_osselot_compare_checksums[depends] += " \
    ${PN}:do_osselot_create_s_checksums \
    ${PN}:do_osselot_create_spdx_checksums \
"
do_deploy_osselot[depends] = "${PN}:do_osselot_compare_checksums"
do_deploy_osselot[dirs] = "${OSSELOT_WORKDIR}"
do_deploy_osselot[cleandirs] = "${OSSELOT_DEPLOYDIR}/${PN}"
do_deploy_osselot[sstate-inputdirs] = "${OSSELOT_WORKDIR}"
do_deploy_osselot[sstate-outputdirs] = "${OSSELOT_DEPLOYDIR}/${PN}"
addtask do_deploy_osselot_setscene
addtask do_deploy_osselot
do_build[recrdeptask] += "do_deploy_osselot"
do_rootfs[recrdeptask] += "do_deploy_osselot"


def read_json(path):
    import json
    from pathlib import Path
    return json.loads(Path(path).read_text())


def write_json(path, content):
    import json
    from pathlib import Path
    Path(path).write_text(json.dumps(content, indent=2))


def scantree(path):
    from os import scandir
    for entry in scandir(path):
        if entry.is_dir(follow_symlinks=False):
            yield from scantree(entry.path)
        else:
            yield entry


def osselot_ignore_package(d):
    pn = d.getVar("PN")
    bpn = d.getVar("BPN")
    s = d.getVar("S")
    osselot_ignore = d.getVar("OSSELOT_IGNORE")
    osselot_ignore_licenses = d.getVar("OSSELOT_IGNORE_LICENSES")
    p_license = d.getVar("LICENSE")

    # ignore non-target packages
    for suffix in d.getVar("SPECIAL_PKGSUFFIX").split():
        if suffix in pn.removeprefix(bpn):
            return True, f"{pn} contained non-target suffix: {suffix}"

    # ignore packages without source files ("S" folder missing)
    if not os.path.isdir(s):
        return True, f"{pn} does not have a source folder"

    # ignore packages which have "OSSELOT_IGNORE" set to true
    if osselot_ignore == "1":
        return True, f"{pn} has OSSELOT_IGNORE set to {osselot_ignore}"

    # ignore packages that have a ignored license string
    if p_license in osselot_ignore_licenses:
        return True, f'{pn} license "{p_license}" is set to ignore'

    return False, None


def write_checksum_file(checksum_file, checksum):
    bb.utils.mkdirhier(os.path.dirname(checksum_file))
    try:
        hf = open(checksum_file, "w")
    except:
        bb.debug(2, f"Could not open checksum file {checksum_file} for write")
    else:
        with hf:
            hf.write(checksum)
            bb.debug(2, f"Checksum written to {checksum_file}.")


def find_best_version_match(osselot_version, available_osselot_versions):
    import os
    import subprocess

    # attempt to find a exact match
    if osselot_version in available_osselot_versions:
        return osselot_version

    # otherwise, identify the closest version match
    bb.debug(2, f"Version {osselot_version} not available in osselot database. Finding the next best version match")
    osselot_data_version_strings = list(available_osselot_versions)
    osselot_data_version_strings.append(osselot_version)
    process = subprocess.Popen("sort -V".split(" "), stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, stdin=subprocess.PIPE, shell=True)
    so, se = process.communicate("\n".join(osselot_data_version_strings).encode())
    osselot_data_version_strings_sorted = so.decode().strip("\n").split("\n")

    if len(osselot_data_version_strings_sorted) != len(osselot_data_version_strings):
        bb.fatal(f"Sorted osselot version list content does not match original list")
    
    osselot_version_index = osselot_data_version_strings_sorted.index(osselot_version)
    if osselot_version_index == 0:
        best_version_match = osselot_data_version_strings_sorted[osselot_version_index+1]
    else:
        best_version_match = osselot_data_version_strings_sorted[osselot_version_index-1]
    return best_version_match


def match_spdx_file_to_source_file(spdx_checksum_file_path, s):
    from pathlib import Path

    spdx_checksum_file_orig = spdx_checksum_file_path
    spdx_checksum_file_path = Path(spdx_checksum_file_path)
    s = Path(s)

    bb.debug(2, f"Attempting to match {spdx_checksum_file_orig} to a source code file")
    while s.joinpath(spdx_checksum_file_path).is_file() is False:
        spdx_checksum_file_path = spdx_checksum_file_path.relative_to(spdx_checksum_file_path.parts[0])
        if s.joinpath(spdx_checksum_file_path) == s:
            bb.debug(2, f"No matching source code file for SPDX checksum file {spdx_checksum_file_orig}. Skipping...")
            return None

    bb.debug(2, f"Found valid SPDX checksum path {spdx_checksum_file_path}")
    return spdx_checksum_file_path
