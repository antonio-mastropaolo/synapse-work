# Synapse Work — agent instructions

This file briefs Claude Code (and any AI collaborator) on how to work in this
repository. Read it before editing.

## Project

Synapse Work is the native iOS + macOS reframe of the **work** half of Synapse
v2 (the web app at `/Users/amastro/Projects/synapse-v2`). Synapse v2 stays
canonical for product behavior; Synapse Work re-implements it using SwiftUI,
SwiftData, and `URLSession` — no `WKWebView` wrappers, no React Native, no
Capacitor. The native idiom wins on every surface.

Surfaces hosted here: Spotlight, Approvals, Inbox, Sequences, People,
Reviews, Conferences, Cost, Ask, Timeline, Shell, Settings. **Private-life
surfaces** (personal finance, life-log, advisors) live in the sibling
[`synapse`](https://github.com/antonio-mastropaolo/synapse) repo — do not
port them here.

## Hard rules

1. **Swift 6, strict concurrency.** All shared DTOs are `Sendable`. Views are
   `@MainActor`. Actor boundaries are explicit and justified.
2. **No force-unwraps. No force-casts.** Use `guard`, `throws`, `try #require`
   in tests. The lint config enforces this.
3. **Test-first when adding behavior.** Write or extend tests before the
   implementation. The package's `swift test` is the load-bearing gate.
4. **No emojis** in code, comments, commit messages, or docs.
5. **No changelog-in-comments.** Comments answer "why", not "what just
   changed". Phrases like `// removed`, `// added for X`, `// previously`
   are forbidden.
6. **Do not wrap web views.** If a feature seems hard to native-port, file a
   note and discuss — do not reach for `WKWebView` as a shortcut.

## Tooling

- `xcodegen generate` regenerates `SynapseWork.xcodeproj` from `project.yml`.
  The `.xcodeproj` is checked in for convenience; if you change `project.yml`,
  regenerate and commit both.
- `swift test --package-path packages/SynapseWorkKit` runs the package tests.
- `swiftformat .` and `swiftlint` enforce style.

## Module boundaries

Mirrors the layout of sibling [`synapse`](https://github.com/antonio-mastropaolo/synapse):

- `Networking` owns transport. It does not know about persistence or UI.
- `Auth` owns the keychain. It does not call the network.
- `DesignSystem` is pure — no networking, no persistence.
- `Models` is the only module other modules are allowed to import broadly.

## Translation references

When translating a Synapse v2 work-side feature, follow this order:

1. Read the v2 source at `/Users/amastro/Projects/synapse-v2/<area>/`. Identify
   the framework (React/Next/etc.), state shape, routes, API surface.
2. Decide the native idiom per platform: iPhone, iPad regular, Mac. Do not
   port literally — translate intent.
3. Land the change behind tests where it makes sense.

## When in doubt

Default to the Human Interface Guidelines, then to whatever Synapse v2 already
encoded as user-visible behavior. Disagreement with either is fine — just
write down why.
