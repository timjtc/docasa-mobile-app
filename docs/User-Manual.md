# DOCASA Air Purifier — Mobile App User Manual

**Version:** app release of November 2026 (purifier firmware 4.2.1)  
**Audience:** owners and operators of the DOCASA portable air purifier  
**Scope:** everything the DOCASA app shows and does with your purifier over
Bluetooth Low Energy (BLE)

> This manual matches the current app. Anything unfamiliar is explained in
> plain words in the Glossary (§9). If the app and this manual ever differ,
> this file is updated with every app release.

---

## 1. What the product is

The DOCASA app is the companion app for the DOCASA portable air purifier. The
purifier measures the air — particulate levels (PM1.0/PM2.5/PM10), temperature,
humidity, and a chemical-vapor gauge (VOC) — and reports its own status (fan
speed, battery, filter-usage counters) over Bluetooth Low Energy. The phone
turns that stream into five simple tabs — current air quality, system status,
history, filter life, and the device itself — and keeps the story alive
between sessions by asking the purifier for its counters, its recorded offline
history, and its saved settings.

Connecting is automatic on app start; everything else is one tap.

---

## 2. The five tabs

The bar at the bottom of the screen always shows five tabs. The label at the
top-right shows the connection state at a glance (§3.1).

How this manual names screen parts (plain words only — no jargon):

| Word | What it means |
|---|---|
| **Tab** | One of the five sections at the bottom of the screen (Air, System, History, Filter, Device) |
| **Card** | A rounded box of related information on a page (e.g. the FILTER LIFE card) |
| **Slider** | A control you drag sidewise to pick a value (e.g. the filter-sensitivity slider) |
| **Switch** | An on/off control that flips (e.g. the dark/light moon switch at the top-right) |
| **Progress bar** | The horizontal bar that shows a % by filling or draining |
| **Pop-up** | A message box that appears over the screen until you act on it (e.g. the filter-replacement alert) |
| **Label** | Small standing text, such as the connection state at the top-right |

| Tab | What it answers |
|---|---|
| **Air** | “Is the air safe right now, and what should I do about it?” |
| **System** | “What is the device measuring, and how is it doing?” |
| **History** | “How has the air behaved over time?” |
| **Filter** | “How much life is left in the filter, and what do I do about it?” |
| **Device** | “Am I connected, and which device am I talking to?” |

### 2.1 Air tab (AIR MONITOR)

- **Air level card** — the big colored headline at the top: `GOOD`, `FAIR`,
  `POOR`, `BAD`, `HAZARD`. The color mirrors the device LCD/LED colors
  (green → yellow → orange → red → purple). Below it, the live **PM2.5**
  reading in µg/m³ with a “live · updated hh:mm” timestamp.
- **PM1.0 / PM10** cards — the same moment, the other particle size bands,
  µg/m³.
- **Recommendations** (bottom of the page) — two short, plain-language
  sentences that adapt to the current air level: what it means for the user
  and what to do with the purifier. E.g. POOR: “Air is poor — breathing
  irritation is likely, especially for sensitive people.” / “Keep the
  purifier on and windows closed; avoid outdoor exertion.” If the device sent
  an unclear air level, the card reads a human “the device sent an unclear
  air level — retrying” note instead of an error code.

The wording follows the widely used AQI (Air Quality Index) health guidance,
condensed to what matters for the purifier.

### 2.2 System tab (SYSTEM STATUS)

| Card | Meaning |
|---|---|
| **Temperature** | Room temperature, °C |
| **Humidity** | Relative humidity, % |
| **Air chemicals (VOC)** | A rough gauge of chemical-vapor level in kΩ. Below 30 kΩ the card turns amber: “Chemical vapors high — air level counts worse” — the device actually counts the air one level worse in that condition, which is why the wording says so |
| **Fan speed** | Current fan speed in RPM (revolutions per minute) |
| **Battery** | Charge %, or FULL; shows “Charging” while on external power |

Each number is self-describing — the cards carry no technical sub-labels.

### 2.3 History tab (HISTORY)

- **Range selector:** `Day` · `Week` · `Month` · `Last month`.
  `Last month` is the *previous complete calendar month*.
- **Metric dropdown:** PM2.5 / PM10 / PM1.0 (µg/m³), Temperature (°C),
  Humidity (%), VOC (kΩ).
- **Coverage line** under the chart: “Coverage: NN% of window — gaps mean no
  recorded data.” The chart draws line breaks where nothing was recorded.
- **Month compare card** (with `Last month`): a short summary that contrasts
  the previous month with the current one.
- **Refresh** icon re-queries the chart.
- **Notes card** (bottom): “History is recorded by the app while connected to
  the purifier. Offline periods (device off or out of range) appear as gaps.
  When the purifier is back in range, the recorded history is recovered.”

**What happens when you go out of range:** the purifier keeps recording
10-minute air summaries into its own memory (the *offline history*, about two
months of capacity). When the phone comes back in range, the app asks the
purifier for that recording and merges it into your charts — a phone that
reconnects after days away still shows the full story.

### 2.4 Filter tab (FILTER)

