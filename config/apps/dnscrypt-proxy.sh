#!/usr/bin/env bash

# Source required utilities
DNSCRYPT_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${DNSCRYPT_SCRIPT_DIR}/../../utils/logging.sh"

# Configure dnscrypt-proxy
configure_dnscrypt_proxy() {
    log "Configuring dnscrypt-proxy..."
    
    # Create chroot script for dnscrypt-proxy configuration
    cat > /mnt/configure_dnscrypt.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "#################### Configure dnscrypt-proxy ####################"
sudo sed -i -e 's|# blocked_names_file|blocked_names_file|' \
       -e 's|doh_servers = true|doh_servers = false|' \
       -e 's|require_dnssec = false|require_dnssec = true|' \
       -e 's|skip_incompatible = false|skip_incompatible = true|' \
       -e '/skip_incompatible = true/i\routes = [\
    { server_name='\''*'\'' , via=['\''*'\'' ] },\
]\
' \
       -e 's|^# log_file = '\''/var/log/dnscrypt-proxy/blocked-names.log'\''|log_file = '\''/var/log/dnscrypt-proxy/blocked-names.log'\''|' \
       -e 's|^# file = '\''/var/log/dnscrypt-proxy/query.log'\''|file = '\''/var/log/dnscrypt-proxy/query.log'\''|' \
       -e 's|^# log_file = '\''/var/log/dnscrypt-proxy/blocked-ips.log'\''|log_file = '\''/var/log/dnscrypt-proxy/blocked-ips.log'\''|' \
       -e '/\[monitoring_ui\]/,/^\[/{s|^enabled = false|enabled = true|}' \
       -e '/\[monitoring_ui\]/,/^\[/{s|^listen_address = "127.0.0.1:8080"|listen_address = "127.0.0.1:5380"|}' \
       -e '/\[monitoring_ui\]/,/^\[/{s|^username = "admin"|username = ""|}' \
       -e '/\[monitoring_ui\]/,/^\[/{s|^password = "changeme"|password = ""|}' \
       -e '/\[monitoring_ui\]/,/^\[/{s|^privacy_level = 1|privacy_level = 0|}' \
       /etc/dnscrypt-proxy/dnscrypt-proxy.toml

echo "dnscrypt-proxy configuration completed!"
EOF

    chmod +x /mnt/configure_dnscrypt.sh
    arch-chroot /mnt ./configure_dnscrypt.sh || error "Failed to configure dnscrypt-proxy!"
    rm -f /mnt/configure_dnscrypt.sh
    
    # Add the resolvconf-dnscrypt-proxy systemd service
    add_resolvconf_dnscrypt_proxy_systemd_service
}

# Add resolvconf-dnscrypt-proxy systemd service
add_resolvconf_dnscrypt_proxy_systemd_service() {
    log "Adding resolvconf-dnscrypt-proxy systemd service..."
    
    # Create resolvconf-dnscrypt-proxy service
    cat > /mnt/etc/systemd/system/resolvconf-dnscrypt-proxy.service << 'EOF'
[Unit]
Description=systemd service for setting /etc/resolv.conf based on dnscrypt-proxy requirements

[Service]
ExecStart=/usr/bin/bash -c '/usr/bin/echo -e "nameserver ::1\nnameserver 127.0.0.1\noptions edns0 single-request-reopen" | /usr/bin/resolvconf -a dnscrypt; /usr/bin/resolvconf -u'

[Install]
WantedBy=multi-user.target
EOF
    
    log "resolvconf-dnscrypt-proxy systemd service added successfully"
}
