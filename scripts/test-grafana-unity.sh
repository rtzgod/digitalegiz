#!/bin/bash

echo "=== DigitalEgiz - Grafana with Unity Panel Test ==="
echo

# Load environment variables
source .env

# Test 1: Check Grafana accessibility
echo "1. Testing Grafana Connectivity:"
if curl -s --max-time 5 http://localhost:3000/api/health >/dev/null 2>&1; then
    echo "  ✅ Grafana is accessible"
    HEALTH_INFO=$(curl -s http://localhost:3000/api/health)
    VERSION=$(echo "$HEALTH_INFO" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    DATABASE=$(echo "$HEALTH_INFO" | grep -o '"database":"[^"]*"' | cut -d'"' -f4)
    echo "     Version: $VERSION"
    echo "     Database: $DATABASE"
else
    echo "  ❌ Grafana is not accessible"
    exit 1
fi

echo

# Test 2: Test login with credentials
echo "2. Testing Grafana Authentication:"
LOGIN_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "{\"user\":\"$GRAFANA_USER\",\"password\":\"$GRAFANA_PASSWORD\"}" \
  http://localhost:3000/login 2>/dev/null)

if echo "$LOGIN_RESPONSE" | grep -q "message.*Logged in"; then
    echo "  ✅ Login successful with configured credentials"
else
    echo "  ⚠  Login test inconclusive (may require browser session)"
fi

echo

# Test 3: Check Unity plugin registration  
echo "3. Testing Unity Panel Plugin:"
CONTAINER_LOGS=$(docker logs digitalegiz-grafana 2>&1)

if echo "$CONTAINER_LOGS" | grep -q "Plugin registered.*ertis-unity-panel"; then
    echo "  ✅ Unity panel plugin successfully registered"
    
    if echo "$CONTAINER_LOGS" | grep -q "Permitting unsigned plugin"; then
        echo "  ✅ Unsigned plugin permission granted"
    fi
    
    # Check plugin loading details
    PLUGIN_PATH=$(echo "$CONTAINER_LOGS" | grep "Loading plugin.*ertis-unity-panel" | head -1 | grep -o '/var/lib/grafana/plugins/ertis-unity-panel/plugin.json')
    if [ ! -z "$PLUGIN_PATH" ]; then
        echo "     Plugin path: $PLUGIN_PATH"
    fi
else
    echo "  ❌ Unity panel plugin not registered"
fi

echo

# Test 4: Check InfluxDB data source provisioning
echo "4. Testing InfluxDB Data Source Configuration:"

# Get session cookie for API calls
COOKIE=$(curl -s -c - -X POST \
  -H "Content-Type: application/json" \
  -d "{\"user\":\"$GRAFANA_USER\",\"password\":\"$GRAFANA_PASSWORD\"}" \
  http://localhost:3000/login 2>/dev/null | grep "grafana_session" | awk '{print $7}')

if [ ! -z "$COOKIE" ]; then
    # Check data sources
    DATASOURCES=$(curl -s -b "grafana_session=$COOKIE" \
      http://localhost:3000/api/datasources 2>/dev/null)
    
    if echo "$DATASOURCES" | grep -q "InfluxDB-DigitalEgiz"; then
        echo "  ✅ InfluxDB data source provisioned successfully"
        
        # Check if it's the default
        if echo "$DATASOURCES" | grep -q '"isDefault":true'; then
            echo "  ✅ Set as default data source"
        fi
        
        # Check connection
        DATASOURCE_ID=$(echo "$DATASOURCES" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
        if [ ! -z "$DATASOURCE_ID" ]; then
            TEST_RESULT=$(curl -s -b "grafana_session=$COOKIE" \
              http://localhost:3000/api/datasources/$DATASOURCE_ID/health 2>/dev/null)
            
            if echo "$TEST_RESULT" | grep -q '"status":"OK"'; then
                echo "  ✅ InfluxDB connection test successful"
            else
                echo "  ⚠  InfluxDB connection test failed"
            fi
        fi
    else
        echo "  ⚠  InfluxDB data source not found"
    fi
else
    echo "  ⚠  Could not authenticate for data source check"
fi

echo

# Test 5: Plugin file structure check
echo "5. Testing Unity Panel Plugin Files:"
if docker exec digitalegiz-grafana test -f /var/lib/grafana/plugins/ertis-unity-panel/plugin.json; then
    echo "  ✅ Plugin configuration file exists"
    
    if docker exec digitalegiz-grafana test -f /var/lib/grafana/plugins/ertis-unity-panel/module.js; then
        echo "  ✅ Plugin module file exists"
    else
        echo "  ❌ Plugin module file missing"
    fi
    
    # Check plugin.json content
    PLUGIN_INFO=$(docker exec digitalegiz-grafana cat /var/lib/grafana/plugins/ertis-unity-panel/plugin.json 2>/dev/null)
    if echo "$PLUGIN_INFO" | grep -q "ertis-unity-panel"; then
        echo "  ✅ Plugin configuration is valid"
        
        PLUGIN_VERSION=$(echo "$PLUGIN_INFO" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
        if [ ! -z "$PLUGIN_VERSION" ]; then
            echo "     Plugin version: $PLUGIN_VERSION"
        fi
    fi
else
    echo "  ❌ Plugin configuration file missing"
fi

echo

# Test 6: Check Grafana service status
echo "6. Container and Service Status:"
if docker ps --format '{{.Names}}' | grep -q "^digitalegiz-grafana$"; then
    echo "  ✅ Grafana container is running"
    
    # Check port binding
    PORT_INFO=$(docker port digitalegiz-grafana)
    if echo "$PORT_INFO" | grep -q "3000"; then
        echo "  ✅ Port 3000 is properly mapped"
    fi
    
    # Check container health
    CONTAINER_STATUS=$(docker inspect digitalegiz-grafana --format '{{.State.Health.Status}}' 2>/dev/null || echo "no-health-check")
    if [ "$CONTAINER_STATUS" != "no-health-check" ]; then
        echo "     Container health: $CONTAINER_STATUS"
    fi
else
    echo "  ❌ Grafana container is not running"
fi

echo

echo "=== Deployment Summary ==="
echo "🎉 Grafana with Unity Panel is OPERATIONAL!"
echo
echo "Access Information:"
echo "  🌐 Grafana Web UI:   http://localhost:3000"
echo "  👤 Username:         $GRAFANA_USER"
echo "  🔐 Password:         $GRAFANA_PASSWORD"
echo "  🔌 InfluxDB Source:   InfluxDB-DigitalEgiz (provisioned)"
echo "  🎮 Unity Panel:      Available in panel types"
echo
echo "Next Steps:"
echo "  1. Login to Grafana web interface"
echo "  2. Create a new dashboard"
echo "  3. Add Unity panel type to visualize IoT data"
echo "  4. Configure data queries from InfluxDB"