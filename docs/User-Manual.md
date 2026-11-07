# DOCASA Air Purifier — Mobile App User Manual

**Version:** app build of 2026-11-08 (Contract v1.1 · firmware v4.2.1)  
**Audience:** presenters explaining the product to the panel, and any operator of the app  
**Scope:** everything the app shows and does against one DOCASA air purifier over Bluetooth LE

> This document reflects the *current* build. Two user-facing refinements are already
> agreed and listed in §11 “Planned changes” — present the app as it is today and treat
> §11 as the roadmap answer if the panel asks.

---

## 1. What the product is

The DOCASA mobile app is the companion app for the DOCASA portable air purifier. The
purifier measures the air (particulates, temperature, humidity, chemical-vapor proxy) and
reports its own status (fan speed, battery, filter counters) over BLE using a compact
JSON protocol (Contract v1.1). The phone turns that stream into five simple tabs —
current air quality, system status, history, filter life, and the device itself — and
carries the health story between sessions by asking the device for its counters, its
online history ring, and its saved settings.

Connecting is automatic on app start; everything else is one tap.

---

## 2. The five tabs

The notch at the bottom always shows five tabs. A pill in the top-right shows the
connection state at a glance (table below).

| Tab | What it answers |
|---|---|
| **Air** | “Is the air safe right now, and what should I do about it?” |
| **System** | “What is the device measuring, and how is it doing?” |
| **History** | “How has the air behaved over time?” |
| **Filter** | “How much life is left in the filter, and when should I replace it?” |
| **Device** | “Am I connected, and which device am I talking to?” (plus developer tools) |

### 2.1 Air tab (AIR MONITOR)

- **Stage hero** — the headline: `GOOD`, `FAIR`, `POOR`, `BAD`, `HAZARD`. The color
  mirrors the device LCD semantics (green → yellow → orange → red → purple). Below it
  the live **PM2.5** reading in µg/m³ with a “live · updated hh:mm” timestamp.
- **PM1.0 / PM10** tiles — the same moment, the other particle size bands, µg/m³.
- **Recommendations** (bottom of the page) — two short, plain-language bullets that
  adapt to the current stage: what the air means for the user and what to do with the
  purifier. E.g. POOR: “Air is poor — breathing irritation is likely, especially for
  sensitive people.” / “Keep the purifier on and windows closed; avoid outdoor
  exertion.” If the device sent an unclear stage value, the card reads a human
  “the device sent an unclear air level — retrying.” note instead of jargon.

Presenter tip: this tab is the “at a glance” story — stage first, numbers second,
advice third. The wording follows a condensed AQI health-category reference the product
owner supplied (D-033).

### 2.2 System tab (SYSTEM STATUS)

| Tile | Meaning |
|---|---|
| **Temperature** | Room temperature, °C |
| **Humidity** | Relative humidity, % |
| **Air chemicals (VOC)** | A rough gauge of chemical-vapor level in kΩ. When it drops below 30 kΩ the tile turns amber and explains: “Chemical vapors high — air level counts worse” — the device actually bumps the reported air stage in that condition, which is why the wording mentions it |
| **Fan speed** | Current commanded fan speed in RPM |
| **Battery** | Charge %, or FULL; shows “Charging” while on external power |

No technical sub-labels are shown; each number is self-describing.

### 2.3 History tab (HISTORY)

- **Range switcher:** `Day` · `Week` · `Month` · `Last month`.
  `Last month` is the *previous complete calendar month* (calendar-bounded, D-032).
- **Metric dropdown:** PM2.5 / PM10 / PM1.0 (µg/m³), Temperature (°C), Humidity (%),
  VOC (kΩ). Fan and Battery graphs were retired from the UI (D-032).
- **Coverage line** under the chart: “Coverage: NN% of window — gaps mean no recorded
  data.” The chart draws line breaks where nothing was recorded.
