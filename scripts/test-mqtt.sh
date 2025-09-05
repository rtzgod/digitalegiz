#!/bin/bash

echo "=== DigitalEgiz Phase 1 - MQTT Broker Test ==="
echo

# Check if Mosquitto container is running
echo "1. Checking Mosquitto container status..."
if docker ps | grep -q digitalegiz-mosquitto; then
    echo "✓ Mosquitto container is running"
else
    echo "✗ Mosquitto container is not running"
    exit 1
fi

echo

# Test MQTT connectivity
echo "2. Testing MQTT publish/subscribe..."

# Start subscriber in background
mosquitto_sub -h localhost -p 1883 -t "digitalegiz/sensors/+/data" > mqtt_test_output.tmp &
SUB_PID=$!

# Wait a moment for subscriber to connect
sleep 2

# Publish test messages
echo "Publishing test sensor data..."
mosquitto_pub -h localhost -p 1883 -t "digitalegiz/sensors/temp001/data" -m '{"sensor_id":"temp001","temperature":25.5,"humidity":60.0,"timestamp":"'$(date -Iseconds)'"}'
mosquitto_pub -h localhost -p 1883 -t "digitalegiz/sensors/temp002/data" -m '{"sensor_id":"temp002","temperature":22.3,"humidity":55.8,"timestamp":"'$(date -Iseconds)'"}'

# Wait for messages to be received
sleep 2

# Stop subscriber
kill $SUB_PID 2>/dev/null

# Check if messages were received
if [ -s mqtt_test_output.tmp ]; then
    echo "✓ MQTT pub/sub test successful"
    echo "Received messages:"
    cat mqtt_test_output.tmp | sed 's/^/  /'
else
    echo "✗ MQTT pub/sub test failed"
fi

# Cleanup
rm -f mqtt_test_output.tmp

echo
echo "=== Phase 1 Test Complete ==="
echo "MQTT Broker (Mosquitto) is ready for ChirpStack integration"
echo "Ports:"
echo "  - MQTT: 1883"
echo "  - WebSockets: 9001"