- **FILTER LIFE** card: the remaining filter health in %, color-coded
  (green > 50 %, amber > 20 %, red at/below), a progress bar, and the
  **estimated life remaining** — e.g. “About 8 months left · based on recent
  usage”. When close to replacement it switches to days (“About 12 days
  left”), and before enough usage is recorded it says so honestly. No
  calendar dates are shown — just an honest time estimate.
- **Filter sensitivity** slider: `Relaxed (latest)` · `Normal (default)` ·
  `Sensitive (sooner)`. The plain-language line beneath it: “Sliding toward
  Sensitive means the filter will need to be replaced sooner; sliding toward
  Relaxed means it will last longer. Normal keeps the estimate balanced.”
- **How life is counted** — the estimate is based on the time the air spends
  at POOR, BAD or HAZARD around the purifier (its “dirty air”); the
  explanation card on the tab states this in plain language. At Normal
  sensitivity a freshly replaced filter is expected to last around 8 months
  of typical home use.
- **Replace filter → “I replaced the filter”** — the replacement
  confirmation. After physically swapping the cartridge, tap it and a
  confirmation pop-up appears:
  - Title: *“Did you replace the filter?”*
  - Body: “Confirming will reset what the purifier has recorded about the
    filter’s usage, and it will start tracking the filter’s usage again from
    this point on.”
  - *Not yet* — safe dismissal, nothing changes.
  - *Yes, filter replaced* — the tracking restarts fresh (≈100 % health),
    and the alert story re-arms.

### 2.5 Device tab (DEVICE)

- **Connection card:** “Connected to DOCASA-AirPurifier” / “Connecting…” /
  “No device connected”, with `Disconnect` and `Connect`/`Reconnect` (§3.2).
- **Device information:** maker, model, firmware and hardware versions of the
  purifier — worth quoting whenever you contact support (§10).

---

## 3. Connecting and staying connected

### 3.1 Connection states (top-right label and Device tab)

| Label | Meaning |
|---|---|
| `CONNECTED` (green) | Live link — data flows; readings refresh while connected |
| `CONNECTING` (amber) | Link in progress |
| `OFFLINE` (grey) | No link. Phone-side recording pauses; the purifier keeps recording on its own |

### 3.2 Auto-connect and reconnect

- The app **auto-connects on start** to your purifier — no action needed.
- `Reconnect` (from a connected state) closes the link and opens the device
  list — handy after a move or if another phone was connected in between.
- Devices in the list show the **advertised name + a signal-strength icon**
  (cellular-style bars: full bars when close, fewer as you move away). When
  nothing personal to DOCASA is in range, the list shows “other nearby
  devices” with a plain hint to power on and keep the purifier close.

### 3.3 At every connect

On every connect the app reads the purifier’s identity (maker, model,
firmware) and syncs the phone clock to the device — that is what keeps
history timestamps honest across trips.

---

## 4. The filter replacement alert

1. **When it appears** — while connected, when filter health reaches the
   alert level (10 % by default), re-checked on every connect and every
   5 minutes while connected.
2. **How it presents** — app in the foreground → the in-app pop-up
   (“Filter needs replacing — health is at N%…”); app in the background → a
   system notification, whose tap opens the app straight into the pop-up.
3. **Reconnect re-checks** — a fresh connect (app start or `Reconnect`)
   re-surfaces degraded health even if a reminder was shown within the last
   24 hours; ordinary background checks otherwise remind at most about once
   a day.
4. **Pop-up actions**
   - *“I’ll replace it at a later time”* — acknowledge and continue; the
     reminder then repeats at most about once a day while the filter is
     still worn.
   - *“I just replaced the filter”* — after physically swapping the
     cartridge, this confirms it in the purifier: usage tracking restarts
     fresh (≈100 % health) and the alert window re-arms.

You are never nagged: one daily reminder while the filter is worn, plus a
courtesy re-check whenever you open the app or reconnect.

---

## 5. Where data lives

| Data | Lives on | Survives |
|---|---|---|
| Filter usage counters | Inside the purifier (NVS, §9) | A purifier power cycle; erased only by a memory reset |
| Offline air history (10-minute summaries) | Inside the purifier (offline ring, §9) | About two months back; recovered on your next connect |
| Your history charts on the phone | Phone storage | App restarts |
| Your settings (sensitivity, theme, reminders) | Phone storage | App restarts |

Filter health is device truth: it is counted in the purifier itself, so the
percentage follows the purifier, not the phone.

---

## 6. Theme

The moon switch (top-right) changes dark/light instantly; the choice persists.

---

## 7. Getting started and daily use

1. **First run** — power on the purifier and open the app. The first connect
   asks for the phone’s Bluetooth and notification permissions; accept them
   both (notifications are how the replacement reminder reaches you when the
   app is closed).
2. **In range** — keep the phone within Bluetooth range of the purifier for
   live readings; the Air and System tabs update continuously.
3. **Out of range** — live readings pause, but nothing is lost: the purifier
   records its own offline history (§2.3, §5) and the charts back-fill when
   you return.
4. **Replacing the cartridge** — swap the cartridge as described in the
   purifier’s own guide, then in the app: Filter tab → *“I replaced the
   filter”* → confirm (§2.4). Health returns to ≈100 %.
