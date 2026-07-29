import 'package:flutter_test/flutter_test.dart';
import 'package:sigp_plus/app/app.dart';

void main() {
  testWidgets('SIGP+ démarre correctement', (tester) async {
    await tester.pumpWidget(const SigpApp());
    await tester.pumpAndSettle();

    expect(find.text('Connexion SIGP+'), findsOneWidget);
  });
}
