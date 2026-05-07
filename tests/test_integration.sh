#!/bin/bash
set -e

BASE_URL=${1:-"http://localhost:8000"}

echo "Running integration tests against $BASE_URL"

# 1. Test /health
echo "Testing GET /health..."
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
if [ "$HEALTH_STATUS" -ne 200 ]; then
    echo "FAILED: /health returned $HEALTH_STATUS"
    exit 1
fi
echo "PASSED"

# 2. Test POST /services
echo "Testing POST /services..."
SERVICE_RESPONSE=$(curl -s -X POST "$BASE_URL/services" \
    -H "Content-Type: application/json" \
    -d '{"name": "Test Service", "url": "http://test.com"}')
echo "$SERVICE_RESPONSE" | grep -q "Test Service"
echo "PASSED"

# 3. Test GET /services
echo "Testing GET /services..."
SERVICES_LIST=$(curl -s "$BASE_URL/services")
echo "$SERVICES_LIST" | grep -q "Test Service"
echo "PASSED"

# 4. Test duplicate POST /services (should return 409)
echo "Testing duplicate POST /services..."
DUP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/services" \
    -H "Content-Type: application/json" \
    -d '{"name": "Test Service", "url": "http://test.com"}')
if [ "$DUP_STATUS" -ne 409 ]; then
    echo "FAILED: expected 409 for duplicate service, got $DUP_STATUS"
    exit 1
fi
echo "PASSED"

# 5. Test POST /incidents
echo "Testing POST /incidents..."
INCIDENT_RESPONSE=$(curl -s -X POST "$BASE_URL/incidents" \
    -H "Content-Type: application/json" \
    -d '{"service_name": "Test Service", "title": "API Outage", "description": "Investigating", "severity": "critical"}')
echo "$INCIDENT_RESPONSE" | grep -q "investigating"
echo "PASSED"

# 6. Test GET /incidents
echo "Testing GET /incidents..."
INCIDENTS_LIST=$(curl -s "$BASE_URL/incidents")
echo "$INCIDENTS_LIST" | grep -q "API Outage"
echo "PASSED"

echo "ALL INTEGRATION TESTS PASSED"
