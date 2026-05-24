# Synapse Work — App Store Readiness

Scope: ship the native iOS and macOS clients of Synapse Work (research
paper triage, approvals/reimbursements, editorial pipeline, contact graph,
cold-email sequences) to the App Store. This document is the operator
checklist — read once, act on it.

## Identity

- Display name: **Synapse Work** (`CFBundleDisplayName`). Xcode targets
  retain `SynapseWork` internally.
- Bundle IDs:
  - iOS: `tech.synapse.work.ios`
  - macOS: `tech.synapse.work.mac`
- App group: `group.tech.synapse.work`
- Primary App Store category: **Productivity**. Secondary: **Business**.
- URL schemes:
  - Deep links: `synapse-work://`
  - OAuth callback: `tech.synapse.work://oauth` (used for Gmail / Workday
    /editorial-portal session handoff via the synapse-v2 backend; the
    client never holds OAuth secrets itself).
- Sign in with Apple is the only first-party auth path.

## Data the app collects

This app's data is more sensitive than the Life app's because it touches
academic email, vendor receipts, and applicant records. Be conservative on
the questionnaire.

- **Identifiers**: Apple user identifier from Sign in with Apple. Optional
  institutional email (`@wm.edu` or equivalent) if the user binds one.
- **User content**: research paper titles and abstracts pulled from
  Spotlight, reimbursable receipts, approval emails, applicant CVs and
  cover letters, contact-graph entries, drafted cold-email sequences.
  All synced to the synapse-v2 backend, scoped to the signed-in user.
- **Email content**: subjects, bodies, and attachments of emails the user
  has explicitly granted access to via OAuth. Stored on the synapse-v2
  side; the client streams them on demand.
- **Usage data**: request counts, error rates. No analytics SDK.
- **Diagnostics**: opt-in crash reports.
- **Not collected**: contacts (we read editorial-portal exports, not the
  device address book), photos, location, microphone, camera, HealthKit,
  ad identifiers.

## What's shared with Anthropic

The Ask surface and Spotlight's per-paper "read for me" path stream
completions through synapse-v2 to Anthropic. Anthropic receives the prompt
text, which may include paper abstracts, email bodies, or applicant CVs the
user has chosen to feed into an Ask query. Anthropic does not receive the
user's Apple ID, the user's institutional email, or any data the user did
not explicitly include in a prompt. Disclosed in the privacy policy and on
first launch of any surface that performs an LLM call.

## Biometric usage

Optional Face ID / Touch ID gate on app launch and on Approvals (which can
show reimbursement amounts and W&M worktag codes). Justification string:
*"Synapse Work uses Face ID to unlock approvals and email."* Keep it that
short.

## Account deletion

Settings → Account → Delete account. Hits
`POST /api/account/delete` on synapse-v2, which purges the user row, all
joined work-side rows (receipts, approvals, spotlight queue, contacts,
sequences), and revokes OAuth tokens with the upstream providers (Gmail,
Workday connector, editorial portals). Confirmation requires re-auth.

## Demo account considerations for review

Sign in with Apple is **not** sufficient on its own here. A reviewer who
signs in with their own Apple ID will see an empty Spotlight, an empty
Approvals tree, and no Inbox — they cannot meaningfully exercise the app.

Strategy: ship a sanitized fixture account.

- Provision a dedicated reviewer account on the synapse-v2 backend with the
  Apple ID `appreview@synapse.tech` (real Apple ID created and held by the
  developer). Password / 2FA shared in App Review notes.
- Seed it with synthetic data: ten papers in Spotlight (real arXiv IDs,
  real abstracts), three reimbursement receipts tagged `demo=true`, a
  five-contact people graph, one drafted sequence in `Sequences`, and a
  small fake editorial-portal inbox. No real applicants, no real emails,
  no real vendor receipts.
- The fixture data resets nightly via a launchd job so reviewers always see
  the same state.
- The Anthropic-proxied surfaces (Ask, "read for me") run on the same
  free-tier quota as the Life app's reviewer flow.

OAuth-gated surfaces (Gmail, Workday) are shown in a read-only "demo
provider" mode for the reviewer account — the buttons are live, the data
is fixture. Document this explicitly in App Review notes so the reviewer
does not try to bind their own Gmail.

## Screenshot requirements

- iPhone 6.7" (1290×2796): Spotlight queue, paper detail with Ask drawer,
  Approvals tree, Inbox, Sequences.
- iPad 13" (2064×2752): Spotlight with split-view, People graph,
  Approvals with worktag editor.
- macOS (2880×1800): Spotlight in a real window with the LLM-as-judge
  scoring panel, Inbox triage, Sequences composer.

Capture from the fixture account so no real research data leaks.

## Milestone ordering

1. **Pre-flight**: bundle IDs registered, App Store Connect record
   created, OAuth callback scheme registered in `Info.plist`,
   `xcodegen generate` clean.
2. **Fixture reviewer account** provisioned and nightly-reseeding job
   verified on Neon `synapse` schema.
3. **Account deletion path** wired and verified end-to-end including OAuth
   revocation.
4. **Privacy policy and ToS** live (shared with Synapse Life — same
   documents cover both apps).
5. **App Privacy questionnaire** filled in matching the data section. Mark
   "Linked to user" for user content and email content; both are tied to
   the signed-in account, not anonymous.
6. **Screenshots** from the fixture account only.
7. **App Review notes** drafted with reviewer-account credentials and a
   note that OAuth providers are sandboxed for that account.
8. **TestFlight** internal pass, then external for at least three days.
9. **Submit** iOS first; macOS once iOS clears.
