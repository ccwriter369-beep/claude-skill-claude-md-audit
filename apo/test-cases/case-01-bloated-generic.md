# Global Instructions

## Code Style
- Always use `const` instead of `let` when variable is not reassigned
- Prefer arrow functions over function declarations
- Use async/await instead of .then() chains
- Use template literals instead of string concatenation
- Always add semicolons at the end of statements

## Security
- Never expose stack traces to end users
- Always sanitize user input before database queries
- Use HTTPS for all API calls
- Hash passwords with bcrypt, never store plaintext
- Validate JWT tokens on every request

## Git Workflow
- Never force push to main
- Always create feature branches
- Write meaningful commit messages
- Run tests before committing
- Use conventional commits format

## My Project Structure
- Backend lives in /src/api/
- Frontend lives in /src/web/
- Shared types in /src/types/
- E2E tests in /tests/e2e/
- Deploy configs in /infra/terraform/

## Debugging
- Always read the error message carefully
- Check the logs first
- Reproduce the issue before fixing
- Write a test that catches the bug
- Use breakpoints instead of console.log

## Python Preferences
- Use type hints everywhere
- Prefer pathlib over os.path
- Use dataclasses for DTOs
- Always use virtual environments
- Format with black, lint with ruff

## Deployment
- Always run migrations before deploying
- Check that health endpoints respond
- Monitor error rates for 30 minutes after deploy
- Roll back if error rate exceeds 1%
- Never deploy on Fridays

## API Design
- Use REST conventions
- Return proper HTTP status codes
- Paginate list endpoints
- Version APIs with /v1/ prefix
- Document all endpoints with OpenAPI
