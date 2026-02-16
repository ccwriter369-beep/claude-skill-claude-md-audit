# CLAUDE.md

## Important Context
This is a healthcare application subject to HIPAA compliance.
All patient data must be encrypted at rest and in transit.
PHI (Protected Health Information) must never appear in logs.
Audit trail required for all data access - use the AuditLogger class.

## Code Quality
- Use ESLint with our .eslintrc config
- Run prettier before committing
- No any types in TypeScript
- Prefer composition over inheritance
- Keep functions under 50 lines

## Error Handling
- All API errors return { error: string, code: string, requestId: string }
- Never expose internal error details to clients
- Log full error with stack trace to CloudWatch
- Use custom AppError class from src/lib/errors.ts

## Data Model Conventions
- All tables have id (UUID), created_at, updated_at columns
- Soft delete with deleted_at column (HIPAA requires data retention)
- Patient records use composite key: (patient_id, facility_id)
- All timestamps in UTC, stored as timestamptz

## Feature Flags
We use Unleash (self-hosted at https://flags.internal.healthco.net).
New features behind flags named: release.{feature-name}
Patient-facing changes require gradual rollout: 10% -> 50% -> 100%

## Third-Party Integrations
- HL7 FHIR API at https://fhir.healthco.net/r4
- Insurance verification: Availity API (credentials in Vault)
- E-prescriptions: Surescripts via NewCrop adapter in src/integrations/newcrop/

## Review Requirements
- All PRs require 2 approvals
- PHI-touching code requires security team review
- Database migrations require DBA approval
