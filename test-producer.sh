#!/bin/bash
# Test script to produce sample mobile usage events to Kafka

set -e

echo "🚀 Mobile Usage Event Producer - Test Script"
echo "=============================================="
echo ""

# Check if Kafka is running
if ! docker ps | grep -q kafka; then
    echo "❌ Error: Kafka container is not running"
    echo "Please start services with: docker-compose up -d"
    exit 1
fi

echo "✅ Kafka is running"
echo ""

# Function to generate random device ID
generate_device_id() {
    echo "device-$(printf "%03d" $((RANDOM % 100 + 1)))"
}

# Function to generate random usage (10-500 MB)
generate_usage() {
    echo "scale=2; $((RANDOM % 491 + 10)) + $((RANDOM % 100)) / 100" | bc
}

# Function to generate timestamp
generate_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Function to send event
send_event() {
    local device_id=$1
    local usage=$2
    local start_time=$3
    local end_time=$4
    
    local event="{\"device_id\": \"$device_id\", \"usage\": $usage, \"start_time\": \"$start_time\", \"end_time\": \"$end_time\"}"
    
    echo "$event" | docker exec -i kafka kafka-console-producer \
        --bootstrap-server localhost:9092 \
        --topic mobile-usage 2>/dev/null
    
    echo "📤 Sent: $event"
}

# Main test scenarios
echo "📊 Generating test events..."
echo ""

# Scenario 1: Multiple events from same device
echo "Scenario 1: Multiple events from device-001"
for i in {1..3}; do
    send_event "device-001" "$(generate_usage)" "$(generate_timestamp)" "$(generate_timestamp)"
    sleep 0.5
done
echo ""

# Scenario 2: Events from different devices
echo "Scenario 2: Events from different devices"
for i in {1..5}; do
    send_event "$(generate_device_id)" "$(generate_usage)" "$(generate_timestamp)" "$(generate_timestamp)"
    sleep 0.5
done
echo ""

# Scenario 3: High usage event
echo "Scenario 3: High usage event"
send_event "device-999" "1500.75" "$(generate_timestamp)" "$(generate_timestamp)"
echo ""

# Scenario 4: Burst of events
echo "Scenario 4: Burst of 10 events"
for i in {1..10}; do
    send_event "$(generate_device_id)" "$(generate_usage)" "$(generate_timestamp)" "$(generate_timestamp)" &
done
wait
echo ""

echo "✅ Test events sent successfully!"
echo ""
echo "📋 To view consumer output:"
echo "   docker-compose logs -f mobile-billing-consumer"
echo ""
echo "📊 To check consumer group status:"
echo "   docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group mobile-billing-consumer"

# Made with Bob
