import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/sign_config.dart';
import 'tool_paths.dart';

typedef SignLogSink = void Function(String level, String message);

class ApkSignerService {
  /// 签名一个 APK 文件
  ///
  /// 流程：zipalign → apksigner sign
  /// [inputApk] 输入 APK（dpt 加固产物）
  /// [outputApk] 输出 APK 路径
  /// [config] 签名配置
  /// [minSdkVersion] 用于 apksigner 的 --min-sdk-version
  static Future<int> sign({
    required String inputApk,
    required String outputApk,
    required SignConfig config,
    int minSdkVersion = 21,
    required SignLogSink onLog,
    bool Function()? isCanceled,
  }) async {
    if (!config.isValid) {
      onLog('ERROR', '签名配置无效：缺少 keystore 路径或别名');
      return -1;
    }

    // 1. zipalign 对齐
    final alignedApk = outputApk.replaceAll(RegExp(r'\.apk$'), '_aligned.apk');
    onLog('INFO', '运行 zipalign: ${ToolPaths.zipalign} -f 4 "$inputApk" "$alignedApk"');
    final alignResult = await Process.run(
      ToolPaths.zipalign,
      ['-f', '4', inputApk, alignedApk],
      runInShell: true,
    );
    if (alignResult.exitCode != 0) {
      onLog('ERROR', 'zipalign 失败：${alignResult.stderr}');
      return alignResult.exitCode;
    }
    onLog('INFO', 'zipalign 完成');

    if (isCanceled != null && isCanceled()) {
      try {
        File(alignedApk).deleteSync();
      } catch (_) {}
      onLog('WARN', '签名已取消');
      return -2;
    }

    // 2. apksigner 签名
    // 密码经环境变量传递（env:），避免出现在进程命令行中被本机其他进程读取
    final args = <String>[
      '-jar',
      ToolPaths.apksignerJar,
      'sign',
      '--ks',
      config.keystorePath,
      '--ks-key-alias',
      config.alias,
      '--ks-pass',
      'env:APKJIAGU_KS_PASS',
      '--min-sdk-version',
      minSdkVersion.toString(),
    ];

    // 别名密码缺省时不传 --key-pass，让 apksigner 自行回退（先试 keystore 密码再试空密码）
    if (config.aliasPassword.isNotEmpty) {
      args.addAll(['--key-pass', 'env:APKJIAGU_ALIAS_PASS']);
    }

    if (config.autoScheme) {
      onLog('INFO', '签名策略：自动探测（按 minSdk 选择）');
    } else {
      args.addAll([
        '--v1-signing-enabled',
        config.enableV1 ? 'true' : 'false',
        '--v2-signing-enabled',
        config.enableV2 ? 'true' : 'false',
        '--v3-signing-enabled',
        config.enableV3 ? 'true' : 'false',
        '--v4-signing-enabled',
        config.enableV4 ? 'true' : 'false',
      ]);
      onLog('INFO',
          '签名策略：V1=${config.enableV1}, V2=${config.enableV2}, V3=${config.enableV3}, V4=${config.enableV4}');
    }

    args.addAll(['--out', outputApk, alignedApk]);

    onLog('INFO', '运行 apksigner: java ${_maskArgs(args).join(' ')}');
    final proc = await Process.start(
      'java',
      args,
      runInShell: false,
      environment: {
        'APKJIAGU_KS_PASS': config.keystorePassword,
        if (config.aliasPassword.isNotEmpty)
          'APKJIAGU_ALIAS_PASS': config.aliasPassword,
      },
    );

    final stdoutSub = proc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.trim().isNotEmpty) onLog('INFO', line);
    });
    final stderrSub = proc.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      final t = line.trim();
      if (t.isEmpty) return;
      // JVM 启动噪声：识别并降级为 INFO
      if (t.startsWith('Picked up ') || t.contains('Picked up JAVA_')) {
        onLog('INFO', line);
        return;
      }
      onLog('ERROR', line);
    });

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

    // 删除对齐中间文件
    try {
      File(alignedApk).deleteSync();
    } catch (_) {}

    if (exitCode == 0) {
      onLog('INFO', '签名成功：$outputApk');
    } else {
      onLog('ERROR', '签名失败，退出码：$exitCode');
    }
    return exitCode;
  }

  /// 对命令行参数中的敏感信息做掩码，仅用于日志输出
  static List<String> _maskArgs(List<String> args) {
    final masked = <String>[];
    for (final a in args) {
      if (a.startsWith('pass:')) {
        masked.add('pass:***');
      } else {
        masked.add(a);
      }
    }
    return masked;
  }

  /// 验证签名
  static Future<bool> verify(
    String apkPath, {
    required SignLogSink onLog,
  }) async {
    final result = await Process.run(
      'java',
      ['-jar', ToolPaths.apksignerJar, 'verify', '--verbose', apkPath],
      runInShell: false,
    );
    final out = '${result.stdout}\n${result.stderr}';
    if (result.exitCode == 0) {
      onLog('INFO', '签名验证通过：\n$out');
      return true;
    }
    onLog('ERROR', '签名验证失败：\n$out');
    return false;
  }
}
