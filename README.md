# DigitalEgiz IoT Platform

**🐳 Containerized IoT Platform** - Complete LoRaWAN Network Server with time-series database and 3D visualization dashboard.

## 🚀 Deploy with Docker

### Prerequisites
- **Docker** and **Docker Compose** installed
- **8GB+ RAM** recommended

### Option 1: Basic HTTP Setup (Recommended)
```bash
git clone <repository-url> digitalegiz && cd digitalegiz
docker compose up -d
```

### Option 2: HTTPS with SSL (Advanced)
```bash
git clone <repository-url> digitalegiz && cd digitalegiz
./scripts/setup-https.sh
docker compose -f docker-compose.https.yml up -d
```

**🎉 Done!** Your IoT platform is running!

## 🌐 Access Your Platform

### Basic HTTP URLs (Default)
| Service | URL | Login |
|---------|-----|--------|
| **🏠 ChirpStack** | http://localhost:8080 | admin / admin |
| **📊 Grafana** | http://localhost:3000 | admin / digitalegiz2025 |
| **📈 InfluxDB** | http://localhost:8086 | admin / digitalegiz2025 |
| **🔌 REST API** | http://localhost:8090 | - |

### HTTPS URLs (docker-compose.https.yml)
| Service | URL | Login |
|---------|-----|--------|
| **🏠 ChirpStack** | https://your-domain/chirpstack | admin / admin |
| **📊 Grafana** | https://your-domain/grafana | admin / digitalegiz2025 |
| **📈 InfluxDB** | https://your-domain/influxdb | admin / digitalegiz2025 |
| **🔧 Traefik** | https://your-domain/dashboard | admin / [generated] |

## 🏗️ What's Included (7 Services)

```
📡 LoRaWAN Gateway → ChirpStack → MQTT → Telegraf → InfluxDB → Grafana
                              ↓
                         PostgreSQL + Redis
```

- **ChirpStack**: LoRaWAN Network Server + Gateway Bridges + REST API  
- **MQTT**: Message broker for device communication
- **InfluxDB**: Time-series database for IoT sensor data
- **Telegraf**: Data collection from MQTT to InfluxDB  
- **Grafana**: Dashboards with Unity 3D panel support
- **PostgreSQL**: ChirpStack configuration storage
- **Redis**: Caching layer 

## Architecture
![alt text](https://github.com/rtzgod/digitalegiz/blob/main/architecture.png "Architecture")

## 🎯 Connect Your Gateway

Point your LoRaWAN gateway to:
- **UDP**: `your-server-ip:1700` (Packet Forwarder)
- **WebSocket**: `ws://your-server-ip:3001` (BasicStation)

## ⚡ Quick Setup

### 1. Configure ChirpStack
```bash
# Open ChirpStack dashboard
open http://localhost:8080  # admin/admin

# Add your gateway and devices in the web interface
```

### 2. View Data in Grafana
```bash
# Open Grafana dashboard  
open http://localhost:3000  # admin/digitalegiz2025

# InfluxDB data source is already configured
# Create dashboards to visualize your IoT data
```

## 🐳 Docker Management

### Basic HTTP Setup
```bash
# Start platform
docker compose up -d

# Stop platform  
docker compose down

# View logs
docker compose logs -f [service-name]
```

### HTTPS Setup
```bash
# Start HTTPS platform
docker compose -f docker-compose.https.yml up -d

# Stop HTTPS platform
docker compose -f docker-compose.https.yml down

# View logs
docker compose -f docker-compose.https.yml logs -f [service-name]
```

### General Commands
```bash
# View running services
docker compose ps

# Restart service
docker compose restart [service-name]

# Test services
./scripts/test-chirpstack.sh
```

## 📋 Deployment Options

### `docker-compose.yml` (Default - HTTP)
- ✅ **Simple setup** - Just run `docker compose up -d`
- ✅ **Direct port access** - localhost:8080, :3000, :8086
- ✅ **No domain required** - Works on any server
- ✅ **Perfect for development** and internal networks
- ❌ No encryption - HTTP only

### `docker-compose.https.yml` (Advanced - HTTPS)  
- ✅ **SSL encryption** with automatic Let's Encrypt certificates
- ✅ **Reverse proxy** with Traefik dashboard
- ✅ **Production ready** with security features
- ✅ **Single domain** access with path-based routing
- ❌ **Requires domain name** - IP addresses don't work with SSL
- ❌ **More complex** setup and troubleshooting

## ❗ Troubleshooting

**Platform not starting?**
```bash
docker compose down && docker compose up -d
docker compose logs
```

**Gateway not connecting?**
- Open firewall ports: `1700/udp`, `3001/tcp`
- Check gateway config points to your server IP

**No data in Grafana?**
```bash  
docker compose logs telegraf
./scripts/test-telegraf-influx.sh
```

## 📊 Monitor Data

```bash
# Watch live MQTT messages
mosquitto_sub -h localhost -p 1883 -t "application/+/device/+/event/up"

# Check LoRaWAN device data
mosquitto_sub -h localhost -p 1883 -t "gateway/+/event/stats"
```

## 🔧 Production Ready

**Default Region:** EU868 (supports all regions)

**Security:** Change passwords in `.env` file before production

**Data Storage:** All data persisted in Docker volumes

**Ports Used:** 8080, 3000, 8086, 1700/udp, 3001

---

## 📁 Project Structure

```
digitalegiz/
├── docker-compose.yml     # 🐳 Main deployment file
├── configuration/         # ⚙️  Service configs
├── scripts/              # 🧪 Test scripts
├── unity-plugin/         # 🎮 Grafana Unity 3D plugin
└── .env                  # 🔐 Environment variables
```

**🚀 Your containerized IoT platform is ready to deploy!**
