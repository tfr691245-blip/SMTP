# Use Ubuntu Noble (24.04)
FROM ubuntu:noble

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Postfix and all necessary SASL/SSL modules
# We include libsasl2-modules-db to ensure the SMTP plugin is physically present
RUN apt-get update && apt-get install -y \
    postfix \
    libsasl2-modules \
    libsasl2-modules-db \
    libsasl2-2 \
    ca-certificates \
    sasl2-bin \
    && rm -rf /var/lib/apt/lists/*

# 2. Pre-configure Postfix with all the fixes
# - Forces IPv4 to fix the "Host not found" (AAAA) error
# - Sets up Gmail Relay with your App Password
# - Configures TLS for secure transport
RUN postconf -e "relayhost = [smtp.gmail.com]:587" \
    && postconf -e "inet_protocols = ipv4" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
    && postconf -e "maillog_file = /dev/stdout"

# 3. Start Postfix in the foreground
# This keeps the Northflank worker alive and sends logs to the UI
CMD ["/usr/sbin/postfix", "start-fg"]
