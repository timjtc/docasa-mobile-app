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
    if (connState == DocasaConnectionState.connecting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (connState == DocasaConnectionState.disconnected) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Device not connected'),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.bluetooth),
              label: const Text('Connect'),
              onPressed: () =>
                  ref.read(connectionProvider).connect(),
            ),
          ],
        ),
      );
    }

    final air = t?.air;
    final stage = AirStage.fromIndex(air?.stage);
    return ListView(
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
        if (stage == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('Received an invalid stage value — flagged per contract X6.'),
            ),
          ),
      ],
    );
  }
}

/// System status — mirrors the device LCD page 1 (SYSTEM STATUS).
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
      body: ListView(
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
            label: 'VOC (GAS kΩ)',
            icon: Icons.blur_on,
            value: env == null ? '—' : Fmt.vocKOhms(env.vocKOhms),
            subtitle: env == null
                ? null
                : (env.vocKOhms < 30
                    ? 'Elevated — device applies a +1 stage bump below 30 kΩ'
                    : 'Qualitative proxy (uncalibrated BME680)'),
            color: env != null && env.vocKOhms < 30
                ? Colors.amber
                : null,
          ),
          const SizedBox(height: 12),
          ValueTile(
            label: 'FAN SPEED',
                    icon: Icons.toys,
            value: sys == null ? '—' : Fmt.rpm(DomainClamps.fanRpm(sys.fanRpm)),
            subtitle: sys == null ? null : 'commanded target (v3)',
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
            subtitle: sys == null
                ? null
                : [
                    if (sys.charging) 'charging',
                    Fmt.volts(sys.batteryVoltage),
                  ].join(' · '),
            color: sys != null && (sys.charging || sys.batteryFull)
                ? Colors.amber
                : Colors.green,
          ),
        ],
      ),
    );
  }
}
