#!/bin/bash

MOUNT_POINT_ROOT=/tmp/root
MOUNT_POINT_BOOT=/tmp/boot
IMAGE_VERSION_INFO_FILE=${MOUNT_POINT_ROOT}/etc/nonlinear_release
DEVICE=""
DEVICE_P1=""
DEVICE_P2=""
DOWNLOAD_LOCATION="http://home.nonlinear-labs.de/images/bbb"
DOWNLOAD_DIR="/tmp/bbb"

# Parameters
OPT_RECREATE_PARTITIONS=false
OPT_COPY_ROOTFS=false
OPT_COPY_BOOTFS=false
OPT_DEBUG=0
OPT_RELEASE_NUMBER=latest

function is_mounted {
	if [ "$(cat /proc/mounts | grep $1)" = "" ]; then
		return 0
	else
		return 1
	fi
}

function write_uenv_file {
	printf "Creating uEnv.txt..."
	MMC_CMDS="uenvcmd=mmc rescan"
	MMC_CMDS="${MMC_CMDS}; setenv fdtaddr 0x88000000"
	MMC_CMDS="${MMC_CMDS}; load mmc 0:2 \${loadaddr} boot/uImage"
	MMC_CMDS="${MMC_CMDS}; load mmc 0:2 \${fdtaddr} boot/nonlinear-labs-2D.dtb"
	MMC_CMDS="${MMC_CMDS}; setenv mmcroot /dev/mmcblk0p2 ro"
	MMC_CMDS="${MMC_CMDS}; setenv mmcrootfstype ext4 rootwait"
	MMC_CMDS="${MMC_CMDS}; setenv bootargs console=\${console} \${optargs} root=\${mmcroot} rootfstype=\${mmcrootfstype}"
	MMC_CMDS="${MMC_CMDS}; bootm \${loadaddr} - \${fdtaddr}"
	echo "${MMC_CMDS}" > "${DOWNLOAD_DIR}/uEnv.txt"
	sudo cp "${DOWNLOAD_DIR}/uEnv.txt" "${MOUNT_POINT_BOOT}/uEnv.txt"
	printf "OK\n"
}

function mount_boot {
	printf "Mounting boot partition at ${MOUNT_POINT_BOOT}\n"
	mkdir -p ${MOUNT_POINT_BOOT}
	if ! sudo mount ${DEVICE_P1} ${MOUNT_POINT_BOOT}; then
		printf "Can not mount ${DEVICE_P1}. Aborting...\n"
		exit -1
	fi
}

function mount_root {
	printf "Mounting root partition at ${MOUNT_POINT_ROOT}\n"
	mkdir -p ${MOUNT_POINT_ROOT}
	if ! sudo mount ${DEVICE_P2} ${MOUNT_POINT_ROOT}; then
		printf "Can not mount ${DEVICE_P2}. Aborting...\n"
		exit -1
	fi
}

function unmount_boot {
	printf "Unmounting boot..."
	sudo umount ${MOUNT_POINT_BOOT}
	printf "OK\n"
}

function unmount_root {
	printf "Unmounting rootfs..."
	sudo umount ${MOUNT_POINT_ROOT}
	printf "OK\n"
}

function sync_rootfs {
	printf "Syncing rootfs..."
	if ! sudo tar -C "${MOUNT_POINT_ROOT}" -xf "${DOWNLOAD_DIR}/nonlinear-bbb-image-default-beaglebone.tar.xz"; then
		printf "\nCan not untar rootfs.tar. Aborting...\n"
		exit -1
	fi
	if ! sudo cp "${DOWNLOAD_DIR}/nonlinear-labs-2D.dtb" "${MOUNT_POINT_ROOT}/boot/"; then
		printf "\nCan not opy nonlinear-labs-2D.dtb. Aborting...\n"
		exit -1
	fi
	sync
}

function sync_bootfs {
	printf "Syncing bootfs...\n"
	if ! sudo cp "${DOWNLOAD_DIR}/u-boot.img" ${MOUNT_POINT_BOOT}; then
		printf "Can not copy u-boot.img. Aborting...\n"
		exit -1
	fi
	if ! sudo cp "${DOWNLOAD_DIR}/MLO" ${MOUNT_POINT_BOOT}; then
		printf "Can not copy MLO. Aborting...\n"
		exit -1
	fi
}

function rewrite_partitions {
	printf "Flushing old partition table..."
	sudo dd if=/dev/zero of=${DEVICE} bs=1024 count=1024 2>/dev/null 1>/dev/null && sync
	printf "OK\n"

	printf "Creating new partition table..."
	echo -e ',50M,c,*\n,\n' | sudo sfdisk ${DEVICE} 2>/dev/null 1>/dev/null && sync
	printf "OK\n"

	printf "Creating Partitions..."
	sudo mkfs.vfat -n BOOT ${DEVICE_P1} 1>/dev/null 2>/dev/null
	sudo mkfs.ext3 ${DEVICE_P2} 1>/dev/null 2>/dev/null
	printf "OK\n"

	printf "Rereading partition table..."
	sudo partprobe ${DEVICE} && sync
	printf "OK\n"
}

