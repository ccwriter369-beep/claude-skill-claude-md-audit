# Project Instructions

## Team Convention: Branch Naming
- Feature branches: feat/JIRA-123-description
- Bugfix branches: fix/JIRA-456-description
- We use JIRA project key "ACME"

## Never Modify Legacy API
The /api/v1/payments endpoint is maintained by the payments team.
NEVER modify files in src/payments/v1/ without approval from @payments-team.
This is a compliance requirement - PCI DSS scope boundary.

## Database
- Use PostgreSQL 15 for all new services
- Always use transactions for multi-table writes
- Index foreign keys
- Use EXPLAIN ANALYZE before merging query changes

## Testing
- Write unit tests for all new code
- Use Jest for JavaScript, pytest for Python
- Mock external services in tests
- Aim for 80% coverage

## Secrets Management
Our secrets are in AWS Secrets Manager, region us-east-1.
Access pattern: `aws secretsmanager get-secret-value --secret-id acme/{service}/{env}`
NEVER hardcode secrets. NEVER commit .env files.

## Internal Services
- Auth service: https://auth.internal.acme.com
- Feature flags: LaunchDarkly project "acme-web"
- Error tracking: Sentry DSN is in env var SENTRY_DSN
- CI: GitHub Actions, workflows in .github/workflows/

## Performance
- Lazy load images
- Use code splitting for routes
- Compress assets with brotli
- Cache API responses where appropriate
