import 'package:flutter_test/flutter_test.dart';
import 'package:learnflow/app.dart';
import 'package:learnflow/data/learning_session_controller.dart';

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
}
