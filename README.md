# meta-osselot

This README file contains information on the contents of the meta-osselot layer.

## Background

Recently, the topic open-source license compliance in commercial software has seen an increase in interest. As such, an increasing number of industry partners and customers are asking for an "open source clearance document", as a guarantee that the software in question does not violate any open-source (especially copy-left) license terms.

As clearance is done on a file-based level, this poses a huge challenge, especially in the IoT/Bitbake context, where entire (Linux-based) operating systems require clearing. However, since most components are identical throughout the various images within a Yocto release, the idea of sharing and re-using curated license information within the community is only logical and fits the spirit of open source.

Cue to [Osselot](https://www.osselot.org/), a relative new project to tackle this challenge. It is essentially an open-source database of curated license information on various open source projects that is made available as git repository and via REST API.

This layer adds integration of Osselot into the Bitbake build process, utilizing their REST API for receiving curated package information (when-ever possible) at build time.

## Adding the meta-osselot layer to your build

Run `bitbake-layers add-layer meta-osselot` to add the layer to your build.

## Enabling and configuring osselot integration

To enable the Osselot integration, simply add `INHERIT += "osselot"` to your `local.conf` file.

Osselot can provide results in various formats, at the time of writing: json, yaml, xml and spdx. See https://wiki.osselot.org/index.php/REST) for the most up-to-date information.

You can specify a format by setting the `OSSELOT_FORMAT` variable (defaults to `json`).

Additionally, you can customize the output directory for Osselot results by setting the `OSSELOT_DIR` variable (defaults to `${DEPLOY_DIR}/osselot`).

##  Contributing

Please submit any patches against the meta-osselot layer via a GitHub Pull Request.

## (Current) Limitations

1. meta-osselot does not account for patches made to packages within the Bitbake recipes, as the data provided by Osselot is (obviously) limited to the original source code. Thus, patches need to be cleared separately. You can use the [archiver class](https://docs.yoctoproject.org/singleindex.html#ref-classes-archiver) with the [archiver mode](https://docs.yoctoproject.org/singleindex.html#term-ARCHIVER_MODE) set to `original` for extracting all patch files.
2. Osselot relies on accurate package names and versions, rather than using hashes for identifying components. This bears the (incredibly slim) risk of misidentifying another identical named and versioned package.
