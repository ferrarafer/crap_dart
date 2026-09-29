# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Changed

- Merged upstream IstiN/crap4dart 0.10.0: `analyzer` 7.3 -> 14.4 (new
  "parts" AST), `xml` 7.1, `test` 1.32, `lints` 6.1. The SDK floor rises
  to 3.11 with analyzer 14.

## 0.12.3

### Fixed

- `unused_files` reported files as never imported when their only
  importer was excluded by the top-level `exclude`. Excluding generated
  code (e.g. a Stacked `app.router.dart` / `app.locator.dart`) orphaned
  every view and service it wires together. Imports are now read from
  every file in `sources`; excluded files are still never reported.

## 0.12.2

### Fixed

- `--staged` / `--changed` / `--diff` crashed or resolved wrong paths
  when run from a git hook in a sub-package (e.g. `cd app && crap4dart
  check --staged` in a monorepo pre-commit hook): git exports `GIT_DIR`
  to hooks, which makes git treat the current directory as the work-tree
  root, so repository paths were joined twice (`app/app/lib/...`). All
  git calls now drop `GIT_DIR` / `GIT_WORK_TREE` (keeping
  `GIT_INDEX_FILE`) and discover the repository from the project root.

## 0.12.1

### Fixed

- `check --tighten-baseline` rewrote entries in matching order, so a
  run that changed nothing still reordered `.crap-baseline.json` (noisy
  diffs). It now keeps the `--save-baseline` order; a no-op tighten
  leaves the file byte-identical.

## 0.12.0

### Added

- `check --tighten-baseline`: ratchets `.crap-baseline.json` down from a
  full run — ceilings drop to current measures, fixed entries are
  removed, new violations are never added (unlike re-running
  `--save-baseline`), grown violations keep their old ceiling, and
  entries of gates that did not run are untouched. Then checks like
  `--baseline`. Refuses partial selections.

## 0.11.0

### Changed

- `analyze`: a source file missing from the LCOV report (no test loaded
  it) is now scored as 0% covered instead of N/A when it lives under a
  top-level directory the report covers (e.g. `lib/`). Previously a
  brand-new, completely untested file had CRAP N/A and never exceeded
  the threshold — the worst code was invisible. Files under directories
  the report does not cover (e.g. `test/`) stay N/A. Opt out with
  `coverage.unloaded_as_uncovered: false`.

## 0.10.2

### Fixed

- `--diff` / `--diff-base` found nothing when the project is a
  subdirectory of its git repository (monorepo package): `git diff`
  printed repository-root paths (`app/lib/...`) that never matched the
  project-relative sources. It now runs `git diff --relative`.

## 0.10.1

### Fixed

- `check --baseline` ignored `severity: warning` gates: their results
  count as passed, and the baseline only filtered failed gates, so every
  baselined violation was still reported as a warning.

## 0.10.0

Fork release (ferrarafer/crap4dart). Minor bump: `.crap-baseline.json`
is now version 2 (version 1 files still load).

### Added

- `duplication` gate: new `sources` key — additional file/directory paths
  (resolved against the project root) unioned into the duplication scan,
  enabling cross-module duplicate detection in monorepos without widening
  the CRAP analysis scope.
- `crap.count_constructors` (default `false`): score constructors that
  have a body as methods, named `<Class>.<name>` (`<Class>.new` for the
  unnamed constructor). Constructors were unconditionally skipped, which
  hides factory constructors doing validation, JSON normalization or
  mapping work — a common shape in freezed/Flutter model layers, where
  the branching lives in the factory rather than in a method. Bodyless
  and redirecting constructors (`factory Foo() = _Foo;`) stay skipped.
  Off by default: enabling it adds rows to the report and can raise the
  max CRAP of an existing project.

### Fixed

- Baseline: violations were keyed by line number, so any edit above a
  baselined violation (even one blank line) turned it into a "new"
  violation, and measured messages (`1856 lines`, `8.98% duplicated`,
  `coverage 53.0%`) stopped matching as soon as the number moved — even
  when it improved. Baselines now match on gate + file + message shape
  (numbers masked) with per-key counts, and measured violations carry a
  `measure` ceiling: they stay covered while they shrink and fail once
  they grow. `.crap-baseline.json` is now version 2 (no `line`, optional
  `measure`); version 1 files still load.
- `GateRunner` registered `broken_goldens`, `test_assertions`,
  `folder_structure` and `external` twice, so they ran (and reported)
  twice — 25 gate results for 21 gates.
- `analyze --lcov <file>` no longer re-runs the test suite first.
  Because `coverage.run_tests` defaults to `true`, an explicit coverage
  file was silently replaced by a fresh (possibly very long) test run.
  An explicit `--lcov` now skips the config-driven run; `--run-tests`
  still forces one.
- `init` template and README showed `coverage.run_tests: false`,
  contradicting the actual default (`true` since 0.9.0).
- Cyclomatic complexity: `switch` **expression** arms were not counted.
  Only `SwitchCase`/`SwitchPatternCase`/`SwitchDefault` (statement form)
  incremented complexity, so a Dart 3 `switch` expression scored CC 1
  no matter how many arms it had, while the equivalent `switch`
  statement scored one per arm. A 9-arm expression at 0% coverage
  reported CRAP 2.00 instead of 110.00 — an under-report of the exact
  anti-pattern the tool exists to find, on code that is idiomatic modern
  Dart. `SwitchExpressionCase` now counts, so both forms score the same.

### Changed

- `GateRunner`: the three parallel 21-arm `switch` expressions mapping a
  gate id to its `enabled`/`ignorable`/`severity` flag are now lookup
  tables. With the complexity fix above they were CC 23 each (over the
  project's own limit of 12) and drove `GateRunner`'s WMC to 109.

### Changed

- Dependencies refreshed: `analyzer` 7.3 -> 14.4 (new "parts" AST —
  `ClassDeclaration.namePart.typeName`, `NamedType.name`,
  `NamedArgument`/`Argument` model, `body.members`, `isComplete`),
  `xml` 7.1, `test` 1.32, `lints` 6.1.

