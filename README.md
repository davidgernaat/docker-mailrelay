# Host your own mail relay

🟢 This container is designed to function as a self-host mail relay provider.

Many people have port 25 blocked by their Internet Service Providers (ISPs). This port is essential for email and prevents many from hosting mail servers at home. 

A common solution is to setup an email-relay-account at some unknown email-relay-provider that sends and receives mail on your behalf. No solution really, given the reason you want to host a mail server in the first place.

With docker-mail-relay 🐳 you can host your own email-relay-provider at any vps that has port 25 open. All you have to do is point your home mail-server to your vps to circumvent your ISP.

Keep your family's privacy 🚀 Secure communications with family and friends. Host your own mail for the whole family in your own home. 📧

Now in technical terms, this container runs a minimal Postfix relay with SASL-authenticated submission (587/465) and a store-and-forward (mail-relay) service. It is tested in combination with the Docker-MailServer setup but probably works for other setups too (let me know if it does).

## General steps
1. This project assumes you have a running mailserver in your home. (e.g. Docker-MailServer)
2. Find out what is blocked: port 25 INBOUND or OUTBOUND (see below: ISP Port 25 Blocking)
3. Find a vps with port 25 open.
4. Run this docker-mailrelay on this vps (see below: Quick Start)
5. Point you home-mailserver to the vps docker-mailrelay
6. Open firewall ports and change DNS settings accordingly (see below: ISP Port 25 Blocking)

## Prerequisites
- ✅ VPS with open port 25 and rDNS (see section: Setting Up rDNS (Reverse DNS) for Your VPS)
- ✅ Docker installed
- ✅ Valid TLS certificates
- ✅ A running Docker-MailServer in your own home with at least one email account (https://github.com/docker-mailserver/docker-mailserver)
- ✅ All DNS records required for a mailserver: mail subdomain, MX, SPF, DKIM, and DMARC
- ✅ Read this blog post for setting up a mail sever with docker-mailserver: https://ifthenel.se/self-hosted-mail-server/

## Quick Start

On a VPS:

1) 📦 Install

```
git clone https://github.com/davidgernaat/docker-mailrelay
```

```
docker pull ghcr.io/davidgernaat/docker-mailrelay:latest
docker pull davidgernaat/docker-mailrelay:latest
```

2) 🔧 Copy valid certificates on the VPS (you already have them from you mail sever setup):

```
relay-docker/certs/fullchain.pem
relay-docker/certs/privkey.pem
```

3) 🔧 Configure according to INBOUND or OUTBOUND block.

First test port 25 (read below: Test inbound-outbound port 25 blocking)

Then implement (read: Solutions)

5) 🚀 Build & run:

```
cd docker-mailrelay
docker compose up -d --build
```

6) ℹ️ Test and track logs

Start tracking:

Terminal 1 - VPS logs:
```
sudo tail -f /var/log/mail.log
```

Terminal 2 - Home server logs
```
docker logs -f docker-mailserver
```

Now send an email from an external email provider to your email-domain and track logs.

Once receiving email works, send an email from your email-domain to an external email provider.

Done ✅


## ISP Port 25 Blocking

Many ISPs block port 25: inbound, outbound, or both. This docker-mailrelay container solves all three scenarios.

For your setup it is important to test whether INBOUND or OUTBOUND port 25 is blocked. Follow these steps.

### 🔧 Test inbound-outbound port 25 blocking

**Test outbound 25 (from your home to Internet):**
```bash
# From your home server
nc -vz gmail-smtp-in.l.google.com 25
# If it connects and shows 220 banner: outbound 25 is open
# If it times out: outbound 25 is blocked
```

**Test inbound 25 (from Internet to your home):**
```bash
# Find you home' public-ip
# Port forward home router: external 25 -> internal 25
# firewall: sudo ufw allow 25
# On your home mail server, start a temporary listener
sudo nc -l -p 25 -v
# From your VPS or external server
# firewall: sudo ufw allow 25
nc -vz YOUR_HOME_PUBLIC_IP 25
# If it connects: inbound 25 is open
# If it times out: inbound 25 is blocked
```

Write it down. 

Outbound block means that receiving mail at home works, but sending does not -> your vps must do the sending

Inbound block means that sending mail at home works, but receiving does not -> your vps must do the receiving

### Solutions

Now that you know whether INBOUND or OUTBOUND port 25 is blocked, follow these steps to setup your DNS records and firewall on your home server and your vps.

#### OUTBOUND-BLOCKED port 25 (Home → Internet)

