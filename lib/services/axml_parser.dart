import 'dart:convert';
import 'dart:typed_data';

/// AXML 二进制 XML 解析器
/// 用于解析 APK 内的 AndroidManifest.xml 二进制格式。
class AxmlNode {
  final String name;
  final Map<String, String> attributes;
  final List<AxmlNode> children;
  AxmlNode? parent;

  AxmlNode({required this.name, Map<String, String>? attributes})
      : attributes = attributes ?? {},
        children = [];
}

class _AxmlAttribute {
  final String? ns;
  final String name;
  final String? rawValue;
  final int type;
  final int data;

  _AxmlAttribute({
    this.ns,
    required this.name,
    this.rawValue,
    required this.type,
    required this.data,
  });

  String? get value {
    switch (type) {
      case 0x03: // TYPE_STRING
        return rawValue;
      case 0x10: // TYPE_INT_DEC
        return data.toString();
      case 0x11: // TYPE_INT_HEX
        return '0x${data.toRadixString(16)}';
      case 0x12: // TYPE_INT_BOOLEAN
        return data != 0 ? 'true' : 'false';
      default:
        return rawValue ?? data.toString();
    }
  }
}

class AxmlParser {
  final ByteData _data;
  List<String?> _strings = [];
  List<int> _resourceIds = [];

  AxmlParser(this._data);

  /// 解析并返回根节点列表
  List<AxmlNode> parse() {
    _strings = [];
    _resourceIds = [];

    final magic = _u16(0);
    if (magic != 0x0003) {
      throw FormatException('不是有效的 AXML 文件: magic=0x${magic.toRadixString(16)}');
    }

    int offset = 8; // 跳过文件头
    final List<AxmlNode> roots = [];
    final List<AxmlNode> stack = [];
    final Map<int, String> nsMap = {};

    while (offset < _data.lengthInBytes) {
      final chunkType = _u16(offset);
      final chunkSize = _u32(offset + 4);

      if (chunkSize == 0 || offset + chunkSize > _data.lengthInBytes) break;

      switch (chunkType) {
        case 0x0001: // STRING_POOL
          _parseStringPool(offset);
          break;
        case 0x0180: // RESOURCE_MAP
          _parseResourceMap(offset);
          break;
        case 0x0100: // START_NAMESPACE
          final prefix = _u32(offset + 16);
          final uri = _u32(offset + 20);
          if (prefix >= 0 && prefix < _strings.length && uri >= 0 && uri < _strings.length) {
            nsMap[uri] = _strings[prefix] ?? '';
          }
          break;
        case 0x0101: // END_NAMESPACE
          break;
        case 0x0102: // START_ELEMENT
          final node = _parseStartElement(offset, nsMap);
          if (stack.isEmpty) {
            roots.add(node);
          } else {
            stack.last.children.add(node);
            node.parent = stack.last;
          }
          stack.add(node);
          break;
        case 0x0103: // END_ELEMENT
          if (stack.isNotEmpty) stack.removeLast();
          break;
        case 0x0104: // CDATA
          break;
      }

      offset += chunkSize;
    }

    return roots;
  }

  int _u16(int offset) => _data.getUint16(offset, Endian.little);
  int _u32(int offset) => _data.getUint32(offset, Endian.little);

  void _parseStringPool(int chunkOffset) {
    final headerSize = _u16(chunkOffset + 2);
    final stringCount = _u32(chunkOffset + 8);
    final flags = _u32(chunkOffset + 16);
    final stringsStart = _u32(chunkOffset + 20);
    final isUtf8 = (flags & (1 << 8)) != 0;
    final offsetsStart = chunkOffset + headerSize;

    _strings = List<String?>.filled(stringCount, null);
    final stringDataStart = chunkOffset + stringsStart;

    for (int i = 0; i < stringCount; i++) {
      final strOffset = _u32(offsetsStart + i * 4);
      final absOffset = stringDataStart + strOffset;
      _strings[i] = _readString(absOffset, isUtf8);
    }
  }

