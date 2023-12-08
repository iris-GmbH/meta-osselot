# SPDX-License-Identifier: MIT
# Copyright 2023 iris-GmbH infrared & intelligent sensors

# see https://wiki.osselot.org/index.php/REST for available formats
OSSELOT_FORMATS ??= "json"
OSSELOT_DIR ??= "${DEPLOY_DIR}/osselot"
OSSELOT_REST_URI ??= "https://rest.osselot.org"

OSSELOT_META_FILE = "${OSSELOT_DIR}/meta.json"
OSSELOT_META_FILE_LOCK = "${OSSELOT_DIR}/meta.json.lock"

python do_osselot_init() {
    from datetime import datetime
    import json

    osselot_dir = d.getVar("OSSELOT_DIR")
    osselot_meta_file = d.getVar("OSSELOT_META_FILE")

    bb.utils.mkdirhier(osselot_dir)
    write_json(osselot_meta_file, {
        "timestamp": datetime.now().astimezone().isoformat(),
        "packages": {}
    })
}
addhandler do_osselot_init
do_osselot_init[eventmask] = "bb.event.BuildStarted"

python do_osselot_collect() {
    import urllib
    import json
    import re

    osselot_dir = d.getVar("OSSELOT_DIR")
    osselot_formats = d.getVar("OSSELOT_FORMATS").split()
    osselot_rest_uri = d.getVar("OSSELOT_REST_URI")
    osselot_meta_file = d.getVar("OSSELOT_META_FILE")
    osselot_ignore = d.getVar("OSSELOT_IGNORE")
    pn = d.getVar("PN")
    bpn = d.getVar("BPN")
    pv = d.getVar("PV")

    osselot_package = d.getVar("OSSELOT_NAME") or bpn
    version = d.getVar("OSSELOT_VERSION") or pv

    meta = read_json(osselot_meta_file)

    # ignore non-target packages
    for suffix in d.getVar("SPECIAL_PKGSUFFIX").split():
        if suffix in pn.removeprefix(bpn):
            reason = f"Package name contains non-target suffix: {suffix}"
            bb.debug(2, f"Ignoring {pn}: {reason}")
            meta["packages"].update({
                f"{pn}/{version}": {
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
            f"{pn}/{version}": {
                "status": "ignored",
                "reason": reason
            }
        })
        write_json(osselot_meta_file, meta)
        return

    # if version not clearly identifiable (i.e. using a commit hash, autoinc, etc.) skip package
    if "+" in version:
        reason = f"{pn} contains not clearly identifiable version {version}"
        bb.warn(reason)
        meta["packages"].update({
            f"{pn}/{version}": {
                "status": "not_found",
                "reason": reason
            }
        })
        write_json(osselot_meta_file, meta)
        return

    bb.debug(2, f"Searching osselot API for package {osselot_package} in version {version}")
    try:
        for osselot_format in osselot_formats:
            uri = f"{osselot_rest_uri}/{osselot_format}/{osselot_package}/{version}"
            output = f"{osselot_dir}/{pn}/{pn}-{version}.{osselot_format}"
            urllib.request.urlretrieve(uri, output)
            if f"{pn}/{version}" not in meta["packages"]:
                meta["packages"].update({
                    f"{pn}/{version}": {
                        "status": "found"
                    }
                })
            meta["packages"][f"{pn}/{version}"][osselot_format] = output
            write_json(osselot_meta_file, meta)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            reason = f"Package {osselot_package} in version {version} not found in the osselot database"
            bb.warn(reason)
            meta["packages"].update({
                f"{pn}/{version}": {
                    "status": "not_found",
                    "reason": reason
                }
            })
            write_json(osselot_meta_file, meta)
        else:
            bb.error(f"Failed request to {uri}. [HTTP Error] {e.code}; Reason: {e.reason}")
}
addtask osselot_collect
do_osselot_collect[nostamp] = "1"
do_osselot_collect[network] = "1"
do_osselot_collect[dirs] = "${OSSELOT_DIR}"
do_osselot_collect[cleandirs] = "${OSSELOT_DIR}/${PN}"
do_osselot_collect[lockfiles] = "${OSSELOT_META_FILE_LOCK}"
do_rootfs[recrdeptask] += "do_osselot_collect"

def read_json(path):
    import json
    from pathlib import Path
    return json.loads(Path(path).read_text())

def write_json(path, content):
    import json
    from pathlib import Path
    Path(path).write_text(json.dumps(content, indent=2))