Outbound block means that receiving mail at home works, but sending does not -> your vps must do the sending

**DNS changes:**
- ✅ A record: `relay.yourdomain.tld → VPS_IP` (no proxy)
- ✅ PTR record: VPS IP → `relay.yourdomain.tld` (no proxy)
- ❌ No MX record changes (keep existing MX pointing to home)

**VPS docker-mailrelay yaml-config:**
```
RELAY_HOSTNAME=relay.yourdomain.tld -> should match A and PTR records, and your TLS certificate.
RELAY_DOMAIN=yourdomain.tld
RELAY_USER=relay@yourdomain.tld -> Use his username-structure to fill change docker secrets.
RELAY_PASSWORD=CHANGE_ME -> RELAY_USER and RELAY_PASSWORD are defined in docker secrets
TLS_CERT_PATH=/certs/fullchain.pem
TLS_KEY_PATH=/certs/privkey.pem
```

**VPS Firewall:**
```bash
sudo ufw allow 465/tcp
sudo ufw allow 587/tcp
# Port 25 not required ( -> because receiving mail at home works)
```

**Home docker-mailserver config:**
```bash
# In docker-mailserver/mailserver.env
RELAY_HOST=relay.yourdomain.tld
RELAY_PORT=587
RELAY_USER=relay@yourdomain.tld
RELAY_PASSWORD=YOUR_PASSWORD
```

**Home docker-mailserver yaml-config:**
```bash
  - "25:25"    # SMTP  (explicit TLS => STARTTLS, Authentication is DISABLED => use port 465/587 instead)
  - "143:143"  # IMAP4 (explicit TLS => STARTTLS)
  - "465:465"  # ESMTP (implicit TLS)
  - "587:587"  # ESMTP (explicit TLS => STARTTLS)
  - "993:993"  # IMAP4 (implicit TLS)
```

**Home firewall:**
```bash
ufw allow 25
ufw allow 143
ufw allow 465
ufw allow 587
ufw allow 993
```

**Home router:**
```bash
 External 25  -> internal 25
 External 143 -> internal 143
 External 465 -> internal 465
 External 587 -> internal 587
 External 993 -> internal 993
```

#### INBOUND-BLOCKED port 25 (Internet → Home)

Inbound block means that sending mail at home works, but receiving does not -> your vps must do the receiving

**DNS changes:**
- ✅ A record: `relay.yourdomain.tld → VPS_IP` (no proxy)
- ✅ PTR record: VPS IP → `relay.yourdomain.tld` (no proxy)
- 🔄 MX record: Change to VPS
  ```
  MX 10 relay.yourdomain.tld
  ```

**VPS docker-mailrelay yaml-config:**
```
RELAY_HOSTNAME=relay.yourdomain.tld -> should match A and PTR records, and your TLS certificate.
RELAY_DOMAIN=yourdomain.tld
RELAY_USER=relay@yourdomain.tld -> Use his username-structure to fill change docker secrets.
RELAY_PASSWORD=CHANGE_ME -> RELAY_USER and RELAY_PASSWORD are defined in docker secrets
TLS_CERT_PATH=/certs/fullchain.pem
TLS_KEY_PATH=/certs/privkey.pem
# Fill in if port 25 INBOUND is blocked, otherwise leave empty
FORWARD_DOMAIN=yourdomain.tld
FORWARD_TARGET=mail.yourdomain.tld:2525 #DNS record must point to home-ip (without proxy)
```

**VPS Firewall:**
```bash
sudo ufw allow 25/tcp
sudo ufw allow 465/tcp
sudo ufw allow 587/tcp
```

**Home docker-mailserver yaml-config:**
  - "2525:25"  # SMTP  (explicit TLS => STARTTLS, Authentication is DISABLED => use port 465/587 instead)
  - "143:143"  # IMAP4 (explicit TLS => STARTTLS)
  - "465:465"  # ESMTP (implicit TLS)
  - "587:587"  # ESMTP (explicit TLS => STARTTLS)
  - "993:993"  # IMAP4 (implicit TLS)

**Home firewall:**
```bash
ufw allow 2525
ufw allow 143
ufw allow 465
ufw allow 587
ufw allow 993
# No need to open port 25 (inbound blocked anyway), limit exposure, also change port 25 to 2525 in the docker-compose.yaml
```

**Home router:**
```bash
 External 2525 -> internal 2525
 External 143 -> internal 143
 External 465 -> internal 465
 External 587 -> internal 587
 External 993 -> internal 993
```

#### Both 25 Blocked

