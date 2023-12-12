# SPDX-License-Identifier: MIT
# Copyright 2023 iris-GmbH infrared & intelligent sensors

OSSELOT_DEPLOY_DIR ??= "${DEPLOY_DIR}/osselot"
OSSELOT_SRC_URI ??= "git://github.com/Open-Source-Compliance/package-analysis.git;protocol=https;branch=main"
OSSELOT_SRCREV ??= "${AUTOREV}"
OSSELOT_PV ??= "1.0+git${SRCPV}"
OSSELOT_DATA_DIR_S ??= "${OSSELOT_DATA_DIR}/git"

OSSELOT_DATA_DIR = "${TMPDIR}/osselot-data"
OSSELOT_META_FILE = "${OSSELOT_DEPLOY_DIR}/meta.json"
OSSELOT_META_FILE_LOCK = "${OSSELOT_DEPLOY_DIR}/meta.json.lock"


python do_osselot_init() {
    from datetime import datetime
    import json

    osselot_deploy_dir = d.getVar("OSSELOT_DEPLOY_DIR")
    osselot_meta_file = d.getVar("OSSELOT_META_FILE")

    bb.utils.mkdirhier(osselot_deploy_dir)
    write_json(osselot_meta_file, {
        "timestamp": datetime.now().astimezone().isoformat(),
        "packages": {}
    })
}
addhandler do_osselot_init
do_osselot_init[eventmask] = "bb.event.BuildStarted"

python do_osselot_collect() {
    import json
    import shutil

    osselot_deploy_dir = d.getVar("OSSELOT_DEPLOY_DIR")
    osselot_data_dir_s = d.getVar("OSSELOT_DATA_DIR_S")
    osselot_meta_file = d.getVar("OSSELOT_META_FILE")
    osselot_ignore = d.getVar("OSSELOT_IGNORE")
    pn = d.getVar("PN")
    bpn = d.getVar("BPN")
    pv = d.getVar("PV")

    osselot_name = d.getVar("OSSELOT_NAME") or bpn
    osselot_version = d.getVar("OSSELOT_VERSION") or pv

    meta = read_json(osselot_meta_file)

    # ignore non-target packages
    for suffix in d.getVar("SPECIAL_PKGSUFFIX").split():
        if suffix in pn.removeprefix(bpn):
            reason = f"Package name contains non-target suffix: {suffix}"
            bb.debug(2, f"Ignoring {pn}: {reason}")
            meta["packages"].update({
                f"{pn}/{pv}": {
                    "status": "ignored",
                    "reason": reason
                }
            })
            write_json(osselot_meta_file, meta)
            return

    # ignore package if OSSELOT_IGNORE is set to true within recipe
    bb.debug(2, f"{pn} has OSSELOT_IGNORE set to {osselot_ignore}.")
    if bool(osselot_ignore) is True:
        reason = f"OSSELOT_IGNORE set to {osselot_ignore}"
        bb.debug(2, f"Ignoring {pn}: {reason}")
        meta["packages"].update({
            f"{pn}/{pv}": {
                "status": "ignored",
                "reason": reason
            }
        })
        write_json(osselot_meta_file, meta)
        return

    # try to find exact version of package
    osselot_package_data_path = os.path.abspath(f"{osselot_data_dir_s}/analysed-packages/{osselot_name}")
    osselot_versioned_package_data_path = os.path.abspath(f"{osselot_package_data_path}/version-{osselot_version}")
    osselot_package_deploy_dir = os.path.abspath(f"{osselot_deploy_dir}/{pn}")
    osselot_versioned_package_deploy_dir = os.path.abspath(f"{osselot_package_deploy_dir}/{osselot_version}")

    bb.debug(2, f"Attempting to find exact version match on {osselot_name}/{osselot_version} at {osselot_versioned_package_data_path}.")
    if os.path.isdir(osselot_versioned_package_data_path):
        bb.debug(2, f"Found exact version match on {osselot_name}/{osselot_version} at {osselot_versioned_package_data_path}.")
        shutil.copytree(osselot_versioned_package_data_path, os.path.abspath(osselot_versioned_package_deploy_dir))
        meta["packages"].update({
            f"{pn}/{pv}": {
                "status": "found",
                "path": osselot_versioned_package_deploy_dir
            }
        })
    else:
        bb.warn(f"No exact version match on {osselot_name}/{osselot_version} found. Attempting to find other versions.")
        if os.path.isdir(osselot_package_data_path):
            mismatch_dir = os.path.abspath(f"{osselot_package_deploy_dir}/version_mismatch")
            shutil.copytree(osselot_package_data_path, mismatch_dir)
            meta["packages"].update({
                f"{pn}/{pv}": {
                    "status": "version_mismatch",
                    "path": mismatch_dir
                }
            })
        else:
            bb.warn(f"No curated data available for {osselot_name}.")
            meta["packages"].update({
                f"{pn}/{pv}": {
                    "status": "not_found",
                }
            })
    write_json(osselot_meta_file, meta)
}
addtask osselot_collect
do_osselot_collect[nostamp] = "1"
do_osselot_collect[dirs] = "${OSSELOT_DEPLOY_DIR}"
do_osselot_collect[cleandirs] = "${OSSELOT_DEPLOY_DIR}/${PN}"
do_osselot_collect[lockfiles] = "${OSSELOT_META_FILE_LOCK}"
do_osselot_collect[depends] = "osselot-package-analysis-native:do_patch"
do_rootfs[recrdeptask] += "do_osselot_collect"

def read_json(path):
    import json
    from pathlib import Path
    return json.loads(Path(path).read_text())

def write_json(path, content):
    import json
    from pathlib import Path
    Path(path).write_text(json.dumps(content, indent=2))
