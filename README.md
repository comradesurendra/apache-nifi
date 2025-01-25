# Apache NiFi Production Setup

## Table of Contents
- [Project Overview](#project-overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Security Setup](#security-setup)
- [Installation & Deployment](#installation--deployment)
- [Configuration](#configuration)
- [Monitoring & Management](#monitoring--management)
- [Troubleshooting](#troubleshooting)

## Project Overview
This project provides a production-ready Apache NiFi setup using Docker containers with clustering capabilities, security configurations, and performance optimizations. It includes MongoDB and MySQL connectivity support out of the box.

## Project Structure
```
apache-nifi/
├── docker-compose.yml    # Container orchestration configuration
├── Dockerfile            # NiFi image customization
├── security/             # SSL/TLS certificates and keys
│   ├── keystore.jks     # Java keystore for SSL/TLS
│   ├── truststore.jks   # Java truststore for SSL/TLS
│   └── nifi.crt         # NiFi certificate
├── data/                # Persistent data storage
│   ├── flow/            # NiFi flow configurations
│   ├── content/         # Flow file content repository
│   ├── database/        # H2 database files
│   ├── provenance/      # Provenance event records
│   └── state/           # Component state management
└── zookeeper-data/      # ZooKeeper data persistence
```

## Prerequisites
- Docker Engine (20.10.0 or later)
- Docker Compose (2.0.0 or later)
- Java keytool (for certificate generation)
- Minimum 8GB RAM available
- 4 CPU cores recommended

## Security Setup

### 1. Create Required Directories
```bash
# Clean up existing data (if any)
docker-compose down -v
rm -rf data security

# Create directory structure
mkdir -p security data/{flow,content,database,provenance,state}
cd security
```

### 2. Generate SSL Certificates
```bash
# Generate keystore
keytool -genkeypair -alias nifi -keyalg RSA -keysize 4096 \
  -keystore keystore.jks -validity 365 \
  -storepass keystorePassword -keypass keyPassword \
  -dname "CN=localhost"  # Change CN to match your domain

# Export certificate
keytool -exportcert -alias nifi -keystore keystore.jks \
  -storepass keystorePassword -file nifi.crt

# Import into truststore
keytool -importcert -alias nifi -file nifi.crt \
  -keystore truststore.jks -storepass truststorePassword \
  -noprompt
```

## Installation & Deployment

### 1. Build and Start Services
```bash
# Start NiFi and ZooKeeper containers
docker-compose up -d

# Monitor container startup
docker-compose logs -f
```

### 2. Access NiFi Interface
- Web UI: https://localhost:8443/nifi
- Default credentials:
  - Username: admin
  - Password: adminPassword123!
  
### 2.1 Obtain Access Token
```bash
docker-compose logs nifi --tail 100 2>&1 | grep -A 1 -B 1 "Generated Username"
```

## Configuration

### Key Environment Variables
```yaml
# HTTPS Configuration
NIFI_WEB_HTTPS_PORT: 8443
NIFI_SECURITY_KEYSTORE_PASSWD: keystorePassword
NIFI_SECURITY_KEY_PASSWD: keyPassword
NIFI_SECURITY_TRUSTSTORE_PASSWD: truststorePassword

# Authentication
NIFI_SECURITY_USER_LOGIN_IDENTITY_PROVIDER: single-user-provider
NIFI_SECURITY_USER_SINGLE_USER_CREDENTIALS_USERNAME: admin
NIFI_SECURITY_USER_SINGLE_USER_CREDENTIALS_PASSWORD: adminPassword123!

# Performance Tuning
NIFI_JVM_HEAP_INIT: 2g
NIFI_JVM_HEAP_MAX: 4g
```

### Clustering Configuration
```yaml
NIFI_CLUSTER_IS_NODE: true
NIFI_CLUSTER_NODE_PROTOCOL_PORT: 8082
NIFI_CLUSTER_NODE_ADDRESS: nifi
NIFI_ZK_CONNECT_STRING: zookeeper:2181
NIFI_ELECTION_MAX_WAIT: 1 min
```

## Monitoring & Management

### Health Checks
```bash
# Check NiFi system diagnostics
curl -k -H "Authorization: Bearer $TOKEN" https://localhost:8443/nifi-api/system-diagnostics

# View container logs
docker-compose logs nifi --tail 100
```

### Resource Management
- CPU Limits: 2.0 cores
- Memory Limits: 8GB
- Memory Reservations: 4GB

## Troubleshooting

### Common Issues
1. **Certificate Issues**
   - Verify CN matches the access URL
   - Check certificate permissions in container
   - Ensure truststore contains the correct certificate

2. **Connection Issues**
   - Verify ports are not in use
   - Check firewall settings
   - Ensure ZooKeeper is running for clustering

3. **Performance Issues**
   - Monitor JVM heap usage
   - Check system resources
   - Adjust container resource limits

### Accessing Logs
```bash
# View NiFi logs
docker-compose logs nifi --tail 100

# View ZooKeeper logs
docker-compose logs zookeeper
```

### Getting Support
- Official Documentation: https://nifi.apache.org/docs.html
- GitHub Issues: https://github.com/apache/nifi/issues
- NiFi Mailing Lists: https://nifi.apache.org/mailing_lists.html