If both INBOUND and OUTBOUND port 25 are blocked it means that both sending and receiving mail at home does not work -> your vps must do the sending and the receiving

Use both the INBOUND and OUTBOUND solutions, meaning: (1) implement the DNS changes including the MX, (2) fill in FORWARD_DOMAIN and FORWARD_TARGET in this docker-mailrelay yaml-file, (3) fill in the relay_host/ports/user/password in docker-mailserver environment-file, (4) open port 2525 at home and port 25 at vps.


## Environment Variables Configuration

This section explains all the environment variables available in `docker-compose.yaml` and how to configure them for your setup.

### 🔧 Basic Relay Configuration

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `RELAY_HOSTNAME` | DNS A record of the relay server (must match DNS A/PTR records and TLS certificate) | `relay.yourdomain.com` | ✅ |
| `RELAY_DOMAIN` | Domain allowed to relay through this server | `yourdomain.com` | ✅ |
| `TLS_CERT_PATH` | Path to TLS certificate inside container | `/certs/fullchain.pem` | ✅ |
| `TLS_KEY_PATH` | Path to TLS private key inside container | `/certs/privkey.pem` | ✅ |

### 🔐 Authentication Configuration

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `RELAY_USER_FILE` | Path to file containing SASL username (Docker secret) | `/run/secrets/relay_user` | ✅ |
| `RELAY_PASSWORD_FILE` | Path to file containing SASL password (Docker secret) | `/run/secrets/relay_password` | ✅ |

### 📧 Store-and-Forward Configuration

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `FORWARD_DOMAIN` | Domain to forward emails for (only if inbound port 25 is blocked) | `yourdomain.com` | Only when INBOUND port 25 is blocked |
| `FORWARD_TARGET` | Target mail server for forwarding (only if inbound port 25 is blocked) | `mail.yourdomain.com:2525` | Only when INBOUND port 25 is blocked |

### ⚡ Queue Management Configuration to keep exposure to a minmum

| Variable | Description | Default |
|----------|-------------|---------|
| `MAXIMAL_QUEUE_LIFETIME` | How long to keep emails in queue before deletion | `3d` |
| `BOUNCE_QUEUE_LIFETIME` | How long to keep bounce messages | `3d` |
| `MAXIMAL_BACKOFF_TIME` | Maximum wait between delivery attempts | `4000s` |
| `MINIMAL_BACKOFF_TIME` | Minimum wait between delivery attempts | `1000s` |
| `QUEUE_RUN_DELAY` | How often to check the queue | `1000s` |


## Test SASL connection:

Test connection between vps and home mail server via SASL authentication on port 587:

On vps, have docker-mailrelay running with a sasl username and password.

On home email server:

First generate base64 username and password:
```
printf '\0YOURRELAYUSERNAME@relay.yourdomain.tld\0YOURRELAYPASSWORD' | base64 -w0
```

Connect:
```
openssl s_client -starttls smtp -connect relay.yourdomain.tld:587 -crlf -quiet
```

Then type:
```
EHLO test.local
```

Then type:
```
AUTH LOGIN THEGENERATEDBASE64STRING
```

## Setting Up rDNS (Reverse DNS) for Your VPS

Reverse DNS (rDNS) is **critical** for mail servers. Without proper rDNS, most mail servers will reject your emails or mark them as spam.

### 🔍 What is rDNS?

rDNS maps your VPS IP address back to your domain name. When other mail servers receive email from your relay, they check:
- **Forward DNS**: Does `relay.yourdomain.tld` resolve to your VPS IP? ✓
- **Reverse DNS**: Does your VPS IP resolve back to `relay.yourdomain.tld`? ✓

Both must match!

### ✅ Why It's Required

- **Email Deliverability**: Gmail, Outlook, and other providers require valid rDNS
- **Spam Prevention**: Servers without rDNS are often blocked
- **Reputation**: Proper rDNS shows you're a legitimate mail server

### 🔧 How to Set Up rDNS

**Step 1: Create a new A record subdomain**

```bash
relay.yourdomain.tld.
```

**Step 2: Set rDNS in Your VPS Provider's Control Panel**

The process varies by provider:
- Look for: "Reverse DNS", "PTR Record", or "rDNS" in your control panel
- Contact support if you can't find it - all reputable VPS providers support this

**Step 3: ✅ Verify**

After setting up, verify it works:

```bash
$ dig -x 1.2.3.4 +short
relay.yourdomain.tld.

$ dig relay.yourdomain.tld +short
1.2.3.4
```

Both directions must match!

