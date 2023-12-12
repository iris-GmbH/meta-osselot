# meta-osselot

This README file contains information on the contents of the meta-osselot layer.

## Background

Recently, the topic open-source license compliance in commercial software has seen an increase in interest. As such, an increasing number of industry partners and customers are asking for an "open source clearance document", as a guarantee that the software in question does not violate any open-source (especially copy-left) license terms.

As clearance is done on a file-based level, this poses a huge challenge, especially in the IoT/Bitbake context, where entire (Linux-based) operating systems require clearing. However, since most components are identical throughout the various images within a Yocto release, the idea of sharing and re-using curated license information within the community is only logical and fits the spirit of open source.

Cue to [Osselot](https://www.osselot.org/), a relative new project to tackle this challenge. It is essentially an open-source database of curated license information on various open source projects that is made available as git repository.

This layer adds integration of Osselot into the Bitbake build process, utilizing the Osselot git repository for receiving curated package information at build time, whenever available.

## Adding the meta-osselot layer to your build

Run `bitbake-layers add-layer meta-osselot` to add the layer to your build.

## Enabling and configuring osselot integration

To enable the Osselot integration, simply add `INHERIT += "osselot"` to your `local.conf` file.

Additionally, you can customize Osselot with the following variables:

| Variable             | Description                                                                                                                                                                                     | Default value                                                                               |
|----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| `OSSELOT_DEPLOY_DIR` | The directory where Osselot data is collected after build completion.                                                                                                                           | `"${DEPLOY_DIR}/osselot"`                                                                   |
| `OSSELOT_GIT_SRC`    | The value used as the osselot-package-analysis-native packages [SRC_URI](https://docs.yoctoproject.org/singleindex.html#term-SRC_URI). This determines where curated data is sourced from.      | `"git://github.com/Open-Source-Compliance/package-analysis.git;protocol=https;branch=main"` |
|  `OSSELOT_SRCREV`    | The value used as the osselot-package-analysis-native packages [SRCREV](https://docs.yoctoproject.org/singleindex.html#term-SRCREV). This determines the used version of the curated data.      | `"${AUTOREV}"`                                                                              |
| `OSSELOT_PV`         | The value used as the osselot-package-analysis-native packages [PV](https://docs.yoctoproject.org/singleindex.html#term-SRCREV). This determines the package version in Bitbake.                | `"1.0+git${SRCPV}"`                                                                         |
| `OSSELOT_DATA_DIR_S` | The value used as the osselot-package-analysis-native packages [S](https://docs.yoctoproject.org/singleindex.html#term-S). This points to the folder containing the Osselot data after fetching | `"${OSSELOT_DATA_DIR}/git"`                                                                 |

## Overriding package names and versions for Osselot

There might be false negatives when matching packages against the Osselot data folder structure due to mismatch in name or version formatting between the recipe and the Osselot database. In these cases you can set the variables `OSSELOT_NAME` and `OSSELOT_VERSION` within your recipe. If the mismatch occurs within an upstream recipe from the openembedded-core layer, please fix this by submitting a bbappend file to this repository.

## Excluding packages from Osselot

You can opt to exclude packages from Osselot by setting `OSSELOT_IGNORE = "1"` within a recipe.

##  Contributing

Please submit any patches against the meta-osselot layer via a GitHub Pull Request.

## (Current) Limitations

1. meta-osselot does not account for patches made to packages within the Bitbake recipes, as the data provided by Osselot is (obviously) limited to the original source code. Thus, patches need to be cleared separately. You can use the [archiver class](https://docs.yoctoproject.org/singleindex.html#ref-classes-archiver) with the [archiver mode](https://docs.yoctoproject.org/singleindex.html#term-ARCHIVER_MODE) set to `original` for extracting all patch files.
2. Osselot relies on accurate package names and versions, rather than using hashes for identifying components. This bears the (incredibly slim) risk of misidentifying another identical named and versioned package.
