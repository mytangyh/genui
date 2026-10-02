# Flutter 3.27.4 compatibility implementation

Status: compatibility code and Android acceptance passed; final fixed-source publication checks in progress.

Current evidence (2026-10-02): supported core strict analysis is clean; upstream
core suites pass (69 + 67 + 1321 + 375), AI SDK unit suites pass (2529 with 11
upstream conditional skips), Google Cloud offline suite passes (202), and SSE
suite passes (13). Android native media integration passes on Redmi 7A. Each
compatibility repository now has its own FVM pin. CI and delivery source checks
are authored locally, not yet executed remotely. See VALIDATION.md for the
separate source, build, runtime and real-model evidence boundaries.

Dartantic's minimal public accessor widening is implemented after explaining
the API difference and alternatives. Its seven offline files pass (146 tests).
simple_chat unit tests pass (3); official samples plus three-mode history/action
follow-up pass in flutter-tester (7); main-entrypoint Android APK builds.

Scope update (2026-10-02): the user now requires Android validation only.
Windows runtime/media is unverified and is no longer an acceptance gate. The
user supplied an OpenAI-compatible gateway and gpt-5.6-luna; credentials are
stored only in ignored local configuration. Seven native Android offline tests
now pass on Redmi 7A. All three live loops now pass, including actual climbing
tool execution and both UI action follow-ups; the user authorized local commits and pushes to mytangyh forks, and
external dependencies now use fixed full commit references. APK compilation alone does not substitute
for real-model acceptance.

The three independent lower dependency repositories additionally pass complete
offline profiles from exported source snapshots and a fresh temporary Pub cache.
All five root lockfiles now use pub.dev, with unchanged package versions/archive
hashes; strict resolution succeeds there. Final remote fixed-commit clones remain
pending and are not inferred from these local checks.

## Fixed inputs and scope

- Official GenUI baseline: `40d4df6a90bcc74513d4278278f59c4903095c26` (latest official main observed on 2026-10-02; includes legacy GenUI and official simple_chat).
- Local checkout: `work/genui`, origin `https://github.com/mytangyh/genui.git`, branch `compat/flutter-3.27.4`.
- FVM: Flutter 3.27.4, Dart 3.6.2, verified by `fvm flutter --no-version-check --version`.
- Keep upstream package names, licenses, architecture, complete standard Catalog, protocol, schemas, binding, events and example behaviors. No TeaTime integration or a2ui_flutter migration.
- `packages/archive/a2ui_core` is activated only after comparing **every published 0.1.0 lib Dart file** with this fixed baseline: identical after newline normalization. Pub metadata points to this same GenUI repository; relocation commit `96b024cb091a86e766c5aaa81081597feac79809` preserves its ancestry. See `evidence/a2ui-source-comparison.json`.
- Schema submodule: `39a26c1af38951840d1542103b99b00dc3a95bf1`; JSON Schema suite: `15e4505bf689de5d30c29d50782bb48fa465c93f`. Checkout these gitlinks, never update to main.
- Existing Workspace changes and original `D:/20_Development/21_Repositories/genui` checkout are preserved.

## Ordered implementation and evidence

1. Resolve workspace with target SDK, using same-repository a2ui_core, genai_primitives, json_schema_builder, genui and the restored simple_chat with its real Dartantic path. The 156-package graph uses twelve fixed Git package sources from four compatibility forks; temporary path overrides are removed. Record package versions, repositories, actual package_config sources and all transitive SDK bounds.
2. Convert unsupported syntax without changing single evaluation, null omission, asynchronous behavior or exceptions. Analyze core, generator and upstream tests; repair real Flutter API incompatibilities. Add behavioral regression coverage for compatibility-sensitive expressions.
3. Adapt Dartantic in a local checkout of its upstream repository on `compat/flutter-3.27.4`; share its monorepo branch across interface and AI packages. Prefer matching compatible released dependencies; fork other source dependencies only if needed. Keep all providers and real model streaming/tool calling.
4. Restore simple_chat workspace membership. Preserve Text only / Basic catalog / Custom catalog, history, climbing UI/tools, action return and follow-up responses. Make model selection configurable and protect local credential files.
5. Initialize fixed submodules and regenerate schema outputs with target build tools. Run format, strict analysis, core + dependency upstream suites and offline simple_chat integration samples. Do not remove failing cases or weaken validation to pass.
6. Per the latest user scope, run Android simple_chat offline integration and interactive checks. Build Android APK. Separately exercise actual audio and video plugins with local test media; record the named Android device. Other native platforms remain unverified, outside acceptance.
7. Run real gpt-5.6-luna interactions through the user-supplied gateway for all three modes, including tool calls, stream/history and UI action follow-up. Configuration is in ignored .compat-local/model.json; offline evidence never substitutes for this step.
8. Add fork-safe CI pinned to 3.27.4: secret-free dependency resolution, source verification, format, analyze, upstream tests, offline flutter-tester integration and Android build. Preserve upstream workflows; compatibility jobs cannot be gated on flutter repository ownership. Credentialed Android live tests are manual and excluded from automatic checks.
9. Prepare dependency/fork inventory, fixed references, lockfile, run instructions, verification evidence, known limitations and upstream synchronization instructions. Replace all development paths/overrides with fixed commit sources before delivery.

## External authorization

On 2026-10-02 the user explicitly authorized local commits and pushes to mytangyh forks. Four dependency forks were created after checking reuse; all five repositories use compat/flutter-3.27.4. This does not authorize a PR merge or release publication.

## Completion audit

Every above step and every user acceptance item needs current authoritative evidence. Dependency resolution, build or starting a window alone is insufficient. Outstanding credentials, remote reference delivery, media runtime validation or actual model loops keep the overall goal incomplete. Keep unsupported tools/examples in the checkout with an explicit support table; they are not first-release gates.
