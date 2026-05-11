# Quick Start Guide

Get the Mobile Data Usage Billing Consumer running in 5 minutes!

## Prerequisites

- Docker or Podman installed
- Docker Compose or Podman Compose installed

## Step 1: Start the Services

```bash
cd fixium-mobile-consumer

# Using Docker
docker-compose up -d

# OR using Podman
podman-compose up -d
```

This will start:
- ✅ Zookeeper (Kafka dependency)
- ✅ Kafka broker
- ✅ Mobile Billing Consumer

## Step 2: Verify Services are Running

```bash
# Check all services
docker-compose ps

# You should see all services as "Up" or "healthy"
```

## Step 3: Send Test Events

Use the provided test script:

```bash
./test-producer.sh
```

This will send various test events to Kafka including:
- Multiple events from the same device
- Events from different devices
- High usage events
- Burst of events

## Step 4: View Consumer Output

```bash
# Watch the consumer logs in real-time
docker-compose logs -f mobile-billing-consumer
```

You should see:
- Individual event processing logs
- **Billing reports every 10 seconds** with:
  - Total events processed
  - Total usage in MB
  - Total cost in USD
  - Per-device breakdown

Example output:
```
================================================================================
BILLING REPORT
================================================================================
Report Time: 2026-05-11T11:00:00.000Z

OVERALL STATISTICS:
  Total Events Processed: 19
  Total Usage: 2847.25 MB
  Total Cost: $284.73
  Unique Devices: 12

TOP DEVICES BY COST:
  1. Device device-999: 1500.75 MB, $150.08, 1 events
  2. Device device-001: 450.50 MB, $45.05, 3 events
  3. Device device-042: 320.25 MB, $32.03, 1 events
  ...
================================================================================
```

## Step 5: Send Your Own Events

You can send custom events using the Kafka console producer:

```bash
# Access Kafka container
docker exec -it kafka bash

# Send a custom event
echo '{"device_id": "my-device", "usage": 100.5, "start_time": "2026-05-11T10:00:00Z", "end_time": "2026-05-11T10:05:00Z"}' | \
  kafka-console-producer --bootstrap-server localhost:9092 --topic mobile-usage

# Exit the container
exit
```

## Step 6: Monitor Consumer Status

```bash
# Check consumer group status
docker exec kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --describe \
  --group mobile-billing-consumer
```

## Step 7: Stop the Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v
```

## Troubleshooting

### Services won't start
```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart
```

### Consumer not receiving messages
```bash
# Verify topic exists
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list

# Check if messages are in topic
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic mobile-usage \
  --from-beginning \
  --max-messages 5
```

### Using Podman instead of Docker

Replace `docker` with `podman` and `docker-compose` with `podman-compose`:

```bash
# Start services
podman-compose up -d

# View logs
podman-compose logs -f mobile-billing-consumer

# Stop services
podman-compose down
```

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Customize billing rates in `consumer/billing_consumer.py`
- Add your own producer application
- Integrate with a database for persistent storage

## Event Format Reference

```json
{
  "device_id": "device-12345",
  "usage": 150.5,
  "start_time": "2026-05-11T10:00:00Z",
  "end_time": "2026-05-11T10:05:00Z"
}
```

- `device_id`: Unique device identifier (required)
- `usage`: Data usage in MB (required)
- `start_time`: Usage period start (optional)
- `end_time`: Usage period end (optional)

## Support

For issues or questions, check the [README.md](README.md) troubleshooting section.