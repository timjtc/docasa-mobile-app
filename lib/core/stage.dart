import 'package:flutter/material.dart';

/// Five-level air status — mirrors the device LCD semantics exactly
/// (v3 firmware `updateAirQualityDynamic` / LED colors: GOOD→green,
/// FAIR→yellow, POOR→orange, BAD→red, HAZARD→purple).
enum AirStage {
  good(1, 'GOOD', Color(0xFF4CAF50)),
  fair(2, 'FAIR', Color(0xFFFFC107)),
  poor(3, 'POOR', Color(0xFFFF9800)),
  bad(4, 'BAD', Color(0xFFF44336)),
  hazard(5, 'HAZARD', Color(0xFF9C27B0));

  const AirStage(this.index1, this.label, this.color);

  /// Device-side `overallStage` value (1–5, Contract §4.1).
  final int index1;
  final String label;
  final Color color;

  /// Null for out-of-range values — callers flag/clamp per Contract §8/X6.
  static AirStage? fromIndex(int? i) {
    if (i == null) return null;
    for (final s in AirStage.values) {
      if (s.index1 == i) return s;
    }
    return null;
  }

  /// Clamp an out-of-range stage into the valid band (X6 UI behavior).
  static AirStage clamped(int i) {
    if (i <= 1) return AirStage.good;
    if (i >= 5) return AirStage.hazard;
    return fromIndex(i)!;
  }
}

/// X6 domain clamps — decode is permissive; the UI clamps for display.
abstract final class DomainClamps {
  static int pm(int v) => v.clamp(0, 999);
  static int batteryPct(int v) => v.clamp(0, 100);
  static int fanRpm(int v) => v < 0 ? 0 : v;
}
