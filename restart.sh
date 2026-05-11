#!/bin/bash
# Restart script - rebuilds and restarts all services

echo "🔄 Rebuilding and restarting all services..."

# Stop and remove containers
podman-compose down 2>/dev/null || docker-compose down

# Rebuild consumer image
echo "🔨 Building Mobile Billing Consumer..."
podman-compose build mobile-billing-consumer 2>/dev/null || docker-compose build mobile-billing-consumer

# Start all services
echo "🚀 Starting all services..."
podman-compose up -d 2>/dev/null || docker-compose up -d

# Wait for Kafka to be ready
echo ""
echo "⏳ Waiting for Kafka to be ready..."
sleep 10

# Create Kafka topic
echo "📋 Creating Kafka topic 'mobile-usage'..."
podman exec kafka kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic mobile-usage \
  --partitions 1 \
  --replication-factor 1 \
  --if-not-exists 2>/dev/null || \
docker exec kafka kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic mobile-usage \
  --partitions 1 \
  --replication-factor 1 \
  --if-not-exists

if [ $? -eq 0 ]; then
    echo "✅ Topic 'mobile-usage' ready"
else
    echo "⚠️  Topic may already exist"
fi

echo ""
echo "✅ Services restarted"
echo ""
echo "📋 Check status:"
echo "   podman-compose ps  (or docker-compose ps)"
echo ""
echo "📊 View logs:"
echo "   podman-compose logs -f mobile-billing-consumer"
echo ""
echo "🧪 Start the producer:"
echo "   cd /Users/hrishikeshpai/Documents/git_repos_old/iot-usage-kafka-logger"
echo "   ./start-local.sh"
echo ""
echo "📤 Test with curl:"
echo "   curl -X POST http://localhost:3000/mobile-usage \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"device_id\":\"device-001\",\"usage\":150.5,\"start_time\":\"2026-05-11T10:00:00.000Z\",\"end_time\":\"2026-05-11T10:05:00.000Z\",\"package_type\":\"prepaid\"}'"

# Made with Bob
