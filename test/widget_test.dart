import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:apkjiagu/app.dart';
import 'package:apkjiagu/providers/app_state.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    // 三栏布局按桌面窗口设计，默认 800x600 测试画面会触发溢出断言
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const ApkJiaguApp(),
      ),
    );
    // 等待两帧：首帧构建 + AppState._bootstrap 异步完成
    await tester.pump();
    await tester.pump();
    expect(find.text('APK 加固'), findsWidgets);
  });
}
