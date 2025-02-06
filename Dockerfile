# Use the official Apache NiFi image
FROM apache/nifi:1.28.1

# Switch to root for package installation
USER root

# Install wget, download drivers, and clean up
RUN mkdir -p /var/lib/apt/lists/partial && \
    apt-get update && \
    apt-get install -y wget && \
    # Download MongoDB Java drivers
    wget -P /opt/nifi/nifi-current/lib/ \
    https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-sync/5.3.1/mongodb-driver-sync-5.3.1.jar && \
    wget -P /opt/nifi/nifi-current/lib/ \
    https://repo1.maven.org/maven2/org/mongodb/bson/5.3.1/bson-5.3.1.jar && \
    wget -P /opt/nifi/nifi-current/lib/ \
    https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-core/5.3.1/mongodb-driver-core-5.3.1.jar && \
    # Download MySQL JDBC driver
    wget -P /opt/nifi/nifi-current/lib/ \
    https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/9.2.0/mysql-connector-j-9.2.0.jar && \
    # Ensure NiFi user owns the files
    chown -R nifi:nifi /opt/nifi/nifi-current/lib/ && \
    # Clean up
    apt-get purge -y wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy custom TLS certificates (optional; better to use volumes)
COPY security/keystore.jks /opt/nifi/nifi-current/security/
COPY security/truststore.jks /opt/nifi/nifi-current/security/

# Ensure proper permissions for security files
USER root
RUN chown -R nifi:nifi /opt/nifi/nifi-current/security/
USER nifi
