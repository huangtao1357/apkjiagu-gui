import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'tool_paths.dart';

/// 加固参数配置
class HardenOptions {
  final String apkPath;
  final String? outputDir;
  final Set<String> excludeAbis; // arm, arm64, x86, x86_64
  final bool smaller;
  final bool noSign;
  final bool keepClasses;
  final bool debuggable;
  final bool verifySign;
  final bool disableAcf;
  final bool noisyLog;
  final String? rulesFile;
  final String? protectConfig;

  HardenOptions({
    required this.apkPath,
    this.outputDir,
    this.excludeAbis = const {},
    this.smaller = false,
    this.noSign = false,
    this.keepClasses = false,
    this.debuggable = false,
    this.verifySign = false,
    this.disableAcf = false,
    this.noisyLog = false,
    this.rulesFile,
    this.protectConfig,
  });

  /// 构造命令行参数列表
  List<String> toArgs() {
    final args = <String>[
      '-jar',
      ToolPaths.dptJar,
      '-f',
      apkPath,
    ];

    if (excludeAbis.isNotEmpty) {
      args.addAll(['-e', excludeAbis.join(',')]);
    }
    if (smaller) args.add('-S');
    if (noSign) args.add('-x');
    if (keepClasses) args.add('-K');
    if (debuggable) args.add('--debug');
    if (verifySign) args.add('-vs');
    if (disableAcf) args.add('--disable-acf');
    if (noisyLog) args.add('--noisy-log');
    if (rulesFile != null && rulesFile!.isNotEmpty) {
      args.addAll(['-r', rulesFile!]);
    }
    if (protectConfig != null && protectConfig!.isNotEmpty) {
      args.addAll(['-c', protectConfig!]);
    }
    if (outputDir != null && outputDir!.isNotEmpty) {
      args.addAll(['-o', outputDir!]);
    }
    return args;
  }
}

/// 加固运行结果
class HardenResult {
  final int exitCode;
  final String? outputApkPath;
  final String? outputDir;
  HardenResult({required this.exitCode, this.outputApkPath, this.outputDir});
}

typedef LogSink = void Function(String level, String message);

class DptRunner {
  /// 执行加固。
  ///
  /// [onLog] 用于流式输出日志，level 取值：INFO/WARN/ERROR/DEBUG。
  /// [isCanceled] 函数返回 true 时中断进程。
  static Future<HardenResult> run({
    required HardenOptions options,
    required LogSink onLog,
    bool Function()? isCanceled,
  }) async {
    final java = 'java';
    final args = options.toArgs();
    onLog('INFO', '启动 dpt-shell: java ${args.join(' ')}');

    // dpt 工作目录默认指向 dpt.jar 所在目录，以便找到 shell-files
    final workingDir = File(ToolPaths.dptJar).parent.path;

    final proc = await Process.start(
      java,
      args,
      workingDirectory: workingDir,
      runInShell: false,
    );

    final stdoutSub = proc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _parseLog(line, onLog);
    });

    final stderrSub = proc.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _parseLog(line, onLog, defaultLevel: 'ERROR');
    });

    // 监听取消
    Timer? cancelTimer;
    if (isCanceled != null) {
      cancelTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
        if (isCanceled()) {
          proc.kill(ProcessSignal.sigkill);
          t.cancel();
        }
      });
    }

    final exitCode = await proc.exitCode;
    await stdoutSub.cancel();
    await stderrSub.cancel();
    cancelTimer?.cancel();

    final result = HardenResult(exitCode: exitCode);

    if (exitCode == 0) {
      onLog('INFO', '加固进程退出码: 0');
    } else {
      onLog('ERROR', '加固进程退出码: $exitCode');
    }

    return result;
  }

  /// 简单识别日志级别
  ///
  /// 注意：JVM 启动时会把 "Picked up JAVA_TOOL_OPTIONS: ..." 写到 stderr，
  /// 这不是错误，需要单独识别并标记为 INFO。
  static void _parseLog(
    String line,
    LogSink onLog, {
    String defaultLevel = 'INFO',
  }) {
    if (line.trim().isEmpty) return;

    // JVM 启动噪声：识别并降级为 INFO
    if (line.startsWith('Picked up ') ||
        line.startsWith('Picked up JAVA_') ||
        line.contains('Picked up JAVA_TOOL_OPTIONS') ||
        line.contains('Picked up _JAVA_OPTIONS') ||
        line.contains('Picked up _JAVAOPTIONS')) {
      onLog('INFO', line);
      return;
    }

    final upper = line.toUpperCase();
    String level = defaultLevel;
    // 仅当行内显式包含 ERROR/EXCEPTION/FAILED 关键字时才视为错误，
    // 避免把 stderr 上的普通信息（如 JVM 噪声）误判为错误
    if (upper.contains('ERROR') ||
        upper.contains('EXCEPTION') ||
        upper.contains('FAILED') ||
        upper.contains('FATAL')) {
      level = 'ERROR';
    } else if (upper.contains('WARN')) {
      level = 'WARN';
    } else if (upper.contains('DEBUG')) {
      level = 'DEBUG';
    } else if (upper.contains('INFO')) {
      level = 'INFO';
    }
    onLog(level, line);
  }
}
