import 'package:flutter/material.dart';

import '../../data/learning_session_controller.dart';
import '../../theme/design_tokens.dart';
import '../custom_input/custom_input_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../game/word_catch_screen.dart';
import '../lab/ml_lab_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.controller, super.key});

  final LearningSessionController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(
        controller: widget.controller,
        openGame: () => setState(() => _selectedIndex = 1),
        openCustomInput: () => setState(() => _selectedIndex = 2),
      ),
      WordCatchScreen(controller: widget.controller),
      const CustomInputScreen(),
      const MlLabScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('LEARN / FLOW'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpace.md),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.cyan,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: const Text(
              'MVP CỤC BỘ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: _SlabNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _SlabNavigation extends StatelessWidget {
  const _SlabNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const destinations = [
    (Icons.route_outlined, 'Hôm nay'),
    (Icons.sports_esports_outlined, 'Mini-game'),
    (Icons.mic_none_rounded, 'Custom'),
    (Icons.science_outlined, 'ML Lab'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(destinations.length, (index) {
            final destination = destinations[index];
            final selected = index == selectedIndex;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: destination.$2,
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    constraints: const BoxConstraints(minHeight: 64),
                    color: selected ? AppColors.pear : AppColors.paper,
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(destination.$1, size: 23),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          destination.$2,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
