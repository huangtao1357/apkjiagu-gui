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

// 语义色（不随主题辅色变化）
const _warnColor = Color(0xFFF59E0B);
const _errColor = Color(0xFFEF4444);

class HardenPage extends StatefulWidget {
  const HardenPage({super.key});

  @override
  State<HardenPage> createState() => _HardenPageState();
}

class _HardenPageState extends State<HardenPage> {
  final _logScrollController = ScrollController();
  bool _dragOver = false;

  // 监听加固任务结束（成功/失败/取消），弹出提示
  AppState? _observedState;
  bool _wasRunning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.read<AppState>();
    if (!identical(s, _observedState)) {
      _observedState?.removeListener(_onAppStateChanged);
      _observedState = s;
      _observedState!.addListener(_onAppStateChanged);
      _wasRunning = s.running;
    }
  }

  @override
  void dispose() {
    _observedState?.removeListener(_onAppStateChanged);
    _logScrollController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    final s = _observedState!;
    if (_wasRunning && !s.running && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      if (s.lastOutputApk != null) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('加固完成'),
            action: SnackBarAction(
              label: '打开目录',
              onPressed: () => revealInExplorer(s.lastOutputApk!),
            ),
          ),
        );
      } else if (s.lastError != null) {
        messenger.showSnackBar(
          SnackBar(content: Text('加固失败：${s.lastError}')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('加固已取消')),
        );
      }
    }
    _wasRunning = s.running;
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

    return Row(
      children: [
        // 左栏：APK + 加固参数
        SizedBox(
          width: 356,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 10, 20),
            child: ListView(
              children: [
                _buildPageHeader(context, '加固配置', Icons.tune_rounded),
                const SizedBox(height: 18),
                _buildApkSelector(context, s),
                const SizedBox(height: 16),
                _buildHardeningOptions(context, s),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // 中栏：签名配置 + 操作按钮
        SizedBox(
          width: 312,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
            child: Column(
              children: [
                _buildPageHeader(
                    context, '签名 & 执行', Icons.play_circle_outline_rounded),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    children: [
                      _buildSignSection(context, s),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildActionButtons(context, s),
              ],
            ),
          ),
        ),
        // 右栏：日志面板
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 20, 20),
            child: _buildLogPanel(context, s),
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppPalette.primary.withValues(alpha: 0.16),
                AppPalette.accent.withValues(alpha: 0.14),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppPalette.primary),
        ),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppPalette.primaryOnDark : AppPalette.primary;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildApkSelector(BuildContext context, AppState s) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'APK 文件', icon: Icons.android_rounded),
          const SizedBox(height: 12),
          DropTarget(
            onDragEntered: (_) => setState(() => _dragOver = true),
            onDragExited: (_) => setState(() => _dragOver = false),
            onDragDone: (detail) {
              setState(() => _dragOver = false);
              if (detail.files.isNotEmpty) {
                final path = detail.files.first.path;
                if (path.toLowerCase().endsWith('.apk')) {
                  s.loadApk(path);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('仅支持 .apk 文件')),
                  );
                }
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 116,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _dragOver
                      ? AppPalette.primary
                      : AppPalette.primary.withValues(alpha: 0.28),
                  width: _dragOver ? 2 : 1.5,
                ),
                gradient: LinearGradient(
                  colors: _dragOver
                      ? [
                          AppPalette.primary.withValues(alpha: 0.16),
                          AppPalette.accent.withValues(alpha: 0.12),
                        ]
                      : [
                          AppPalette.primary.withValues(alpha: 0.06),
                          AppPalette.accent.withValues(alpha: 0.04),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: _dragOver ? 1.12 : 1,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(Icons.cloud_upload_outlined,
                          size: 30, color: AppPalette.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dragOver ? '松开以载入' : '拖入 APK 文件',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.folder_open_outlined, size: 14),
                      label: const Text('选择文件',
                          style: TextStyle(fontSize: 11.5)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: s.running
                          ? null
                          : () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['apk'],
                              );
                              if (result != null && result.files.isNotEmpty) {
                                s.loadApk(result.files.first.path!);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (s.apkInfo != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppPalette.darkSoft
                    : AppPalette.surfaceSoftLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoTile('文件名', s.apkInfo!.fileName),
                  _infoTile('路径', s.apkInfo!.path),
                  _infoTile('大小', formatBytes(s.apkInfo!.fileSize)),
                  _infoTile('包名', s.apkInfo!.packageName),
                  _infoTile('版本',
                      '${s.apkInfo!.versionName} (${s.apkInfo!.versionCode})'),
                  _infoTile('minSdk', '${s.apkInfo!.minSdk}'),
                ],
              ),
            ),
          ] else if (s.apkLoadError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _errColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _errColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 15, color: _errColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.apkLoadError!,
                        style: const TextStyle(
                            fontSize: 11.5, color: _errColor)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(label,
                style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: SelectableText(value,
                style: TextStyle(
                    fontSize: 11.5, height: 1.45, color: cs.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _buildHardeningOptions(BuildContext context, AppState s) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, '加固参数', icon: Icons.tune_rounded),
          const SizedBox(height: 12),
          Text('排除架构 (ABI)',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurfaceVariant)),
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
          _softDivider(),
          _switchTile(s, '体积压缩 (-S)', 'smaller', '牺牲部分性能换取更小体积'),
          _switchTile(s, '加固不签名 (-x)', 'noSign', 'dpt 不进行签名'),
          _switchTile(s, '保留类 (-K)', 'keepClasses', '保留部分类以提升启动速度'),
          _switchTile(s, 'Debuggable', 'debuggable', '使包可调试'),
          _switchTile(s, '运行时签名校验', 'verifySign', '运行时校验 APK 签名'),
          _switchTile(s, '禁用组件工厂', 'disableAcf', '禁用 AppComponentFactory'),
          _switchTile(s, '禁用反调试', 'disableAntiDebug', '加固应用调试时崩溃可尝试开启'),
          _switchTile(s, '禁用 CRC 检测', 'disableCrcDetect', '关闭运行时 libc .text CRC 校验'),
          _switchTile(s, '禁用 Frida 检测', 'disableFridaDetect', '关闭运行时 Frida 检测'),
          _switchTile(s, '详细日志', 'noisyLog', '打开 noisy 日志'),
          _softDivider(),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.rule_rounded,
                size: 18, color: cs.onSurfaceVariant),
            title: const Text('排除规则文件 (-r)', style: TextStyle(fontSize: 12.5)),
            subtitle: Text(s.rulesFile ?? '未选择',
                style: const TextStyle(fontSize: 10.5)),
            trailing: OutlinedButton(
              onPressed: s.running
                  ? null
                  : () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null && result.files.isNotEmpty) {
                        s.setRulesFile(result.files.first.path);
                      }
                    },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('选择', style: TextStyle(fontSize: 11.5)),
            ),
          ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.folder_copy_outlined,
                size: 18, color: cs.onSurfaceVariant),
            title: const Text('输出目录', style: TextStyle(fontSize: 12.5)),
            subtitle: Text(
              (s.customOutputDir != null && s.customOutputDir!.isNotEmpty)
                  ? s.customOutputDir!
                  : '默认：APK 所在目录下的 dpt_output 文件夹',
              style: const TextStyle(fontSize: 10.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s.customOutputDir != null &&
                    s.customOutputDir!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    tooltip: '恢复默认',
                    visualDensity: VisualDensity.compact,
                    onPressed:
                        s.running ? null : () => s.setOutputDir(null),
                  ),
                OutlinedButton(
                  onPressed: s.running
                      ? null
                      : () async {
                          final dirPath =
                              await FilePicker.platform.getDirectoryPath(
                            dialogTitle: '选择加固输出目录',
                          );
                          if (dirPath != null) {
                            s.setOutputDir(dirPath);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('选择', style: TextStyle(fontSize: 11.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _softDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
          height: 1,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.7)),
    );
  }

  Widget _checkboxTile(AppState s, String label, String fieldName) {
    final value = _getBool(s, fieldName) as bool;
    return SizedBox(
      width: 148,
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
      title: Text(title, style: const TextStyle(fontSize: 12.5)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10.5)),
      value: value,
      onChanged: s.running
          ? null
          : (v) {
              setState(() => _setBool(s, fieldName, v));
            },
    );
  }

  Widget _buildSignSection(BuildContext context, AppState s) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, '自动签名', icon: Icons.verified_user_outlined),
          const SizedBox(height: 6),
          Text(
            '加固完成后调用 apksigner 进行签名',
            style: TextStyle(
                fontSize: 10.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          s.signConfigs.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: _warnColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(11),
                    border:
                        Border.all(color: _warnColor.withValues(alpha: 0.22)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: _warnColor),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '尚无签名配置，请到"签名配置"标签页添加',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '选择签名配置',
                    isDense: true,
                  ),
                  initialValue: s.selectedSignConfigId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('不签名', style: TextStyle(fontSize: 12.5)),
                    ),
                    ...s.signConfigs.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child:
                            Text(c.name, style: const TextStyle(fontSize: 12.5)),
                      ),
                    ),
                  ],
                  onChanged:
                      s.running ? null : (v) => s.selectSignConfig(v),
                ),
          if (s.selectedSignConfig != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppPalette.darkSoft
                    : AppPalette.surfaceSoftLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoTile('Keystore', s.selectedSignConfig!.keystorePath),
                  _infoTile('别名', s.selectedSignConfig!.alias),
                  _infoTile(
                    '策略',
                    s.selectedSignConfig!.autoScheme
                        ? "自动探测"
                        : _schemeSummary(s.selectedSignConfig!),
                  ),
                ],
              ),
            ),
          ],
        ],
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
              foregroundColor: _errColor,
              side: BorderSide(color: _errColor.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            onPressed: s.cancel,
          )
        else
          GradientButton(
            icon: const Icon(Icons.play_arrow_rounded),
            label: '开始加固',
            onPressed: s.apkInfo == null ? null : s.runHarden,
          ),
        if (s.lastOutputApk != null && !s.running) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open_outlined, size: 15),
            label: const Text('打开产物目录', style: TextStyle(fontSize: 12.5)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
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
    final termBg = isDark ? AppPalette.darkSurface : Colors.white;
    final termHeaderBg =
        isDark ? AppPalette.darkSurface2 : AppPalette.surfaceSoftLight;
    final headerColor = isDark ? AppPalette.primaryOnDark : AppPalette.primary;

    return Container(
      decoration: BoxDecoration(
        color: termBg,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(color: AppPalette.darkBorder, width: 1)
            : null,
        boxShadow: isDark ? AppShadows.dark : AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏
          Container(
            height: 42,
            color: termHeaderBg,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.terminal_rounded, size: 15, color: headerColor),
                const SizedBox(width: 8),
                Text(
                  '运行日志',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                if (s.logs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppPalette.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${s.logs.length}',
                      style: TextStyle(
                        color: headerColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const Spacer(),
                _logIconButton(
                  icon: Icons.copy_rounded,
                  tooltip: '复制全部',
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
                _logIconButton(
                  icon: Icons.delete_sweep_outlined,
                  tooltip: '清空',
                  onPressed: s.logs.isEmpty ? null : s.clearLogs,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
          // 日志内容
          Expanded(
            child: Container(
              color: termBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: s.logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.article_outlined,
                              size: 34,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 10),
                          Text(
                            '尚无日志，开始加固后将在此显示',
                            style: TextStyle(
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.5),
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
    );
  }

  Widget _logIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon, size: 15),
      color: cs.onSurfaceVariant,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      onPressed: onPressed,
    );
  }

  Widget _logLine(DateTime time, String level, String message) {
    final cs = Theme.of(context).colorScheme;
    Color levelColor;
    switch (level) {
      case 'ERROR':
        levelColor = _errColor;
        break;
      case 'WARN':
        levelColor = _warnColor;
        break;
      case 'DEBUG':
        levelColor = cs.onSurfaceVariant;
        break;
      default:
        levelColor =
            Theme.of(context).brightness == Brightness.dark
                ? AppPalette.primaryOnDark
                : AppPalette.primary;
    }
    final timeStr = DateFormat('HH:mm:ss').format(time);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: RichText(
        softWrap: true,
        selectionRegistrar: SelectionContainer.maybeOf(context),
        selectionColor: AppPalette.primary.withValues(alpha: 0.2),
        text: TextSpan(
          style: TextStyle(
              fontFamily: 'Consolas, monospace',
              fontSize: 11.5,
              height: 1.55,
              color: cs.onSurface),
          children: [
            TextSpan(
                text: '$timeStr  ',
                style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
            TextSpan(
                text: '$level ',
                style: TextStyle(
                    color: levelColor, fontWeight: FontWeight.w700)),
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
    s.setHardenOption(field, v);
  }
}
