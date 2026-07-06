import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';
import 'package:app/features/splash/splash_page.dart';

void main() {
  testWidgets('App boots to splash page', (WidgetTester tester) async {
    await tester.pumpWidget(const EasyAgreeApp());

    expect(find.byType(SplashPage), findsOneWidget);
  });
}
