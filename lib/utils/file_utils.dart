import 'dart:io';

/// 在文件管理器中打开路径
Future<void> revealInExplorer(String path) async {
  final f = File(path);
  final d = Directory(path);
  String arg;
  if (f.existsSync()) {
    arg = '/select,"${f.path}"';
  } else if (d.existsSync()) {
    arg = '"${d.path}"';
  } else {
    // 父目录
    final parent = File(path).parent;
    if (parent.existsSync()) {
      arg = '"${parent.path}"';
    } else {
      return;
    }
  }
  try {
    await Process.start('explorer', [arg]);
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
