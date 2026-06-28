import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/apk_info.dart';
import '../models/history_record.dart';
import '../models/sign_config.dart';
import '../services/apk_parser.dart';
import '../services/apk_signer.dart';
import '../services/dpt_runner.dart';
import '../services/history_store.dart';
import '../services/sign_config_store.dart';
import '../services/tool_paths.dart';

/// 一条日志
class LogEntry {
  final DateTime time;
  final String level;
  final String message;
  LogEntry(this.level, this.message) : time = DateTime.now();
}

class AppState extends ChangeNotifier {
  AppState() {
    _bootstrap();
  }

  // ===== 运行环境 =====
  String? _javaVersion;
  String? _envError;
  bool _envReady = false;
  String? get javaVersion => _javaVersion;
  String? get envError => _envError;
  bool get envReady => _envReady;

  // ===== 选中 APK =====
  ApkInfo? _apkInfo;
  ApkInfo? get apkInfo => _apkInfo;
  String? _apkLoadError;
  String? get apkLoadError => _apkLoadError;

  // ===== 加固参数 =====
  bool excludeX86 = true;
  bool excludeX86_64 = true;
  bool excludeArm = false;
  bool excludeArm64 = false;
  bool smaller = true;
  bool noSign = true;
  bool keepClasses = false;
  bool debuggable = false;
  bool verifySign = false;
  bool disableAcf = false;
  bool noisyLog = false;
  String? rulesFile;
  String? protectConfig;

  // ===== 签名配置 =====
  List<SignConfig> signConfigs = [];
  String? selectedSignConfigId; // null 表示不签名

  // ===== 日志 =====
  final List<LogEntry> logs = [];

  // ===== 历史 =====
  List<HistoryRecord> history = [];

  // ===== 运行状态 =====
  bool _running = false;
  bool get running => _running;
  bool _cancelRequested = false;
  bool get cancelRequested => _cancelRequested;

  // ===== 运行结果 =====
  String? _lastOutputDir;
  String? get lastOutputDir => _lastOutputDir;
  String? _lastOutputApk;
  String? get lastOutputApk => _lastOutputApk;
  String? _lastError;
  String? get lastError => _lastError;

  Future<void> _bootstrap() async {
    try {
      await ToolPaths.initialize();
      final v = await ToolPaths.detectJava();
      if (v == null) {
        _envError = '未检测到 Java，请安装 JDK/JRE 17+ 并配置 PATH';
      } else {
        _javaVersion = v;
      }
      signConfigs = await SignConfigStore.loadAll();
      if (signConfigs.isEmpty) {
        // 创建一个默认占位配置示例
        signConfigs.add(SignConfig.create(name: '示例签名'));
        await SignConfigStore.saveAll(signConfigs);
      }
      history = await HistoryStore.list();
      _envReady = true;
    } catch (e, st) {
      _envError = '初始化失败: $e\n$st';
    }
    notifyListeners();
  }

  // ===== 日志方法 =====
  void log(String level, String message) {
    logs.add(LogEntry(level, message));
    if (logs.length > 5000) {
      logs.removeRange(0, logs.length - 5000);
    }
    notifyListeners();
  }

  void clearLogs() {
    logs.clear();
    notifyListeners();
  }

  // ===== APK 选择 =====
  Future<void> loadApk(String path) async {
    _apkLoadError = null;
    notifyListeners();
    try {
      final info = ApkParser.parse(path);
      _apkInfo = info;
      log('INFO', '已加载 APK: ${info.fileName}');
      log('INFO',
          '包名=${info.packageName} 版本=${info.versionName}(${info.versionCode}) minSdk=${info.minSdk} 大小=${_humanSize(info.fileSize)}');
    } catch (e, st) {
      _apkInfo = null;
      _apkLoadError = '解析 APK 失败: $e';
      log('ERROR', '解析 APK 失败: $e\n$st');
    }
    notifyListeners();
  }

  void clearApk() {
    _apkInfo = null;
    _apkLoadError = null;
    notifyListeners();
  }

