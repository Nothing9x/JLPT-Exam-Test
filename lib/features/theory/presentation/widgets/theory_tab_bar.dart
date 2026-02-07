import 'package:flutter/material.dart';

/// Custom tab bar for Theory screen
class TheoryTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;

  const TheoryTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        indicatorColor: Colors.white,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Colors.white,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        dividerColor: Colors.transparent,
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}