  String? _readString(int offset, bool isUtf8) {
    if (offset >= _data.lengthInBytes) return null;
    if (isUtf8) {
      // UTF-8: 变长长度（先 1 byte 或 2 byte 的字符数，再 1 byte 或 2 byte 的字节数）
      // 简化处理：高位置 1 表示用 2 byte
      int charCount = _data.getUint8(offset);
      int byteOffset = offset + 1;
      if ((charCount & 0x80) != 0) {
        charCount = ((charCount & 0x7F) << 8) | _data.getUint8(offset + 1);
        byteOffset = offset + 2;
      }
      int byteLen = _data.getUint8(byteOffset);
      int dataOffset = byteOffset + 1;
      if ((byteLen & 0x80) != 0) {
        byteLen = ((byteLen & 0x7F) << 8) | _data.getUint8(byteOffset + 1);
        dataOffset = byteOffset + 2;
      }
      final bytes = Uint8List.view(
          _data.buffer, _data.offsetInBytes + dataOffset, byteLen);
      try {
        return utf8.decode(bytes);
      } catch (_) {
        return String.fromCharCodes(bytes);
      }
    } else {
      // UTF-16: 2 byte 字符数
      int len = _u16(offset);
      int dataOffset = offset + 2;
      if ((len & 0x8000) != 0) {
        len = ((len & 0x7FFF) << 16) | _u16(offset + 2);
        dataOffset = offset + 4;
      }
      final codeUnits = List<int>.filled(len, 0);
      for (int i = 0; i < len; i++) {
        codeUnits[i] = _u16(dataOffset + i * 2);
      }
      return String.fromCharCodes(codeUnits);
    }
  }

  void _parseResourceMap(int chunkOffset) {
    final headerSize = _u16(chunkOffset + 2);
    final chunkSize = _u32(chunkOffset + 4);
    final count = (chunkSize - headerSize) ~/ 4;
    _resourceIds = List<int>.filled(count, 0);
    for (int i = 0; i < count; i++) {
      _resourceIds[i] = _u32(chunkOffset + headerSize + i * 4);
    }
  }

  AxmlNode _parseStartElement(int offset, Map<int, String> nsMap) {
    // offset + 8: lineNumber (4)
    // offset + 12: comment (4)
    final nameIdx = _u32(offset + 20);
    final attributeStart = _u16(offset + 24);
    final attributeSize = _u16(offset + 26);
    final attributeCount = _u16(offset + 28);

    final name = nameIdx < _strings.length ? (_strings[nameIdx] ?? '') : '';
    final node = AxmlNode(name: name);

    // attributeStart 是相对于 ResXMLTree_attrExt 的偏移，
    // 而 ResXMLTree_attrExt 起始在 chunk header (16 字节) 之后。
    int attrOffset = offset + 16 + attributeStart;
    for (int i = 0; i < attributeCount; i++) {
      final attr = _parseAttribute(attrOffset);
      final key = attr.name;
      final v = attr.value;
      if (v != null) {
        node.attributes[key] = v;
      }
      attrOffset += attributeSize;
    }

    return node;
  }

  _AxmlAttribute _parseAttribute(int offset) {
    final nameIdx = _u32(offset + 4);
    final rawValueIdx = _u32(offset + 8);
    final type = _data.getUint8(offset + 15);
    final data = _u32(offset + 16);

    final name = nameIdx < _strings.length ? (_strings[nameIdx] ?? '') : '';
    final rawValue = rawValueIdx != 0xFFFFFFFF && rawValueIdx < _strings.length
        ? _strings[rawValueIdx]
        : null;

    return _AxmlAttribute(
      ns: null,
      name: name,
      rawValue: rawValue,
      type: type,
      data: data,
    );
  }
}

/// 已知的 Android 资源 ID
class AndroidResId {
  static const int versionName = 0x0101021b;
  static const int versionCode = 0x0101021c;
  static const int versionCodeNew = 0x01010576;
  static const int versionNameNew = 0x01010577;
  static const int minSdkVersion = 0x0101020c;
  static const int targetSdkVersion = 0x01010270;
  static const int name = 0x01010003;
  static const int debuggable = 0x0101000f;
}