function check_if_mounted_and_unmount {
	PARTITIONS=$(ls "$DEVICE"?* 2>/dev/null)
	if [ -n "$PARTITIONS" ]; then
		printf "Checking mountpoints:\n"
	fi

	for partition in $PARTITIONS; do
		is_mounted $partition
		if [ $? -eq 1 ]; then
			printf "  $partition: is mounted. Unmounting..."
			sudo umount "$partition" 2>/dev/null
			printf "OK\n"
		else
			printf "  $partition: is not mounted. Ok!\n"
		fi
	done
	printf "\n"
}

function download {
	mkdir -p "${DOWNLOAD_DIR}"
	rm -f "${DOWNLOAD_DIR}/*"

	printf "Downloading release %s from %s/%s:\n" ${OPT_RELEASE_NUMBER} ${DOWNLOAD_LOCATION} ${OPT_RELEASE_NUMBER}

	for f in MLO u-boot.img nonlinear-labs-2D.dtb nonlinear-bbb-image-default-beaglebone.tar.xz; do
		printf "  %s..." ${f}
		curl -o "/tmp/bbb/${f}" --fail --progress-bar "${DOWNLOAD_LOCATION}/${OPT_RELEASE_NUMBER}/${f}" 2>/dev/null 1>/dev/null && printf "OK\n" || (printf "ERR: -%i\n" $?; exit -1)
	done
	printf "\n"
}

function usage {
	printf "Usage:\n\n"
	printf "$0 [options] <PATH TO CARD>\n\n";
	printf "  options:\n"
	printf "  -p|--partition           Recreate partitions\n"
	printf "  -r|--root                Update files on root partition\n"
	printf "  -b|--boot                Update files on boot partition\n"
	printf "  -n|--release-number <nr> Specify release number <nr> (e.g. 11)\n"
	printf "  -v|--verbose             Be more verbose (even more if used twice)\n"
	printf "\n"
	exit -1
}

function debug {
	if [ ${OPT_DEBUG} -ge 1 ]; then
		printf "%s\n" "${1}"
	fi
}

function debugdebug {
	if [ ${OPT_DEBUG} -ge 2 ]; then
		printf "%s\n" "${1}"
	fi
}



# usage:
#  get_partition "/dev/sdc" "1"
#  returns "/dev/sdc1"
#  get_partition "/dev/mmcblk0" "2"
#  returns "/dev/mmcblk0p2"
function get_partition {
	[[ $1 == *"/dev/mmcblk"* ]] && echo "${1}p${2}"
	[[ $1 == *"/dev/sd"* ]] && echo "${1}${2}"
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
			-p|--partition)
				OPT_RECREATE_PARTITIONS=true
			;;
			-r|--root)
				OPT_COPY_ROOTFS=true
			;;
			-b|--boot)
				OPT_COPY_BOOTFS=true
			;;
			-v|--verbose)
				OPT_DEBUG=$((OPT_DEBUG+1))
			;;
			*)
				printf "Unknown option: %s\n" "${key}"
				usage
		esac
		;;
	esac
	shift # shift argument
	DEVICE=$1
done

if [ -b "${DEVICE}" ]; then
	DEVICE_P1=$(get_partition ${DEVICE} 1)
	DEVICE_P2=$(get_partition ${DEVICE} 2)
	debug "Working on:"
	debug "  ${DEVICE}"
	debug "    ${DEVICE_P1}  boot"
	debug "    ${DEVICE_P2}  rootfs"
	debug ""
else
	printf "Device \"$1\" does not seem to be a block device!\n"
	usage
fi

debugdebug "OPT_WIFI_NAME            = $OPT_WIFI_NAME"
debugdebug "OPT_RELEASE_NOTE         = $OPT_RELEASE_NOTE"
debugdebug "OPT_RECREATE_PARTITIONS  = $OPT_RECREATE_PARTITIONS"
debugdebug "OPT_COPY_ROOTFS          = $OPT_COPY_ROOTFS"
debugdebug "OPT_COPY_BOOTFS          = $OPT_COPY_BOOTFS"
debugdebug "OPT_CREATE_INSTALL_MEDIA = $OPT_CREATE_INSTALL_MEDIA"
debugdebug "OPT_DEBUG                = $OPT_DEBUG"
debugdebug "OPT_RELEASE_NUMBER       = $OPT_RELEASE_NUMBER"
debugdebug "DEVICE                   = $DEVICE"

###############################################################################
# Do the actual work
###############################################################################

sudo true

download

check_if_mounted_and_unmount

if [ ${OPT_RECREATE_PARTITIONS} = true ]; then
	rewrite_partitions
fi

mount_root
mount_boot

if [ ${OPT_COPY_ROOTFS} = true ]; then
	sync_rootfs && sync
fi

if [ ${OPT_COPY_BOOTFS} = true ]; then
	sync_bootfs && write_uenv_file && sync
fi

printf "Cleaning up:\n"

unmount_boot
unmount_root

printf "Done.\n"