### ⚠️ Important Notes

- **DNS Propagation**: rDNS changes can take 1-24 hours to propagate
- **Match Your Certificate**: The rDNS should match your TLS certificate hostname
- **One IP per hostname**: Each IP can only have one rDNS entry
- **Required for port 25**: If you're receiving email (port 25 open), rDNS is mandatory

## Security Features

This mail relay includes several security measures to protect against abuse:

### 🔐 Authentication & Access Control
- **SASL Authentication**: All email submission requires valid username/password authentication
- **TLS Encryption**: All connections use encrypted TLS/SSL to protect credentials and email content
- **IP-based Rate Limiting**: Prevents single IP addresses from overwhelming the server

### 🛡️ Rate Limiting Protection (Postfix anvil)
Rate limiting means setting limits to the amount of user/connetions/messages can be active at the same time. This relay uses Postfix’s built‑in anvil service for rate limiting. Anvil is a small Postfix service that keeps counters for client events (connections, messages, errors) and makes those counters available to smtpd processes. The smtpd limits above use those counters to throttle abusive clients without any external services or custom code.

- **Concurrent connection limit** (`smtpd_client_connection_count_limit`): Max simultaneous SMTP connections per client IP (default here: 10)
- **Connection rate limit** (`smtpd_client_connection_rate_limit`): Max new connections per minute per client IP (default here: 10)
- **Message rate limit** (`smtpd_client_message_rate_limit`): Max messages per minute per client IP (default here: 10)

These defaults are set in `files/main.cf.tpl` and apply to both port 25 and 465.

**Why this matters**: Without rate limiting, malicious actors could:
- Launch brute force attacks to guess passwords
- Flood your server with thousands of connection attempts
- Send massive amounts of spam through your relay
- Overwhelm your server resources and make it unusable

### 🔒 Container Security
- **Capability Dropping**: All unnecessary Linux capabilities are dropped (`CAP_DROP: ALL`)
- **Minimal Capabilities**: Only essential capabilities are added (CHOWN, SETGID, SETUID, NET_BIND_SERVICE, etc.)
- **Docker Secrets**: Sensitive credentials stored securely using Docker secrets instead of environment variables
- **Isolated Network**: Custom Docker network with dedicated IPAM subnet (172.20.0.0/16) for network isolation
- **Read-only Volumes**: Certificate files mounted read-only to prevent tampering

### 🛡️ Resource Protection
The relay includes resource limits to prevent resource exhaustion attacks:

- **Memory Limits**: Maximum 512MB memory usage (128MB reserved)
- **CPU Limits**: Maximum 1 CPU core (0.1 core reserved)
- **Process Limits**: Maximum 100 processes per container
- **File Descriptor Limits**: Maximum 1024 open files
- **Memory Lock Limits**: Prevents excessive memory locking

**Why this matters**: Without resource limits, attackers could:
- Exhaust server memory and crash the system
- Consume all CPU resources making the server unresponsive
- Create thousands of processes to overwhelm the system
- Open unlimited file handles to exhaust system resources

### 🌐 Network Security
- **Port Separation**: Different ports for different purposes (25 for receiving, 587/465 for sending)
- **Firewall Integration**: Designed to work with standard firewall rules
- **Docker Network Isolation**: Custom bridge network with dedicated subnet prevents direct access to other containers
- **Temporary Filesystems**: `/tmp` and `/var/run` use tmpfs for better security and performance

**Why this helps**: These features ensure your mail relay:
- Stays online and responsive even under attack
- Protects your reputation by preventing spam abuse
- Maintains reliable email delivery for legitimate users
- Prevents attackers from accessing other services on your VPS

## Files
- `Dockerfile`: Debian 12 + Postfix + Cyrus SASL
- `files/main.cf.tpl`: Postfix main config (templated with env)
- `files/master.cf`: Enables smtp(25), submission(587), smtps(465)
- `files/smtpd.conf`: Cyrus SASL (PLAIN/LOGIN via sasldb)
- `files/transport.tpl`: Optional store-and-forward template
- `files/whitelist.tpl`: IP whitelist template for trusted IPs
- `files/entrypoint.sh`: Renders configs, creates SASL user, starts services
- `files/entrypoint.sh.backup`: Backup of original entrypoint script
- `docker-compose.yaml`: Orchestration

## Credits

- [docker-mailserver](https://github.com/docker-mailserver/docker-mailserver)
- [Postfix](https://www.postfix.org/)
- [ifthen:else blog post](https://ifthenel.se/self-hosted-mail-server/)

