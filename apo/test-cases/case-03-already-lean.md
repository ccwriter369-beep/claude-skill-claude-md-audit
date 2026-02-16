# Instructions

## Monorepo Layout
Apps in apps/, packages in packages/. Use turborepo for builds.

## Auth
All APIs require Bearer token from auth.myco.io. Refresh tokens stored in HttpOnly cookies only.

## Forbidden Actions
- NEVER delete production database records. Use soft-delete (deleted_at column).
- NEVER merge to main without passing CI. No --no-verify.
- NEVER expose internal service URLs in client-facing responses.

## Styling
We use Tailwind CSS with custom theme in tailwind.config.ts. Design tokens in packages/ui/tokens/.
