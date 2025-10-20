#!/bin/bash

# A script to prepare a USB stick for an old car stereo.
#
# 1. Wipes the USB stick and creates a new MBR (DOS) partition table.
# 2. Creates one primary partition.
# 3. Sets the partition type to 'c' (W95 FAT32 LBA).
# 4. Formats the partition as FAT32.
# 5. Creates a folder named CD01.
# 6. Uses helper script to Download music
# 7. Uses other helper script to safe name it (no emoji's or strange chars)
# 8. Lastly, moves only 
#
# SAFETY:
# - Requires root privileges.
# - Only works on block devices smaller than 16GB.
# - Asks for final confirmation before wiping the disk.


# --- Configuration ---
# DO NOT CHANGE THIS
readonly MAX_SIZE_BYTES=17179869185
readonly FOLDER_TO_CREATE="CD01"
readonly MUSIC_FOLDER="music_unsafe"
readonly SAFE_FOLDER="music_safe"
readonly DOWNLOAD_SCRIPT="req_scripts/download_playlist.sh"
readonly SAFETYPE_SCRIPT="req_scripts/safetype_name.sh"
readonly MOVE_SCRIPT="req_scripts/move_only_n.sh"
readonly COPY_SCRIPT="req_scripts/copy_only_n.sh"

# Change this as you wish
FILESYSTEM_LABEL="CAR_USB" # name of the usb after the formatting   
NO_MELODIES=40 # how many songs we actually move (old cars have some limitations in this regard)


# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Initial Checks ---

if [[ "$(id -u)" -ne 0 ]]; then
  echo -e "${RED}This script must be run as root. Please use sudo.${NC}"
  echo "Usage: sudo $0 /dev/sdX <youtube_PLAYLIST_link>"
  echo "Example:"
  echo "sudo $0 /dev/sdb https://youtube.com/someurl"
  echo "sudo $0 /dev/sda https://youtube.com/someurl"
  exit 1
fi

if [[ "$#" -ne 2 ]]; then
  echo "Usage: sudo $0 /dev/sdX <youtube_PLAYLIST_link>"
  echo "Example:"
  echo "sudo $0 /dev/sdb https://youtube.com/someurl"
  echo "sudo $0 /dev/sda https://youtube.com/someurl"
  exit 1
fi

DEVICE=$1
YOUTUBE_LINK=$2

if [[ ! -b "$DEVICE" ]]; then
  echo -e "${RED}Error: '$DEVICE' is not a valid block device.${NC}"
  echo "Usage: sudo $0 /dev/sdX <youtube_PLAYLIST_link>"
  echo "Do not add the number at the end!"
  lsblk 
  exit 1
fi

echo "--> Checking device size..."
DEVICE_SIZE_BYTES=$(lsblk -b -n -d -o SIZE "$DEVICE")

if [[ "$DEVICE_SIZE_BYTES" -ge "$MAX_SIZE_BYTES" ]]; then
  DEVICE_SIZE_GB=$(awk "BEGIN {printf \"%.2f\", $DEVICE_SIZE_BYTES/1024/1024/1024}")
  echo -e "${RED}SAFETY LOCK ENGAGED!${NC}"
  echo -e "Device ${YELLOW}$DEVICE${NC} is ${DEVICE_SIZE_GB}GB, which is larger than the 16GB safety limit."
  echo "This script will not continue to prevent accidental data loss on a large drive."
  exit 1
else
  echo -e "${GREEN}Device size is under 16GB. Safety check passed.${NC}"
fi


# --- Final Confirmation ---
format_the_disk() {
    echo
    echo -e "${YELLOW}WARNING: This script will completely erase all data on ${DEVICE}.${NC}"
    read -p "Are you absolutely sure you want to continue? (yes/no): " CONFIRM
    if [[ "${CONFIRM,,}" != "yes" ]]; then
      echo "Operation cancelled."
      exit 0
    fi

    echo "--> Unmounting all partitions on $DEVICE..."
    umount "${DEVICE}"* &>/dev/null || true 

    echo "--> Creating new MBR partition table and partition on $DEVICE..."
    {
      echo o # Create a new empty MBR (DOS) partition table
      echo n # Add a new partition
      echo p # Primary partition
      echo 1 # Partition number 1
      echo   # Default - first sector
      echo   # Default - last sector
      echo t # Change partition type
      echo c # Set to 'c' which is W95 FAT32 (LBA)
      echo a # Make the partition active (bootable)
      echo w # Write table to disk and exit
    } | fdisk "$DEVICE"

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: fdisk failed to partition the device.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Partition table created successfully.${NC}"

    # Allow a moment for the kernel to recognize the new partition table
    sleep 2
    partprobe "$DEVICE"

    PARTITION="${DEVICE}1"

    echo "--> Formatting ${PARTITION} as FAT32..."
    mkfs.fat -F 32 -n "$FILESYSTEM_LABEL" "$PARTITION"

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: mkfs.fat failed to format the partition.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Formatting successful.${NC}"
}

