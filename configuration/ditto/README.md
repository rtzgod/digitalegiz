# Eclipse Ditto Configuration

This directory contains configuration files for Eclipse Ditto digital twin platform integration with DigitalEgiz.

## MQTT Integration

### ChirpStack → Ditto Connection

To create a connection between ChirpStack (via Mosquitto MQTT) and Ditto, you need to POST the connection configuration to Ditto's DevOps API.

#### 1. Create the MQTT Connection

```bash
curl -X POST \
  https://ditto.${DOMAIN}/devops/piggyback/connectivity \
  -H 'Content-Type: application/json' \
  -u devops:${DITTO_DEVOPS_PASSWORD} \
  -d @mqtt-connection-template.json
```

#### 2. Verify Connection Status

```bash
curl -X GET \
  https://ditto.${DOMAIN}/api/2/connections \
  -u ${DITTO_GATEWAY_AUTH}
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
  -u ${DITTO_GATEWAY_AUTH} \
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

### Accessing Ditto UI

Navigate to: `https://ditto.${DOMAIN}`

Login with credentials from your `.env` file:
- Username: `ditto`
- Password: `${DITTO_GATEWAY_AUTH}` (after colon)

## API Endpoints

- **HTTP API**: `https://ditto.${DOMAIN}/api`
- **WebSocket**: `wss://ditto.${DOMAIN}/ws`
- **DevOps API**: `https://ditto.${DOMAIN}/devops`
- **Web UI**: `https://ditto.${DOMAIN}`

## Default Credentials

Set these in your `.env` file:
- MongoDB: `MONGO_INITDB_ROOT_USERNAME` / `MONGO_INITDB_ROOT_PASSWORD`
- DevOps API: `DITTO_DEVOPS_PASSWORD`
- Gateway Auth: `DITTO_GATEWAY_AUTH`

## Architecture

```
ChirpStack Device → MQTT (Mosquitto) → Ditto Connectivity → Ditto Things
                                                ↓
                                          Digital Twin
                                                ↓
                                          InfluxDB (via MQTT)
```

## Further Reading

- [Eclipse Ditto Documentation](https://www.eclipse.dev/ditto/)
- [Ditto HTTP API](https://www.eclipse.dev/ditto/httpapi-overview.html)
- [Ditto Protocol](https://www.eclipse.dev/ditto/protocol-overview.html)
