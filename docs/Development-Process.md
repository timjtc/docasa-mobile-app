# DOCASA — Development Process

Status: active (living document)
Date: 2026-10-30
Companion docs:
- `docs/IoT-Integration-Plan.md` — **architecture authority** (frozen as *Plan v1*; see §1.3 governance)
- `docs/BLE-Protocol-Contract.md` — **interface authority** (frozen v1.0 at Phase 0)
- `docs/Decision-Log.md` — append-only register of decisions; entries supersede Plan v1 sections where noted
- `docs/App-Required-Features.md` — product requirements (input, do not edit)

This document governs **how we work**: phases, gates, verification, and standards. It does not
restate architecture — that lives in the Plan. Plan section references use `Plan §x`.

---

## 1. Review findings (analysis of Plan + Features docs + v3 code audit)

### 1.1 Verified — Plan §1 matches the code

`docasa-air-purifier-v3.ino` (634 lines) was audited against Plan §1.1–§1.2. All claims check out:
monolithic non-blocking loop @ ~66 Hz (`delay(15)`), the `pm10Value` naming trap (holds PM1.0 from
`data.pm10_env`), `currentFanRpm` = commanded target (not measured), 5 s boot screen, LEDC core-3.x
`ledcAttach` API, no BLE/NVS/version-string/firmware-clock anywhere. The Plan's data inventory is
complete for all three required features.

### 1.2 Findings that change or extend the Plan

| # | Finding | Severity | Disposition |
|---|---|---|---|
| R1 | **`fanSeconds` as uint32 overflows** (Plan §4.2). Same math the Plan applies to `pmWeightedFanSeconds` applies here: 3000 h × ~4000 RPM × 3600 s ≈ 4.3 × 10¹⁰ RPM·s ≫ 2³² (u32 dies in ~12 days at max speed). | High (silent data corruption) | Resolved: D-004 — both integrals stored/accumulated as **uint64**. `Preferences.putULong64` exists on core 3.x. |
| R2 | **`runtimeHours` vs `powerOnHours` are defined identically** (Plan §4.2, both "Σ dt while powered"); payload carries both (`on`, `rt`). Redundant. | Low | Resolved: D-004 — merge into one `powerOnSeconds` counter; payload keeps only `on` (whole hours). |
| R3 | **Passkey-on-TFT (Plan §7.8) conflicts with the §1.4 display freeze** — drawing a passkey is display-code change. | Medium (blocks P3 design) | Open: D-010, ruling due at Phase 5 kickoff. Interim: dev builds ship unauthenticated (Plan §7.8 MVP flag). |
| R4 | **NVS partition too small for the P3 offline ring buffer.** Plan §5's ~86 KB/30-day estimate exceeds the default ~20 KB NVS partition. | Medium (P3) | Risk 7.19: custom partition table is a Phase 5 design task; reflash implications noted there. |
| R5 | **ArduinoJson missing from the Plan's library list** (§12.2) — JSON v1 encoding implies it. | Low | Resolved: D-003; pin at Phase 1. |
| R6 | **`fan` key semantics ambiguity** (Plan §3.4 comment vs §9.3 "`rpm` added"). | Low | Resolved in Contract §4: `fan` = commanded target forever; a future measured-RPM key (`rpm`) would be **additive**, never a repurpose. |
| R7 | **App history growth is unbounded** without a downsampling/retention policy (1 Hz ≈ 86 k samples/day). | Medium | Risk 7.22: retention design is a Phase 3 task (§4.4.5). |
| R8 | **Toolchain gaps on this machine**: `arduino-cli` not installed; `flutter` CLI not on shell PATH (Android Studio builds work — `app-debug.apk` exists); repo is **not yet a git repo**. | Low (process) | Phase 0 tasks (§4.1). |
| R9 | **Open Question #1 resolved by user**: module is **ESP32 WROOM** → GPIO16/17 are safe for UART2 (no PSRAM conflict). Plan §7.4 blocker cleared. | — | Recorded: D-001. |
| R10 | Flutter app is the stock counter template; `applicationId` is `com.example.docasa_app` (rename before any real distribution). | Low | Backlog note; not scheduled. |

