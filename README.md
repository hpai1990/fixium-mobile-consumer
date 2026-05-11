# Mobile Data Usage Billing Consumer

A Kafka consumer application that processes mobile data usage events and generates billing information in real-time.

## Overview

This application:
- Consumes mobile usage events from a Kafka topic
- Aggregates usage data per device in memory
- Calculates billing information based on usage ($0.10 per MB)
- Logs billing reports every 10 seconds to standard output

## Architecture

```
┌─────────────┐      ┌─────────────┐      ┌──────────────────┐
│  Producer   │─────▶│   Kafka     │─────▶│  Billing         │
│  (External) │      │   Topic     │      │  Consumer        │
└─────────────┘      └─────────────┘      └──────────────────┘
                                                    │
                                                    ▼
                                           ┌──────────────────┐
                                           │  In-Memory       │
                                           │  Aggregation     │
                                           └──────────────────┘
                                                    │
                                                    ▼
                                           ┌──────────────────┐
                                           │  Billing Report  │
                                           │  (Every 10s)     │
                                           └──────────────────┘
```

## Event Format

The consumer expects JSON events with the following structure:

```json
{
  "device_id": "device-12345",
  "usage": 150.5,
  "start_time": "2026-05-11T10:00:00Z",
  "end_time": "2026-05-11T10:05:00Z"
}
```

**Fields:**
- `device_id` (string, required): Unique device identifier
- `usage` (float, required): Data usage in megabytes (MB)
- `start_time` (string, optional): Usage period start time (ISO 8601)
- `end_time` (string, optional): Usage period end time (ISO 8601)

## Prerequisites

- Docker or Podman
- Docker Compose or Podman Compose

## Quick Start

### Using Docker Compose

```bash
# Start all services (Zookeeper, Kafka, Consumer)
docker-compose up -d

# View consumer logs
docker-compose logs -f mobile-billing-consumer

# Stop all services
docker-compose down
```

### Using Podman Compose

```bash
# Start all services
podman-compose up -d

# View consumer logs
podman-compose logs -f mobile-billing-consumer

# Stop all services
podman-compose down
```

## Configuration

### Kafka Configuration

The consumer connects to Kafka with these default settings:

- **Bootstrap Servers**: `kafka:9092`
- **Topic**: `mobile-usage`
- **Consumer Group**: `mobile-billing-consumer`
- **Auto Offset Reset**: `earliest`

### Billing Configuration

- **Rate**: $0.10 per MB
- **Report Interval**: 10 seconds
- **Storage**: In-memory (data is lost on restart)

## Billing Report Format

Every 10 seconds, the consumer logs a billing report:

```
================================================================================
BILLING REPORT
================================================================================
Report Time: 2026-05-11T10:42:00.512Z

OVERALL STATISTICS:
  Total Events Processed: 1250
  Total Usage: 18750.50 MB
  Total Cost: $1875.05
  Unique Devices: 42

TOP DEVICES BY COST:
  1. Device device-001: 850.25 MB, $85.03, 15 events
  2. Device device-042: 720.50 MB, $72.05, 12 events
  3. Device device-015: 650.00 MB, $65.00, 10 events
  ...
================================================================================
```

## Testing the Consumer

### 1. Start the Services

```bash
docker-compose up -d
```

### 2. Produce Test Events

You can produce test events using the Kafka console producer:

```bash
# Access Kafka container
docker exec -it kafka bash

# Create test events
kafka-console-producer --bootstrap-server localhost:9092 --topic mobile-usage << EOF
{"device_id": "device-001", "usage": 150.5, "start_time": "2026-05-11T10:00:00Z", "end_time": "2026-05-11T10:05:00Z"}
{"device_id": "device-002", "usage": 200.0, "start_time": "2026-05-11T10:00:00Z", "end_time": "2026-05-11T10:05:00Z"}
{"device_id": "device-001", "usage": 75.25, "start_time": "2026-05-11T10:05:00Z", "end_time": "2026-05-11T10:10:00Z"}
EOF
```

### 3. View Consumer Output

```bash
docker-compose logs -f mobile-billing-consumer
```

You should see:
- Individual event processing logs
- Billing reports every 10 seconds
- Aggregated statistics per device

## Project Structure

```
fixium-mobile-consumer/
├── consumer/
│   └── billing_consumer.py    # Main consumer application
├── config/                     # Configuration files (if needed)
├── docker-compose.yml          # Docker Compose configuration
├── Dockerfile                  # Consumer container image
├── requirements.txt            # Python dependencies
├── .gitignore                  # Git ignore rules
└── README.md                   # This file
```

## Development

### Local Development Setup

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run consumer locally (requires Kafka running)
python consumer/billing_consumer.py
```

### Running Tests

```bash
# Install test dependencies
pip install pytest pytest-cov

# Run tests (when test suite is added)
pytest tests/
```

## Monitoring

### Health Checks

Check if services are running:

```bash
# Check all services
docker-compose ps

# Check Kafka health
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092

# Check consumer logs
docker-compose logs mobile-billing-consumer
```

### Kafka Topic Information

```bash
# List topics
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list

# Describe topic
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic mobile-usage

# Check consumer group
docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group mobile-billing-consumer
```

## Troubleshooting

### Consumer Not Starting

1. Check if Kafka is healthy:
   ```bash
   docker-compose logs kafka
   ```

2. Verify network connectivity:
   ```bash
   docker exec mobile-billing-consumer ping kafka
   ```

3. Check consumer logs:
   ```bash
   docker-compose logs mobile-billing-consumer
   ```

### No Messages Being Consumed

1. Verify topic exists:
   ```bash
   docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list
   ```

2. Check if messages are in the topic:
   ```bash
   docker exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic mobile-usage --from-beginning --max-messages 5
   ```

3. Verify consumer group is active:
   ```bash
   docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group mobile-billing-consumer
   ```

### Podman-Specific Issues

If using Podman, you may need to:

1. Enable Podman socket:
   ```bash
   systemctl --user enable --now podman.socket
   ```

2. Set Docker compatibility:
   ```bash
   export DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock
   ```

## Production Considerations

For production deployment, consider:

1. **Persistence**: Add database storage for billing data
2. **Scaling**: Run multiple consumer instances for high throughput
3. **Monitoring**: Add metrics (Prometheus, Grafana)
4. **Alerting**: Set up alerts for consumer lag, errors
5. **Security**: Enable Kafka authentication and encryption
6. **Backup**: Implement data backup and recovery
7. **Configuration**: Use environment-specific configs
8. **Logging**: Centralized logging (ELK, Splunk)

## License

MIT License

## Support

For issues or questions, please open an issue in the repository.