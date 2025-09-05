# DigitalEgiz IoT Platform

A complete IoT platform built with ChirpStack LoRaWAN Network Server, InfluxDB time-series database, and Grafana visualization with Unity 3D panel support.

## 🏗️ Architecture

```
LoRaWAN Gateways → ChirpStack → MQTT → Telegraf → InfluxDB → Grafana (Unity Panel)
```

**Components:**
- **ChirpStack**: LoRaWAN Network Server with gateway bridges and REST API
- **Eclipse Mosquitto**: MQTT message broker
- **PostgreSQL**: ChirpStack database storage
- **Redis**: Caching layer
- **InfluxDB**: Time-series database for IoT data
- **Telegraf**: Data collection and forwarding agent
- **Grafana**: Visualization dashboards with Unity 3D panel plugin

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Git (for cloning)
- 8GB+ available RAM recommended

### Launch the Platform (3 Commands)
```bash
# 1. Start all services
docker compose up -d

# 2. Wait for initialization (optional but recommended)
sleep 60

# 3. Import LoRaWAN device repository (optional)
make import-lorawan-devices
```

### Verify Deployment
```bash
# Test ChirpStack deployment
./scripts/test-chirpstack.sh

# Test data flow (Telegraf → InfluxDB)  
./scripts/test-telegraf-influx.sh

# Test Grafana with Unity panel
./scripts/test-grafana-unity.sh
```

## 🌐 Access Points

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| **ChirpStack Web UI** | http://localhost:8080 | `admin` | `admin` |
| **ChirpStack REST API** | http://localhost:8090 | - | - |
| **InfluxDB** | http://localhost:8086 | `admin` | `digitalegiz2025` |
| **Grafana** | http://localhost:3000 | `admin` | `digitalegiz2025` |
| **MQTT Broker** | `localhost:1883` | - | - |
| **MQTT WebSocket** | `localhost:9001` | - | - | 

## 📡 Gateway Connection

### UDP Packet Forwarder
Configure your LoRaWAN gateway to forward packets to:
- **Server**: Your server IP address
- **Port**: `1700` (UDP)

### BasicStation Gateway
Configure BasicStation gateway with:
- **WebSocket URL**: `ws://your-server:3001`

## 📊 Getting Started

### 1. ChirpStack Setup
1. Access http://localhost:8080 (admin/admin)
2. Create Network Server profile
3. Add gateway and device profiles
4. Register your devices

### 2. Data Visualization
1. Access Grafana at http://localhost:3000 (admin/digitalegiz2025)
2. InfluxDB data source is pre-configured as `InfluxDB-DigitalEgiz`
3. Create dashboards with Unity panels for 3D visualization
4. Query data from `iot-data` bucket

## 🔧 Configuration Files

* `docker-compose.yml`: Complete platform services configuration
* `configuration/chirpstack/`: ChirpStack configuration files
* `configuration/chirpstack-gateway-bridge/`: Gateway Bridge configurations
* `configuration/mosquitto/`: MQTT broker configuration  
* `configuration/telegraf/`: Data collection configuration
* `configuration/grafana/`: Dashboard and data source provisioning
* `configuration/postgresql/initdb/`: Database initialization scripts

## 🛠️ Management Commands

### Start/Stop Services
```bash
# Start all services
docker compose up -d

# Stop all services  
docker compose down

# View service logs
docker compose logs -f [service-name]

# Restart specific service
docker compose restart [service-name]
```

### Monitor & Debug
```bash
# View container status
docker compose ps

# Check resource usage
docker stats

# Test platform components
./scripts/test-chirpstack.sh
./scripts/test-telegraf-influx.sh
./scripts/test-grafana-unity.sh
```

## 🔍 Troubleshooting

### Common Issues

**Services not starting:**
```bash
docker compose logs [service-name]
docker compose down && docker compose up -d
```

**Gateway not connecting:**
- Check firewall settings for ports 1700 (UDP) and 3001 (TCP)
- Verify gateway configuration matches server IP

**No data in InfluxDB:**
- Check Telegraf logs: `docker compose logs telegraf`
- Verify MQTT broker connectivity
- Test data flow with: `./scripts/test-telegraf-influx.sh`

**Grafana Unity panel not loading:**
- Check plugin logs: `docker compose logs grafana | grep unity`
- Verify plugin files are mounted correctly

### Regional Configuration

This setup is pre-configured for all regions (EU868, US915, AS923, etc.). 

**To change region:**
1. Update `enabled_regions` in `configuration/chirpstack/chirpstack.toml`
2. Modify MQTT topic templates in `docker-compose.yml` 
3. Use appropriate BasicStation config file

Default region: **EU868** (topic prefix: `eu868`)

## 📊 Data Flow & MQTT Topics

### Monitor Real-time Data
```bash
# Device uplinks
mosquitto_sub -h localhost -p 1883 -t "application/+/device/+/event/up"

# Gateway statistics  
mosquitto_sub -h localhost -p 1883 -t "gateway/+/event/stats"

# Device join events
mosquitto_sub -h localhost -p 1883 -t "application/+/device/+/event/join"
```

### Data Persistence
- **PostgreSQL**: ChirpStack configuration and device data
- **InfluxDB**: Time-series IoT sensor data  
- **Redis**: Session and cache data
- **Grafana**: Dashboard configurations

All data persisted in Docker named volumes.

## 🚀 Production Notes

### Security Checklist
- [ ] Change default passwords in `.env` file
- [ ] Enable TLS for external connections
- [ ] Configure firewall rules (ports: 8080, 3000, 8086, 1700, 3001)
- [ ] Set up monitoring and alerting
- [ ] Regular backups of volumes

### Performance Optimization  
- Adjust Telegraf collection intervals
- Configure InfluxDB retention policies
- Optimize PostgreSQL settings
- Scale services horizontally as needed

---

**🎉 Your complete IoT platform is ready!**

For advanced configuration and production deployment, see the individual service documentation in the `configuration/` directories.
