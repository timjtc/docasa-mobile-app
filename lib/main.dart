import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'data/notifications.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/device/device_page.dart';
import 'features/filter/filter_alert_modal.dart';
import 'features/filter/filter_page.dart';
import 'features/history/history_page.dart';
import 'providers.dart';

void main() {
  runApp(const ProviderScope(child: DocasaApp()));
}

class DocasaApp extends ConsumerWidget {
  const DocasaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'DOCASA',
      debugShowCheckedModeBanner: false,
      theme: DocasaTheme.light(),
      darkTheme: DocasaTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  bool _alertDialogOpen = false;

  static const _pages = [
    DashboardPage(),
    SystemPage(),
    HistoryPage(),
    FilterPage(),
    DevicePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Boot the recording pipeline (recorder + compactor + alert checks) and
    // auto-connect the (fake) device.
    Future.microtask(
      () => ref
          .read(recordingServiceProvider)
          .start(ref.read(connectionProvider)),
    );
    // Cold-started by a filter-notification tap → raise the modal directly.
    Future.microtask(() async {
      if (await LocalFilterAlertPort.didLaunchFromFilter()) {
        ref.read(filterModalEventsProvider.notifier).fire();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleProvider.notifier).update(state);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    ref.listen(filterModalEventsProvider, (prev, next) {
      if (next > (prev ?? 0) && !_alertDialogOpen && mounted) {
        _alertDialogOpen = true;
        showFilterReplaceModal(context).then((_) => _alertDialogOpen = false);
      }
    });
    return Scaffold(
      body: Column(
        children: [
          // Brand banner (user-supplied PNG pair) + dark/light toggle. The
          // banner variant follows the active theme brightness.
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Image.asset(
                    cs.brightness == Brightness.dark
                        ? 'assets/docasa-logo-banner-dark.png'
                        : 'assets/docasa-logo-banner-light.png',
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cs.brightness == Brightness.dark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                      Switch(
                        value: cs.brightness == Brightness.dark,
                        onChanged: (dark) =>
                            ref.read(themeModeProvider.notifier).set(
                                  dark ? ThemeMode.dark : ThemeMode.light,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: IndexedStack(index: _tab, children: _pages)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.air_outlined),
              selectedIcon: Icon(Icons.air),
              label: 'Air'),
          NavigationDestination(
              icon: Icon(Icons.device_thermostat_outlined),
              selectedIcon: Icon(Icons.device_thermostat),
              label: 'System'),
          NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart),
              label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.filter_alt_outlined),
              selectedIcon: Icon(Icons.filter_alt),
              label: 'Filter'),
          NavigationDestination(
              icon: Icon(Icons.bluetooth_outlined),
              selectedIcon: Icon(Icons.bluetooth),
              label: 'Device'),
        ],
      ),
    );
  }
}
