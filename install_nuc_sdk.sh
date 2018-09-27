#!/bin/bash

DOWNLOAD_LOCATION="http://home.nonlinear-labs.de/images/nuc_sdk/"
DOWNLOAD_DIR="/tmp/nuc"
DOWNLOAD_FILE="nonlinear-nuc-distro-glibc-x86_64-nonlinear-nuc-image-default-corei7-64-toolchain-64.sh"

function download {
	mkdir -p "${DOWNLOAD_DIR}"

	printf "Downloading sdk from %s:\n" ${DOWNLOAD_LOCATION}

	for f in ${DOWNLOAD_FILE}; do
		printf "  %s...\n" ${f}
		curl -o "${DOWNLOAD_DIR}/${f}" --fail --progress-bar "${DOWNLOAD_LOCATION}/${f}" && printf "OK\n" || (printf "ERR: -%i\n" $?; exit -1)
	done
	printf "\n"
}

function install_sdk {
	chmod +x ${DOWNLOAD_DIR}/${DOWNLOAD_FILE}
	/bin/sh ${DOWNLOAD_DIR}/${DOWNLOAD_FILE}
}


download || (printf "Error while downloading.\n"; exit -1)
install_sdk || (printf "Error while installing sdk.\n"; exit -1)
