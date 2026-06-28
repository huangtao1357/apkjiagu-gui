/// APK 元信息
class ApkInfo {
  final String path;
  final String fileName;
  final int fileSize;
  final String packageName;
  final String versionName;
  final int versionCode;
  final int minSdk;

  ApkInfo({
    required this.path,
    required this.fileName,
    required this.fileSize,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.minSdk,
  });

  String get displayName {
    if (versionName.isNotEmpty) {
      return '$fileName (v$versionName)';
    }
    return fileName;
  }
}
