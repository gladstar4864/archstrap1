#!/usr/bin/env bash

# Source required utilities
LOCALE_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
if [[ -z "${LOG_FILE:-}" ]]; then
    source "${LOCALE_SCRIPT_DIR}/../../utils/logging.sh"
fi

# Configure system locale
# Uses SECONDARY_LANGUAGE variable set by select_secondary_language() in inputs.sh
configure_locale() {
    log "Configuring system locale..."
    
    # Always enable English (US)
    sed -i 's|#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|' /mnt/etc/locale.gen
    
    # Enable secondary language if selected
    if [[ -n "${SECONDARY_LANGUAGE:-}" ]]; then
        log "Enabling secondary locale: ${SECONDARY_LANGUAGE}"
        
        # The locale pattern in locale.gen is "locale_code charset"
        # e.g., "de_DE.UTF-8 UTF-8"
        local locale_pattern="${SECONDARY_LANGUAGE} UTF-8"
        
        # Enable the selected locale in locale.gen
        if grep -q "^#${locale_pattern}$" /mnt/etc/locale.gen; then
            sed -i "s|^#${locale_pattern}$|${locale_pattern}|" /mnt/etc/locale.gen
            log "Secondary locale ${SECONDARY_LANGUAGE} enabled"
        elif grep -q "^#${locale_pattern} " /mnt/etc/locale.gen; then
            # Handle case with trailing spaces
            sed -i "s|^#${locale_pattern} |${locale_pattern} |" /mnt/etc/locale.gen
            log "Secondary locale ${SECONDARY_LANGUAGE} enabled"
        else
            warning "Locale ${SECONDARY_LANGUAGE} not found in locale.gen"
        fi
    else
        log "No secondary language selected - English only"
    fi
    
    # Generate locales
    arch-chroot /mnt locale-gen
    
    # Set primary language to English
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
    
    log "Locale configuration completed"
}