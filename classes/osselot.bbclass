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
    bpn = d.getVar("BPN")

    osselot_package = d.getVar("OSSELOT_NAME") or bpn
    version = d.getVar("OSSELOT_VERSION") or d.getVar("PV")

    meta = read_json(osselot_meta_file)

    # ignore package if OSSELOT_IGNORE is set to true within recipe
    ignore = bool(d.getVar("OSSELOT_IGNORE"))
    bb.debug(2, f"{bpn} has OSSELOT_IGNORE set to {ignore}.")
    if ignore is True:
        reason = f"OSSELOT_IGNORE set to {d.getVar('OSSELOT_IGNORE')}"
        bb.debug(2, f"Ignoring {bpn}: {reason}")
        meta["packages"].update({
            f"{bpn}/{version}": {
                "status": "ignored",
                "reason": reason
            }
        })
        write_json(osselot_meta_file, meta)
        return

    # if version not clearly identifiable (i.e. using a commit hash, autoinc, etc.) skip package
    if "+" in version:
        reason = f"{bpn} contains not clearly identifiable version {version}"
        bb.warn(reason)
        meta["packages"].update({
            f"{bpn}/{version}": {
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
            output = f"{osselot_dir}/{bpn}/{bpn}-{version}.{osselot_format}"
            urllib.request.urlretrieve(uri, output)
            if f"{bpn}/{version}" not in meta["packages"]:
                meta["packages"].update({
                    f"{bpn}/{version}": {
                        "status": "found"
                    }
                })
            meta["packages"][f"{bpn}/{version}"][osselot_format] = output
            write_json(osselot_meta_file, meta)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            reason = f"Package {osselot_package} in version {version} not found in the osselot database"
            bb.warn(reason)
            meta["packages"].update({
                f"{bpn}/{version}": {
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
do_osselot_collect[cleandirs] = "${OSSELOT_DIR}/${BPN}"
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
