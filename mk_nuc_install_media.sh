#!/bin/bash

DOWNLOAD_LOCATION="http://home.nonlinear-labs.de/images/nuc"
DOWNLOAD_DIR="/tmp/nuc"

DOWNLOAD_FILE=nonlinear-nuc-image-default-nonlinear-intel-corei7-64.hddimg

OPT_RELEASE_NUMBER=latest

function download {
	mkdir -p "${DOWNLOAD_DIR}"
	rm -f "${DOWNLOAD_DIR}/*"

	printf "Downloading release %s from %s/%s:\n" ${OPT_RELEASE_NUMBER} ${DOWNLOAD_LOCATION} ${OPT_RELEASE_NUMBER}

	for f in ${DOWNLOAD_FILE}; do
		printf "  %s..." ${f}
		curl -o "${DOWNLOAD_DIR}/${f}" --fail --progress-bar "${DOWNLOAD_LOCATION}/${OPT_RELEASE_NUMBER}/${f}" && printf "OK\n" || (printf "ERR: -%i\n" $?; exit -1)
	done
	printf "\n"
}

function usage {
	printf "Usage:\n\n"
	printf "$0 [options] <PATH TO STICK>\n\n";
	printf "  options:\n"
	printf "  -n|--release-number <nr> Specify release number <nr> (e.g. 511)\n"
	printf "\n"
	exit -1
}

function confirm {
# call with a prompt string or use a default
	read -r -p "${1:-Are you sure? [y/N]} " response
	case "$response" in
		[yY][eE][sS]|[yY])
		true
		;;
	*)
		false
		;;
	esac
}

###############################################################################
# Do Pre Checks for params and stuff
###############################################################################

while [[ $# -gt 1 ]]; do
	key="$1"
	case $key in
		-n|--release-number)
			OPT_RELEASE_NUMBER="$2"
			shift # shift argument value
		;;
		*)
		# Arguments without value
		case $key in
			*)
				printf "Unknown option: %s\n" "${key}"
				usage
		esac
		;;
	esac
	shift # shift argument
done

DEVICE=$1

if [ -b "${DEVICE}" ]; then
	confirm "Attention: All data on ${DEVICE} will be deleted! Are you really sure?" || (echo "Aborted by user!"; exit -1)
else
	printf "Device \"$1\" does not seem to be a block device!\n"
	usage
fi

###############################################################################
# Do the actual work
###############################################################################

sudo true

download

printf "Dumping image on ${DEVICE}...\n"
pv ${DOWNLOAD_DIR}/${DOWNLOAD_FILE} | sudo dd of=${DEVICE} bs=512k oflag=dsync 1>/dev/zero 2>/dev/zero && sync
printf "Done.\n"

printf "Cleaning up..."

rm -Rf ${DOWNLOAD_DIR}

printf "Done.\n"

