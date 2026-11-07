# DOCASA Air Purifier — Mobile App User Manual

**Version:** app build of 2026-11-09 (Contract v1.1 · firmware v4.2.1 · tip `0dc9b3c`)  
**Audience:** everyday users of the app, and the product presenters explaining it to the panel  
**Scope:** everything the app shows and does against one DOCASA air purifier over
Bluetooth Low Energy (BLE)

> This document reflects the *current* build — every screen in it is verified against
> the phone. Two notes for presenters: (1) all product decisions are numbered `D-###`
> and live in `docs/Decision-Log.md` — the numbers appear here only as citations, never
> on any screen; (2) technical terms are defined in the Glossary (§9) — use those
> definitions, not assumptions, when the panel asks “what does X mean?”

---

## 1. What the product is

The DOCASA mobile app is the companion app for the DOCASA portable air purifier. The
purifier measures the air — particulate levels (PM1.0/PM2.5/PM10), temperature,
humidity, and a chemical-vapor gauge (VOC) — and reports its own status (fan speed,
battery, filter-usage counters) over Bluetooth Low Energy using a compact JSON
protocol called the **Contract** (v1.1). The phone turns that stream into five simple
tabs — current air quality, system status, history, filter life, and the device
itself — and keeps the story alive between sessions by asking the purifier for its
counters, its recorded offline history, and its saved settings.

Two launcher builds share this UI, both carrying the DOCASA square-logo launcher icon
(D-039):

- **DOCASA** (the BLE build) — talks to the real purifier over Bluetooth.
- **DOCASA Demo** — self-contained emulator mode, for demos without hardware.
  Emulator = a built-in software stand-in for the purifier, running inside the app.

Connecting is automatic on app start; everything else is one tap.

---

## 2. The five tabs

The notch at the bottom always shows five tabs. A pill in the top-right shows the
connection state at a glance (§3.1).

| Tab | What it answers |
|---|---|
| **Air** | “Is the air safe right now, and what should I do about it?” |
| **System** | “What is the device measuring, and how is it doing?” |
| **History** | “How has the air behaved over time?” |
| **Filter** | “How much life is left in the filter, and what do I do about it?” |
| **Device** | “Am I connected, and which device am I talking to?” (plus developer tools) |

### 2.1 Air tab (AIR MONITOR)

- **Stage hero** — the headline: `GOOD`, `FAIR`, `POOR`, `BAD`, `HAZARD`. The color
  mirrors the device LCD/LED semantics (green → yellow → orange → red → purple).
  Below it, the live **PM2.5** reading in µg/m³ with a “live · updated hh:mm”
  timestamp.
- **PM1.0 / PM10** tiles — the same moment, the other particle size bands, µg/m³.
- **Recommendations** (bottom of the page) — two short, plain-language bullets that
  adapt to the current stage: what the air means for the user and what to do with the
  purifier. E.g. POOR: “Air is poor — breathing irritation is likely, especially for
  sensitive people.” / “Keep the purifier on and windows closed; avoid outdoor
  exertion.” If the device sent an unclear stage value, the card reads a human
  “the device sent an unclear air level — retrying.” note instead of jargon.

Presenter tip: this tab is the “at a glance” story — stage first, numbers second,
advice third. The wording follows a condensed AQI (Air Quality Index) health-category
reference the product owner supplied (D-033).

### 2.2 System tab (SYSTEM STATUS)

| Tile | Meaning |
|---|---|
| **Temperature** | Room temperature, °C |
| **Humidity** | Relative humidity, % |
| **Air chemicals (VOC)** | A rough gauge of chemical-vapor level in kΩ. Below 30 kΩ the tile turns amber: “Chemical vapors high — air level counts worse” — the device actually bumps the reported air stage in that condition, which is why the wording says so |
| **Fan speed** | Current commanded fan speed in RPM (revolutions per minute) |
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
  the previous month with the current one — a presenter-friendly closing line.
- **Refresh** icon re-queries.
- **Notes card** (bottom): “History is recorded by the app while connected to the
  purifier. Offline periods (device off or out of range) appear as gaps. When the
  purifier is back in range, the recorded history is recovered.”

Story worth telling: during the offline gaps the purifier records 10-minute summary
envelopes into its own flash storage (the **offline ring**, ~2 months of capacity) and
the app merges that recording into the charts on reconnect (Contract §10, D-028). The
history is therefore not phone-recorded-only; a phone that reconnects after days away
still shows the story straight after the drain.

