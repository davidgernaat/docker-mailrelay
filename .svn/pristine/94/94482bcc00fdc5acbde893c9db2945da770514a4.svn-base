myhostname = ${RELAY_HOSTNAME}
myorigin = ${RELAY_HOSTNAME}

# Disable chroot for container environment
queue_directory = /var/spool/postfix
daemon_directory = /usr/lib/postfix/sbin
command_directory = /usr/sbin
data_directory = /var/lib/postfix
mail_owner = postfix
mailq_path = /usr/bin/mailq
newaliases_path = /usr/bin/newaliases
sendmail_path = /usr/sbin/sendmail

# Disable chroot for all services

# Network configuration
mynetworks = 127.0.0.0/8

# Relay-only; no local delivery
mydestination =
relay_domains = ${RELAY_DOMAIN}
default_transport = smtp
relay_transport = smtp

# TLS for submission
smtpd_tls_security_level = encrypt
smtpd_tls_auth_only = yes
smtpd_tls_protocols = !SSLv2, !SSLv3
smtpd_tls_ciphers = high
smtpd_tls_exclude_ciphers = aNULL, eNULL, EXPORT, DES, RC4, MD5, PSK, SRP, CAMELLIA

# SASL configuration (enabled per-service in master.cf)
smtpd_sasl_type = cyrus
smtpd_sasl_path = smtpd

# Note: Port 465 (smtps) restrictions are handled in master.cf

# security: Rate limiting to prevent abuse
smtpd_client_connection_count_limit = 10
smtpd_client_connection_rate_limit = 10
smtpd_client_message_rate_limit = 10

# Required baseline relay policy to avoid fatal startup error
smtpd_relay_restrictions =
    permit_mynetworks,
    reject_unauth_destination

# Outbound TLS to other MXs
smtp_tls_security_level = may
smtp_tls_loglevel = 1
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt

# Store-and-forward map (optional)
transport_maps = hash:/etc/postfix/transport

# Queue management settings (configurable via environment variables)
maximal_queue_lifetime = ${MAXIMAL_QUEUE_LIFETIME}
bounce_queue_lifetime = ${BOUNCE_QUEUE_LIFETIME}

# Delivery attempt settings
maximal_backoff_time = ${MAXIMAL_BACKOFF_TIME}
minimal_backoff_time = ${MINIMAL_BACKOFF_TIME}

# Queue cleanup
queue_run_delay = ${QUEUE_RUN_DELAY}

# Resource limits to prevent DoS attacks
message_size_limit = 10485760
mailbox_size_limit = 0

# Connection limits (additional DoS protection)

# Process limits
smtpd_hard_error_limit = 5
smtpd_soft_error_limit = 2

# Ensure proper service communication
# These are handled automatically by Postfix

# Additional TLS settings for better compatibility
smtpd_tls_received_header = yes
smtpd_tls_session_cache_timeout = 3600s
tls_random_source = dev:/dev/urandom


