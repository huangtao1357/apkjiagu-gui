import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/sign_config.dart';

/// 签名配置持久化。
///
/// 密码不写入 JSON，统一存入 flutter_secure_storage（Windows 下基于 DPAPI）。
/// JSON 文件采用带版本号的包装结构：
///   {"version": 2, "configs": [...]}
/// 旧版（v1）格式为不带包装的纯数组，且密码明文写入；首次加载会自动迁移。
class SignConfigStore {
  static const _fileName = 'sign_configs.json';
  static const _formatVersion = 2;
  static const _secureStorage = FlutterSecureStorage();

  static String _ksPassKey(String id) => 'sign_config.$id.ks_pass';
  static String _aliasPassKey(String id) => 'sign_config.$id.alias_pass';

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static Future<List<SignConfig>> loadAll() async {
    final f = await _file();
    if (!f.existsSync()) return [];

    dynamic decoded;
    try {
      decoded = jsonDecode(await f.readAsString());
    } catch (_) {
      return [];
    }

    List<dynamic> rawConfigs;
    bool needsMigration = false;

    if (decoded is List) {
      // v1：纯数组，密码明文
      rawConfigs = decoded;
      needsMigration = true;
    } else if (decoded is Map<String, dynamic>) {
      rawConfigs = (decoded['configs'] as List<dynamic>?) ?? [];
    } else {
      return [];
    }

    final configs = rawConfigs
        .map((e) => SignConfig.fromJson(e as Map<String, dynamic>))
        .toList();

    if (needsMigration) {
      // 把明文密码迁入安全存储，并清空 JSON 中的密码字段后重写文件
      for (final c in configs) {
        await _writePassword(_ksPassKey(c.id), c.keystorePassword);
        await _writePassword(_aliasPassKey(c.id), c.aliasPassword);
      }
      await _writeJson(configs);
    } else {
      // v2：从安全存储载入密码
      for (final c in configs) {
        c.keystorePassword = await _secureStorage.read(key: _ksPassKey(c.id)) ?? '';
        c.aliasPassword = await _secureStorage.read(key: _aliasPassKey(c.id)) ?? '';
      }
    }

    return configs;
  }

  static Future<void> saveAll(List<SignConfig> configs) async {
    final existingIds = configs.map((c) => c.id).toSet();
    await _deleteOrphanedPasswords(existingIds);

    for (final c in configs) {
      await _writePassword(_ksPassKey(c.id), c.keystorePassword);
      await _writePassword(_aliasPassKey(c.id), c.aliasPassword);
    }
    await _writeJson(configs);
  }

  static Future<void> _writeJson(List<SignConfig> configs) async {
    final f = await _file();
    final sanitized = configs.map((c) {
      final m = c.toJson();
      m['keystorePassword'] = '';
      m['aliasPassword'] = '';
      return m;
    }).toList();
    final wrapper = {
      'version': _formatVersion,
      'configs': sanitized,
    };
    await f.writeAsString(jsonEncode(wrapper), flush: true);
  }

  static Future<void> _writePassword(String key, String value) async {
    if (value.isEmpty) {
      await _secureStorage.delete(key: key);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  /// 删除不在 configs 列表中的孤立密码条目
  static Future<void> _deleteOrphanedPasswords(Set<String> existingIds) async {
    final all = await _secureStorage.readAll();
    for (final key in all.keys) {
      final parsed = _parseKey(key);
      if (parsed != null && !existingIds.contains(parsed)) {
        await _secureStorage.delete(key: key);
      }
    }
  }

  static String? _parseKey(String key) {
    if (!key.startsWith('sign_config.')) return null;
    final parts = key.split('.');
    if (parts.length != 3) return null;
    return parts[1];
  }
}
