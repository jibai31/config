# Review checklist: Dependencies

Part of the pr-review core checklist. It lists *where problems hide*, not rules to enforce everywhere. Only
comment when you can point at a line and name the consequence. Stack packs and the project guide override this file.

- **Need.** Does a new dependency duplicate one already present, or the standard library/framework? Is it heavy for a
  small need?
- **Health.** Maintained (recent releases, issues answered), widely used, license compatible.
- **Platform fit.** For mobile: supported by the project's framework/runtime version and build setup (e.g. native
  module requirements).
- **Version pinning** per project convention; lockfile updated consistently with the manifest.
- **Scope.** Dev-only dependency added as a runtime dependency, or vice versa.
- **Upgrades.** Major version bumps: changelog breaking changes addressed in the PR.
