# Project Rules

## Absolute Rules
- NEVER run `rm -rf` on any directory
- NEVER push directly to main or production branches
- NEVER modify files in vendor/ or node_modules/
- ALWAYS run the full test suite before creating a PR
- NEVER use `sudo` in any command
- ALWAYS include migration rollback scripts with schema changes

## Architecture
We use a microservices architecture with event-driven communication.
Services communicate via RabbitMQ (amqp://mq.internal:5672).
API gateway at src/gateway/ routes to downstream services.
Shared protobuf definitions in proto/ directory.

## Naming
- Services: {domain}-service (e.g., billing-service, auth-service)
- Queues: {source}.{event}.{destination} (e.g., billing.invoice-created.notification)
- Tables: singular, snake_case (e.g., invoice, line_item)
- API routes: plural, kebab-case (e.g., /invoices, /line-items)

## Monitoring
- All services expose /health and /ready endpoints
- Metrics on port 9090, Prometheus format
- Structured JSON logging to stdout
- Correlation ID in X-Request-Id header, propagate through all services

## DO NOT TOUCH
The following files are auto-generated and will be overwritten:
- src/generated/**
- proto/compiled/**
- docs/api/openapi.yaml (generated from code annotations)
