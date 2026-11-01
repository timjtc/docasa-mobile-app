# Filter-Health Math — NVS counters → health % → projections

Source of truth: `firmware/docasa-air-purifier-v4/docasa-air-purifier-v4.ino`
(DOCASA IoT additions, ~lines 880–935), `docs/BLE-Protocol-Contract.md` §4.4,
and the app-side model `lib/data/filter_health.dart` + `lib/providers.dart`.

## 1. What the NVS partition stores (namespace `docasa`)

| NVS key | Type/units | Meaning |
|---|---|---|
| `fanSec` | uint64, **RPM·s** | Usage integral: Σ (fan RPM × seconds the fan actually runs) |
| `pwfs` | uint64, **RPM·µg·s** | Load integral: Σ (fan RPM × µg/m³ PM2.5 × seconds) |

Two u64 keys, deliberately tiny. Both accumulate every whole second while the
sketch runs, with a sub-second residual counter keeping the whole-second math
exact (no rounding drift):

```
docasaFanSeconds       += fanRpm · dt_sec          // RPM·s
docasaPmWeightedFanSec += fanRpm · pm25 · dt_sec   // RPM·µg·s
```

- **Persistence is throttled to once per 5 minutes** (Plan §4.2 flash-wear math).
  A hard power cut loses at most ~5 min of accumulated usage, never the history.
- `docasaPowerOnSeconds` (lifetime powered hours) lives in **RAM only** and
  resets each boot — intentionally Informational, it is NOT part of health %.
- The sub-second residual is also RAM-only (in-session precision).

## 2. Why these two counters drive filter health

1. **`fanSec` — time/air-move wear.** A filter ages with the air it processes,
   not with wall-clock powered time: idling at 0 RPM accumulates nothing;
   a fan running hard at high RPM ages it fastest.
2. **`pwfs` — load wear.** The "dirty-air" axis: at equal RPM-time, running
   through a dust event (high PM2.5) consumes filter life faster. This matches
   the load-model used by commercial purifiers — an **estimate**, not a direct
   measurement (BME680-derived PM values are uncalibrated proxies).
3. **NVS = continuity across power cycles.** Filter life would be meaningless
   if a reboot restarted the meter; restore-on-boot keeps the counters
   continuous across unplugs (restored at `docasaNvsRestore()` → `fanSec`/`pwfs`).
4. **Reset semantics** (Phase 5, D-010): `resetFilter` zeroes the two usage
   integrals `fanSec`/`pwfs` **only** — power-on lifetime hours are preserved.
5. **Overflow safety**: uint64 plus codec clamps (Contract X-tests) keep
   hostile/overflow payload values from crashing the math.

## 3. App-side math (`computeFilterHealth`, budgets per D-011/D-018)

```
loadFrac = pwfs / loadBudgetRpmUgS     // "dirt" consumption vs load budget
hourFrac = fanSec / hourBudgetRpmS     // "air-moved" time vs hour budget
consumed = max(loadFrac, hourFrac), clamped 0..1
health % = (1 − consumed) × 100
```

- `loadBinding = loadFrac >= hourFrac` — which axis dominates. In a polluted
  home the load budget binds; in a clean room the hour budget does. The Filter
  page tells the user which counter is the failing axis.
- Health only drops while the purifier is actually moving (and dirtying) air —
  powered-and-idling time shows up in `powerOnHours` but consumes nothing.

### Replacement projection

- **Level** comes from NVS (`pwfs`).
- **Rate** comes from the app's recorded history — `estimateLoadRatePerDay()`
  over the drift minute aggregates (needs enough recorded samples; returns
  null otherwise).
- `remainingDays = (loadBudget − pwfs) / loadRatePerDay`, clamped ≥ 0;
  `projectedReplacement = now + remainingDays` (shown in the Filter page).
- Null rate → no projection displayed (health % still works).

## 4. Budgets (D-011/D-018)

`FilterBudgets` placeholders ≈ 3000 h nominal-equivalent load/hour budgets are
configurable; replace with the real cartridge numbers when the actual filter
model is chosen (the bench session is the natural moment — Decision-Log D-018).
