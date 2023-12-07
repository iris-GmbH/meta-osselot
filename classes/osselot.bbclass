# SPDX-License-Identifier: MIT
# Copyright 2023 iris-GmbH infrared & intelligent sensors

# see https://wiki.osselot.org/index.php/REST for available formats
OSSELOT_FORMAT ??= "json"
OSSELOT_DIR ??= "${DEPLOY_DIR}/osselot"

OSSELOT_FORMAT_DIR = "${OSSELOT_DIR}/${OSSELOT_FORMAT}"
OSSELOT_META_FILE = "${OSSELOT_FORMAT_DIR}/meta.json"
OSSELOT_META_FILE_LOCK = "${OSSELOT_META_FILE}.lock"
OSSELOT_REST_URI = "https://rest.osselot.org"

# enable networking for the do_osselot_connect task
python () {
    d.setVarFlag('do_osselot_collect', 'network', '1')
}

python do_osselot_init() {
    from datetime import datetime

    osselot_format = d.getVar("OSSELOT_FORMAT")
    osselot_format_dir = d.getVar("OSSELOT_FORMAT_DIR")
    osselot_meta_file = d.getVar("OSSELOT_META_FILE")
    bb.debug(2, f"Creating osselot directory for format {format}: {osselot_format_dir}")
    bb.utils.mkdirhier(f"{osselot_format_dir}")

    bb.debug(2, "Creating empty meta file: {osselot_meta_file}")
    write_json(osselot_meta_file, {
        "timestamp": datetime.now().astimezone().isoformat(),
        "packages_found": [],
        "packages_missed": [],
        "packages_ignored": []
    })
}

addhandler do_osselot_init
do_osselot_init[eventmask] = "bb.event.BuildStarted"

python do_osselot_collect() {
    import urllib
    import json
    import re

    osselot_format = d.getVar("OSSELOT_FORMAT")
    osselot_format_dir = d.getVar("OSSELOT_FORMAT_DIR")
    osselot_meta_file = d.getVar("OSSELOT_META_FILE")
    osselot_rest_uri = d.getVar("OSSELOT_REST_URI")

    meta = read_json(osselot_meta_file)

    package = d.getVar("OSSELOT_NAME") or d.getVar("BPN")
    version = d.getVar("OSSELOT_VERSION") or d.getVar("PV")

    # ignore package if OSSELOT_IGNORE is set to true within recipe
    ignore = bool(d.getVar("OSSELOT_IGNORE"))
    bb.debug(2, f"{package} has OSSELOT_IGNORE set to {ignore}.")
    if ignore is True:
        reason = f"OSSELOT_IGNORE set to {d.getVar('OSSELOT_IGNORE')}"
        bb.debug(2, f"Ignoring {package}: {reason}")
        meta["packages_ignored"].append({
            "name": package,
            "version": version,
            "reason": reason
        })
        write_json(osselot_meta_file, meta)
        return

    # if version not clearly identifiable (i.e. using a commit hash, autoinc, etc.) skip package
    if "+" in version:
        reason = f"Package {package} contains not clearly identifiable version {version}"
        bb.warn(reason)
        meta["packages_missed"].append({
            "name": package,
            "version": version,
            "reason": reason
        })
        write_json(osselot_meta_file, meta)
        return

    uri = f"{osselot_rest_uri}/{osselot_format}/{package}/{version}"
    output = f"{osselot_format_dir}/{package}-{version}.{osselot_format}"

    bb.debug(2, f"Searching osselot API for package {package} in version {version}")
    try:
        urllib.request.urlretrieve(uri, output)
        meta["packages_found"].append({
            "name": package,
            "version": version,
            "format": output
        })
        write_json(osselot_meta_file, meta)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            reason = f"Package {package} in version {version} not found in the osselot database"
            bb.warn(reason)
            meta["packages_missed"].append({
                "name": package,
                "version": version,
                "reason": reason
            })
            write_json(osselot_meta_file, meta)
        else:
            bb.error(f"Failed request to {uri}. [HTTP Error] {e.code}; Reason: {e.reason}")
}

addtask osselot_collect
do_osselot_collect[nostamp] = "1"
do_osselot_collect[lockfiles] += "${OSSELOT_META_FILE_LOCK}"
do_rootfs[recrdeptask] += "do_osselot_collect"

def read_json(path):
    import json
    from pathlib import Path
    return json.loads(Path(path).read_text())

def write_json(path, content):
    import json
    from pathlib import Path
    Path(path).write_text(json.dumps(content, indent=2))