### 2.4 Filter tab (FILTER)

- **FILTER LIFE** hero: the remaining filter health in %, color-coded (green > 50 %,
  amber > 20 %, red at/below), a progress bar, and the **estimated life remaining** —
  e.g. “About 8 months left · based on recent usage”. When close to replacement it
  switches to days (“About 12 days left”), and before enough usage is recorded it
  says so honestly. No calendar dates are ever shown (user decision from the copy
  sweep).
- **Filter sensitivity** slider: `Relaxed (latest)` (×1.5) · `Normal (default)` (×1.0)
  · `Sensitive (sooner)` (×0.5). The plain-language line beneath it: “Sliding toward
  Sensitive means the filter will need to be replaced sooner; sliding toward Relaxed
  means it will last longer. Normal keeps the estimate balanced.”
- **Replacement basis** — the consumer is pinned to `Dirty-air hours`; there is no
  basis selector on this tab (D-036). The explanation card below states in plain
  language how the basis estimates consumption. The budget is a calibrated placeholder
  (D-037/D-038: 5,300 h of dirty-air exposure ≈ 8 months at Normal) — presenters
  should say “a calibrated placeholder budget, to be finalized with the real cartridge
  numbers”, not a measured truth. Developers flip the basis in Developer options
  (§3.4).
- **Replace filter → “I replaced the filter”** — the manual replacement action.
  Tapping it opens a confirmation prompt:
  - Title: *“Did you replace the filter?”*
  - Body: “Confirming will reset what the purifier has recorded about the
    filter’s usage, and it will start tracking the filter’s usage again from
    this point on.”
  - *Not yet* — safe dismissal, nothing changes.
  - *Yes, filter replaced* — sends `resetFilter` to the purifier: the tracking
    restarts fresh (≈100 % health), and the alert story re-arms.

**Calibration (D-037/D-038):** the dirty-air budget is **5,300 h of POOR+ exposure** —
at Normal sensitivity and recorded normal-use exposure, a freshly reset filter
projects **~8 months** (the accepted 6–10-month band; Sensitive ≈4 months, Relaxed
≈12). It is a calibrated placeholder budget — the real cartridge model supersedes it
(D-011/D-018) when its numbers land.

### 2.5 Device tab (DEVICE)

- **Connection card:** “Connected to DOCASA-AirPurifier” / “Connecting…” / “No device
  connected”, with `Disconnect` and `Connect`/`Reconnect`. On the demo build the
  Connect/Reconnect opens the same device-selection sheet as the real transport (a
  mock DOCASA row with signal bars) so the flow is presentable without hardware
  (D-033).
- **Device information:** Maker / Model / Firmware / Hardware. On this build’s demo,
  the fake device’s Firmware reads “4.1.0” — a cosmetic placeholder of the emulator;
  the real purifier reports its true 4.2.1.
- **Device counters** (developer-only, §3.4): the raw per-stage exposure seconds and
  lifetime counters.
- **Developer options** (developer-only, §3.4): demo tools, including the 2-month
  seeding that produces the panel story.

---

## 3. Connecting, states, and developer tools

### 3.1 Connection states (top-right pill and Device tab)

| Pill | Meaning |
|---|---|
| `CONNECTED` (green) | Live link — data flows; counters refresh while connected |
| `CONNECTING` (amber) | Link in progress (handshake) |
| `OFFLINE` (grey) | No link. Phone-side recording pauses; the purifier keeps recording on its own |

### 3.2 Auto-connect and reconnect

- The app **auto-connects on start** to the paired purifier (demo build: to the
  built-in emulator) — no action needed for the panel.
- `Reconnect` (from a connected state) closes the link and opens the device picker —
  the same flow users see with the real hardware.
- Device-picker rows show only the **advertised name + a signal-strength icon**
  (cellular bars: ≥ −60 dBm full bars, ≥ −75 dBm two bars, else one). No dBm digits,
  no service-tag text — friendlier nothing (D-033). When nothing personal to DOCASA
  is in range, the picker lists “other nearby devices” with a plain hint to power on
  and keep the purifier close.

### 3.3 Time sync and handshake

On every connect the app reads the device info and syncs the phone clock to the
device (the *handshake*, Contract §5). This is what keeps history timestamps honest
across trips.

### 3.4 Developer options (demo/dev builds)

