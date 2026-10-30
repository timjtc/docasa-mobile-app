import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/stage.dart';
import '../../protocol/models.dart';
import '../../providers.dart';

/// Small label-over-value card used across pages.
class ValueTile extends StatelessWidget {
  const ValueTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.color,
    this.icon,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: color ?? cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: color ?? cs.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The dashboard hero: stage color band + label + PM2.5 (mirrors LCD page 0).
class StageHero extends StatelessWidget {
  const StageHero({super.key, this.stage, this.pm25, this.updatedAt});

  final AirStage? stage;
  final int? pm25;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final s = stage ?? AirStage.good;
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: s.color.withValues(alpha: 0.25),
            child: Center(
              child: Text(
                stage == null ? '—' : s.label,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: s.color,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  pm25 == null ? '—' : '${DomainClamps.pm(pm25!)}',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text('PM2.5 (µg/m³)',
                    style: TextStyle(color: cs.onSurfaceVariant)),
                if (updatedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'live · updated ${Fmt.time(updatedAt!)}',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Connection status chip (app bar / device page).
class ConnectionChip extends StatelessWidget {
  const ConnectionChip(this.state, {super.key});

  final DocasaConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      DocasaConnectionState.connected => ('CONNECTED', Colors.green),
      DocasaConnectionState.connecting => ('CONNECTING', Colors.amber),
      DocasaConnectionState.disconnected => ('OFFLINE', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Connection gate shared by live-feed pages (Air, System): shows the
/// connecting spinner / connect prompt instead of stale values while offline.
class ConnectGate extends ConsumerWidget {
  final DocasaConnectionState connState;
  final Widget child;

  const ConnectGate({super.key, required this.connState, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onPressed: () => ref.read(connectionProvider).connect(),
            ),
          ],
        ),
      );
    }
    return child;
  }
}
