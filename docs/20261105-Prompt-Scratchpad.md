Issues/Tasks:
- [x] BLE not connecting
- [ ] Fix graph label colors in 'History' tab when in light mode. When in light mode, line graph tooltip text/numbers are not visible when the graph is pressed/tapped as well as the axis labels. It still follows dark mode theming.
- [ ] Change filter health math
- [ ] Pre-seed filter data for 1 month
- [ ] Filter health alert

---

Prompt 1 - Prep / First fix task

We're continuing this project from a handoff and all docs/code here are pushed before switching development device (from Linux -> Windows). Analyze and index this repo and ensure you adhere to all the specs, requirements, processes and limitations specified in the docs. When doing the software development process, ensure you are doing it methodically and document everything.

The next task is: Fix the BLE connection issue. The app can see the ESP32 from the prototype, but can't fully connect when selected from the device selection, it only shows a 'CONNECTING' indicator on the top right and a constant loading animation on the center. Troubleshoot this by pulling the logcat logs from the dev phone live while the app tries to connect. Rebuild and reinstall the latest BLE build first to ensure consistency.

---

Prompt 2 - Fix graph label

Next task: Fix graph label colors in 'History' tab when in light mode. When in light mode, line graph tooltip text/numbers are not visible when the graph is pressed/tapped as well as the axis labels. It still follows dark mode theming.

---
