#!/bin/bash

# --- CONFIGURATION ---
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found!"
    exit 1
fi

if [ "$USE_NAS" != "true" ]; then
    echo "USE_NAS is false. Skipping mount logic."
    exit 0
fi

# --- PRE-FLIGHT CHECKS ---
if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root (sudo)."
    exit 1
fi

echo "Checking for required tools..."
if [[ "${PROTOCOL}" == "nfs" ]]; then
    apt-get update && apt-get install -y nfs-common
else
    apt-get update && apt-get install -y cifs-utils
fi

# --- PREPARE MOUNT POINT ---
if [ ! -d "${STORAGE_ROOT}" ]; then
    echo "Creating directory ${STORAGE_ROOT}..."
    mkdir -p "${STORAGE_ROOT}"
    # Ensure your Docker user (usually 1000:1000) can write here
    chown ${PUID}:${PGID} "${STORAGE_ROOT}"
fi

# --- BACKUP FSTAB ---
cp /etc/fstab /etc/fstab.bak
echo "Backup of /etc/fstab created at /etc/fstab.bak"

# --- CONSTRUCT FSTAB LINE ---
if [[ "${PROTOCOL}" == "nfs" ]]; then
    # NFS Line: optimized for high-speed media streaming
    FSTAB_LINE="${NAS_IP}:${NAS_EXPORT}  ${STORAGE_ROOT}  nfs  defaults,soft,intr,bg,timeo=14,x-systemd.automount 0 0"
else
    # Samba/CIFS Line
    FSTAB_LINE="//${NAS_IP}/${NAS_EXPORT}  ${STORAGE_ROOT}  cifs  username=${SMB_USER},password=${SMB_PASS},iocharset=utf8,uid=${PUID},gid=${PGID} 0 0"
fi

# --- APPLY CHANGES ---
if grep -q "${STORAGE_ROOT}" /etc/fstab; then
    echo "Warning: ${STORAGE_ROOT} is already defined in /etc/fstab. Skipping append."
else
    echo "Adding mount to /etc/fstab..."
    echo "${FSTAB_LINE}" >> /etc/fstab
fi

echo "Attempting to mount..."
mount -a

if mountpoint -q "${STORAGE_ROOT}"; then
    echo "SUCCESS: NAS is mounted at ${STORAGE_ROOT}"
else
    echo "ERROR: Mount failed. Check 'dmesg' or your NAS permissions."
    exit 1
fi