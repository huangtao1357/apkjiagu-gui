import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';

import '../models/apk_info.dart';
import 'axml_parser.dart';

/// APK 元信息解析器：读取 APK 内的 AndroidManifest.xml 并解析
class ApkParser {
  /// 解析指定 APK 文件
  static ApkInfo parse(String apkPath) {
    final file = File(apkPath);
    if (!file.existsSync()) {
      throw FileSystemException('APK 文件不存在', apkPath);
    }

    final fileSize = file.lengthSync();

    // 流式读取 Zip 目录，避免把整个 APK 读入内存（大 APK 可能 100MB+）
    final input = InputFileStream(apkPath);
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBuffer(input);
    } catch (_) {
      input.closeSync();
      rethrow;
    }

    try {
      ArchiveFile? manifestFile;
      for (final f in archive.files) {
        if (f.name == 'AndroidManifest.xml') {
          manifestFile = f;
          break;
        }
      }

      if (manifestFile == null) {
        throw FormatException('APK 内未找到 AndroidManifest.xml');
      }

      // content 按需解压，只把 manifest 本身（几十 KB）读进内存
      final manifestBytes =
          Uint8List.fromList(manifestFile.content as List<int>);
      final byteData = ByteData.view(manifestBytes.buffer);

      final roots = AxmlParser(byteData).parse();
      if (roots.isEmpty) {
        throw FormatException('AndroidManifest.xml 解析为空');
      }

      AxmlNode manifest = roots.first;
      if (manifest.name != 'manifest') {
        // 找第一个 manifest 节点
        AxmlNode? m;
        _findManifest(roots, (n) => m = n);
        if (m != null) manifest = m as AxmlNode;
      }

      // package 属性 (直接在 <manifest> 上)
      final packageName = manifest.attributes['package'] ?? '';
      final versionName = manifest.attributes['versionName'] ??
          manifest.attributes['android:versionName'] ??
          '';
      final versionCodeStr = manifest.attributes['versionCode'] ??
          manifest.attributes['android:versionCode'] ??
          '0';
      final versionCode = int.tryParse(versionCodeStr) ?? 0;

      // 在 <uses-sdk> 节点中查找 minSdkVersion
      int minSdk = 1;
      _walk(manifest, (n) {
        if (n.name == 'uses-sdk') {
          final min = n.attributes['minSdkVersion'] ??
              n.attributes['android:minSdkVersion'];
          if (min != null) {
            minSdk = int.tryParse(min) ?? 1;
          }
        }
      });

      return ApkInfo(
        path: apkPath,
        fileName: file.uri.pathSegments.last,
        fileSize: fileSize,
        packageName: packageName,
        versionName: versionName,
        versionCode: versionCode,
        minSdk: minSdk,
      );
    } finally {
      input.closeSync();
    }
  }

  static void _walk(AxmlNode node, void Function(AxmlNode) visitor) {
    visitor(node);
    for (final c in node.children) {
      _walk(c, visitor);
    }
  }

  static void _findManifest(
      List<AxmlNode> nodes, void Function(AxmlNode) onFound) {
    for (final n in nodes) {
      if (n.name == 'manifest') {
        onFound(n);
        return;
      }
      _findManifest(n.children, onFound);
    }
  }
}
