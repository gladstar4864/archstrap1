#!/usr/bin/env bash

if [[ -z "${LOG_FILE:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
fi

# Check system prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if boot type is UEFI
    if [[ ! -d /sys/firmware/efi/efivars ]]; then
        fatal_error "Boot type is not UEFI!"
    fi
    
    # Check internet connection
    if ! ping -q -c 1 archlinux.org >/dev/null 2>&1; then
        fatal_error "No internet connection!"
    fi
    
    # Check and install required packages
    local required_packages=("dialog" "git")
    local packages_to_install=()
    
    # Check which packages are missing
    for package in "${required_packages[@]}"; do
        if ! command -v "$package" >/dev/null 2>&1; then
            packages_to_install+=("$package")
        fi
    done
    
    # Install missing packages
    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        log "Installing required packages: ${packages_to_install[*]}"
        pacman -Sy --noconfirm "${packages_to_install[@]}"
    fi
    
    log "Prerequisites check passed"
}
