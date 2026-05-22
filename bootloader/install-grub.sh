#!/usr/bin/env bash

GRUB_INSTALL_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
if [[ -z "${LOG_FILE:-}" ]]; then
    source "${GRUB_INSTALL_SCRIPT_DIR}/../utils/logging.sh"
fi

install_grub() {
    log "Installing GRUB bootloader..."

    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck

    log "GRUB installed successfully"
}
