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
  static const _toolsVersion = '9';

  /// dpt.jar 字节码为 class file version 55，最低要求 Java 11
  static const minJavaMajor = 11;

  static late final String _toolsRoot;
  static late final String _dptJarPath;
  static late final String _apksignerJarPath;
  static late final String _zipalignPath;
  static late final String _shellFilesDir;
  static late final String _excludeRulesTemplate;

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
      'tools/shell-files/dex/classes.dex',
      'tools/shell-files/libs/arm/lib830f622c2304076e.so',
      'tools/shell-files/libs/arm64/lib830f622c2304076e.so',
      'tools/shell-files/libs/x86/lib830f622c2304076e.so',
      'tools/shell-files/libs/x86_64/lib830f622c2304076e.so',
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

  /// 检查 Java 是否可用，返回版本字符串（如 "17.0.12"），不可用返回 null。
  ///
  /// java 不在 PATH 时 Process.run 会抛 ProcessException，需单独识别，
  /// 否则会以"初始化失败: ProcessException..."的形式误导用户。
  static Future<String?> detectJava() async {
    ProcessResult result;
    try {
      result = await Process.run('java', ['-version']);
    } on ProcessException {
      return null;
    }
    if (result.exitCode != 0) return null;
    // java -version 的版本信息输出在 stderr
    final out = '${result.stderr}\n${result.stdout}';
    final m = RegExp(r'"(\d+(?:\.\d+)+)"').firstMatch(out);
    return m?.group(1);
  }

  /// 解析 Java 版本字符串的主版本号，兼容 "17.0.12" 与 "1.8.0_292" 两种格式
  static int javaMajor(String version) {
    final parts = version.split('.');
    if (parts[0] == '1' && parts.length > 1) {
      return int.tryParse(parts[1].split('_').first) ?? 0;
    }
    return int.tryParse(parts[0]) ?? 0;
  }

  static String? _dptVersion;

  /// 读取 dpt.jar 自身版本号（java -jar dpt.jar -v，输出如 "2.21.0"）。
  /// 结果缓存，java 不可用或读取失败时返回 null。
  static Future<String?> detectDptVersion() async {
    if (_dptVersion != null) return _dptVersion;
    try {
      final r = await Process.run('java', ['-jar', _dptJarPath, '-v']);
      if (r.exitCode != 0) return null;
      final out = '${r.stdout}${r.stderr}'.trim();
      final m = RegExp(r'^\d+(?:\.\d+){0,3}').firstMatch(out);
      _dptVersion = m?.group(0);
    } on ProcessException {
      // java 不可用
    }
    return _dptVersion;
  }
}
