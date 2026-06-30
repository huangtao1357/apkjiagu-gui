import 'dart:io';

/// 在文件管理器中打开路径
///
/// 在 Windows 上，使用 `cmd /c explorer ...` 方式执行，
/// 避免直接通过 Process.start 传递参数时引号被重复转义，
/// 导致 explorer 收到无效参数而回退到默认目录。
Future<void> revealInExplorer(String path) async {
  // 规范化路径为 Windows 反斜杠格式
  final normalized = path.replaceAll('/', '\\');

  final f = File(normalized);
  final d = Directory(normalized);

  String cmd;
  if (f.existsSync()) {
    // 选中文件：explorer /select,"C:\path\to\file.apk"
    cmd = 'explorer /select,"${f.path}"';
  } else if (d.existsSync()) {
    // 打开目录：explorer "C:\path\to\folder"
    cmd = 'explorer "${d.path}"';
  } else {
    // 父目录兜底
    final parent = File(normalized).parent;
    if (parent.existsSync()) {
      cmd = 'explorer "${parent.path}"';
    } else {
      return;
    }
  }

  try {
    await Process.start('cmd', ['/c', cmd], runInShell: false);
  } catch (_) {
    // ignore
  }
}

/// 格式化文件大小
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}
