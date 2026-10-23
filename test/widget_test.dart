import 'package:flutter_test/flutter_test.dart';
import 'package:klip/app/klip_app.dart';

void main() {
  testWidgets('home displays Klip and editing tools', (tester) async {
    await tester.pumpWidget(const KlipApp());
    expect(find.text('Klip'), findsOneWidget);
    expect(find.text('New project'), findsOneWidget);
    expect(find.text('AutoCut'), findsOneWidget);
    expect(find.text('AI Lab'), findsOneWidget);
  });
}
