# Use the official Apache NiFi image
FROM apache/nifi:2.1.0

# Copy custom TLS certificates (optional; better to use volumes)
COPY security/keystore.jks /opt/nifi/nifi-current/security/
COPY security/truststore.jks /opt/nifi/nifi-current/security/

# Add custom NiFi NAR files (e.g., processors)
COPY custom-nars/*.nar /opt/nifi/nifi-current/lib/