Open Plan questions still standing: #2 (fan rail — not blocking app work), #4 (filter budgets → D-011),
#5 (core/NimBLE pin verification → Phase 1), #6 (= D-010).

---

## 1.3 Document governance

| Doc | Role | Mutability |
|---|---|---|
| `IoT-Integration-Plan.md` | Architecture authority, *Plan v1* snapshot | **Frozen** — never edited; corrections via Decision-Log entries that cite the superseded section |
| `BLE-Protocol-Contract.md` | The frozen device↔app interface (UUIDs, payloads, commands, semantics) | Versioned; changes require a Decision-Log entry + version bump |
| `Development-Process.md` (this) | Process authority | Living; phase-level amendments via Decision-Log entries |
| `Decision-Log.md` | Append-only register (ADR-lite) | Append-only |
| `docs/gate-reports/G<n>.md` | One-page verification record per phase gate | Created at each gate completion |

---

## 2. Lifecycle model

- **Phase-gated incremental development.** Each phase has entry criteria, a task list, and an
  **exit gate (Gn)** — a concrete verification ritual. A phase is done only when its gate report is
  written. No phase starts before the previous gate passes (exception: Phase 3 can start once
  Phase 0's contract is frozen — see §3).
- **Two tracks joined by a frozen contract.** The firmware track needs the bench (device + serial +
  nRF Connect). The app track is **hardware-free** until Phase 4: it develops against the
  `BLE-Protocol-Contract.md` and a fake-device stream. This removes all hardware dependencies from
  the critical path of app development.
- **Verify, then proceed.** Firmware changes are held to the Plan §12.4 behavior-preservation gate
  (§5.2); app changes are held to `flutter analyze` + `flutter test` green.
- **Small batches.** One concern per commit; gates tagged in git.

```
Phase 0 ──► Phase 1 ──► Phase 2 ─────────────► Phase 4 ──► Phase 5 ──► Phase 6 (future)
 (contract)  (firmware   (firmware               (app+device   (cmds, security,
              NVS)        BLE, nRF-verified)      integration)  offline history)
                  └──────────► Phase 3 (app core, hardware-free) ──────────┘
                            (starts after Phase 0 only)
```

Rough effort (sole developer, focused sessions): P0 0.5 d · P1 0.5–1 d · P2 1–2 d · P3 3–5 d ·
P4 2–3 d · P5 3–5 d. MVP (through Phase 4) ≈ 7–11 working days.

---

## 3. Phase 0 — Foundations & contract freeze

**Goal:** reproducible baselines, version control, frozen interface. No feature work.

**Entry:** this document reviewed by the developer.

Tasks:
1. `git init` + first commit of current state. Extend `.gitignore` for firmware build dirs.
2. Repo housekeeping (permitted by Plan §12.2, file moves only — content untouched, tagged for easy revert):
   ```
   firmware/
     baseline/                                  # frozen references, never built
       docasa-air-purifier-v3.ino                #   diff target for the behavior gate (§5.2)
       Air_Purifier_Final_Revision_pt2.ino
     docasa-air-purifier-v4/                     # active sketch (Arduino: dir == sketch name)
       docasa-air-purifier-v4.ino                # seeded as byte-identical copy of v3
   tools/                                        # scripts (compile check, diff gate)
   ```
3. Install `arduino-cli` + ESP32 core **3.x**; record exact core + library versions in the
   Decision-Log (resolves Plan OQ #5 partially). Compile the byte-identical v4 copy —
   must succeed before any edit (proves toolchain parity).
4. Put `flutter`/`dart` on shell PATH (currently Android Studio only); record
   `flutter analyze` + `flutter test` green on the template baseline.
5. Ratify `BLE-Protocol-Contract.md` v1.0 (UUIDs already generated and frozen — D-002).

**Exit gate G0:** git history exists; v4 copy compiles; app baseline analyze/test green; contract
ratified; Decision-Log seeded (D-001…D-011). Write `docs/gate-reports/G0.md`.

---

## 4. Phase 1 — Firmware: persistence & observability (Plan §8 P0)

**Goal:** NVS raw counters + firmware version, additive only, §1.4-compliant.

Tasks (all inside `docasa-air-purifier-v4.ino`, appended — no restructuring):
1. `Preferences`, namespace `"docasa"`. Keys: `fanSec` (u64, RPM·s), `pwfs` (u64, RPM·µg·s),
   `onSec` (u32, powered seconds). Read into RAM accumulators at boot (D-004).
2. `docasaIoService()` helper called **additively from `loop()`, immediately before `delay(15)`**.
   Internally: 1 Hz tick via unsigned-delta `millis()` math (rollover-safe, Plan §7.2) that
   accumulates `currentFanRpm × dt`, `currentFanRpm × pm25Value × dt`, `onSec += dt`; NVS write
   throttled to every 5 min (Plan §4.2 wear math).
3. `FIRMWARE_VERSION` string (`"4.0.0"` after this phase — D-005); print at boot over Serial.
4. Serial verification line every 60 s dumping counters (watchable without an app).

**Exit gate G1 (bench, ~1 h):** counters grow plausibly at each fan stage (0 RPM stage adds nothing
to `fanSec`); values **survive power cycle**; serial spam does not disturb LCD/LED/fan behavior;
whitespace-ignoring diff vs `baseline/docasa-air-purifier-v3.ino` shows only additive code (§5.2).
Write `docs/gate-reports/G1.md`.

---

## 5. Phase 2 — Firmware: BLE telemetry (Plan §8 P1)

**Goal:** read-only BLE per the Contract, nRF Connect-verified. No commands yet.

Tasks:
1. Add **NimBLE-Arduino 2.x** + **ArduinoJson 7.x** (pins recorded — D-003).
2. GATT server exactly per Contract §2–§3: Device Information, Battery, DOCASA telemetry service
   (Air Quality / Environment / System Status read+notify; Filter Counters read; Command — write
   handler stub that ignores everything in v4.1).
3. BLE init inserted in `setup()` **immediately before `showBootScreen()`** — the one pre-approved
   setup() insertion (Plan §7.6). Advertising is up during the boot animation.
4. Extend `docasaIoService()`'s 1 Hz tick: serialize + notify subscribed characteristics
   (CCCD-gated — risk 7.23); **extra on-change notify** for stage/charging/full transitions
   (Plan §3.3). BLE callbacks set flags only — never call FastLED/TFT (Plan §3.3).
5. Advertising payload per Contract §1 (name in ADV, service UUID in scan response);
   single-central policy (Plan §7.9).

**Exit gate G2 (bench + nRF Connect checklist):** device discoverable by service-UUID filter and
name; connect works **during** the boot animation and after; DIS/BAS reads correct; subscribing
yields 1 Hz notifications whose values match the LCD in real time; stage change pushes an
immediate extra notify; MTU 247 negotiates; disconnect → re-advertises; 10× reconnect + overnight
soak with no crash/heap growth; **boot animation, LCD pages, LED chase, fan behavior unchanged**
(Plan §12.4). Write `docs/gate-reports/G2.md`.

---

## 6. Phase 3 — App core, hardware-free (Plan §8 P2a)

**Goal:** the whole app working against a simulated device. Start immediately after Phase 0.

Tasks:
1. Pin app dependencies (each pin → Decision-Log): `flutter_blue_plus`, `flutter_riverpod`
   (D-007), `drift` + `sqlite3_flutter_libs` (D-008), `fl_chart`, `flutter_local_notifications`,
   `intl`.
2. Architecture scaffold per Plan §6.1 — strict layering, protocol knowledge in one place:
   ```
   lib/
     ble/        interfaces (DocasaConnection) + fake + (later) flutter_blue_plus impl
     protocol/   codec: JSON v1 ↔ typed models; the ONLY file that knows the Contract
     data/       repositories: recording, history queries, filter-health math, settings
     features/   dashboard | system | history | filter | connection
     core/       stage model (mirrors LCD semantics/colors), theme, units
   ```
3. Codec + **golden tests from Contract §8 fixtures** (valid, malformed, unknown-field,
   wrong-version tolerance). The codec suite is the executable form of the Contract.
4. `FakeDocasaDevice`: 1 Hz `Stream<AirSample>` (random-walk PM, stage transitions incl. VOC-bump
   behavior, charging/full events, out-of-range gaps) — drives the entire app.
5. DB schema + recording pipeline with **downsampling tiers** (e.g. raw 1 Hz kept 24–48 h →
   1-min aggregates 7 d → 1-h aggregates 90 d; exact policy decided here, risk 7.22) and history
   queries for day/week/month.
6. Screens per Plan §6.3: dashboard (live mirror of LCD page 0), system (page 1), filter
   (health %, counters detail, reset disabled until Phase 5), connection manager, history charts
   (line charts for PM/temp/humidity/VOC; stage-distribution donut for time-share).
7. Filter-health math + property tests (monotonic consumption, reset → 100%, load-cap interplay,
   u64 ranges — formulas from Plan §4.2 with app-side budgets; defaults from D-011 placeholder).

**Exit gate G3:** `flutter analyze` + `flutter test` green; simulated 24 h session renders
day/week/month views correctly with gaps marked; stage colors/labels match LCD semantics;
filter math tests pass. Write `docs/gate-reports/G3.md`.

---

## 7. Phase 4 — App ↔ device integration (Plan §8 P2b → MVP complete)

**Goal:** real BLE end-to-end. **Entry:** G2 + G3 passed.

Tasks:
1. Set `minSdk` (D-009 — recommend 31); AndroidManifest: `BLUETOOTH_SCAN`
   (`neverForLocation`) + `BLUETOOTH_CONNECT`; runtime permission flow with graceful denial UX.
2. `flutter_blue_plus` implementation of the `ble/` interfaces: scan by service UUID, connect,
   MTU 247, CCCD subscribe, disconnect handling, **reconnect with exponential backoff**
   (0.5→8 s cap, reset on success — Plan §7.15).
3. Connect handshake per Contract §6.1 (snapshot reads, counters read, time sync write,
   subscribe).
4. Wire live stream into the existing recording pipeline; dashboard/system/filter go live;
   day chart fills in real time.
5. Filter replacement **local notification** on threshold crossing (default 10 %, configurable).

**Exit gate G4 (device in hand, checklist):** permission flow on a real phone; scan finds
`DOCASA-AirPurifier` by UUID; connect during boot & post-boot; live values match LCD within ≤2 s;
walk-away disconnect → backoff reconnect works; history survives app restarts; filter % plausible;
time sync sent on every connect. **This gate completes Plan P2 = required features 1 & 3 met,
feature 2 met for connected periods.** Write `docs/gate-reports/G4.md`.

---

## 8. Phase 5 — Commands, security, offline history (Plan §8 P3)

**Goal:** write path + true week/month history.

Tasks:
1. Command characteristic: `resetFilter` (zeroes `fanSec` + `pwfs` only — `onSec` is device
   lifecycle, Contract §5) + confirmed UI flow with post-reset counter re-read.
2. Security decision D-010 executed (bonding/passkey options — needs the §1.4 scope ruling).
3. On-device sparse ring buffer (1 sample/10 min in NVS) — **requires custom partition table**
   (risk 7.19; design note + reflash procedure in the gate report); bulk-sync protocol addition
   → Contract v1.1; app timestamps everything (device epoch is untrusted across reboots,
   Plan §7.13).
4. History views merge app-recorded + device-offline data; gap rendering for power-off periods.

**Exit gate G5:** reset zeroes counters (verified by read-back) and app recomputes 100 %;
bonding flow works (if in scope); week/month views include disconnected periods; §5.2 diff gate
still clean. Write `docs/gate-reports/G5.md`.

---

## 9. Phase 6 — Future (Plan §8 P4/P5 — not scheduled)

WiFi/OTA/cloud (P4) and differential-pressure/outlet-PM hardware (P5) remain deferred per the
Plan, including the restricted-list items (fan override, tach input — Plan §1.4/§9.3).
Trigger: product direction decision, recorded as a new Decision-Log entry.

---

## 10. Cross-cutting standards

### 10.1 Version control
- Trunk-based: short-lived branches (`p1/nvs-counters`, `app/codec`), merged to `main` after gate
  checks. Conventional-style commits. Tag every gate: `gate/G1`, `gate/G2`, …
- No CI server (local-only project) — the pre-merge ritual substitutes: firmware → compile via
  `arduino-cli`; app → `flutter analyze && flutter test`.

### 10.2 Firmware behavior-preservation gate (every firmware change — Plan §1.4/§12.4)
1. `firmware/baseline/docasa-air-purifier-v3.ino` is pristine forever.
2. Every firmware commit message includes the output of
   `diff -w firmware/baseline/docasa-air-purifier-v3.ino firmware/docasa-air-purifier-v4/docasa-air-purifier-v4.ino`
   (or a Phase 0 `tools/` script equivalent).
3. Reviewer confirms hunks are **additive only** and limited to: BLE/NVS/transmission code, plus
   the two pre-approved insertions — `docasaIoService()` before `delay(15)` in `loop()`, and BLE
   init before `showBootScreen()` in `setup()` (Plan §7.6).
4. Bench check: LCD pages, colors, animations, fan behavior, LED behavior, sensor cadence,
   boot sequence unchanged.
5. Anything outside this list requires an explicit user approval **first** (Decision-Log entry).

### 10.3 Testing strategy

| Layer | What | How | Phase |
|---|---|---|---|
| Protocol codec | Golden fixtures (Contract §8), malformed input, unknown-field & version tolerance | Unit | 3 |
| Filter math | Monotonicity, reset, cap interplay, u64 ranges | Unit (property-style) | 3 |
| History pipeline | Downsampling correctness, gap handling, retention pruning | Unit | 3 |
| App state / BLE | Fake device streams, connect/disconnect/reconnect transitions | Unit + widget | 3–4 |
| UI | Stage rendering, permission-denial states, empty/disconnected states | Widget | 3–4 |
| Firmware | Compile gate, §10.2 diff gate, serial soak, nRF Connect checklist | Scripted + manual bench | 1–2 |
| End-to-end | G2 / G4 / G5 checklists with the physical device | Manual | 2, 4, 5 |

### 10.4 Definition of Done (every phase)
1. Exit-gate checklist complete; `docs/gate-reports/G<n>.md` written.
2. `flutter analyze` + `flutter test` green (app) / compile + diff gate clean (firmware).
3. Behavior-preservation bench check signed off (firmware phases).
4. Decision-Log updated for anything decided or discovered.
5. Gate tagged in git.

### 10.5 Risk delta (extends Plan §7 master list — see also §1.2 above)

| # | Risk | Mitigation |
|---|---|---|
| 7.18 | `fanSeconds` u32 overflow (Plan gap) | Resolved by D-004 (uint64 both integrals) |
| 7.19 | Default NVS partition too small for P3 ring buffer | Custom partition table designed in Phase 5; document reflash implications |
| 7.20 | u64 JSON values lose precision on JS platforms | App targets Dart-native (Android) only; web explicitly not a target |
| 7.21 | Unbounded app history growth | Downsampling/retention policy designed in Phase 3 (§6.5) |
| 7.22 | Notify work when nobody subscribed | CCCD-gate all notifies in the 1 Hz scheduler |
| 7.23 | Toolchain: no arduino-cli, flutter off PATH, no git repo | Phase 0 tasks (§3) |

---

## 11. Environment facts (updated at G0 — 2026-10-30)

- **Flutter 3.47.9 stable / Dart 3.13.7** — CLI on PATH (added to `~/.bashrc`); builds also work
  via Android Studio. Template counter app, stock `minSdk = flutter.minSdkVersion`. Baseline:
  analyze clean, tests pass.
- **git 2.55** — repo initialized on `main` at Phase 0 (snapshot `3f77473`).
- **arduino-cli 1.5.1** (`~/.local/bin`) + **ESP32 Arduino core 3.3.12** + baseline libraries
  pinned (versions in D-013). v4 sketch (byte-identical to v3) compiles clean — see
  `docs/gate-reports/G0.md`.
- Target device: ESP32 **WROOM** (D-001), running `firmware/baseline/docasa-air-purifier-v3.ino`.
- All hardware code lives under `firmware/` (project directive).
