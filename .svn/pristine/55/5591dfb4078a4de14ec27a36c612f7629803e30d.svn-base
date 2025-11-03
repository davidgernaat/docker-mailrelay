#!/bin/bash
set -euo pipefail

# Copy template files to /etc/postfix directory
cp -r /etc/postfix.templates/* /etc/postfix/ 2>/dev/null || true

# Render main.cf from template
envsubst < /etc/postfix/main.cf.tpl > /etc/postfix/main.cf

# Render transport (optional)
if [[ -n "${FORWARD_DOMAIN:-}" && -n "${FORWARD_TARGET:-}" ]]; then
  envsubst < /etc/postfix/maps/transport.tpl > /etc/postfix/transport
  postmap /etc/postfix/transport || true
fi

# Render IP whitelist
envsubst < /etc/postfix/maps/whitelist.tpl > /etc/postfix/whitelist
postmap /etc/postfix/whitelist || true

# Set up rate limiting
#chmod +x /etc/postfix/rate_limits.sh
#mkdir -p /etc/postfix/rate_limits

# Ensure certs exist
if [[ -n "${TLS_CERT_PATH:-}" && -n "${TLS_KEY_PATH:-}" ]]; then
  if [[ ! -f "${TLS_CERT_PATH}" || ! -f "${TLS_KEY_PATH}" ]]; then
    echo "TLS cert/key not found at paths: ${TLS_CERT_PATH} / ${TLS_KEY_PATH}" >&2
    exit 1
  fi
fi

# Create SASL user if provided (from secrets)
if [[ -f "${RELAY_USER_FILE:-}" && -f "${RELAY_PASSWORD_FILE:-}" ]]; then
  RELAY_USER=$(cat "${RELAY_USER_FILE}")
  RELAY_PASSWORD=$(cat "${RELAY_PASSWORD_FILE}")
  export RELAY_USER RELAY_PASSWORD
  echo "Creating/updating SASL user ${RELAY_USER}"
  
  # Create SASL user in default location (saslauthd looks here)
  echo -n "${RELAY_PASSWORD}" | saslpasswd2 -p -c -u "${RELAY_HOSTNAME}" "${RELAY_USER}" || true
  chown root:sasl /etc/sasldb2
  chmod 640 /etc/sasldb2
  adduser postfix sasl >/dev/null 2>&1 || true
fi

# Start rsyslog for logging
rsyslogd -n &

# Start saslauthd for SASL authentication
saslauthd -a sasldb -d &

# Ensure proper entropy for TLS
if [[ ! -c /dev/urandom ]]; then
  echo "=========================================="
  echo "WARNING: /dev/urandom not available!"
  echo "TLS operations may fail or be insecure."
  echo "=========================================="
  echo ""
  echo "SOLUTION STEPS:"
  echo "1. Add device mount to docker-compose.yaml:"
  echo "   devices:"
  echo "     - /dev/urandom:/dev/urandom:ro"
  echo ""
  echo "2. Restart the container:"
  echo "   docker compose down && docker compose up -d"
  echo ""
  echo "3. Verify the fix:"
  echo "   docker logs relay-postfix"
  echo "   (should not show this warning)"
  echo ""
  echo "4. Test TLS functionality:"
  echo "   openssl s_client -starttls smtp -connect yourdomain.tld:587"
  echo ""
  echo "Without proper entropy, email relay may fail authentication!"
  echo "=========================================="
fi

# Start postfix with all required services
postfix start

trap 'postfix stop; killall saslauthd; killall rsyslogd; exit 0' SIGTERM SIGINT

# Start log monitoring (create log file if it doesn't exist)
touch /var/log/mail.log
tail -F /var/log/mail.log


