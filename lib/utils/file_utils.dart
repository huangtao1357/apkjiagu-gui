import 'dart:io';

/// 在文件管理器中打开路径
///
/// 关键点：不要手动在 path 外层加引号。
/// Dart 的 Process.start 在 Windows 上会根据参数内容自动添加引号
/// （含空格时）。若手动预先包裹引号，会导致双重转义
/// （explorer 收到 "\"C:\\path\""），从而回退到默认目录（我的文档）。
Future<void> revealInExplorer(String path) async {
  // 规范化为 Windows 反斜杠，并去掉尾部分隔符（否则引号包裹时易出错）
  var normalized = path.replaceAll('/', '\\');
  while (normalized.endsWith('\\') && normalized.length > 3) {
    normalized = normalized.substring(0, normalized.length - 1);
  }

  final f = File(normalized);
  final d = Directory(normalized);

  try {
    if (f.existsSync()) {
      // 选中文件：explorer /select,<path>（不要手动加引号）
      await Process.start('explorer.exe', ['/select,$normalized']);
    } else if (d.existsSync()) {
      // 打开目录
      await Process.start('explorer.exe', [normalized]);
    } else {
      // 父目录兜底
      final parent = File(normalized).parent;
      if (parent.existsSync()) {
        await Process.start('explorer.exe', [parent.path]);
      }
    }
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
