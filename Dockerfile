# Use Ubuntu Noble (24.04)
FROM ubuntu:noble

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Postfix and all necessary SASL/SSL modules
RUN apt-get update && apt-get install -y \
    postfix \
    libsasl2-modules \
    libsasl2-modules-db \
    libsasl2-2 \
    ca-certificates \
    sasl2-bin \
    && rm -rf /var/lib/apt/lists/*

# 2. Pre-configure Postfix with the Direct IP Fix
# - [142.251.10.108] is the stable IPv4 for smtp.gmail.com
# - smtp_tls_verify_cert_match = nexthop allows the IP to trust the Gmail SSL cert
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "inet_protocols = ipv4" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
    && postconf -e "smtp_tls_verify_cert_match = nexthop" \
    && postconf -e "maillog_file = /dev/stdout"

# 3. Start Postfix in the foreground
CMD ["/usr/sbin/postfix", "start-fg"]
