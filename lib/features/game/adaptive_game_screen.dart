import 'package:flutter/material.dart';

import '../../data/learning_session_controller.dart';
import '../../domain/learning_models.dart';
import 'text_cipher_screen.dart';
import 'word_catch_screen.dart';

class AdaptiveGameScreen extends StatelessWidget {
  const AdaptiveGameScreen({required this.controller, super.key});

  final LearningSessionController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.plan.game) {
      MiniGameType.wordCatch => WordCatchScreen(controller: controller),
      MiniGameType.textCipher => TextCipherScreen(controller: controller),
    };
  }
}