- **Month compare card** (when viewing `Last month`): a short summary that contrasts
  the previous month with the current one — presenter-friendly closing line.
- **Refresh** icon re-queries.

Story worth telling: the device records 10-minute summary envelopes into its own flash
ring (~2 months at 138 KB) and the app back-fills its timeline from that ring on every
connect (Contract v1.1 §10, D-028). So the history is not phone-recorded-only; a phone
that reconnects after days away still shows the gapless device-recorded story.

### 2.4 Filter tab (FILTER)

- **FILTER LIFE** hero: the remaining filter health in %, color-coded (green > 50 %,
  amber > 20 %, red at/below), a progress bar, and the **projected replacement date**
  (“… (N days at recent usage)”) once there is enough recent usage to project.
- **Filter sensitivity** slider: `Relaxed (latest)` (×1.5) · `Normal (default)` (×1.0)
  · `Sensitive (sooner)` (×0.5). It scales the budget and moves the projected
  replacement date accordingly.
- **Replacement basis** — the consumer is pinned to `Dirty-air hours`; there is no
  basis selector on this tab (D-036). The explanation card below states in plain
  language how the basis estimates consumption; budget numbers are placeholders until
  the real cartridge model is chosen (D-011/D-018) — presenters should say “a
  placeholder budget, to be replaced with the real cartridge numbers”, not a measured
  truth. Developers flip the basis in Developer options (§3.4).
- **Replace filter → “I replaced the filter”** — the manual replacement action. Tapping
  it opens a confirmation prompt:
  - Title: *“Did you replace the filter?”*
  - Body: “Confirming zeroes the purifier’s filter-life counters (the usage
    integrals). Lifetime power-on hours are kept.”
  - *Not yet* — safe dismissal, nothing changes.
  - *Yes, filter replaced* — sends `resetFilter` to the purifier: fresh 100 % health,
    the replacement date re-projects, and the alert story re-arms.

### 2.5 Device tab (DEVICE)

- **Connection card:** “Connected to DOCASA-AirPurifier” / “Connecting…” / “No device
  connected”, with `Disconnect` and `Connect`/`Reconnect`. On the demo build the
  Connect/Reconnect opens the same device-selection sheet as the real transport (a mock
  DOCASA row with signal bars) so the flow is presentable without hardware (D-033).
- **Device information:** Maker, Model, Firmware, Hardware. On this build’s demo the
  fake device’s firmware reads “4.1.0” — a cosmetic placeholder of the emulator; the
  real purifier reports its true 4.2.1.
- **Device counters** (developer-only, §3.4): the raw per-stage exposure seconds and
  lifetime counters.
- **Developer options** (developer-only, §3.4): demo tools, including the 2-month
  seeding that produces the panel story.

---

## 3. Connecting, states, and developer tools

### 3.1 Connection states (top-right pill and Device tab)

| Pill | Meaning |
|---|---|
| `CONNECTED` (green) | Live link — data flows, counters refresh while connected |
| `CONNECTING` (amber) | Handshake in progress |
| `OFFLINE` (grey) | No link. Data recording pauses; the device keeps its own history |

### 3.2 Auto-connect and reconnect

- The app **auto-connects on start** to the paired purifier (demo build: to the
  built-in emulator) — no action needed for the panel.
- `Reconnect` (from a connected state) closes the link and opens the device picker —
  the same flow users see with the real hardware.
- Device picker rows show only the **advertised name + a signal-strength icon**
  (cellular bars, ≥ −60 dBm full bars, ≥ −75 dBm mid, else weak). No dBm digits, no
  service-tag text.

### 3.3 Time sync and handshake

On every connect the app reads the device info and syncs the phone clock to the device
(Contract §5). This is what keeps history timestamps honest across trips.

### 3.4 Developer options (demo/dev builds)

Hidden by default (D-030). Reveal: tap the **Device information card 7 times** within
2.5 s windows (a demo/dev knob, also useful as a party trick on stage). Inside:

