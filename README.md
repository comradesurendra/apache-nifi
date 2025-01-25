# Apache Nifi Production Setup
```
apache-nifi/
├── docker-compose.yml
├── Dockerfile
├── security/
├── data/
│   ├── flow/
│   ├── content/
│   ├── database/
│   ├── provenance/
│   └── state/
```

# Stop and remove all containers/volumes
```
docker-compose down -v
```

# Delete all local data/certs
```
rm -rf data security
```

# Recreate directory structure
```
mkdir -p security data/{flow,content,database,provenance,state}
cd security
```


# Generate keystore with "localhost" as CN (critical for local development)
```
keytool -genkeypair -alias nifi -keyalg RSA -keysize 4096 \
  -keystore keystore.jks -validity 365 \
  -storepass keystorePassword -keypass keyPassword \
  -dname "CN=localhost"  # <<< MUST match your access URL
```

# Generate truststore (optional but recommended)
```
keytool -exportcert -alias nifi -keystore keystore.jks -storepass keystorePassword -file nifi.crt
keytool -import -file nifi.crt -alias nifi -keystore truststore.jks -storepass truststorePassword -noprompt 
```
# Dockerfile
``` 
# Use the official Apache NiFi image
FROM apache/nifi:2.1.0

# Switch to root for package installation
USER root

# Install wget, download drivers, and clean up
RUN mkdir -p /var/lib/apt/lists/partial && \
    apt-get update && \
    apt-get install -y wget && \
    # Download MongoDB Java drivers
    wget -P /opt/nifi/nifi-current/lib/ \
    https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-sync/4.11.0/mongodb-driver-sync-4.11.0.jar && \
    wget -P /opt/nifi/nifi-current/lib/ \
    https://repo1.maven.org/maven2/org/mongodb/bson/4.11.0/bson-4.11.0.jar && \
    wget -P /opt/nifi/nifi-current/lib/ \
    https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-core/4.11.0/mongodb-driver-core-4.11.0.jar && \
    # Download MySQL JDBC driver
    wget -P /opt/nifi/nifi-current/lib/ \
    https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar && \
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
```

# compose yaml file 
```
version: "3.8"
services:
  nifi:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8443:8443"
      - "8080:8080"
    environment:
      # HTTPS Configuration
      - NIFI_WEB_HTTPS_PORT=8443
      - NIFI_SECURITY_KEYSTORE=/opt/nifi/nifi-current/security/keystore.jks
      - NIFI_SECURITY_KEYSTORE_TYPE=JKS
      - NIFI_SECURITY_KEYSTORE_PASSWD=keystorePassword
      - NIFI_SECURITY_KEY_PASSWD=keyPassword
      - NIFI_SECURITY_TRUSTSTORE=/opt/nifi/nifi-current/security/truststore.jks
      - NIFI_SECURITY_TRUSTSTORE_TYPE=JKS
      - NIFI_SECURITY_TRUSTSTORE_PASSWD=truststorePassword

      # Single-User Auth
      - NIFI_SECURITY_USER_LOGIN_IDENTITY_PROVIDER=single-user-provider
      - NIFI_SECURITY_USER_SINGLE_USER_CREDENTIALS_USERNAME=admin
      - NIFI_SECURITY_USER_SINGLE_USER_CREDENTIALS_PASSWORD=adminPassword123!
      - NIFI_SENSITIVE_PROPS_KEY=mySuperSecretKey123!

      # Clustering Configuration
      - NIFI_CLUSTER_IS_NODE=true
      - NIFI_CLUSTER_NODE_PROTOCOL_PORT=8082
      - NIFI_CLUSTER_NODE_ADDRESS=nifi
      - NIFI_ZK_CONNECT_STRING=zookeeper:2181
      - NIFI_ELECTION_MAX_WAIT=1 min

      # Performance and Resource Management
      - NIFI_JVM_HEAP_INIT=2g
      - NIFI_JVM_HEAP_MAX=4g
      - NIFI_WEB_HTTP_HOST=0.0.0.0
      - NIFI_FLOWFILE_REPOSITORY_ALWAYS_SYNC=true
    volumes:
      - ./security:/opt/nifi/nifi-current/security
      - ./data:/opt/nifi/nifi-current/data
    networks:
      - nifi-net
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 8G
        reservations:
          cpus: '1.0'
          memory: 4G
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
    healthcheck:
      test: ["CMD", "curl", "-k", "-f", "https://localhost:8443/nifi-api/system-diagnostics"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 45s
    depends_on:
      - zookeeper

  zookeeper:
    image: zookeeper:3.8
    ports:
      - "2181:2181"
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=zookeeper:2888:3888;2181
    volumes:
      - ./zookeeper-data:/data
      - ./zookeeper-datalog:/datalog
    networks:
      - nifi-net
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
    healthcheck:
      test: ["CMD", "zkServer.sh", "status"]
      interval: 30s
      timeout: 10s
      retries: 5

networks:
  nifi-net:
    driver: bridge
```

# Run Docker Compose
```
docker-compose up -d
```

# Get Username and Password
```
docker-compose logs nifi --tail 100 2>&1 | grep -A 1 -B 1 "Generated Username"
``` 

# Get Flows
```
curl -k -H "Authorization: Bearer $TOKEN" https://localhost:8443/nifi-api/flows
```

