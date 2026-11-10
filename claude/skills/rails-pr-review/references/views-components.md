# Review checklist: Controllers, views & components

Part of the rails-pr-review checklist. It lists *where bugs hide*, not rules to enforce everywhere. Only comment
when you can point at a line and name the consequence. Project rules (the repo review guide) override this file.

## Controllers, views & components

- **Failed form responses.** A failed form submission must render with `status: :unprocessable_entity` (and a redirect should be `:see_other` after a non-GET) for Turbo to behave.
- **Fat controllers.** Business logic in a controller that already exists (or belongs) in a model, service, or form object.
- **`before_action` coverage.** New actions are covered by the auth/loading callbacks. Watch `only:`/`except:` lists that silently exclude them.
- **ViewComponents.** Logic belongs in the Ruby class, not the template. Use `render?` for conditional rendering. Components query the database in a loop (N+1 again).
- **Partials and components** rendered in a collection get the data they need passed in, rather than querying.
