#!/bin/bash

function usage {
	printf "Usage:\n\n"
	printf "$0 <PATH TO SDK> <PATH_TO_NLAUDIO>\n\n";
	printf "\n"
	exit -1
}


########################################################################

if ! [[ $# -eq 2 ]]; then
	usage
fi

SDK_DIR=$(readlink -f $1)
NLAUDIO_DIR=$(readlink -f $2)

if ! [ -f ${SDK_DIR}/environment-setup-corei7-64-nonlinear-linux ]; then
	printf "Err: There is no environment-setup-corei7-64-nonlinear-linux in %s\n" ${SDK_DIR}
	exit -1
fi

if ! [ -f ${NLAUDIO_DIR}/CMakeLists.txt ]; then
	printf "Err: There is no CMakeLists.txt in %s. Wrong path, maybe?\n" ${NLAUDIO_DIR}
	exit -1
fi

printf "Working on:\n"
printf "  SDK:     %s\n" ${SDK_DIR}
printf "  NLAUDIO: %s\n" ${NLAUDIO_DIR}

source ${SDK_DIR}/environment-setup-corei7-64-nonlinear-linux
mkdir -p ${NLAUDIO_DIR}/../nlaudio_build_nuc
cd ${NLAUDIO_DIR}/../nlaudio_build_nuc

export CFLAGS=" -O0 -pipe -g -feliminate-unused-debug-types"
export CXXFLAGS=" -O0 -pipe -g -feliminate-unused-debug-types"
export LDFLAGS=" -Wl,-O0 -Wl,--hash-style=gnu -Wl,--as-needed"

cmake ../nlaudio && VERSBOE=1 make -j8 && qtcreator ../nlaudio &
