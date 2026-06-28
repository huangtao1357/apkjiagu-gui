import 'package:uuid/uuid.dart';

/// 签名策略
enum SignScheme {
  v1,
  v2,
  v3,
  v4,
  auto;

  String get label {
    switch (this) {
      case SignScheme.v1:
        return 'V1 (JAR)';
      case SignScheme.v2:
        return 'V2';
      case SignScheme.v3:
        return 'V3';
      case SignScheme.v4:
        return 'V4';
      case SignScheme.auto:
        return '自动探测';
    }
  }

  String get id => name;
}

/// 一套签名配置
class SignConfig {
  final String id;
  String name;
  String keystorePath;
  String keystorePassword;
  String alias;
  String aliasPassword;
  bool enableV1;
  bool enableV2;
  bool enableV3;
  bool enableV4;
  bool autoScheme;

  SignConfig({
    required this.id,
    required this.name,
    required this.keystorePath,
    required this.keystorePassword,
    required this.alias,
    required this.aliasPassword,
    this.enableV1 = true,
    this.enableV2 = true,
    this.enableV3 = true,
    this.enableV4 = false,
    this.autoScheme = false,
  });

  factory SignConfig.create({
    required String name,
    String keystorePath = '',
    String keystorePassword = '',
    String alias = '',
    String aliasPassword = '',
    bool enableV1 = true,
    bool enableV2 = true,
    bool enableV3 = true,
    bool enableV4 = false,
    bool autoScheme = false,
  }) {
    return SignConfig(
      id: const Uuid().v4(),
      name: name,
      keystorePath: keystorePath,
      keystorePassword: keystorePassword,
      alias: alias,
      aliasPassword: aliasPassword,
      enableV1: enableV1,
      enableV2: enableV2,
      enableV3: enableV3,
      enableV4: enableV4,
      autoScheme: autoScheme,
    );
  }

  bool get isValid =>
      keystorePath.isNotEmpty &&
      alias.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'keystorePath': keystorePath,
        'keystorePassword': keystorePassword,
        'alias': alias,
        'aliasPassword': aliasPassword,
        'enableV1': enableV1,
        'enableV2': enableV2,
        'enableV3': enableV3,
        'enableV4': enableV4,
        'autoScheme': autoScheme,
      };

  factory SignConfig.fromJson(Map<String, dynamic> json) {
    return SignConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      keystorePath: json['keystorePath'] as String? ?? '',
      keystorePassword: json['keystorePassword'] as String? ?? '',
      alias: json['alias'] as String? ?? '',
      aliasPassword: json['aliasPassword'] as String? ?? '',
      enableV1: json['enableV1'] as bool? ?? true,
      enableV2: json['enableV2'] as bool? ?? true,
      enableV3: json['enableV3'] as bool? ?? true,
      enableV4: json['enableV4'] as bool? ?? false,
      autoScheme: json['autoScheme'] as bool? ?? false,
    );
  }

  SignConfig copy() => SignConfig(
        id: id,
        name: name,
        keystorePath: keystorePath,
        keystorePassword: keystorePassword,
        alias: alias,
        aliasPassword: aliasPassword,
        enableV1: enableV1,
        enableV2: enableV2,
        enableV3: enableV3,
        enableV4: enableV4,
        autoScheme: autoScheme,
      );
}