# --- Check current state of drive ---
echo "--- Checking current state of ${DEVICE} ---"
NEEDS_FORMAT=0
PARTITION="${DEVICE}1"

# Check 1: Partition Table Type
PT_TYPE=$(lsblk -o PTTYPE -n -d "$DEVICE")
echo -n "Checking Partition Table..."
if [[ "$PT_TYPE" != "dos" ]]; then
  echo -e " ${RED}Incorrect (found '$PT_TYPE', expected 'dos').${NC}"
  NEEDS_FORMAT=1
else
  echo -e " ${GREEN}OK (MBR/dos found).${NC}"
fi

# Check 2: Filesystem Type (only if partition exists)
if [[ -b "$PARTITION" ]]; then
  FS_TYPE=$(lsblk -o FSTYPE -n "$PARTITION")
  echo -n "Checking Filesystem..."
  if [[ "$FS_TYPE" != "vfat" ]]; then
    echo -e " ${RED}Incorrect (found '$FS_TYPE', expected 'vfat').${NC}"
    NEEDS_FORMAT=1
  else
    echo -e " ${GREEN}OK (FAT32/vfat found).${NC}"
  fi
else
    echo -e "${YELLOW}No partition found. Disk needs to be formatted.${NC}"
    NEEDS_FORMAT=1
fi

if [[ "$NEEDS_FORMAT" -eq 1 ]]; then
  echo -e "\n${YELLOW}Disk requires formatting.${NC}"
  format_the_disk
else
  echo -e "\n${GREEN}Disk is already formatted correctly. No changes needed.${NC}"
fi


echo "--> Creating folder '$FOLDER_TO_CREATE'..."
MOUNT_POINT=$(mktemp -d)
mount "$PARTITION" "$MOUNT_POINT"

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to mount the new partition.${NC}"
    rmdir "$MOUNT_POINT"
    exit 1
fi

mkdir "${MOUNT_POINT}/${FOLDER_TO_CREATE}"
echo "Folder created."

# --- DOWNLOAD--SAFETYPE--MOVE ---

echo -e "${GREEN} Formating completed. Starting downloading music...${NC}"

chmod +x "${DOWNLOAD_SCRIPT}"
if [[ ! -d ${MUSIC_FOLDER} ]]; then
    mkdir ${MUSIC_FOLDER}
fi

./"${DOWNLOAD_SCRIPT}" "${YOUTUBE_LINK}" "${MUSIC_FOLDER}"

echo -e "${GREEN} Download completed. Starting safetyping music names...${NC}"

chmod +x "${SAFETYPE_SCRIPT}"
if [[ ! -d ${SAFE_FOLDER} ]]; then
    mkdir ${MUSIC_FOLDER}
fi
./"${SAFETYPE_SCRIPT}" "${MUSIC_FOLDER}" "${SAFE_FOLDER}"

echo -e "${GREEN} Safetype completed. Starting moving music to the usab...${NC}"

shopt -s nullglob
rm -f "${MOUNT_POINT}/${FOLDER_TO_CREATE}/"*.mp3
shopt -u nullglob

chmod +x "${MOVE_SCRIPT}"
./"${MOVE_SCRIPT}" "${SAFE_FOLDER}" "${MOUNT_POINT}/${FOLDER_TO_CREATE}" "${NO_MELODIES}"

echo -e "${GREEN} Move completed. Starting cleanup...${NC}"


# --- Clean up ---
umount "$MOUNT_POINT"
rmdir "$MOUNT_POINT"

echo
echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN}Success! USB stick $DEVICE is ready for your car.${NC}"
echo -e "${GREEN}--------------------------------------------------${NC}"
fdisk -l "$DEVICE"

exit 0
