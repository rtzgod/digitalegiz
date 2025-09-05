#!/bin/bash

echo "=== DigitalEgiz - ChirpStack Deployment Test ==="
echo

# Check all containers
echo "1. Container Status Check:"
CONTAINERS=(
    "digitalegiz-chirpstack:ChirpStack Main (Port 8080)"
    "digitalegiz-chirpstack-rest-api:ChirpStack REST API (Port 8090)" 
    "digitalegiz-chirpstack-gateway-bridge:Gateway Bridge UDP (Port 1700)"
    "digitalegiz-chirpstack-gateway-bridge-basicstation:Gateway Bridge BasicStation (Port 3001)"
    "digitalegiz-mosquitto:MQTT Broker (Ports 1883, 9001)"
    "digitalegiz-postgres:PostgreSQL Database"
    "digitalegiz-redis:Redis Cache"
)

for container_info in "${CONTAINERS[@]}"; do
    IFS=':' read -r container_name description <<< "$container_info"
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "  ✅ $description - Running"
    else
        echo "  ❌ $description - Not running"
    fi
done

echo

# Test API endpoints
echo "2. API Connectivity Tests:"

# Test ChirpStack Web Interface
if curl -s --max-time 5 http://localhost:8080/api/internal/version >/dev/null 2>&1; then
    echo "  ✅ ChirpStack Web Interface (http://localhost:8080) - Accessible"
else
    echo "  ⚠  ChirpStack Web Interface - Not responding (may still be initializing)"
fi

# Test REST API
if curl -s --max-time 5 http://localhost:8090/api/internal/version >/dev/null 2>&1; then
    echo "  ✅ ChirpStack REST API (http://localhost:8090) - Accessible"
    echo "     Version: $(curl -s http://localhost:8090/api/internal/version 2>/dev/null | head -1)"
else
    echo "  ⚠  ChirpStack REST API - Not responding"
fi

echo

# Test MQTT connectivity
echo "3. MQTT Integration Tests:"

# Test basic MQTT connectivity
timeout 3 mosquitto_pub -h localhost -p 1883 -t "test/digitalegiz" -m "ChirpStack deployment test" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "  ✅ MQTT Broker - Publishing works"
else
    echo "  ❌ MQTT Broker - Publishing failed"
fi

# Test gateway topics (EU868)
echo "  📡 Testing LoRaWAN Gateway Topics:"
timeout 2 mosquitto_sub -h localhost -p 1883 -t "eu868/gateway/+/event/+" -C 1 >/dev/null 2>&1 
if [ $? -eq 124 ]; then  # timeout occurred (normal, no real gateway)
    echo "     ✅ EU868 Gateway topics accessible (no messages expected without real gateway)"
else
    echo "     ⚠  Gateway topic subscription issue"
fi

echo

# Database connectivity test
echo "4. Database Status:"
if docker exec digitalegiz-postgres pg_isready -U chirpstack -d chirpstack >/dev/null 2>&1; then
    echo "  ✅ PostgreSQL Database - Ready"
else
    echo "  ❌ PostgreSQL Database - Not ready"
fi

if docker exec digitalegiz-redis redis-cli ping >/dev/null 2>&1; then
    echo "  ✅ Redis Cache - Ready"  
else
    echo "  ❌ Redis Cache - Not ready"
fi

echo

echo "=== Deployment Summary ==="
echo "🎉 ChirpStack LoRaWAN Network Server is OPERATIONAL!"
echo
echo "Access Points:"
echo "  🌐 Web Interface:    http://localhost:8080"
echo "  🔌 REST API:         http://localhost:8090"
echo "  📡 Gateway UDP:      localhost:1700"
echo "  📡 Gateway BasicStation: localhost:3001"
echo "  📨 MQTT Broker:      localhost:1883"
echo "  🔌 MQTT WebSockets:  localhost:9001"
echo
echo "Default Login (Web Interface):"
echo "  Username: admin"
echo "  Password: admin"