FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    postfix \
    libsasl2-modules \
    sasl2-bin \
    gettext-base \
    ca-certificates \
    tzdata \
    nano \
    rsyslog \
 && rm -rf /var/lib/apt/lists/*

# Prepare directories
RUN mkdir -p /etc/postfix/sasl /docker-entrypoint.d /etc/postfix/maps /certs

COPY files/main.cf.tpl /etc/postfix/main.cf.tpl
COPY files/master.cf /etc/postfix/master.cf
COPY files/smtpd.conf /etc/postfix/sasl/smtpd.conf
COPY files/transport.tpl /etc/postfix/maps/transport.tpl
COPY files/whitelist.tpl /etc/postfix/maps/whitelist.tpl
COPY files/entrypoint.sh /entrypoint.sh

# Configure saslauthd to use sasldb instead of pam
RUN sed -i 's/MECHANISMS="pam"/MECHANISMS="sasldb"/' /etc/default/saslauthd

RUN chmod +x /entrypoint.sh

EXPOSE 25 465 587

STOPSIGNAL SIGTERM

CMD ["/entrypoint.sh"]