Hidden by default (D-030). Reveal them by tapping the **Device information card 7
times** (taps must come within ~2.5 s of each other). Inside:

| Control | Effect |
|---|---|
| Toggle switch | Turns the section off again |
| **Seed demo data (2 months)** | Replaces the phone history timeline with a generated 2-month story (clean stretches + dirty episodes) **and fills the whole current day 00:00→23:59**, so the Day chart always has data (D-038). It also pushes matching usage counters into the device (real NVS on a 4.2.1 purifier; the emulator echoes) — health then reads ≈1–2 % on Normal, and the replacement alert fires right away (D-030/D-031) |
| **Clear history** | Wipes the phone-side history database |
| **Preview filter alert** | Raises the replacement modal directly (demo-only, D-021) |
| **Device counters** card | Fan usage (equivalent full-speed hours), PM-weighted load (weighted particle-and-fan index), Dirty-air time (hours in POOR/BAD/HAZARD since the filter swap), Time share per stage (one line per air level), Powered on (lifetime) |
| **Replacement basis (developer)** | Switches the health engine between `Dirty-air hours` and `Load (µg·h)`. Consumers are pinned to dirty-air hours on the Filter tab; this knob is the only way to change it (D-036) |

Counters “live on the purifier and survive power cycles” — on real hardware they sit
in the purifier’s NVS (flash memory that remembers things while powered off, defined
properly in the Glossary). **Never run an erase/erase-flash on the purifier** — it
would wipe these counters and the offline ring, deleting the whole history story.

---

## 4. The filter replacement alert (D-021, D-035)

The story the panel cares most about:

1. **When it fires** — while connected, the health is at or below the alert threshold
   (default ≤ 10 %), re-evaluated on every connect and every 5 minutes while
   connected.
2. **How it presents** — app in the foreground → the in-app modal (“Filter needs
   replacing — health is at N%…”); app in the background → a system push
   notification, whose tap opens the app straight into the modal.
3. **Reconnect is a trigger** — a fresh connect (boot or user reconnect) re-surfaces
   degraded health **even within 24 h of the previous alert** (D-035); routine
   background ticks remain capped at most once per day.
4. **Modal actions**
   - *“I’ll replace it at a later time”* — acknowledge and continue; the reminder then
     respects the at-most-once-per-day cap while the filter is still degraded.
   - *“I just replaced the filter”* — sends `resetFilter` to the purifier: the usage
     tracking restarts fresh (≈100 % health), and the alert window re-arms.

Demo flow that always lands: seed (§3.4) → modal fires at ~2 % → press *“I just
replaced the filter”* → the Filter tab reads ~100 % and “About 8 months left” →
reconnect again to re-arm the modal story when needed (D-035).

---

## 5. Where data lives (persistence)

| Data | Lives on | Survives |
|---|---|---|
| Device counters (filter integrals, st[]) | Purifier NVS | A purifier power cycle; NOT erasing/erase-flash |
| Offline 10-min history ring | Purifier flash (256 KB docasa_ring) | ~4.6 months of runway |
| Phone history timeline (minute/hour aggregates) | Phone DB | App restarts; wiped by “Clear history” |
| Basis / sensitivity / alert-ack settings | Phone DB | App restarts |
| Demo emulator runtime state | App process memory | NOT an app restart — re-seed after a restart |

On the demo build, a fresh app start returns the emulator to healthy defaults; the
seeded *history* stays on the phone, but the filter counters must be re-seeded before
a panel session if the app was restarted.

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
   ×7) → `Seed demo data (2 months)` → the replacement modal arrives (health ≈ 2 %).
   Explain the modal and its two actions; choose *“I’ll replace it at a later time”*.
   Mention the manual “I replaced the filter” action that lives on the Filter tab
   itself (§2.4).
3. **Show the evidence trail** — History tab: switch Day (the seeded current day is
   fully populated — D-038), Week, then `Last month` and the month-compare card; point
   out the coverage line and the offline-recording story.
4. **Close on the Device tab** — connection card (mention that reconnect re-prompting
   the alert is now a feature, §4), Device information, and the raw Device counters as
   “the engineering truth under the friendly UI”.
5. If the panel asks “what if I really changed the filter?” — describe the
   *“I just replaced the filter”* semantics in words (the tracking restarts, life
   returns to ~100 %, the alert re-arms) — do NOT press it mid-demo, it resets the
   seeded story.

