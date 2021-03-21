#!/usr/bin/env bash


PROGNAME=$(basename $0)
VERSION="1.0"

_DO_BURN=1
_DO_CONFIGURE=1
_IMGFILE=ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz
_OUTDEVICE=/dev/sdc
_IPADDR=192.168.3.10/24

usage() {
    echo "Usage: $PROGNAME [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help"
    echo "      --version"
    echo "  --no-burn"
    echo "  --no-configure"
    echo "  --img IMGFILE"
    echo "  --dev DEVICEFILE"
    echo "  --ip IPADDR"
    echo
    echo "$PROGNAME --img ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz --dev /dev/sdc --ip 192.168.3.10/24"
    exit 1
}

while (( $# > 0 )); do
    case $1 in
        -h | --help) usage; exit 1;;
        --version)   echo $VERSION; exit 1;;
        -c | --no-burn)
            _DO_BURN=0
            shift 1
            ;;
        -c | --no-configure)
            _DO_CONFIGURE=0
            shift 1
            ;;
        --img|--image)
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$PROGNAME: option requires an argument -- $1" 1>&2
                exit 1
            fi
            _IMGFILE=$2
            shift 2
            ;;
        --dev|--device|--outdevice)
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$PROGNAME: option requires an argument -- $1" 1>&2
                exit 1
            fi
            _OUTDEVICE=$2
            shift 2
            ;;
        --ip|--ipaddr)
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$PROGNAME: option requires an argument -- $1" 1>&2
                exit 1
            fi
            _IPADDR=$2
            shift 2
            ;;
        -*|*)
            echo "$PROGNAME: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
            exit 1
            ;;
    esac
done

IPADDR="${_IPADDR}"
IMGFILE="${_IMGFILE}"
OUTDEVICE="${_OUTDEVICE}"
MOUNTPOINT=/mnt

if [ ! -b ${OUTDEVICE} ]; then
    echo "ERROR: ${OUTDEVICE} is not missing or is not block device file"
    exit 1
fi

set -xu

# umount /dev/sdc /dev/sdc1 /dev/sdc2 ...
sudo umount ${OUTDEVICE}* || true
if [ $_DO_BURN -eq 1 ]; then
  if [ ! -f "${IMGFILE}" ]; then
    echo "ERROR: ${IMGFILE} does not exists."
    exit 1
  fi
  xzcat ${IMGFILE} | sudo dd of=${OUTDEVICE} bs=1MB status=progress
  sudo partprobe ${OUTDEVICE}
  sleep 1
fi

if [ $_DO_CONFIGURE -eq 1 ]; then
  label=`lsblk -no label ${OUTDEVICE}1`
  if [ ! "${label}" == "system-boot" ]; then
      echo "ERROR: label ${label} is not 'system-boot'."
      echo "       ${OUTDEVICE}1 may not be cloud-init pertition of preinstalled raspi image."
      exit 1
  fi

  sudo mount ${OUTDEVICE}1 ${MOUNTPOINT}
  cat network-config | sed -e "s%IPADDR%${IPADDR}%g" | sudo tee ${MOUNTPOINT}/network-config > /dev/null
  sudo cp -f user-data ${MOUNTPOINT}/user-data
  sudo umount ${MOUNTPOINT}
fi


echo "Burn and configure successed!"
