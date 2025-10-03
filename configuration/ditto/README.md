# Eclipse Ditto Configuration

This directory contains configuration files for Eclipse Ditto digital twin platform integration with DigitalEgiz.

## Deployment

Eclipse Ditto is deployed as a **separate Docker Compose stack** to ensure stability and proper cluster formation.

### Initial Setup

1. **Update your `.env` file** with Ditto credentials:
```bash
cp .env.example .env
# Edit .env and set:
# - DITTO_VERSION=3.5.11
# - MONGO_INITDB_ROOT_USERNAME=ditto
# - MONGO_INITDB_ROOT_PASSWORD=your-secure-password
# - DITTO_DEVOPS_PASSWORD=your-devops-password
# - DITTO_USER=ditto
# - DITTO_PASSWORD=your-ditto-password
# - DOMAIN=your-domain.com
```

2. **Create htpasswd file** for nginx authentication:
```bash
cd configuration/ditto
chmod +x create-htpasswd.sh
./create-htpasswd.sh
cd ../..
```

3. **Start Ditto services**:
```bash
docker-compose -f docker-compose.ditto.yml up -d
```

4. **Verify all services are running**:
```bash
docker-compose -f docker-compose.ditto.yml ps
```

Wait 1-2 minutes for all services to fully initialize and form the cluster.

5. **Check logs** if needed:
```bash
docker-compose -f docker-compose.ditto.yml logs -f ditto-gateway
```

### Accessing Ditto

- **Web UI**: `https://ditto.${DOMAIN}`
- **HTTP API**: `https://ditto.${DOMAIN}/api`
- **WebSocket**: `wss://ditto.${DOMAIN}/ws`
- **DevOps API**: `https://ditto.${DOMAIN}/devops`
- **Status**: `https://ditto.${DOMAIN}/status` (no auth)

**Login credentials**: Use `DITTO_USER` and `DITTO_PASSWORD` from your `.env` file.

## Architecture

```
Internet → Traefik (HTTPS/SSL) → Ditto Nginx → Ditto Gateway → Ditto Services
                                             → Ditto UI

Ditto Services Cluster:
- ditto-policies      (Authorization)
- ditto-things        (Digital Twin State)
- ditto-things-search (Search Engine)
- ditto-connectivity  (MQTT/External Integrations)
- ditto-gateway       (API Entry Point)
- mongodb             (Database)
```

All Ditto microservices form a cluster using the `ditto-cluster` network alias for internal communication.

## MQTT Integration

### ChirpStack → Ditto Connection

To create a connection between ChirpStack (via Mosquitto MQTT) and Ditto:

#### 1. Create the MQTT Connection

```bash
curl -X POST \
  https://ditto.${DOMAIN}/devops/piggyback/connectivity \
  -H 'Content-Type: application/json' \
  -u ditto:your-password \
  -d @configuration/ditto/mqtt-connection-template.json
```

#### 2. Verify Connection Status

```bash
curl -X GET \
  https://ditto.${DOMAIN}/api/2/connections \
  -u ditto:your-password
```

### Connection Details

**Source (ChirpStack → Ditto):**
- Topic: `application/+/device/+/event/up`
- Listens to all ChirpStack uplink messages
- Automatically creates/updates digital twins based on device data

**Target (Ditto → ChirpStack):**
- Topic: `application/{{ thing:namespace }}/device/{{ thing:name }}/command/down`
- Sends commands from digital twins to physical devices
- Supports twin events and live messages

### Example: Creating a Digital Twin

```bash
curl -X PUT \
  https://ditto.${DOMAIN}/api/2/things/org.digitalegiz:sensor-001 \
  -H 'Content-Type: application/json' \
  -u ditto:your-password \
  -d '{
    "policyId": "org.digitalegiz:sensor-policy",
    "attributes": {
      "location": "Office",
      "type": "temperature-sensor"
    },
    "features": {
      "temperature": {
        "properties": {
          "value": 0,
          "unit": "celsius"
        }
      }
    }
  }'
```

## Managing Ditto

### Start/Stop Services

```bash
# Start
docker-compose -f docker-compose.ditto.yml up -d

# Stop
docker-compose -f docker-compose.ditto.yml down

# Restart
docker-compose -f docker-compose.ditto.yml restart

# View logs
docker-compose -f docker-compose.ditto.yml logs -f
```

### Updating Ditto

1. Update `DITTO_VERSION` in `.env`
2. Pull new images and restart:
```bash
docker-compose -f docker-compose.ditto.yml pull
docker-compose -f docker-compose.ditto.yml up -d
```

## Troubleshooting

### Services not forming cluster
- Wait 2-3 minutes after startup
- Check logs: `docker-compose -f docker-compose.ditto.yml logs`
- Ensure all services have `ditto-cluster` network alias

### 502 Bad Gateway
- Verify nginx is running: `docker ps | grep ditto-nginx`
- Check gateway is healthy: `curl -u ditto:pass https://ditto.${DOMAIN}/status`
- Review nginx logs: `docker logs digitalegiz-ditto-nginx`

### Authentication issues
- Regenerate htpasswd: `cd configuration/ditto && ./create-htpasswd.sh`
- Verify credentials in `.env` file

## Further Reading

- [Eclipse Ditto Documentation](https://www.eclipse.dev/ditto/)
- [Ditto HTTP API](https://www.eclipse.dev/ditto/httpapi-overview.html)
- [Ditto Protocol](https://www.eclipse.dev/ditto/protocol-overview.html)
- [Ditto Connectivity](https://www.eclipse.dev/ditto/connectivity-overview.html)
