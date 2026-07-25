import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/sign_config.dart';
import '../providers/app_state.dart';

class SignConfigsPage extends StatelessWidget {
  const SignConfigsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('签名配置', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('新增签名'),
                onPressed: () async {
                  final c =
                      SignConfig.create(name: '新签名 ${s.signConfigs.length + 1}');
                  final saved = await showDialog<SignConfig>(
                    context: context,
                    builder: (_) => _SignConfigDialog(config: c),
                  );
                  if (saved != null) {
                    await s.addSignConfig(saved);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '管理用于加固后自动签名的 keystore 配置',
            style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: s.signConfigs.isEmpty
                ? _emptyState(context)
                : ListView.separated(
                    itemCount: s.signConfigs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _configCard(context, s, s.signConfigs[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppPalette.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.vpn_key_outlined,
                size: 34, color: AppPalette.primary.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          Text(
            '尚无签名配置',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '点击右上角"新增签名"按钮添加你的第一个 keystore',
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _configCard(BuildContext context, AppState s, SignConfig c) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppPalette.primary.withValues(alpha: 0.16),
                  AppPalette.accent.withValues(alpha: 0.14),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.vpn_key_rounded,
                size: 20, color: AppPalette.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 12,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        c.keystorePath.isEmpty
                            ? '未配置 keystore'
                            : c.keystorePath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _actionIcon(
            icon: Icons.edit_outlined,
            tooltip: '编辑',
            color: AppPalette.primary,
            onPressed: () async {
              final updated = await showDialog<SignConfig>(
                context: context,
                builder: (_) => _SignConfigDialog(config: c.copy()),
              );
              if (updated != null) {
                await s.updateSignConfig(updated);
              }
            },
          ),
          const SizedBox(width: 4),
          _actionIcon(
            icon: Icons.delete_outline_rounded,
            tooltip: '删除',
            color: const Color(0xFFEF4444),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('确认删除'),
                  content: Text('删除签名配置 "${c.name}" ?'),
                  actions: [
                    TextButton(
                      child: const Text('取消'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444)),
                      child: const Text('删除'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await s.deleteSignConfig(c.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: color,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.08),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      onPressed: onPressed,
    );
  }
}

class _SignConfigDialog extends StatefulWidget {
  final SignConfig config;
  const _SignConfigDialog({required this.config});

  @override
  State<_SignConfigDialog> createState() => _SignConfigDialogState();
}

class _SignConfigDialogState extends State<_SignConfigDialog> {
  late final TextEditingController _name;
  late final TextEditingController _ksPath;
  late final TextEditingController _ksPass;
  late final TextEditingController _alias;
  late final TextEditingController _aliasPass;
  late bool v1, v2, v3, v4, auto;

  @override
  void initState() {
    super.initState();
    final c = widget.config;
    _name = TextEditingController(text: c.name);
    _ksPath = TextEditingController(text: c.keystorePath);
    _ksPass = TextEditingController(text: c.keystorePassword);
    _alias = TextEditingController(text: c.alias);
    _aliasPass = TextEditingController(text: c.aliasPassword);
    v1 = c.enableV1;
    v2 = c.enableV2;
    v3 = c.enableV3;
    v4 = c.enableV4;
    auto = c.autoScheme;
  }

  @override
  void dispose() {
    _name.dispose();
    _ksPath.dispose();
    _ksPass.dispose();
    _alias.dispose();
    _aliasPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppPalette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.vpn_key_rounded,
                size: 18, color: AppPalette.primary),
          ),
          const SizedBox(width: 12),
          const Text('签名配置'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: '配置名称'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ksPath,
                      decoration: const InputDecoration(
                        labelText: 'Keystore 路径',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    child: const Text('浏览'),
                    onPressed: () async {
                      final r = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jks', 'keystore'],
                      );
                      if (r != null && r.files.isNotEmpty) {
                        _ksPath.text = r.files.first.path!;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ksPass,
                decoration: const InputDecoration(
                  labelText: 'Keystore 密码',
                  isDense: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _alias,
                decoration: const InputDecoration(
                  labelText: '别名 (alias)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _aliasPass,
                decoration: const InputDecoration(
                  labelText: '别名密码',
                  isDense: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('签名策略',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.primary,
                      letterSpacing: 0.8,
                    )),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('自动探测', style: TextStyle(fontSize: 13)),
                subtitle: Text('按 minSdkVersion 自动选择签名方案',
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                value: auto,
                onChanged: (v) => setState(() {
                  auto = v;
                  if (v) {
                    v1 = v2 = v3 = v4 = false;
                  }
                }),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    _schemeChip('V1 (JAR)', v1, (b) => setState(() => v1 = b)),
                    _schemeChip('V2', v2, (b) => setState(() => v2 = b)),
                    _schemeChip('V3', v3, (b) => setState(() => v3 = b)),
                    _schemeChip('V4', v4, (b) => setState(() => v4 = b)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
        FilledButton(
          child: const Text('保存'),
          onPressed: () {
            final c = widget.config
              ..name = _name.text.trim()
              ..keystorePath = _ksPath.text.trim()
              ..keystorePassword = _ksPass.text
              ..alias = _alias.text.trim()
              ..aliasPassword = _aliasPass.text
              ..enableV1 = v1
              ..enableV2 = v2
              ..enableV3 = v3
              ..enableV4 = v4
              ..autoScheme = auto;
            Navigator.pop(context, c);
          },
        ),
      ],
    );
  }

  Widget _schemeChip(String label, bool value, ValueChanged<bool> onChanged) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      label: Text(label),
      selected: value,
      showCheckmark: true,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: value ? Colors.white : cs.onSurfaceVariant,
      ),
      backgroundColor:
          isDark ? AppPalette.darkSoft : AppPalette.surfaceSoftLight,
      selectedColor: AppPalette.primary,
      elevation: 0,
      pressElevation: 0,
      side: value
          ? const BorderSide(color: AppPalette.primary)
          : BorderSide(
              color: isDark ? AppPalette.darkBorder : AppPalette.borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (v) {
        if (auto) {
          setState(() => auto = false);
        }
        onChanged(v);
      },
    );
  }
}