5. **Deciding when to replace** — the alert (§4) does the checking for you;
   the sensitivity slider (§2.4) lets households with allergies or other
   sensitivities lean toward earlier replacement.

---

## 8. Troubleshooting

| Symptom | Meaning / action |
|---|---|
| OFFLINE right after app start | The link is (re)establishing; wait a moment or use `Reconnect` |
| The app cannot find the purifier | Power the purifier on and keep it close; check Bluetooth is on for the phone, then `Reconnect` |
| Filter health never updates | It refreshes on every connect and every 5 minutes while connected |
| History shows gaps | No recording happened while disconnected; gaps are shown truthfully (“gaps mean no recorded data”) and back-fill from the purifier’s own recording on reconnect |
| Pop-up did not return on reconnect | It re-presents while health is at/below the alert level and the purifier still reports low filter life; if you actually replaced the cartridge, confirm it with *“I replaced the filter”* (§2.4) |
| Notifications not arriving | Check the phone’s notification settings for the DOCASA app (§7) |

---

## 9. Glossary / definition of terms

Read this once — it explains every word this manual uses.

| Term | Definition |
|---|---|
| **BLE** (Bluetooth Low Energy) | The wireless link between the purifier and the phone — low-power, short-range radio, the successor of classic Bluetooth. All device↔phone communication travels over it. |
| **Firmware** | The program running inside the purifier — it reads the sensors, drives the fan, and speaks to the app. The current release is 4.2.1, shown on the Device tab. |
| **ESP32** | The small computer inside the purifier; it runs the firmware, reads the sensors, handles the Bluetooth radio. |
| **PM1.0 / PM2.5 / PM10** | Particulate-matter readings: the mass concentration of airborne particles ≤ 1.0 / 2.5 / 10 micrometers across, in micrograms per cubic meter (µg/m³). PM2.5 is the headline because those particles reach deep into the lungs. |
| **µg/m³** | Micrograms per cubic meter — how many millionths-of-a-gram of particles sit in a one-meter cube of air. Higher = dirtier. |
| **VOC** | Volatile Organic Compounds — gases from cleaners, cooking, paint. The sensor reports them as a resistance in kilo-ohms (kΩ); lower resistance = more gas = a dirtier reading. It is a relative gauge, not a lab instrument — the app words it “Air chemicals (VOC)”. |
| **Stage** | The five-level air-quality story — GOOD (1), FAIR (2), POOR (3), BAD (4), HAZARD (5) — mirrored on the purifier’s LCD and LED colors. Each level is derived from the PM readings (and the VOC condition). |
| **Dirty-air hours** | The accumulated time the air sat at POOR, BAD or HAZARD since the filter was installed — the basis of the filter-life estimate. |
| **Budget** | The rated amount of dirty-air exposure a cartridge is designed to last; the app turns what remains into the % you see. |
| **Sensitivity** | A personal multiplier on that budget: Normal keeps the estimate balanced, Sensitive expects replacement sooner, Relaxed expects it later. |
| **Recent usage** | How fast the filter is wearing down in your home, measured over the recorded days — the “based on recent usage” in the projection comes from this. |
| **Alert threshold** | The filter health below which the replacement pop-up appears (10 % by default). |
| **Daily cap** | The reminder repeating at most about once a day, so the app never nags; opening the app or reconnecting can re-check sooner. |
| **NVS** | Non-Volatile Storage — the flash memory inside the purifier that keeps settings and counters while the power is off. It is why filter health is device truth, not a phone guess. Erasing it (a factory-reset/service operation) deletes the counters and the offline history — avoid it unless support instructs otherwise. |
| **Offline ring** | The purifier’s memory that records 10-minute air summaries whenever the phone is out of range — about two months of capacity. On your next connect the app merges it into the phone’s charts. |
| **Handshake** | The automatic exchange at every connect: the app reads the purifier’s identity and syncs the clock, so every recorded moment is timestamped consistently. |
| **Device list** | The screen that lists nearby devices by advertised name with signal bars. It hides phones and other noise — only DOCASA purifiers (plus, in a separate group, “other nearby devices”) appear. |

---

## 10. Where to get more help

- If this manual and what you see diverge, or a problem persists after §8,
  contact the DOCASA team and quote the **Firmware** and **Hardware** values
  from the Device tab — they identify your unit.
- Updates to the app are announced with the product; the Manual version above
  tells you whether your copy is up to date.

---

## 11. What’s new in this version

1. **Air-tab Recommendations** — plain-language advice that adapts to the
   current air level.
2. **Reconnect re-checks** — reconnecting re-surfaces the replacement pop-up
   even within the daily reminder window (§4).
3. **“I replaced the filter”** — the replacement confirmation now lives on
   the Filter tab itself, with its confirmation pop-up (§2.4).
4. **Honest projection** — the Filter tab reads “About N months left · based
   on recent usage”, with no calendar dates; at Normal sensitivity a fresh
   filter projects around 8 months.
5. **Fresh launcher look** — the app icon now carries the DOCASA logo.
