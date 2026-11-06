import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/stage.dart';
import '../../protocol/models.dart';
import '../../providers.dart';
import '../shared/widgets.dart';

/// Live air monitor — mirrors the device LCD page 0 (AIR MONITOR).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState =
        ref.watch(connectionStateProvider).value ??
            DocasaConnectionState.disconnected;
    final telemetry = ref.watch(telemetryProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIR MONITOR'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ConnectionChip(connState),
          ),
        ],
      ),
      body: _body(context, ref, connState, telemetry),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    DocasaConnectionState connState,
    DocasaTelemetry? t,
  ) {
    final air = t?.air;
    final stage = AirStage.fromIndex(air?.stage);
    return ConnectGate(
      connState: connState,
      child: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        StageHero(
          stage: stage,
          pm25: air?.pm25,
          updatedAt: t?.at,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ValueTile(
                label: 'PM1.0',
                value: air == null ? '—' : '${DomainClamps.pm(air.pm1)}',
                subtitle: 'µg/m³',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ValueTile(
                label: 'PM10',
                value: air == null ? '—' : '${DomainClamps.pm(air.pm10)}',
                subtitle: 'µg/m³',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (stage == null) ...[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child:
                  Text('The device sent an unclear air level — retrying.'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Recommendations sit at the bottom, after the PM sections
        // (user request).
        _recommendations(stage),
      ],
      ),
    );
  }

  /// Health recommendations for the current air level (user request) —
  /// plain-language, purifier-actionable. Reference wording from the AQI
  /// health-category guidance (Good→Hazardous, D-033), condensed so a normal
  /// user knows: what the air means for them + what to do about it.
  List<String> _recommendationList(AirStage? stage) => switch (stage) {
        null => ['Reading the current air level…'],
        AirStage.good => [
            'Air is clean — no health concerns. Enjoy your space.',
            'Run the purifier as usual; ventilation is safe.',
          ],
        AirStage.fair => [
            'Air quality is fair — sensitive people (asthma, allergies) may '
                'feel mild symptoms; keep outdoor activity light.',
            'Keep the purifier running to pull the level down.',
          ],
        AirStage.poor => [
            'Air is poor — breathing irritation is likely, especially for '
                'sensitive people.',
            'Keep the purifier on and windows closed; avoid outdoor exertion.',
          ],
        AirStage.bad => [
            'Air is bad — heart and lungs come under stress; irritations are '
                'more likely for everyone.',
            'Run the purifier at full power, keep windows shut, and avoid '
                'indoor smoke or fumes.',
          ],
        AirStage.hazard => [
            'Hazardous air — strong irritation is likely for everyone; avoid '
                'outdoor activity.',
            'Keep the purifier at maximum and stay in the cleanest room.',
          ],
      };

  Widget _recommendations(AirStage? stage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.health_and_safety, size: 18),
                SizedBox(width: 8),
                Text('Recommendations',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            for (final tip in _recommendationList(stage))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SystemPage extends ConsumerWidget {
  const SystemPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(telemetryProvider).value;
    final connState =
        ref.watch(connectionStateProvider).value ??
            DocasaConnectionState.disconnected;

    final env = t?.env;
    final sys = t?.sys;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SYSTEM STATUS'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ConnectionChip(connState),
          ),
        ],
      ),
      body: ConnectGate(
        connState: connState,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
          Row(
            children: [
              Expanded(
                child: ValueTile(
                  label: 'TEMPERATURE',
                  icon: Icons.device_thermostat,
                  value: env == null ? '—' : Fmt.tempC(env.temperature),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ValueTile(
                  label: 'HUMIDITY',
                  icon: Icons.water_drop,
                  value: env == null ? '—' : Fmt.humidity(env.humidity),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ValueTile(
            label: 'Air chemicals (VOC)',
            icon: Icons.blur_on,
            value: env == null ? '—' : Fmt.vocKOhms(env.vocKOhms),
            subtitle: env == null
                ? null
                : (env.vocKOhms < 30
                    ? 'Chemical vapors high — air level counts worse'
                    : 'Rough gauge of chemical-vapor level'),
            color: env != null && env.vocKOhms < 30
                ? Colors.amber
                : null,
          ),
          const SizedBox(height: 12),
          ValueTile(
            label: 'FAN SPEED',
                    icon: Icons.toys,
            value: sys == null ? '—' : Fmt.rpm(DomainClamps.fanRpm(sys.fanRpm)),
          ),
          const SizedBox(height: 12),
          ValueTile(
            label: 'BATTERY',
            icon: Icons.battery_charging_full,
            value: sys == null
                ? '—'
                : sys.batteryFull
                    ? 'FULL'
                    : '${DomainClamps.batteryPct(sys.batteryPct)}%',
            subtitle: sys == null || !sys.charging ? null : 'Charging',
            color: sys != null && (sys.charging || sys.batteryFull)
                ? Colors.amber
                : Colors.green,
          ),
        ],
        ),
      ),
    );
  }
}
