# Review checklist: Background jobs & external integrations

Part of the rails-pr-review checklist. It lists *where bugs hide*, not rules to enforce everywhere. Only comment
when you can point at a line and name the consequence. Project rules (`docs/review/` in the repo) override this file.

## Background jobs (Sidekiq / Active Job)

- **Enqueue timing.** A job enqueued inside a transaction or `after_save` may run before the record is committed, giving `RecordNotFound` or stale data. Enqueue after commit.
- **Arguments** must be simple JSON types. Pass IDs, not ActiveRecord objects (plain Sidekiq workers). Never pass secrets in arguments: they're visible in the Web UI and in Redis.
- **Idempotency.** Jobs are retried. Would a retry double-send an email, double-charge, or duplicate records? Check for a guard such as a state check or unique key.
- **Missing records.** The record may have been deleted by the time the job runs. Handle `find_by` returning nil, or rescue deliberately.
- **Fan-out.** `perform_async` in a loop over many records: consider `perform_bulk` / `perform_all_later`, or batching.
- **Long jobs** that can't be interrupted safely at deploy. Break them up or make them resumable.
- **Queue choice and retry config** for new jobs: does it match the job's urgency and failure mode?

## External integrations (HTTP, OAuth, third-party APIs)

- **Timeouts.** Every HTTP call has open and read timeouts. A default of none or 60s can hang a Puma thread or a Sidekiq worker.
- **Failure handling.** Rate limits (429), 5xx, network errors: retry with backoff where safe, and surface the error otherwise.
- **Token refresh.** OAuth token expiry and refresh are handled. The refresh token is persisted when rotated.
- **Pagination.** API list calls handle all pages, with a sane stop condition, not an infinite loop.
- **Regional or tenant endpoints.** Hosts, IDs, or URLs are not hardcoded where they vary per customer.
- **Tests** stub the HTTP layer and don't hit the network.
