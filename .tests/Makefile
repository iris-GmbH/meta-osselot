MAKEFILE_PATH := $(abspath $(lastword ${MAKEFILE_LIST}))
MAKEFILE_DIR := $(dir ${MAKEFILE_PATH})
export KAS_CONTAINER_TAG ?= 4.2
export KAS_CONTAINER_IMAGE ?= ghcr.io/siemens/kas/kas:${KAS_CONTAINER_TAG}
export KAS_BASE_CONFIG_FILE ?= .config.yaml
export KAS_COMMAND ?= KAS_CONTAINER_IMAGE=${KAS_CONTAINER_IMAGE} ${MAKEFILE_DIR}kas-container shell --update -c "bitbake core-image-minimal --runonly=populate_osselot"

test-lts: test-kirkstone test-dunfell
test-current: test-lts test-nanbield
test-all: test-current test-master

test-master:
	${KAS_COMMAND} ${KAS_BASE_CONFIG_FILE}:.master.yaml
	mv ${MAKEFILE_DIR}build/tmp/deploy/osselot ${MAKEFILE_DIR}osselot-master

test-nanbield:
	${KAS_COMMAND} ${KAS_BASE_CONFIG_FILE}:.nanbield.yaml
	mv ${MAKEFILE_DIR}build/tmp/deploy/osselot ${MAKEFILE_DIR}osselot-nanbield

test-kirkstone:
	${KAS_COMMAND} ${KAS_BASE_CONFIG_FILE}:.kirkstone.yaml
	mv ${MAKEFILE_DIR}build/tmp/deploy/osselot ${MAKEFILE_DIR}osselot-kirkstone

test-dunfell:
	${KAS_COMMAND} ${KAS_BASE_CONFIG_FILE}:.dunfell.yaml
	mv ${MAKEFILE_DIR}build/tmp/deploy/osselot ${MAKEFILE_DIR}osselot-dunfell
