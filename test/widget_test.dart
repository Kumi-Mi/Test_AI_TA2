import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/app.dart';
import 'package:learnflow/data/learning_session_controller.dart';
import 'package:learnflow/features/game/text_cipher_screen.dart';
import 'package:learnflow/theme/design_tokens.dart';

void main() {
  testWidgets('shows the adaptive learning dashboard', (tester) async {
    await tester.pumpWidget(
      LearnFlowApp(controller: LearningSessionController.demo()),
    );
    await tester.pump();

    expect(find.text('Hôm nay nên học gì?'), findsOneWidget);
    expect(find.text('Bắt đầu phiên'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('text cipher fits and starts on a compact mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: TextCipherScreen(controller: LearningSessionController.demo()),
        ),
      ),
    );
    await tester.tap(find.text('Bắt đầu giải mã'));
    await tester.pumpAndSettle();

    expect(find.text('BẢN MÃ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
