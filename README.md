# NiFi Docker Compose
```
nifi-production/
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

# yaml 
```
version: '3.8'
services:
  nifi:
    image: apache/nifi:2.1.0  # Tested stable version
    ports:
      - "8443:8443"
    environment:
      # HTTPS Configuration
      - NIFI_WEB_HTTPS_PORT=8443
      - NIFI_SECURITY_KEYSTORE=/opt/nifi/nifi-current/security/keystore.jks
      - NIFI_SECURITY_KEYSTORE_TYPE=JKS
      - NIFI_SECURITY_KEYSTORE_PASSWD=keystorePassword
      - NIFI_SECURITY_KEY_PASSWD=keyPassword
      
      # Single-User Auth (QUOTED VALUES)
      - NIFI_SECURITY_USER_LOGIN_IDENTITY_PROVIDER=single-user-provider
      - NIFI_SECURITY_USER_SINGLE_USER_CREDENTIALS_USERNAME="admin"
      - NIFI_SECURITY_USER_SINGLE_USER_CREDENTIALS_PASSWORD="adminPassword123!"  # Quoted password
      - NIFI_SENSITIVE_PROPS_KEY="mySuperSecretKey123!"  # Quoted key
      
      # Performance
      - NIFI_JVM_HEAP_MAX=4g
    volumes:
      - ./security:/opt/nifi/nifi-current/security
      - ./data:/opt/nifi/nifi-current/data
    networks:
      - nifi-net

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
docker-compose logs nifi | grep -i username
docker-compose logs nifi | grep -i password
``` 

# Get Flows
```
curl -k -H "Authorization: Bearer $TOKEN" https://localhost:8443/nifi-api/flows
```

