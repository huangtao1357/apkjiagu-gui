import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app.dart';

/// 在默认浏览器中打开 URL
Future<void> _openUrl(String url) async {
  await Process.run('cmd', ['/c', 'start', '', url]);
}

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'v${info.version}.${info.buildNumber}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // 应用图标与名称
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppPalette.primary, AppPalette.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'APK 加固工具',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                _version.isEmpty ? '' : _version,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '基于 DPT-SHELL (v2.14.0) 的可视化加固与签名工具',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),

              // 链接区域
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _LinkTile(
                        icon: Icons.person_outline,
                        title: '作者 GitHub 主页',
                        subtitle: 'github.com/huangtao1357',
                        url: 'https://github.com/huangtao1357',
                        onTap: () =>
                            _openUrl('https://github.com/huangtao1357'),
                      ),
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                      _LinkTile(
                        icon: Icons.code,
                        title: '项目源码仓库',
                        subtitle: 'github.com/huangtao1357/apkjiagu-gui',
                        url: 'https://github.com/huangtao1357/apkjiagu-gui',
                        onTap: () => _openUrl(
                            'https://github.com/huangtao1357/apkjiagu-gui'),
                      ),
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                      _LinkTile(
                        icon: Icons.bug_report_outlined,
                        title: '问题反馈',
                        subtitle: '提交 Issue 或 Pull Request',
                        url:
                            'https://github.com/huangtao1357/apkjiagu-gui/issues',
                        onTap: () => _openUrl(
                            'https://github.com/huangtao1357/apkjiagu-gui/issues'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 开源许可
              _SectionTitle(title: '开源许可', cs: cs),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppPalette.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'MIT License',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Copyright © 2026 huangtao1357',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '本项目基于 MIT 协议开源，允许自由使用、修改和分发。'
                        '在所有副本或重要部分中须保留版权声明与本许可声明。',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 合规声明
              _SectionTitle(title: '合规声明', cs: cs),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DisclaimerItem(
                        text: '本工具仅供软件开发者对自有应用进行安全加固保护使用。'
                            '使用者须确保对被加固的 APK 拥有合法权利或已获得授权。',
                        cs: cs,
                      ),
                      const SizedBox(height: 10),
                      _DisclaimerItem(
                        text: '严禁将本工具用于任何侵犯他人知识产权、'
                            '破坏他人应用安全或违反法律法规的用途。'
                            '使用者自行承担因不当使用而产生的一切法律责任。',
                        cs: cs,
                      ),
                      const SizedBox(height: 10),
                      _DisclaimerItem(
                        text: '本工具基于开源项目 DPT-SHELL (v2.14.0) 构建，'
                            '不对加固后的应用提供绝对的安全保证。'
                            '加固效果可能因目标应用的结构而异。',
                        cs: cs,
                      ),
                      const SizedBox(height: 10),
                      _DisclaimerItem(
                        text: '本软件按"现状"提供，不作任何明示或暗示的担保。'
                            '在任何情况下，作者均不对因使用本软件而产生的任何损失负责。',
                        cs: cs,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 底部技术信息
              Text(
                'Flutter ${isDark ? "Dark" : "Light"} · Built with Flutter & Dart',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ColorScheme cs;
  const _SectionTitle({required this.title, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String url;
  final VoidCallback onTap;
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppPalette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new,
                size: 16, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _DisclaimerItem({required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '•',
            style: TextStyle(
              fontSize: 12,
              color: AppPalette.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
