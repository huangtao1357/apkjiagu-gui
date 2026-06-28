import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/sign_config.dart';

class SignConfigStore {
  static const _fileName = 'sign_configs.json';

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static Future<List<SignConfig>> loadAll() async {
    final f = await _file();
    if (!f.existsSync()) return [];
    try {
      final raw = await f.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SignConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<SignConfig> configs) async {
    final f = await _file();
    final list = configs.map((c) => c.toJson()).toList();
    await f.writeAsString(jsonEncode(list), flush: true);
  }
}
