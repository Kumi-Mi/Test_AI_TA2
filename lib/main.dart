import 'package:flutter/material.dart';

import 'app.dart';
import 'data/learning_session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await LearningSessionController.create();
  runApp(LearnFlowApp(controller: controller));
}