Panel-pitfalls to avoid:
- Restarting the app mid-demo puts the emulator counters back to healthy — re-seed.
- Don’t erase the purifier flash (the NVS counters + ring are the demo’s data spine).
- The demo fake reports firmware “4.1.0” in Device information — say it is the
  emulator’s placeholder if asked.
- Developer options ON state is remembered; leave the section ON for the panel, or
  flip the switch to hide it if you want a pristine customer view.
- Re-seeding also resets the alert daily-cap clock — the modal fires immediately and
  again on every reconnect, which is exactly the demonstration you want.

---

## 8. Troubleshooting quick list

| Symptom | Meaning / action |
|---|---|
| OFFLINE right after app start | The link is (re)establishing; the auto-connect loop retries — wait a beat or use `Reconnect` |
| “Filter health is…” never updates | It updates on connect and on 5-min ticks; the seeded story changes after `Seed demo data` |
| History shows gaps | No recording happened while disconnected; gaps are shown truthfully (“gaps mean no recorded data”), and the offline ring fills them on reconnect |
| Modal did not return on reconnect | It re-presents on reconnect while health is ≤ threshold and the counters read degraded (D-035); on the demo, re-seed if the app restarted |
| adb phone shown `unauthorized` | Accept the RSA prompt on the phone (screen may need waking) |
| Watch-host: pressing serial port resets the ESP32 | Known host quirk; avoid opening COM while the app is mid-demo |

---

## 9. Glossary / definition of terms

Read this once — it is everything a presenter needs when a technical word comes up.

| Term | Definition |
|---|---|
| **BLE** (Bluetooth Low Energy) | The wireless link between the purifier and the phone — low-power, short-range radio, the successor of classic Bluetooth. All device↔phone communication travels over it. |
| **Contract (v1.1)** | The written interface agreement between firmware and app: what every BLE message must contain (readings, counters, commands) and how they are encoded. “Frozen” means hardware and app agree on it before either changes. |
| **Firmware** | The program running inside the purifier’s ESP32 chip — it reads the sensors, walks the fan, and speaks the Contract. v4.2.1 is the flashed lineage. |
| **ESP32** | The micro-controller board inside the purifier; has Wi-Fi/Bluetooth on board. |
| **PM1.0 / PM2.5 / PM10** | Particulate-matter readings: the mass concentration of airborne particles ≤ 1.0 / 2.5 / 10 micrometers across, in micrograms per cubic meter (µg/m³). PM2.5 is the headline because those particles reach deep into the lungs. |
| **µg/m³** | Micrograms per cubic meter — how many millionths-of-a-gram of particles sit in a cubic-meter cube of air. Higher = dirtier. |
| **VOC** | Volatile Organic Compounds — gases from cleaners, cooking, paint. The sensor (a BME680) reports them as a resistance in kilo-ohms (kΩ); lower resistance = more gas = a dirtier reading. It is a relative gauge, not a lab instrument — the app words it “Air chemicals (VOC)”. |
| **Stage** | The five-level air-quality story — GOOD (1), FAIR (2), POOR (3), BAD (4), HAZARD (5) — mirrored on the purifier’s LCD and LED colors. Each stage is derived from the PM levels (and the VOC bump below 30 kΩ). |
| **Filter basis** | The rule that converts filter usage into a filter-life percentage. Consumers use the `Dirty-air hours` basis; `Load (µg·h)` remains a developer option. |
| **Dirty-air hours** | The accumulated time the air sat in POOR/BAD/HAZARD since the filter was installed. The installed basis subtracts it from the budget: health % = 100 − dirty time ÷ allowed time. |
| **Budget** | The amount of dirty-air exposure (in seconds) a filter is allowed before replacement. Currently a calibrated placeholder: 5,300 h (D-037/D-038). |
| **Sensitivity** | A multiplier the user applies to that budget: Normal ×1.0, Sensitive ×0.5 (replace in half the time → sooner), Relaxed ×1.5 (last longer). |
| **Calibrated placeholder** | A number chosen deliberately from an assumed usage model (≈ how much dirty air a normal home sees a day) — to be replaced with measured cartridge data later (D-011/D-018). |
| **Device counters / integrals** | The tallies the purifier keeps: total fan work (RPM-seconds), particulate-weighted fan work (RPM·µg·s), powered-on hours, and the per-stage seconds (st[]). “Integral” = math-speak for these running sums. They feed the filter-health formula. |
| **NVS** | Non-Volatile Storage — the small flash-memory area *inside the purifier’s ESP32* used like a tiny hard drive for settings and counters: it survives power-offs and reboots. It is why filter health is device-truth, not a phone guess. Wiping it (an “erase/erase-flash” operation) deletes that memory — never do it on the demo unit. |
| **Ring / offline ring** | A ring-shaped (oldest-is-overwritten) block of the purifier’s flash that stores 10-minute air summaries while the phone is away. Capacity ~256 KB ≈ 2 months. On reconnect the app “drains” it and merges those windows into the phone timeline — the reason gaps can reappear as data. |
| **Handshake** | The little ritual at every connect: the app reads the purifier’s identity (maker/model/firmware) and syncs the clock, so every recorded second is timestamped consistently. |
| **Emulator (fake connection)** | A software recreation of the purifier inside the demo app, speaking the same Contract. It powers the hardware-free demo path; its device info deliberately shows firmware “4.1.0”. |
| **Bucket / aggregate** | The charting time-slices: one row per minute (`minute_aggregates`) or per hour (`hour_aggregates`) holding averages and per-stage seconds. Gaps in the buckets = gaps in the chart. |
| **Recent usage / rate** | How fast the filter consumed its budget over the recorded window (seconds of dirty air per day). The projection multiplies the remaining budget by that rate — hence “based on recent usage”. |
| **Alert threshold** | The health % below which the replacement alert fires (default 10 %). |
| **Daily cap** | The once-per-24-h rule for background re-alerts, so the app never nags; a fresh (re)connect re-surfaces the alert even inside this window (D-035). |
| **Whitelist of names** | The picker hides phones/noise — it only surfaces devices whose BLE advertisement belongs to a DOCASA purifier (D-002), with everything else tucked away as “other nearby devices”. |
| **Adaptive icon** | Android’s two-layer launcher icon (a foreground logo + a background the launcher shapes into circles/squares). Both app builds carry the DOCASA logo this way, generated from `assets/docasa-logo-square-icon.png`. |
| **seed / seeding** | The demo tool that back-fills a believable 2-month timeline and matching counters (D-030). The whole current day is included, so the Day chart always opens populated (D-038). |

