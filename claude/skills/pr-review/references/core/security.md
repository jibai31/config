# Review checklist: Security

Part of the pr-review core checklist. It lists *where problems hide*, not rules to enforce everywhere. Only
comment when you can point at a line and name the consequence. Stack packs and the project guide override this file.

- **Authorization.** Every new or changed entry point that loads or mutates data by an identifier from the client
  checks the caller may access it (scoped query or policy). Missing scoping is blocking.
- **Authentication.** New endpoints/routes reachable without auth when they shouldn't be; tokens without expiry or
  rotation; session fixation.
- **Mass assignment.** Client-settable fields that shouldn't be (owner id, role, price, state, timestamps).
- **Injection.** String-built SQL, shell commands, file paths, regexes, HTML or URLs from untrusted input. Sort/filter
  columns not allow-listed.
- **XSS / unsafe rendering.** Raw HTML rendering, `dangerouslySetInnerHTML`, WebViews loading untrusted content or
  exposing a JS bridge.
- **Secrets and PII.** Secrets in code, client bundles or logs; tokens or personal data in logs, error reports,
  analytics events, URLs or job arguments. Sensitive data stored unencrypted on device when the project requires
  secure storage.
- **Redirects and deep links.** Open redirects; deep-link handlers that perform actions without validation.
- **Webhooks / OAuth.** Signature verification (constant-time compare), `state`/PKCE checks.
- **Uploads.** Type allow-list, size limit, storage outside the web root.
- **Rate limiting / abuse** on new public endpoints that create data or send messages.
