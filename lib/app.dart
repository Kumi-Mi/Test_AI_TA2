import 'package:flutter/material.dart';

import 'data/learning_session_controller.dart';
import 'features/shell/app_shell.dart';
import 'theme/design_tokens.dart';

class LearnFlowApp extends StatelessWidget {
  const LearnFlowApp({required this.controller, super.key});

  final LearningSessionController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnFlow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AppShell(controller: controller),
    );
  }
}