---

## 10. Reference documents

- `docs/BLE-Protocol-Contract.md` — frozen protocol interface (v1.1)
- `docs/Development-Process.md` — process, phases, gates, handoff state
- `docs/Decision-Log.md` — every product decision, D-001…D-039
- `docs/sessions/2026-11-05-ble-connect-triage.md` — session trail (Tasks 1–23)
- `docs/App-ADB-Test.md` — scripted on-device driving notes
- `docs/Bench-Runbook.md` — formal bench checklists (G1/G2)

**PDF export** (A4, styled tables, TOC):  
`bash tools/export-user-manual-pdf.sh` → `releases/DOCASA-User-Manual-<date>.pdf`  
(pandoc → styled HTML → headless-Chromium print; needs only pandoc and Google
Chrome — no LaTeX. The print stylesheet lives in `docs/pdf-header.html`.)

---

## 11. Refinements shipped in this build

The app has been on a consumer-focus pass; the visible refinements, newest last:

1. **User-centric copy sweep** (D-033) — picker rows show a name + signal bars only;
   the System tab speaks in plain tiles; the Air tab gained stage-appropriate
   **Recommendations**; dev jargon removed from user surfaces.
2. **Device counters relocated** (D-034) — raw counters moved to the Device tab behind
   developer mode; the Filter tab is consumer-only.
3. **Reconnect re-alerts** (D-035) — reconnecting re-surfaces a degraded filter’s
   modal even within the once-per-day window.
4. **Filter-tab consumer batch** (D-036) — basis selection moved to Developer options
   (consumers are pinned to Dirty-air hours) and the manual **“I replaced the filter”**
   action with its confirmation prompt arrived.
5. **6–10-month calibration** (D-037/D-038) — the dirty-air budget recalibrated so a
   freshly reset filter projects ≈8 months at Normal; the projection reads
   “About N months left” with no calendar dates, and seeding fills the whole current
   day so the Day chart always has data.
6. **Branding** (D-039) — the BLE build is simply **DOCASA**; both builds carry the
   square DOCASA launcher icon.

If the panel asks “why can’t I change the
basis?” — it was a developer/engineering choice all along; the consumer UX now shows
exactly that.
