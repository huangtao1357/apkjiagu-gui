import 'package:flutter_test/flutter_test.dart';

import 'package:apkjiagu/app.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const ApkJiaguApp());
    // 等待一帧
    await tester.pump();
    expect(find.text('APK 加固'), findsWidgets);
  });
}
