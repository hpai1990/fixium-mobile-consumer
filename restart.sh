#!/bin/bash
# Restart script - rebuilds and restarts the consumer

echo "🔄 Rebuilding and restarting consumer..."

# Stop and remove containers
podman-compose down

# Rebuild the consumer image
podman-compose build mobile-billing-consumer

# Start all services
podman-compose up -d

echo "✅ Services restarted"
echo ""
echo "📋 Check status:"
echo "   podman-compose ps"
echo ""
echo "📊 View logs:"
echo "   podman-compose logs -f mobile-billing-consumer"

# Made with Bob
