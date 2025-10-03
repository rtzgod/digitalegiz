# Eclipse Ditto Configuration

Official Eclipse Ditto deployment integrated with DigitalEgiz platform.

## Quick Start

1. **Create htpasswd file** for authentication:
```bash
cd configuration/ditto
./create-htpasswd.sh
cd ../..
```

2. **Start Ditto**:
```bash
docker-compose -f docker-compose.ditto.yml up -d
```

3. **Wait** for cluster formation (1-2 minutes), then access:
   - **Web UI**: `https://ditto.${DOMAIN}/ui/`
   - **HTTP API**: `https://ditto.${DOMAIN}/api`
   - **Status**: `https://ditto.${DOMAIN}/status` (no auth)

Login with credentials from `.env` file (`DITTO_USER` / `DITTO_PASSWORD`).

## What's Included

This is the **official Eclipse Ditto deployment** with minimal modifications:
- ✅ All 6 Ditto microservices (policies, things, search, connectivity, gateway)
- ✅ MongoDB database
- ✅ Ditto UI web interface
- ✅ Official nginx reverse proxy
- ✅ Integrated with Traefik for HTTPS/SSL
- ✅ Connected to DigitalEgiz network for MQTT access

## Architecture

```
Internet → Traefik (HTTPS) → Ditto Nginx → Ditto Services Cluster
                                         → Ditto UI

Ditto Cluster (internal):
- mongodb (database)
- policies (authorization)
- things (digital twin state)
- things-search (search engine)
- connectivity (MQTT/external integrations)
- gateway (API entry point)
```

## MQTT Integration with ChirpStack

Ditto can connect to your existing Mosquitto broker to create digital twins from ChirpStack devices.

### Create MQTT Connection

```bash
curl -X POST \
  https://ditto.${DOMAIN}/devops/piggyback/connectivity \
  -H 'Content-Type: application/json' \
  -u ditto:your-password \
  -d @configuration/ditto/mqtt-connection-template.json
```

### Verify Connection

```bash
curl https://ditto.${DOMAIN}/api/2/connections \
  -u ditto:your-password
```

## Managing Ditto

```bash
# Start
docker-compose -f docker-compose.ditto.yml up -d

# Stop
docker-compose -f docker-compose.ditto.yml down

# View logs
docker-compose -f docker-compose.ditto.yml logs -f gateway

# Restart
docker-compose -f docker-compose.ditto.yml restart
```

## Configuration

### Environment Variables (`.env`)

```bash
DITTO_VERSION=3.5.11
DITTO_USER=ditto
DITTO_PASSWORD=your-password
DOMAIN=your-domain.com
```

### Custom Configuration

Ditto services can be configured via `JAVA_TOOL_OPTIONS` environment variables in [docker-compose.ditto.yml](../../docker-compose.ditto.yml).

Example:
```yaml
environment:
  - JAVA_TOOL_OPTIONS=-Dditto.gateway.authentication.devops.password=custom-password
```

## Troubleshooting

### Services not starting
- Check logs: `docker-compose -f docker-compose.ditto.yml logs`
- Wait 2-3 minutes for cluster formation
- Verify all containers are running: `docker-compose -f docker-compose.ditto.yml ps`

### 502 Bad Gateway
- Ensure nginx is connected to both networks
- Check gateway is healthy: `curl https://ditto.${DOMAIN}/status`
- Verify Traefik can reach nginx: `docker logs digitalegiz-traefik`

### UI not loading
- Clear browser cache
- Check nginx logs: `docker logs digitalegiz-ditto-nginx`
- Verify UI container is running: `docker ps | grep ditto-ui`

## API Examples

### Create a Thing (Digital Twin)

```bash
curl -X PUT \
  https://ditto.${DOMAIN}/api/2/things/org.digitalegiz:sensor-001 \
  -H 'Content-Type: application/json' \
  -u ditto:your-password \
  -d '{
    "attributes": {
      "location": "Office",
      "manufacturer": "Acme Corp"
    },
    "features": {
      "temperature": {
        "properties": {
          "value": 23.5
        }
      }
    }
  }'
```

### Query Things

```bash
curl https://ditto.${DOMAIN}/api/2/things \
  -u ditto:your-password
```

### WebSocket Connection

```javascript
const ws = new WebSocket('wss://ditto.${DOMAIN}/ws/2');
ws.onopen = () => {
  // Send auth
  ws.send(JSON.stringify({
    type: 'START',
    protocolVersion: 2
  }));
};
```

## Further Reading

- [Eclipse Ditto Documentation](https://www.eclipse.dev/ditto/)
- [Ditto HTTP API](https://www.eclipse.dev/ditto/httpapi-overview.html)
- [Ditto Protocol](https://www.eclipse.dev/ditto/protocol-overview.html)
- [Ditto Connectivity](https://www.eclipse.dev/ditto/connectivity-overview.html)
- [Official Docker Deployment](https://github.com/eclipse-ditto/ditto/tree/master/deployment/docker)
