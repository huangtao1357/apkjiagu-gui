import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/sign_config.dart';
import '../providers/app_state.dart';
import '../utils/file_utils.dart';

class HardenPage extends StatefulWidget {
  const HardenPage({super.key});

  @override
  State<HardenPage> createState() => _HardenPageState();
}

class _HardenPageState extends State<HardenPage> {
  final _logScrollController = ScrollController();

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    _scrollToBottom();

    return Scaffold(
      body: Row(
        children: [
          // 左栏：APK + 加固参数
          SizedBox(
            width: 340,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: ListView(
                children: [
                  _buildPageHeader(context, '加固配置', Icons.tune),
                  const SizedBox(height: 12),
                  _buildApkSelector(context, s),
                  const SizedBox(height: 12),
                  _buildHardeningOptions(context, s),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _divider(),
          // 中栏：签名配置 + 操作按钮（按钮固定底部）
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Column(
                children: [
                  _buildPageHeader(context, '签名 & 执行', Icons.play_circle_outline),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildSignSection(context, s),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButtons(context, s),
                ],
              ),
            ),
          ),
          _divider(),
          // 右栏：日志面板（缩小占比）
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
              child: _buildLogPanel(context, s),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      color: Theme.of(context).dividerColor.withOpacity(0.5),
    );
  }

  Widget _buildPageHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppPalette.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppPalette.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title,
      {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: AppPalette.primary),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppPalette.primary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildApkSelector(BuildContext context, AppState s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, 'APK 文件', icon: Icons.android),
            const SizedBox(height: 10),
            DropTarget(
              onDragDone: (detail) {
                if (detail.files.isNotEmpty) {
                  final path = detail.files.first.path;
                  if (path.toLowerCase().endsWith('.apk') ||
                      path.toLowerCase().endsWith('.aab')) {
                    s.loadApk(path);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请拖入 .apk 或 .aab 文件')),
                    );
                  }
                }
              },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppPalette.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppPalette.primary.withOpacity(0.06),
                      AppPalette.primary.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload,
                          size: 28, color: AppPalette.primary),
                      const SizedBox(height: 6),
                      const Text('拖入 APK 文件',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_open, size: 14),
                        label: const Text('选择文件',
                            style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: s.running
                            ? null
                            : () async {
                                final result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['apk', 'aab'],
                                );
                                if (result != null &&
                                    result.files.isNotEmpty) {
                                  s.loadApk(result.files.first.path!);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (s.apkInfo != null) ...[
              _infoTile('文件名', s.apkInfo!.fileName),
              _infoTile('路径', s.apkInfo!.path),
              _infoTile('大小', formatBytes(s.apkInfo!.fileSize)),
              _infoTile('包名', s.apkInfo!.packageName),
              _infoTile('版本',
                  '${s.apkInfo!.versionName} (${s.apkInfo!.versionCode})'),
              _infoTile('minSdk', '${s.apkInfo!.minSdk}'),
            ] else if (s.apkLoadError != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(s.apkLoadError!,
                          style: const TextStyle(fontSize: 11, color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: SelectableText(value,
                style: const TextStyle(fontSize: 11, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildHardeningOptions(BuildContext context, AppState s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, '加固参数', icon: Icons.tune),
            const SizedBox(height: 10),
            const Text('排除架构 (ABI)',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 0,
              runSpacing: -8,
              children: [
                _checkboxTile(s, 'armeabi-v7a', 'excludeArm'),
                _checkboxTile(s, 'arm64-v8a', 'excludeArm64'),
                _checkboxTile(s, 'x86', 'excludeX86'),
                _checkboxTile(s, 'x86_64', 'excludeX86_64'),
              ],
            ),
            const Divider(height: 20),
            _switchTile(
              s,
              '体积压缩 (-S)',
              'smaller',
              '牺牲部分性能换取更小体积',
            ),
            _switchTile(
              s,
              '加固不签名 (-x)',
              'noSign',
              'dpt 不进行签名',
            ),
            _switchTile(
              s,
              '保留类 (-K)',
              'keepClasses',
              '保留部分类以提升启动速度',
            ),
            _switchTile(s, 'Debuggable', 'debuggable', '使包可调试'),
            _switchTile(
              s,
              '运行时签名校验',
              'verifySign',
              '运行时校验 APK 签名',
            ),
            _switchTile(
              s,
              '禁用组件工厂',
              'disableAcf',
              '禁用 AppComponentFactory',
            ),
            _switchTile(s, '详细日志', 'noisyLog', '打开 noisy 日志'),
            const Divider(height: 20),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.rule, size: 18),
              title: const Text('排除规则文件 (-r)',
                  style: TextStyle(fontSize: 12)),
              subtitle: Text(s.rulesFile ?? '未选择',
                  style: const TextStyle(fontSize: 10)),
              trailing: OutlinedButton(
                onPressed: s.running
                    ? null
                    : () async {
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null && result.files.isNotEmpty) {
                          setState(() => s.rulesFile = result.files.first.path);
                        }
                      },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('选择', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkboxTile(AppState s, String label, String fieldName) {
    final value = _getBool(s, fieldName) as bool;
    return SizedBox(
      width: 140,
      child: CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: value,
        title: Text(label, style: const TextStyle(fontSize: 12)),
        onChanged: s.running
            ? null
            : (v) {
                setState(() => _setBool(s, fieldName, v ?? false));
              },
      ),
    );
  }

  Widget _switchTile(
      AppState s, String title, String fieldName, String subtitle) {
    final value = _getBool(s, fieldName) as bool;
    return SwitchListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(title, style: const TextStyle(fontSize: 12)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10)),
      value: value,
      onChanged: s.running
          ? null
          : (v) {
              setState(() => _setBool(s, fieldName, v));
            },
    );
  }

  Widget _buildSignSection(BuildContext context, AppState s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, '自动签名', icon: Icons.verified_user),
            const SizedBox(height: 4),
            const Text(
              '加固完成后调用 apksigner 进行签名',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            s.signConfigs.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppPalette.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 14, color: AppPalette.accent),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            '尚无签名配置，请到"签名配置"标签页添加',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  )
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '选择签名配置',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                    ),
                    initialValue: s.selectedSignConfigId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('不签名',
                            style: TextStyle(fontSize: 12)),
                      ),
                      ...s.signConfigs.map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                    onChanged: s.running
                        ? null
                        : (v) => s.selectSignConfig(v),
                  ),
            if (s.selectedSignConfig != null) ...[
              const SizedBox(height: 10),
              _infoTile('Keystore', s.selectedSignConfig!.keystorePath),
              _infoTile('别名', s.selectedSignConfig!.alias),
              _infoTile(
                '策略',
                s.selectedSignConfig!.autoScheme
                    ? "自动探测"
                    : _schemeSummary(s.selectedSignConfig!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _schemeSummary(SignConfig c) {
    final parts = <String>[];
    if (c.enableV1) parts.add('V1');
    if (c.enableV2) parts.add('V2');
    if (c.enableV3) parts.add('V3');
    if (c.enableV4) parts.add('V4');
    return parts.isEmpty ? '无' : parts.join('+');
  }

  Widget _buildActionButtons(BuildContext context, AppState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s.running)
          OutlinedButton.icon(
            icon: const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: const Text('取消'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: s.cancel,
          )
        else
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('开始加固'),
            onPressed: s.apkInfo == null ? null : s.runHarden,
          ),
        if (s.lastOutputApk != null && !s.running) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open, size: 14),
            label: const Text('打开产物目录',
                style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: () => revealInExplorer(s.lastOutputApk!),
          ),
        ],
      ],
    );
  }

  Widget _buildLogPanel(BuildContext context, AppState s) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final termBg = isDark ? const Color(0xFF1E293B) : cs.surface;
    final termHeaderBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final termBorder = cs.outlineVariant;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: termBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            Container(
              height: 36,
              color: termHeaderBg,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.terminal,
                      size: 14, color: AppPalette.primary),
                  const SizedBox(width: 8),
                  Text(
                    '日志',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (s.logs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppPalette.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${s.logs.length}',
                        style: TextStyle(
                          color: AppPalette.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14),
                    color: cs.onSurfaceVariant,
                    tooltip: '复制全部',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 24, minHeight: 24),
                    onPressed: s.logs.isEmpty
                        ? null
                        : () {
                            final text = s.logs
                                .map((e) =>
                                    '[${DateFormat('HH:mm:ss').format(e.time)}] [${e.level}] ${e.message}')
                                .join('\n');
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已复制全部日志'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, size: 14),
                    color: cs.onSurfaceVariant,
                    tooltip: '清空',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 24, minHeight: 24),
                    onPressed: s.clearLogs,
                  ),
                ],
              ),
            ),
            // 日志内容
            Expanded(
              child: Container(
                color: termBg,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: s.logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 32,
                                color: cs.onSurfaceVariant.withOpacity(0.3)),
                            const SizedBox(height: 8),
                            Text(
                              '尚无日志',
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SelectionArea(
                        child: ListView.builder(
                          controller: _logScrollController,
                          padding: EdgeInsets.zero,
                          itemCount: s.logs.length,
                          itemBuilder: (context, i) {
                            final e = s.logs[i];
                            return _logLine(e.time, e.level, e.message);
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logLine(DateTime time, String level, String message) {
    final cs = Theme.of(context).colorScheme;
    Color levelColor;
    switch (level) {
      case 'ERROR':
        levelColor = const Color(0xFFDC2626);
        break;
      case 'WARN':
        levelColor = const Color(0xFFD97706);
        break;
      case 'DEBUG':
        levelColor = cs.onSurfaceVariant;
        break;
      default:
        levelColor = AppPalette.primary;
    }
    final timeStr = DateFormat('HH:mm:ss').format(time);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        softWrap: true,
        selectionRegistrar: SelectionContainer.maybeOf(context),
        selectionColor: AppPalette.primary.withOpacity(0.2),
        text: TextSpan(
          style: TextStyle(
              fontFamily: 'Consolas, monospace',
              fontSize: 11.5,
              height: 1.5,
              color: cs.onSurface),
          children: [
            TextSpan(
                text: '[$timeStr] ',
                style: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.7))),
            TextSpan(
                text: '[$level] ',
                style: TextStyle(
                    color: levelColor, fontWeight: FontWeight.w600)),
            TextSpan(text: message),
          ],
        ),
      ),
    );
  }

  dynamic _getBool(AppState s, String field) {
    switch (field) {
      case 'excludeX86':
        return s.excludeX86;
      case 'excludeX86_64':
        return s.excludeX86_64;
      case 'excludeArm':
        return s.excludeArm;
      case 'excludeArm64':
        return s.excludeArm64;
      case 'smaller':
        return s.smaller;
      case 'noSign':
        return s.noSign;
      case 'keepClasses':
        return s.keepClasses;
      case 'debuggable':
        return s.debuggable;
      case 'verifySign':
        return s.verifySign;
      case 'disableAcf':
        return s.disableAcf;
      case 'noisyLog':
        return s.noisyLog;
    }
    return false;
  }

  void _setBool(AppState s, String field, bool v) {
    switch (field) {
      case 'excludeX86':
        s.excludeX86 = v;
        break;
      case 'excludeX86_64':
        s.excludeX86_64 = v;
        break;
      case 'excludeArm':
        s.excludeArm = v;
        break;
      case 'excludeArm64':
        s.excludeArm64 = v;
        break;
      case 'smaller':
        s.smaller = v;
        break;
      case 'noSign':
        s.noSign = v;
        break;
      case 'keepClasses':
        s.keepClasses = v;
        break;
      case 'debuggable':
        s.debuggable = v;
        break;
      case 'verifySign':
        s.verifySign = v;
        break;
      case 'disableAcf':
        s.disableAcf = v;
        break;
      case 'noisyLog':
        s.noisyLog = v;
        break;
    }
  }
}
