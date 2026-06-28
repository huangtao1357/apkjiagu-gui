import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 解析并维护内置工具（dpt.jar、apksigner.jar、zipalign.exe 等）的工作目录。
///
/// Flutter 桌面应用发布后无法直接以文件方式访问 assets，需要将可执行文件
/// 释放到应用支持目录再调用。
class ToolPaths {
  static const _versionKey = 'tools_version';
  static const _toolsVersion = '1';

  static late final String _toolsRoot;
  static late final String _dptJarPath;
  static late final String _apksignerJarPath;
  static late final String _zipalignPath;
  static late final String _shellFilesDir;
  static late final String _excludeRulesTemplate;
  static late final String _protectConfigTemplate;

  /// 必须在 runApp 之前调用
  static Future<void> initialize() async {
    final supportDir = await getApplicationSupportDirectory();
    _toolsRoot = p.join(supportDir.path, 'dpt_tools');

    if (!Directory(_toolsRoot).existsSync()) {
      Directory(_toolsRoot).createSync(recursive: true);
    }

    await _extractIfNeeded();

    _dptJarPath = p.join(_toolsRoot, 'dpt.jar');
    _apksignerJarPath = p.join(_toolsRoot, 'apksigner.jar');
    _zipalignPath = p.join(_toolsRoot, 'zipalign.exe');
    _shellFilesDir = p.join(_toolsRoot, 'shell-files');
    _excludeRulesTemplate = p.join(_toolsRoot, 'dpt-exclude-classes-template.rules');
    _protectConfigTemplate = p.join(_toolsRoot, 'dpt-protect-config-template.json');
  }

  static Future<void> _extractIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_versionKey);
    final dptExists = File(p.join(_toolsRoot, 'dpt.jar')).existsSync();
    final apksignerExists = File(p.join(_toolsRoot, 'apksigner.jar')).existsSync();
    final zipalignExists = File(p.join(_toolsRoot, 'zipalign.exe')).existsSync();
    final shellExists =
        Directory(p.join(_toolsRoot, 'shell-files')).existsSync();

    if (v == _toolsVersion &&
        dptExists &&
        apksignerExists &&
        zipalignExists &&
        shellExists) {
      return;
    }

    // 释放文件清单
    const files = <String>[
      'tools/dpt.jar',
      'tools/apksigner.jar',
      'tools/zipalign.exe',
      'tools/dpt-exclude-classes-template.rules',
      'tools/dpt-protect-config-template.json',
      'tools/shell-files/dex/classes.dex',
      'tools/shell-files/libs/arm/libe01ce7566771bf96.so',
      'tools/shell-files/libs/arm64/libe01ce7566771bf96.so',
      'tools/shell-files/libs/x86/libe01ce7566771bf96.so',
      'tools/shell-files/libs/x86_64/libe01ce7566771bf96.so',
    ];

    for (final assetPath in files) {
      final relPath = assetPath.substring('tools/'.length);
      final outPath = p.join(_toolsRoot, relPath);
      final outFile = File(outPath);
      if (outFile.existsSync() && v == _toolsVersion) continue;
      await Directory(p.dirname(outPath)).create(recursive: true);
      final data = await rootBundle.load('assets/$assetPath');
      await outFile.writeAsBytes(data.buffer.asUint8List());
    }

    await prefs.setString(_versionKey, _toolsVersion);
  }

  static String get dptJar => _dptJarPath;
  static String get apksignerJar => _apksignerJarPath;
  static String get zipalign => _zipalignPath;
  static String get shellFilesDir => _shellFilesDir;
  static String get excludeRulesTemplate => _excludeRulesTemplate;
  static String get protectConfigTemplate => _protectConfigTemplate;

  /// 检查 Java 是否可用
  static Future<String?> detectJava() async {
    final result = await Process.run('java', ['-version']);
    if (result.exitCode == 0) {
      // result.stderr 包含版本信息
      final out = (result.stderr ?? '').toString();
      final m = RegExp(r'"(\d+(?:\.\d+)*)').firstMatch(out);
      return m?.group(1) ?? 'unknown';
    }
    return null;
  }
}
