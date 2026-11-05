Issues/Tasks:
- [x] BLE not connecting
- [x] Fix graph label colors in 'History' tab when in light mode. When in light mode, line graph tooltip text/numbers are not visible when the graph is pressed/tapped as well as the axis labels. It still follows dark mode theming.
- [ ] Add a more simpler filter health math - only use the accumulated air quality time share as the basis for filter replacement. This should be added as a toggleable filter replacement method in the 'Filter' tab.
  - This mode should be the default. Keep the old method still accessible and don't remove it yet from the codebase
  - The user must be able to set a customizable threshold/sensitivity value that moves the filter replacement date sooner/later (e.g. default/normal is the most sensible, lower/higher means the filter must be replaced sooner, whichever makes sense) (this is for demonstration purposes, when the prototype is presented)
- [ ] Pre-seed filter data for 1 month
- [ ] Filter health alert
- [ ] Clean up UI

---

Prompt 1 - Prep / First fix task

We're continuing this project from a handoff and all docs/code here are pushed before switching development device (from Linux -> Windows). Analyze and index this repo and ensure you adhere to all the specs, requirements, processes and limitations specified in the docs. When doing the software development process, ensure you are doing it methodically and document everything.

The next task is: Fix the BLE connection issue. The app can see the ESP32 from the prototype, but can't fully connect when selected from the device selection, it only shows a 'CONNECTING' indicator on the top right and a constant loading animation on the center. Troubleshoot this by pulling the logcat logs from the dev phone live while the app tries to connect. Rebuild and reinstall the latest BLE build first to ensure consistency.

---

Prompt 2 - Fix graph label

Next task: Fix graph label colors in 'History' tab when in light mode. When in light mode, line graph tooltip text/numbers are not visible when the graph is pressed/tapped as well as the axis labels. It still follows dark mode theming.

---

Prompt 3 - Filter replacement math revision

Now assist me in setting decisions/directions first. For context, the next task requires some major revision: Add a more simpler filter health math - only use the accumulated air quality time share as the basis for filter replacement. This should be added as a toggleable filter replacement method in the 'Filter' tab. The user must be able to set a customizable threshold/sensitivity value that moves the filter replacement date sooner/later (e.g. default/normal is the most sensible, lower/higher means the filter must be replaced sooner, whichever makes sense) (this is for demonstration purposes, when the prototype is presented)

The reason for this is to simplify the math and the explanation of the product to a panel. However, there are a couple of problems that I see here:
- If we use accumulated air quality share as the basis, the data must be reset when filter is replaced
- But we want data retention for at least 2 months, so the filter health computation must be differentiated/subtracted
- When disconnected, the app cannot record the air quality time share

Before changing anything, here's my question first. Can the ESP32 record and store air quality data for 2 months? If not, is there any way to compress it?

---

Prompt 4 - Filter health model revision

Decision:
1. (a) dirty-air hours only (POOR/BAD/VERY-BAD) (recommended)
2. Budget multiplier with named steps (Relaxed 1.5×, Normal 1.0×, Sensitive 0.5×). I want the same user-friendly scale for the original filter math instead of setting values in the filter model budget text fields.
3. accumulated air quality time share as the default setting
(A) Recommended: include gapless offline history now — v4.2.0 = stage counters and offline envelope ring and v1.1 sync; one partition reflash; Day chart stays; all three views back-filled.

Some concerns: since we're offloading the air quality keeping to the ESP32, we need an efficient way to query it on connect (like a query JSON payload sent by the app, only initiated on select moments like on app connect)

Switching back to build mode, so document the necessary stuff now.
