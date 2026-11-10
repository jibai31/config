# Review checklist: Security

Part of the rails-pr-review checklist. It lists *where bugs hide*, not rules to enforce everywhere. Only comment
when you can point at a line and name the consequence. Project rules (`docs/review/` in the repo) override this file.

## Security

- **Authorization scoping.** For every new or changed action that loads a record from params, check that the query is scoped to what the current user may access. `Model.find(params[:id])` in a multi-tenant app is almost always blocking. Look for `current_account.things.find`, a policy check (Pundit/ActionPolicy), or an equivalent scoping step.
- **Strong params.** New attributes permitted in `permit(...)`: can a user set something they shouldn't, like `account_id`, `role`, `admin`, `state`, or a price?
- **SQL injection.** String interpolation in `where("... #{x}")`, `order(params[:sort])`, `pluck(params[...])`, `find_by_sql`, or `Arel.sql` with user input. Sort columns must be allow-listed.
- **XSS.** `html_safe`, `raw`, `<%==`, and `content_tag` with interpolated user content, including inside ViewComponents and helpers.
- **Dynamic dispatch on input.** `constantize`, `safe_constantize`, `send`, and `public_send` with a value that comes from params.
- **Redirects.** `redirect_to params[:return_to]` without `allow_other_host: false` or an allow-list is an open redirect.
- **Secrets & PII.** Tokens, passwords, or OAuth credentials written to logs, exception messages, or job arguments. New sensitive params missing from `filter_parameters`.
- **CSRF.** A new `skip_forgery_protection` or `protect_from_forgery except:` needs a justification, such as a webhook that has signature verification.
- **Uploads.** New uploaders need an extension/content-type allow-list and a size limit.
- **OAuth / webhooks.** `state` must be verified on the callback. Webhook signatures must be checked with a constant-time comparison.
