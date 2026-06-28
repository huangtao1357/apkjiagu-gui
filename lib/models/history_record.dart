/// 加固/签名历史记录状态
enum RecordStatus {
  running,
  success,
  failed,
  canceled;

  String get label {
    switch (this) {
      case RecordStatus.running:
        return '进行中';
      case RecordStatus.success:
        return '成功';
      case RecordStatus.failed:
        return '失败';
      case RecordStatus.canceled:
        return '已取消';
    }
  }
}

/// 历史记录
class HistoryRecord {
  final String id;
  final String fileName;
  final String filePath;
  final int originalSize;
  final int? outputSize;
  final DateTime createdAt;
  final DateTime? finishedAt;
  final String packageName;
  final String versionName;
  final int versionCode;
  final String outputPath;
  final RecordStatus status;
  final String? errorMessage;

  HistoryRecord({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.originalSize,
    this.outputSize,
    required this.createdAt,
    this.finishedAt,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.outputPath,
    required this.status,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'originalSize': originalSize,
        'outputSize': outputSize,
        'createdAt': createdAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'packageName': packageName,
        'versionName': versionName,
        'versionCode': versionCode,
        'outputPath': outputPath,
        'status': status.name,
        'errorMessage': errorMessage,
      };

  factory HistoryRecord.fromMap(Map<String, dynamic> m) {
    return HistoryRecord(
      id: m['id'] as String,
      fileName: m['fileName'] as String,
      filePath: m['filePath'] as String,
      originalSize: m['originalSize'] as int,
      outputSize: m['outputSize'] as int?,
      createdAt: DateTime.parse(m['createdAt'] as String),
      finishedAt: m['finishedAt'] == null
          ? null
          : DateTime.parse(m['finishedAt'] as String),
      packageName: m['packageName'] as String? ?? '',
      versionName: m['versionName'] as String? ?? '',
      versionCode: m['versionCode'] as int? ?? 0,
      outputPath: m['outputPath'] as String? ?? '',
      status: RecordStatus.values.firstWhere(
        (s) => s.name == (m['status'] as String? ?? 'failed'),
        orElse: () => RecordStatus.failed,
      ),
      errorMessage: m['errorMessage'] as String?,
    );
  }

  HistoryRecord copyWith({
    int? outputSize,
    DateTime? finishedAt,
    String? outputPath,
    RecordStatus? status,
    String? errorMessage,
  }) {
    return HistoryRecord(
      id: id,
      fileName: fileName,
      filePath: filePath,
      originalSize: originalSize,
      outputSize: outputSize ?? this.outputSize,
      createdAt: createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
      packageName: packageName,
      versionName: versionName,
      versionCode: versionCode,
      outputPath: outputPath ?? this.outputPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