| Control | Effect |
|---|---|
| Toggle switch | Turns the section off again |
| **Seed demo data (2 months)** | Replaces the phone history timeline with a generated 2-month story (clean stretches + dirty episodes) and pushes matching usage counters into the device (real NVS on a 4.2.1 purifier; the emulator echoes) — the health then reads ≈1–2 % on Normal (D-030/D-031) |
| **Clear history** | Wipes the phone-side history DB |
| **Preview filter alert** | Raises the replacement modal directly (demo-only, D-021) |
| **Device counters** card | Fan usage (equivalent full-speed hours), PM-weighted load (weighted particle-and-fan index), Dirty-air time (hours in POOR/BAD/HAZARD since the filter swap), Time share per stage (one line per air level), Powered on (lifetime) |
| **Replacement basis (developer)** | Switches the health engine between `Dirty-air hours` and `Load (µg·h)`. Consumers are pinned to dirty-air hours on the Filter tab; this knob is the only way to change it (D-036) |

Counters “live on the purifier and survive power cycles” — on real hardware they are
NVS-resident; *never* run erase/erase-flash on the purifier, it would wipe those
counters and the offline ring.

---

## 4. The filter replacement alert (D-021, D-035)

The story the panel cares most about:

1. **When it fires** — while connected, the health is at or below the alert threshold
   (default ≤ 10 %), evaluated on every connect and every 5 minutes while connected.
2. **How it presents** — app in the foreground → the in-app modal (“Filter needs
   replacing — health is at N%…”); app in the background → a system push notification,
   whose tap opens the app straight into the modal.
3. **Reconnect is a trigger** — a fresh connect (boot or user reconnect) re-surfaces
   degraded health **even within 24 h of the previous alert** (D-035); routine
   background ticks remain capped at most once per day.
4. **Modal actions**
   - *“I’ll replace it at a later time”* — acknowledge and continue; the reminder
     respects the ≤1/day cap while still degraded.
   - *“I just replaced the filter”* — sends `resetFilter` to the device, zeroing the
     usage integrals (lifetime power-on hours are preserved) and re-arms the story with
     a fresh filter.

Demo flow that always lands: seed (§3.4) → modal at ~1–2 % → acknowledge →
**reconnect** → the modal returns (the point of D-035).

---

## 5. Where data lives (persistence)

| Data | Lives on | Survives |
|---|---|---|
| Device counters (filter integrals, st[]) | Purifier NVS | A purifier power cycle; NOT erasing/erase-flash |
| Offline 10-min history ring | Purifier flash (256 KB docasa_ring) | ~4.6 months of runway |
| Phone history timeline + daily buckets | Phone DB | App restarts; wiped by “Clear history” |
| Basis/sensitivity/ack settings | Phone DB | App restarts |
| Demo emulator runtime state | App process memory | NOT an app restart — re-seed after a restart |

On the demo build a fresh app start returns the emulator to healthy defaults; the
seeded *history* stays on the phone, but the filter counters must be re-seeded before a
panel session if the app was restarted.

---

## 6. Theme

The moon toggle (top-right) switches dark/light instantly; the choice persists.

---

## 7. Demo playbook (presenters)

A reliable 3-minute run, verified on the phone (see `docs/App-ADB-Test.md` when driving
by script):

1. **Show the Air tab live** — the emulator produces a believable PM story; point at
   stage → PM2.5 → PM1.0/PM10 → Recommendations.
2. **Tell the filter story** — Filter tab: 100 % healthy → dev options (info-card
   ×7) → `Seed demo data (2 months)` → the replacement modal arrives (health ≈ 1–2 %).
   Explain the modal and its two actions; choose *later time*. Mention the manual
   “I replaced the filter” action now lives on the Filter tab itself (§2.4).
3. **Show the evidence trail** — History tab: switch Day/Week, then `Last month` and
   the month-compare card; point out the coverage line and the offline-ring else.
