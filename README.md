# meta-osselot

This README file contains information on integrating [Osselot](https://www.osselot.org/) into your openembedded build process using the meta-osselot layer.

## Background: What is Osselot?

In recent years the topic open-source license compliance in commercial software has seen an increase in interest. As a result, an increasing number of industry partners and customers are asking for an "open source clearance document", as a guarantee that the software in question does not violate any open-source (especially copy-left) license terms.

Creating such a clearing document is a multi-step process:

1. You need to identify which packages are shipped within your product.
2. You need to identify (curate) the various licenses and copyright notices within those packages. Depending on the requirements, this might have to happen on a file-to-file, rather than a per-package basis.
3. You need to verify that all license obligations are adhered to.
4. You need to provide this information to the customer in a suitable format.

If clearance is to be done on a file-to-file basis (a requirement that becomes increasingly predominant), this poses a huge challenge, especially in the (open)embedded context, where entire custom-built firmwares need to be considered.

However, even though the firmwares are custom-built, core components used in the underlying (Linux-based) operating systems are largely identical. Incidentally, these are the packages that require the most work during curation, due to their large codebase (it is an entire operating system after all). Therefore, instead of having every vendor to do the same data curation work for these packages for themselves, the idea of sharing and re-using curated license information within the community is only logical and fits spirit of open source.

Cue to [Osselot](https://www.osselot.org/), a relative new project tackling this challenge. In a nutshell, Osselot is an open-source database of curated license information on various open source projects that is made available as git repository. Additionally, Osselot provides documentation and tooling for re-using curation data on divergence in package version and/or individual files.

Osselot therefore helps covering step N<sup>o</sup>2 (and to an extend N<sup>o</sup>4) of the open source clearance process.

Still, the question remains: How can we easily identify packages relevant for license compliance, make Osselot data available wherever possible, as well as identifying divergences between source code cleared in Osselot and source code used in the openembedded build? This is where this layer, meta-osselot comes into play.

## How meta-osselot works

Meta-osselot integrates directly in the bitbake build process. It will identify any target-relevant package and attempt to find the package (in the best-matching version) as JSON SPDX file within the Osselot database. If a suitable package is found, meta-osselot will compare the file checksums for all source code within the ["S" build directory](https://docs.yoctoproject.org/singleindex.html#term-S) against the available curation data. It is worth noting that since meta-osselot uses the Osselot git repository as data source, you can easily replace the upstream repository with your own fork of the Osselot curation database, thus allowing using your own curated data as well.

The results of this comparison, together with other meta-information as well as the available Osselot curation data, will be then provided as build artefacts.

## Adding the meta-osselot layer to your build

Run `bitbake-layers add-layer meta-osselot` to add the core layer to your build.

If you are using [kas](https://kas.readthedocs.io/en/latest/index.html), the configuration looks as follows:

```yaml
repos:
  meta-osselot:
    url: "https://github.com/iris-GmbH/meta-osselot.git"
    branch: "<YOCTO_RELEASE>"
...
```

## Enabling and configuring Osselot integration

To enable the Osselot integration, simply add `INHERIT += "osselot"` to your `local.conf` file. Now osselot tasks will automatically run for every package or image you build. 

Alternatively, if you are only interested in the osselot output and not in building packages add `--runonly=populate_osselot` to your bitbake command, e.g:

```bash
bitbake core-image-minimal --runonly=populate_osselot
```

Meta-osselot can be configured via bitbake environment variables, either on a global or per recipe basis (or both).

Available configuration options are as follows.

### Global configuration

Global configuration is done in your `local.conf` file or a distro configuration file.

| Variable | Description | Default value |
|---|---|---|
| `OSSELOT_HASH_ALGORITHM` | The hash algorithm used when determining equivalence between source code and curation data | `"md5"` |
| `OSSELOT_DEPLOYDIR` | The folder in which Osselot artifact data will be deployed | `"${DEPLOY_DIR}/osselot"` |
| `OSSELOT_SRC_URI` | The bitbake `SRC_URI` configuration for fetching curation data | `"git://github.com/Open-Source-Compliance/package-analysis.git;protocol=https;branch=main"` |
| `OSSELOT_SRCREV` | The revision of the curation data to use (default: latest) | `"${AUTOREV}"` |
| `OSSELOT_PV` | The package version of the curation data | `"1.0+git${SRCPV}"` |
| `OSSELOT_IGNORE_LICENSES` | Ignore packages with the listed licenses (whitespace separated) | `"CLOSED"` |
| `OSSELOT_IGNORE_SOURCE_GLOBS` | Globally ignore source code files in `S` which paths match these globs (whitespace separated) | `".pc/**/* patches/series .git/**/*"` |
| `OSSELOT_IGNORE_PACKAGE_SUFFIXES` | Ignore packages ending with one of the specified suffixes (whitespace separated) | `"${SPECIAL_PKGSUFFIX}"` |

### Per-recipe configuration

Per-recipe configuration is done in either the original `*.bb` recipe file or by appending to an existing (upstream) recipe using `*.bbapped`.

| Variable | Description | Default value |
|---|---|---|
| `OSSELOT_NAME` | The name of this package within the Osselot database | `"${BPN}"` |
| `OSSELOT_VERSION` | The version of this package within the Osselot database | `"${PV}"` |
| `OSSELOT_IGNORE` | Set to `"1"` to ignore this recipe | `"0"` |
| `OSSELOT_IGNORE_SOURCE_GLOBS` | Within this recipe, ignore source code files in `S` where the paths match these globs (whitespace separated) | `".pc/**/* patches/series .git/**/*"` |
| `OSSELOT_HASH_EQUIVALENCE` | Set source code hash equivalence of one or more hashes. Equal hashes are colon separated, statements are whitespace separated, e.g. `"aaaa:bbbb:cccc dddd:ffff"` | `""` |

## Using meta-osselot
### General recommendations

We recommend overwriting `OSSELOT_SRC_URI` with your own fork of the `package-analysis` repository, as this allows you to push and re-use your own curated data. However, remember to keep your fork up-to-date with upstream repository for the latest curation data.

When adding curation data to the git repository, be aware that following assumptions are made by meta-osselot, otherwise your curation data will **not** be identified:

1. Available packages are subdirectories within the `analysed-packages` directory (depth is irrelevant). The package name equals the directory name.
2. Available packages have one or more versions available as direct subdirectory within the package directory.
3. These version directories start with the prefix "version-". The package version equals anything after this prefix.
4. The version directory contains at least one valid SPDX file in JSON format.

We also recommend to [upstream your curation data to the Osselot project](https://wiki.osselot.org/index.php/Main_Page#Contributing_to_the_OSSelot_project) for an additional layer of quality control, and for the open-source spirit of improving the Osselot database by making your curation data available to others.

### Overriding package names and versions for Osselot

There might be false negatives when matching packages against the Osselot data folder structure due to mismatches in name or version formatting between the recipe and the Osselot database.

For example, within the openembedded-core recipe [expat](https://layers.openembedded.org/layerindex/recipe/575/) the name of the package is "expat" and the version is "2.5.0". In Osselot however, the same package is named "libexpat" and the version is "R_2_5_0".

In these cases `OSSELOT_NAME` and/or `OSSELOT_VERSION` need to be overwritten, either within the recipe itself for your own custom layers, or in a matching `.bbappend` file if the mismatch occurs within an upstream layer. In the latter case, please open an issue in this projects issue tracker, or contribute a patch to add the `.bbappend` file for the appropriate layer within the bbappend folder of this repository, so that we can fix this for everyone.

### Ignoring openembedded packages

By default, meta-osselot will already exclude packages where one the following is true:

1. The package name contains a non-target suffix, i.e. it will not end up in the target product (see [`SPECIAL_PKGSUFFIX`](https://docs.yoctoproject.org/singleindex.html#term-SPECIAL_PKGSUFFIX) which is the default value for `OSSELOT_IGNORE_PACKAGE_SUFFIXES`)
2. The package does not have any source code ([`S`](https://docs.yoctoproject.org/singleindex.html#term-S) folder not existent)
3. The recipe [`LICENSE`](https://docs.yoctoproject.org/singleindex.html#term-LICENSE) is set to `"CLOSED"` (see `OSSELOT_IGNORE_LICENSES` variable)
4. The recipe has `OSSELOT_IGNORE` set to `"1"` (see preconfigured bbappends within meta-osselot)

You may globally append to the `OSSELOT_IGNORE_LICENSES` variable, if you want to exclude recipe with based on other licenses (e.g. your custom defined company license)

Also, you may set `OSSELOT_IGNORE = "1"` within any recipe `*.bb` or `*.bbappend` file, if you wish to ignore this package.

### Ignoring source files

> [!CAUTION]
> Always be cautious when ignoring source file globs on a global level, you might end up ignoring valid cases!

There are valid use-cases for ignoring source files from a license compliance perspective.

For example, when you are confident that there files do not end up in the final product. Adding these files to the ignore list will help reduce the diff between version mismatches.

Another valid reason are release tarballs. Openembedded recipes sometimes use software release tarballs (e.g. GitHub releases) rather than the corresponding git source code (which is used during curation in Osselot). These release tarballs might contain additional files (e.g. pre-generated configure files) that are not relevant from a license compliance perspective.

Append to the `OSSELOT_IGNORE_SOURCE_GLOBS` variable if you want to ignore a file (or [glob](https://en.wikipedia.org/wiki/Glob_(programming))), e.g.: `OSSELOT_IGNORE_SOURCE_GLOBS += "tests/**/*"`.

### Defining source code file hash equivalence

There might be cases of source code differences between two versions of the same file, e.g. when applying patches via bitbake recipes. In most of these cases, there are no license compliance relevant changes done to these files. In these cases you can use `OSSELOT_HASH_EQUIVALENCE` variable to define equivalences between two or more hashes, e.g.:

```
# first hash equivalence statement
OSSELOT_HASH_EQUIVALENCE += "bcb82bc370eb937e3b310e98d20aa906:d6b29fc355b6ab0f9f4bb9d4e03e9304:cb31a703b96c1ab2f80d164e9676fe7d"
# second hash equivalence statement
OSSELOT_HASH_EQUIVALENCE += "d3b07384d113edec49eaa6238ad5ff00:c157a79031e1c40f85931829bc5fc552"
```

If an openembedded package source code checksum mismatches the corresponding SPDX checksum entry, meta-osselot will evaluate all available hash equivalence statements. If both the source code checksum as well as the SPDX checksum are available within the same hash equivalence statement, the file will be marked accordingly in the output.

### Working with meta-osselot output

After a successful build, all files relevant to meta-osselot will be stored in the `${OSSELOT_DEPLOYDIR}`.

The file at `${OSSELOT_DEPLOYDIR}/${PN}/${PN}-${PV}-meta.json` contains relevant meta- and checksum-information on the package.

##  Contributing

Please submit any patches against the meta-osselot layer via a GitHub Pull Request.
