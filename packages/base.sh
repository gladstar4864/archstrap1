#!/usr/bin/env bash

# Source required utilities
BASE_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
if [[ -z "${LOG_FILE:-}" ]]; then
    source "${BASE_SCRIPT_DIR}/../utils/logging.sh"
fi

# Install base system
install_base_system() {
    log "Installing base system..."

    local bootloader="${BOOTLOADER:-grub}"
    local bootloader_packages
    local ucode_pkg

    case "${bootloader}" in
        "grub")
            bootloader_packages="grub grub-btrfs inotify-tools os-prober efibootmgr"
            ;;
        "refind")
            bootloader_packages="refind os-prober efibootmgr"
            ;;
        *)
            fatal_error "Unsupported bootloader: ${bootloader}"
            ;;
    esac

    case "$(awk -F': ' '/vendor_id/ {print $2; exit}' /proc/cpuinfo)" in
        "AuthenticAMD")
            CPU_VENDOR="amd"
            ucode_pkg="amd-ucode"
            ;;
        "GenuineIntel")
            CPU_VENDOR="intel"
            ucode_pkg="intel-ucode"
            ;;
        *)
            CPU_VENDOR="intel"
            ucode_pkg="intel-ucode"
            warning "Unknown CPU vendor; defaulting to Intel microcode"
            ;;
    esac

    export CPU_VENDOR

    pacstrap -K /mnt base base-devel linux linux-headers linux-lts linux-lts-headers \
             linux-firmware lvm2 vim git networkmanager ${bootloader_packages} \
             iwd "${ucode_pkg}" curl reflector --noconfirm --ask=4
}
