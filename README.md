# synapse-work

Native SwiftUI iOS/iPadOS client for the **work** half of the Synapse productivity stack.
The personal-life half ships separately as [`synapse-life`](https://github.com/antonio-mastropaolo/synapse-life).

Both clients consume the same Next.js backend at `synapse-v2`.

## Status

M1 in progress. See `/Users/amastro/.claude/plans/flickering-wishing-yao.md` for the
full milestone plan (M1–M6).

## Layout

```
synapse-work/
  apps/SynapseWork-iOS/      # universal iPhone + iPad app target
  packages/SynapseWorkKit/   # SwiftPM modules: WorkCore / WorkUI / WorkRepositories / WorkFeatures
  project.yml                # XcodeGen spec — regenerate with `xcodegen`
```

## Build

```
brew install xcodegen          # if not installed
xcodegen                       # materialises SynapseWork.xcodeproj
open SynapseWork.xcworkspace   # opens with the SwiftPM package wired in
```

## Surfaces (target scope)

- Spotlight (M1 — first surface)
- Approvals (M2)
- Inbox, Sequences (M3)
- People graph, Reviews (M4)
- Applicants, Ask (M5)
- macOS target + Tier-3 surfaces (M6)