  // ===== 签名配置管理 =====
  Future<void> addSignConfig(SignConfig c) async {
    signConfigs.add(c);
    await SignConfigStore.saveAll(signConfigs);
    notifyListeners();
  }

  Future<void> updateSignConfig(SignConfig c) async {
    final i = signConfigs.indexWhere((e) => e.id == c.id);
    if (i >= 0) signConfigs[i] = c;
    await SignConfigStore.saveAll(signConfigs);
    notifyListeners();
  }

  Future<void> deleteSignConfig(String id) async {
    signConfigs.removeWhere((e) => e.id == id);
    if (selectedSignConfigId == id) selectedSignConfigId = null;
    await SignConfigStore.saveAll(signConfigs);
    notifyListeners();
  }

  void selectSignConfig(String? id) {
    selectedSignConfigId = id;
    notifyListeners();
  }

  SignConfig? get selectedSignConfig {
    if (selectedSignConfigId == null) return null;
    return signConfigs.firstWhere(
      (e) => e.id == selectedSignConfigId,
      orElse: () => signConfigs.first,
    );
  }

  // ===== 加固执行 =====
  Set<String> get excludedAbis {
    final s = <String>{};
    if (excludeX86) s.add('x86');
    if (excludeX86_64) s.add('x86_64');
    if (excludeArm) s.add('arm');
    if (excludeArm64) s.add('arm64');
    return s;
  }

