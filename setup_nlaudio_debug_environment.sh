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
SCRIPT=$(readlink -f $0)
SCRIPTPATH=$(dirname $SCRIPT)

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

QTC_SETTINGS_PATH=${NLAUDIO_DIR}/../nlaudio_nuc


# Debug Config
printf "Setting up Debug environment for remote target...\n"
DEBUG_BUILD_DIR=${NLAUDIO_DIR}/../nlaudio_nuc/nlaudio_debug_build_nuc
mkdir -p ${DEBUG_BUILD_DIR}
cd ${DEBUG_BUILD_DIR}

cmake ${NLAUDIO_DIR} \
-DCMAKE_BUILD_TYPE="DEBUG" \
-DCMAKE_C_FLAGS_DEBUG=" -O0 -pipe -g -feliminate-unused-debug-types" \
-DCMAKE_CXX_FLAGS_DEBUG=" -O0 -pipe -g -feliminate-unused-debug-types" \
-DCMAKE_LD_FLAGS_DEBUG=" -Wl,-O0 -Wl,--hash-style=gnu -Wl,--as-needed" \
&& make -j8

# Release Config
printf "Setting up Release environment for remote target...\n"
RELEASE_BUILD_DIR=${NLAUDIO_DIR}/../nlaudio_nuc/nlaudio_release_build_nuc
mkdir -p ${RELEASE_BUILD_DIR}
cd ${RELEASE_BUILD_DIR}

cmake ${NLAUDIO_DIR} \
-DCMAKE_BUILD_TYPE="RELEASE" \
-DCMAKE_C_FLAGS_RELEASE=" -O2 -pipe -g -feliminate-unused-debug-types" \
-DCMAKE_CXX_FLAGS_RELEASE=" -O2 -pipe -g -feliminate-unused-debug-types" \
-DCMAKE_LD_FLAGS_RELEASE=" -Wl,-O1 -Wl,--hash-style=gnu -Wl,--as-needed" \
&& make -j8

printf "\n\n"
printf "Build configurations setup:\n"
printf "  Debug:   ${DEBUG_BUILD_DIR}\n"
printf "  Release: ${RELEASE_BUILD_DIR}\n"

printf "Starting qtcreator\n"
sleep 1

if ! [ -d ${QTC_SETTINGS_PATH}/qtcreator_settings ]; then
	printf "Recreating qtcreator environment!\n"
	printf "If you want to recreate it in the future, just delete:\n"
	printf "  %s" "${QTC_SETTINGS_PATH}/qtcreator_settings"
	cp -R ${SCRIPTPATH}/qtcreator_settings ${QTC_SETTINGS_PATH}
else
	printf "Using qtcreator environment:\n"
	printf "  %s" "${QTC_SETTINGS_PATH}/qtcreator_settings"
	printf "If you want to recreate it in the future, just delete above folder and rerun this script!\n"
fi

qtcreator -settingspath ${QTC_SETTINGS_PATH}/qtcreator_settings ${NLAUDIO_DIR} &