4. **Close on the Device tab** — connection card (mention reconnect now re-prompting
   the alert, §4), Device information, and the raw Device counters as “the engineering
   truth under the friendly UI”.
5. If the panel asks “what if I really changed the filter?” — show `I just replaced the
   filter` semantics in words (device integrals zero, life returns to ~100 %, the alert
   re-arms) — do NOT press it mid-demo, it resets the seeded story.

Panel-pitfalls to avoid:
- Restarting the app mid-demo puts the emulator counters back to healthy — re-seed.
- Don’t erase the purifier flash (NVS counters + ring are the demo’s data spine).
- The demo fake reports firmware “4.1.0” in Device information — say it is the
  emulator’s placeholder if asked.
- Developer options ON state is remembered; leave the section ON for the panel, or
  flip the switch to hide it if you want a pristine customer view.

---

## 8. Troubleshooting quick list

| Symptom | Meaning / action |
|---|---|
| OFFLINE right after app start | The link is (re)establishing; the auto-connect loop retries — wait a beat or use `Reconnect` |
| “Filter health is…” never updates | It updates on connect and on 5-min ticks; the seeded story changes after `Seed demo data` |
| History shows gaps | No recording happened while disconnected; gaps are shown truthfully (“gaps mean no recorded data”) |
| Modal did not return on reconnect | It re-presents on reconnect while health is ≤ threshold and the health computation saw the degraded counters (D-035); on the demo, re-seed if the app restarted |
| adb phone shown `unauthorized` | Accept the RSA prompt on the phone (screen may need waking) |
| Watch-host: pressing serial port resets the ESP32 | Known host quirk; avoid opening COM while the app is mid-demo |

---

## 9. Glossary (use these words on stage)

| Term | Plain meaning |
|---|---|
| PM2.5 / PM1.0 / PM10 | Particle sizes the purifier measures, in µg/m³ |
| VOC | A rough chemical-vapor level gauge (BME680 proxy), kΩ |
| Stage | The five-level air story GOOD→HAZARD mirrored on the device LCD |
| Filter basis | The rule that converts usage into filter-life % |
| Dirty-air hours | Time spent in POOR/BAD/HAZARD air since the filter swap |
| Sensitivity | How much of the budget the user allows (Relaxed/Normal/Sensitive) |
| Ring | The device’s own 10-min flash history used to back-fill the phone |
| NVS | Non-volatile storage on the purifier — counters live here |
| Handshake | Device-info read + clock sync performed on every connect |

---

## 10. Reference documents

- `docs/BLE-Protocol-Contract.md` — frozen protocol interface (v1.1)
- `docs/Development-Process.md` — process, phases, gates
- `docs/Decision-Log.md` — every product decision, D-001…D-035
- `docs/sessions/2026-11-05-ble-connect-triage.md` — session trail (Tasks 1–17)
- `docs/App-ADB-Test.md` — scripted on-device driving notes
- `docs/Bench-Runbook.md` — formal bench checklists (G1/G2)

**PDF export** (keep at A4 default):  
`pandoc docs/User-Manual.md -o DOCASA-User-Manual.pdf --toc -V geometry:margin=2cm`  
(Any Markdown-to-PDF tool works; the file contains no HTML or exotic syntax.)

---

## 11. Recent refinements (shipped in this build)

The two Filter-tab revisions agreed near panel-freeze are now IN this build (D-036):

1. **Basis selection is developer-only** — the Filter tab no longer offers a basis
   selector; consumers are pinned to `Dirty-air hours`. The switching control lives in
   Developer options as **Replacement basis (developer)** (§3.4).
2. **Manual filter replacement on the Filter tab** — the enabled **“I replaced the
   filter”** action with its confirmation prompt (“Did you replace the filter?” →
   *Not yet* / *Yes, filter replaced*) replaces the old disabled placeholder.

If the panel asks about the old two-choice basis UI: it was a dev-only choice from day
one of the story — the consumer UX now reflects that.
