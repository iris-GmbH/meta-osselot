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

We recommend to override `OSSELOT_GIT_SRC` with your own fork of the `package-analysis` repository, as this allows you to push and re-use your own curated data. However, remember to keep your fork up-to-date with upstream repository for the latest curation data. We also recommend to [upstream your curation data to the Osselot project](https://wiki.osselot.org/index.php/Main_Page#Contributing_to_the_OSSelot_project).

## Using meta-osselot
### Working with meta-osselot output

After a successful build, all files relevant to meta-osselot will be stored in the `OSSELOT_DEPLOY_DIR`.

The file at `${OSSELOT_DEPLOY_DIR}/meta.json` contains relevant information on the status of all packages, as well as (if applicable) the path to the curated data:

1. If the status of a package is `found`, the license clearing requirements for this particular package are met and no further actions are required (other than dealing with Yocto patches).
2. If the status of a package is `version_mismatch`, there are two possible reasons for this:
    1. Osselot expects a different version formatting (double-check the folder names in the version-mismatch folder). In this case [override the package version](#overriding-package-names-and-versions-for-osselot).
    2. There is no license clearing information available for this exact version. In this case, use the closest available version and [curate](https://wiki.osselot.org/index.php/Curation_guideline) the diff using Fossology, as described in [use case 2](https://www.osselot.org/index.php?s=presentations).
3. If the status of a package is `ignored`, the package does not contain compliance relevant source code and no further action is required.
4. If the status of a package is `not_found`, the package is unknown to Occelot. In this case, a complete [curation](https://wiki.osselot.org/index.php/Curation_guideline) needs to take place.

### Overriding package names and versions for Osselot

There might be false negatives when matching packages against the Osselot data folder structure due to mismatch in name or version formatting between the recipe and the Osselot database. In these cases you can set the variables `OSSELOT_NAME` and `OSSELOT_VERSION` within your recipe. If the mismatch occurs within an upstream recipe from the openembedded-core layer, please fix this by submitting a bbappend file to this repository.

### Excluding packages from Osselot

You can opt to exclude packages from Osselot by setting `OSSELOT_IGNORE = "1"` within a recipe.

##  Contributing

Please submit any patches against the meta-osselot layer via a GitHub Pull Request.

## (Current) Limitations

1. meta-osselot does not account for patches made to packages within the Bitbake recipes, as the data provided by Osselot is (obviously) limited to the original source code. Thus, patches need to be cleared separately. You can use the [archiver class](https://docs.yoctoproject.org/singleindex.html#ref-classes-archiver) with the [archiver mode](https://docs.yoctoproject.org/singleindex.html#term-ARCHIVER_MODE) set to `original` for extracting all patch files.
2. Osselot relies on accurate package names and versions, rather than using hashes for identifying components. This bears the (incredibly slim) risk of misidentifying another identical named and versioned package.
