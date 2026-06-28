import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sign_config.dart';
import '../providers/app_state.dart';

class SignConfigsPage extends StatelessWidget {
  const SignConfigsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('签名配置', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('新增'),
                onPressed: () async {
                  final c = SignConfig.create(name: '新签名 ${s.signConfigs.length + 1}');
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
          const SizedBox(height: 8),
          Expanded(
            child: s.signConfigs.isEmpty
                ? const Center(
                    child: Text('尚无签名配置，点击右上角"新增"按钮添加',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    itemCount: s.signConfigs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = s.signConfigs[i];
                      return ListTile(
                        leading: const Icon(Icons.key),
                        title: Text(c.name),
                        subtitle: Text(
                          c.keystorePath.isEmpty
                              ? '未配置 keystore'
                              : c.keystorePath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: '编辑',
                              onPressed: () async {
                                final updated =
                                    await showDialog<SignConfig>(
                                  context: context,
                                  builder: (_) =>
                                      _SignConfigDialog(config: c.copy()),
                                );
                                if (updated != null) {
                                  await s.updateSignConfig(updated);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: '删除',
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('确认删除'),
                                    content: Text('删除签名配置 "${c.name}" ?'),
                                    actions: [
                                      TextButton(
                                        child: const Text('取消'),
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                      ),
                                      FilledButton(
                                        child: const Text('删除'),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
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
                    },
                  ),
          ),
        ],
      ),
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
    return AlertDialog(
      title: const Text('签名配置'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: '配置名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ksPath,
                      decoration: const InputDecoration(
                        labelText: 'Keystore 路径',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    child: const Text('选择'),
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
              const SizedBox(height: 12),
              TextField(
                controller: _ksPass,
                decoration: const InputDecoration(
                  labelText: 'Keystore 密码',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _alias,
                decoration: const InputDecoration(
                  labelText: '别名 (alias)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aliasPass,
                decoration: const InputDecoration(
                  labelText: '别名密码',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('签名策略',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              SwitchListTile(
                dense: true,
                title: const Text('自动探测'),
                subtitle: const Text('按 minSdkVersion 自动选择签名方案'),
                value: auto,
                onChanged: (v) => setState(() {
                  auto = v;
                  if (v) {
                    v1 = v2 = v3 = v4 = false;
                  }
                }),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _schemeChip('V1 (JAR)', v1, (b) => setState(() => v1 = b)),
                  _schemeChip('V2', v2, (b) => setState(() => v2 = b)),
                  _schemeChip('V3', v3, (b) => setState(() => v3 = b)),
                  _schemeChip('V4', v4, (b) => setState(() => v4 = b)),
                ],
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
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: (v) {
        if (auto) {
          // 用户手动选择，关闭自动探测
          setState(() => auto = false);
        }
        onChanged(v);
      },
    );
  }
}
