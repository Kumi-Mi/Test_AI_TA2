import 'package:flutter/material.dart';

import '../../data/learning_session_controller.dart';
import '../../theme/design_tokens.dart';
import '../custom_input/custom_input_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../game/adaptive_game_screen.dart';
import '../lab/ml_lab_screen.dart';

enum _AppDestination { today, game, custom, lab }

extension on _AppDestination {
  IconData get icon => switch (this) {
    _AppDestination.today => Icons.route_outlined,
    _AppDestination.game => Icons.sports_esports_outlined,
    _AppDestination.custom => Icons.mic_none_rounded,
    _AppDestination.lab => Icons.science_outlined,
  };

  String get label => switch (this) {
    _AppDestination.today => 'Hôm nay',
    _AppDestination.game => 'Mini-game',
    _AppDestination.custom => 'Custom',
    _AppDestination.lab => 'ML Lab',
  };
}

class AppShell extends StatefulWidget {
  const AppShell({required this.controller, super.key});

  final LearningSessionController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _AppDestination _selected = _AppDestination.today;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(
        controller: widget.controller,
        openGame: () => setState(() => _selected = _AppDestination.game),
        openCustomInput: () =>
            setState(() => _selected = _AppDestination.custom),
      ),
      AdaptiveGameScreen(controller: widget.controller),
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
        child: IndexedStack(index: _selected.index, children: screens),
      ),
      bottomNavigationBar: _SlabNavigation(
        selected: _selected,
        onSelected: (destination) => setState(() => _selected = destination),
      ),
    );
  }
}

class _SlabNavigation extends StatelessWidget {
  const _SlabNavigation({required this.selected, required this.onSelected});

  final _AppDestination selected;
  final ValueChanged<_AppDestination> onSelected;

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
          children: _AppDestination.values.map((destination) {
            final isSelected = destination == selected;
            return Expanded(
              child: Semantics(
                selected: isSelected,
                button: true,
                label: destination.label,
                child: InkWell(
                  onTap: () => onSelected(destination),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    constraints: const BoxConstraints(minHeight: 64),
                    color: isSelected ? AppColors.pear : AppColors.paper,
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(destination.icon, size: 23),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          destination.label,
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
          }).toList(),
        ),
      ),
    );
  }
}