  Future<void> runHarden() async {
    if (_running) return;
    if (_apkInfo == null) {
      log('ERROR', '请先选择 APK 文件');
      return;
    }

    _running = true;
    _cancelRequested = false;
    _lastOutputDir = null;
    _lastOutputApk = null;
    _lastError = null;
    notifyListeners();

    final apk = _apkInfo!;
    final apkDir = p.dirname(apk.path);
    final baseName = p.basenameWithoutExtension(apk.path);
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .substring(0, 19);
    final outDir = p.join(apkDir, 'dpt_output', '${baseName}_$stamp');

    // 创建历史记录
    final record = HistoryRecord(
      id: const Uuid().v4(),
      fileName: apk.fileName,
      filePath: apk.path,
      originalSize: apk.fileSize,
      createdAt: DateTime.now(),
      packageName: apk.packageName,
      versionName: apk.versionName,
      versionCode: apk.versionCode,
      outputPath: outDir,
      status: RecordStatus.running,
    );
    await HistoryStore.insert(record);

    try {
      log('INFO', '═══════════ 开始加固 ═══════════');
      log('INFO', '输入 APK: ${apk.path}');
      log('INFO', '输出目录: $outDir');

      // 1. 运行 dpt-shell
      final options = HardenOptions(
        apkPath: apk.path,
        outputDir: outDir,
        excludeAbis: excludedAbis,
        smaller: smaller,
        noSign: noSign,
        keepClasses: keepClasses,
        debuggable: debuggable,
        verifySign: verifySign,
        disableAcf: disableAcf,
        noisyLog: noisyLog,
        rulesFile: rulesFile,
        protectConfig: protectConfig,
      );

      final result = await DptRunner.run(
        options: options,
        onLog: log,
        isCanceled: () => _cancelRequested,
      );

      if (_cancelRequested) {
        await _updateRecord(record.copyWith(
          status: RecordStatus.canceled,
          finishedAt: DateTime.now(),
          errorMessage: '用户取消',
        ));
        log('WARN', '加固已取消');
        _running = false;
        notifyListeners();
        return;
      }

      if (result.exitCode != 0) {
        await _updateRecord(record.copyWith(
          status: RecordStatus.failed,
          finishedAt: DateTime.now(),
          errorMessage: 'dpt-shell 退出码: ${result.exitCode}',
        ));
        _lastError = 'dpt-shell 退出码: ${result.exitCode}';
        _running = false;
        notifyListeners();
        return;
      }

      // 找到加固产物
      final outputApk = await _findOutputApk(outDir, apk.fileName);
      if (outputApk == null) {
        await _updateRecord(record.copyWith(
          status: RecordStatus.failed,
          finishedAt: DateTime.now(),
          errorMessage: '未找到加固产物 APK',
        ));
        _lastError = '未找到加固产物 APK';
        _running = false;
        notifyListeners();
        return;
      }
      _lastOutputDir = p.dirname(outputApk);
      log('INFO', '加固产物: $outputApk');

      // 2. 自动签名（用户选择签名配置后启用）
      String? signedApk = outputApk;
      final signConfig = selectedSignConfig;
      if (signConfig != null) {
        log('INFO', '═══════════ 开始签名 ═══════════');
        final signedOut = outputApk.replaceAll(RegExp(r'\.apk$'), '_signed.apk');
        final code = await ApkSignerService.sign(
          inputApk: outputApk,
          outputApk: signedOut,
          config: signConfig,
          minSdkVersion: apk.minSdk,
          onLog: log,
          isCanceled: () => _cancelRequested,
        );
        if (code != 0) {
          await _updateRecord(record.copyWith(
            status: RecordStatus.failed,
            finishedAt: DateTime.now(),
            errorMessage: '签名失败: 退出码 $code',
            outputPath: _lastOutputDir,
          ));
          _lastError = '签名失败';
          _running = false;
          notifyListeners();
          return;
        }
        signedApk = signedOut;
        _lastOutputApk = signedApk;
        log('INFO', '签名产物: $signedApk');
      } else {
        _lastOutputApk = outputApk;
      }

      final outputSize = File(signedApk).lengthSync();
      await _updateRecord(record.copyWith(
        status: RecordStatus.success,
        finishedAt: DateTime.now(),
        outputPath: p.dirname(signedApk),
        outputSize: outputSize,
      ));

      log('INFO', '═══════════ 完成 ═══════════');
      log('INFO', '最终产物: $signedApk');
      log('INFO', '原始大小: ${_humanSize(apk.fileSize)} → 加固后: ${_humanSize(outputSize)}');
    } catch (e, st) {
      log('ERROR', '执行异常: $e\n$st');
      await _updateRecord(record.copyWith(
        status: RecordStatus.failed,
        finishedAt: DateTime.now(),
        errorMessage: e.toString(),
      ));
      _lastError = e.toString();
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  /// 在 dpt 输出目录中查找加固后的 APK
  Future<String?> _findOutputApk(String outDir, String originalName) async {
    final dir = Directory(outDir);
    if (!dir.existsSync()) return null;
    final baseName = p.basenameWithoutExtension(originalName);

    // 优先返回与原文件名相同
    final same = p.join(outDir, originalName);
    if (File(same).existsSync()) return same;

    // 在目录中查找 _dpt 子目录
    final dptDir = Directory(p.join(outDir, '${baseName}_dpt'));
    if (dptDir.existsSync()) {
      final f = p.join(dptDir.path, originalName);
      if (File(f).existsSync()) return f;
    }

    // 递归搜索 .apk
    final apks = <File>[];
    await for (final e in dir.list(recursive: true)) {
      if (e is File && e.path.toLowerCase().endsWith('.apk')) {
        apks.add(e);
      }
    }
    if (apks.length == 1) return apks.first.path;
    if (apks.length > 1) {
      // 选最大的
      apks.sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
      return apks.first.path;
    }
    return null;
  }

  Future<void> _updateRecord(HistoryRecord r) async {
    await HistoryStore.update(r);
    final i = history.indexWhere((e) => e.id == r.id);
    if (i >= 0) {
      history[i] = r;
    } else {
      history.insert(0, r);
    }
    notifyListeners();
  }

  void cancel() {
    if (!_running) return;
    _cancelRequested = true;
    log('WARN', '正在取消...');
    notifyListeners();
  }

  // ===== 历史管理 =====
  Future<void> refreshHistory() async {
    history = await HistoryStore.list();
    notifyListeners();
  }

  Future<void> deleteHistory(String id) async {
    await HistoryStore.delete(id);
    history.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ===== 工具方法 =====
  String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}
