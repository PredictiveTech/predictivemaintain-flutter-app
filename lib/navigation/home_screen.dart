import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/session_controller.dart';
import 'nav_destinations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(sessionControllerProvider.select((s) => s?.roles ?? const []));
    final destinations = destinationsFor(roles);
    final index = _currentIndex.clamp(0, destinations.length - 1);

    return Scaffold(
      appBar: AppBar(title: Text(destinations[index].label)),
      body: IndexedStack(
        index: index,
        children: [for (final d in destinations) d.build()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          for (final d in destinations)
            BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
