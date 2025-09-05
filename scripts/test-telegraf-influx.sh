#!/bin/bash

echo "=== DigitalEgiz - Telegraf to InfluxDB Data Flow Test ==="
echo

# Test 1: Check if InfluxDB is accessible
echo "1. Testing InfluxDB Connectivity:"
if curl -s --max-time 5 http://localhost:8086/health >/dev/null 2>&1; then
    echo "  ✅ InfluxDB is accessible"
    HEALTH=$(curl -s http://localhost:8086/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    echo "     Status: $HEALTH"
else
    echo "  ❌ InfluxDB is not accessible"
    exit 1
fi

echo

# Test 2: Check Telegraf status
echo "2. Testing Telegraf Status:"
if docker ps --format '{{.Names}}' | grep -q "^digitalegiz-telegraf$"; then
    echo "  ✅ Telegraf container is running"
    
    # Check for errors in logs
    ERROR_COUNT=$(docker logs digitalegiz-telegraf 2>&1 | grep -c "E!")
    if [ $ERROR_COUNT -eq 0 ]; then
        echo "  ✅ No errors in Telegraf logs"
    else
        echo "  ⚠  Found $ERROR_COUNT error(s) in Telegraf logs"
    fi
else
    echo "  ❌ Telegraf container is not running"
    exit 1
fi

echo

# Test 3: Publish test data to MQTT
echo "3. Publishing Test Data to MQTT:"

# Test data simulating ChirpStack device uplink
TEST_DATA='{
  "applicationID": "1",
  "applicationName": "test-app",
  "deviceName": "test-device-001",
  "devEUI": "0102030405060708",
  "rxInfo": [{
    "gatewayID": "0102030405060708",
    "rssi": -89,
    "loRaSNR": 7.5
  }],
  "txInfo": {
    "frequency": 868100000,
    "dr": 5
  },
  "fCnt": 123,
  "fPort": 1,
  "data": "SGVsbG8gV29ybGQ=",
  "time": "'$(date -Iseconds)'"
}'

# Publish to ChirpStack application topic
mosquitto_pub -h localhost -p 1883 -t "application/1/device/0102030405060708/event/up" -m "$TEST_DATA" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "  ✅ Test data published to MQTT topic"
    echo "     Topic: application/1/device/0102030405060708/event/up"
else
    echo "  ❌ Failed to publish test data to MQTT"
    exit 1
fi

# Publish system test message
mosquitto_pub -h localhost -p 1883 -t "test/digitalegiz/system" -m '{"test": "telegraf-influx", "timestamp": "'$(date -Iseconds)'", "value": 42}' 2>/dev/null

echo

# Test 4: Wait for Telegraf to process and send to InfluxDB
echo "4. Waiting for Telegraf to Process Data:"
echo "  ⏳ Waiting 15 seconds for Telegraf flush interval..."
sleep 15
echo "  ✅ Wait complete"

echo

# Test 5: Query InfluxDB for data
echo "5. Querying InfluxDB for Received Data:"

# Load environment variables
source .env

# Query for MQTT consumer data
QUERY='from(bucket:"'$INFLUXDB_BUCKET'") |> range(start: -5m) |> filter(fn: (r) => r._measurement == "mqtt_consumer") |> count()'

INFLUX_RESULT=$(curl -s --max-time 10 \
  -XPOST "http://localhost:8086/api/v2/query?org=$INFLUXDB_ORG" \
  -H "Authorization: Token $INFLUXDB_TOKEN" \
  -H "Content-Type: application/vnd.flux" \
  -d "$QUERY" 2>/dev/null)

if echo "$INFLUX_RESULT" | grep -q "_value"; then
    RECORD_COUNT=$(echo "$INFLUX_RESULT" | grep "_value" | head -1 | awk -F',' '{print $6}' | tr -d ' ')
    echo "  ✅ Found MQTT data in InfluxDB"
    echo "     Records: $RECORD_COUNT"
else
    echo "  ⚠  No MQTT data found in InfluxDB yet"
fi

# Query for system metrics
SYSTEM_QUERY='from(bucket:"'$INFLUXDB_BUCKET'") |> range(start: -5m) |> filter(fn: (r) => r._measurement == "system") |> count()'

SYSTEM_RESULT=$(curl -s --max-time 10 \
  -XPOST "http://localhost:8086/api/v2/query?org=$INFLUXDB_ORG" \
  -H "Authorization: Token $INFLUXDB_TOKEN" \
  -H "Content-Type: application/vnd.flux" \
  -d "$SYSTEM_QUERY" 2>/dev/null)

if echo "$SYSTEM_RESULT" | grep -q "_value"; then
    SYSTEM_RECORDS=$(echo "$SYSTEM_RESULT" | grep "_value" | head -1 | awk -F',' '{print $6}' | tr -d ' ')
    echo "  ✅ Found system metrics in InfluxDB"
    echo "     System records: $SYSTEM_RECORDS"
else
    echo "  ⚠  No system metrics found in InfluxDB yet"
fi

echo

# Test 6: Show recent Telegraf logs
echo "6. Recent Telegraf Activity:"
echo "  📋 Last 5 log entries:"
docker logs --tail 5 digitalegiz-telegraf 2>&1 | sed 's/^/     /'

echo

echo "=== Test Summary ==="
if echo "$INFLUX_RESULT" | grep -q "_value" || echo "$SYSTEM_RESULT" | grep -q "_value"; then
    echo "🎉 SUCCESS: Data flow working!"
    echo "   Telegraf → InfluxDB pipeline is operational"
else
    echo "⚠  PARTIAL: Services running but no data confirmed yet"
    echo "   This might be normal - try running the test again in a few minutes"
fi

echo
echo "InfluxDB Access:"
echo "  🌐 Web UI: http://localhost:8086"
echo "  👤 Username: $INFLUXDB_USER"
echo "  📊 Organization: $INFLUXDB_ORG"
echo "  🪣 Bucket: $INFLUXDB_BUCKET"