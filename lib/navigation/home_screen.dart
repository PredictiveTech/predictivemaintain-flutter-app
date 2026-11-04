import 'package:flutter/material.dart';

import '../maintenance/presentation/assets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _titles = ['Activos', 'Alertas', 'Órdenes de trabajo'];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const AssetsScreen(),
          for (final title in _titles.skip(1)) Center(child: Text(title)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing),
            label: 'Activos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Órdenes de trabajo',
          ),
        ],
      ),
    );
  }
}
