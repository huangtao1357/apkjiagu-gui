import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/harden_page.dart';
import 'pages/history_page.dart';
import 'pages/sign_configs_page.dart';
import 'providers/app_state.dart';

/// 应用主题色板：科技工业风
/// 主色 deepTeal (#0F766E) + 琥珀辅色 amber (#F59E0B)
class AppPalette {
  static const primary = Color(0xFF0F766E);
  static const primaryDark = Color(0xFF0B5953);
  static const accent = Color(0xFFF59E0B);
  static const accentDark = Color(0xFFB45309);
  static const bgLight = Color(0xFFF6F8FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE2E8F0);
  static const darkSurface = Color(0xFF0F172A);
  static const darkSurface2 = Color(0xFF1E293B);
  static const darkBorder = Color(0xFF334155);
}

class ApkJiaguApp extends StatelessWidget {
  const ApkJiaguApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APK 加固工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.primary,
          brightness: Brightness.light,
          primary: AppPalette.primary,
          secondary: AppPalette.accent,
          surface: AppPalette.bgLight,
        ),
        scaffoldBackgroundColor: AppPalette.bgLight,
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppPalette.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppPalette.borderLight, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerColor: AppPalette.borderLight,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Microsoft YaHei UI',
        textTheme: const TextTheme(
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppPalette.primary,
            side: const BorderSide(color: AppPalette.primary, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppPalette.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.primary,
          brightness: Brightness.dark,
          primary: AppPalette.primary,
          secondary: AppPalette.accent,
        ),
        scaffoldBackgroundColor: AppPalette.darkSurface,
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppPalette.darkSurface2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppPalette.darkBorder, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerColor: AppPalette.darkBorder,
      ),
      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pages = [
      const HardenPage(),
      const SignConfigsPage(),
      const HistoryPage(),
    ];

    return Scaffold(
      body: Row(
        children: [
          _SideNav(
            index: _index,
            onChanged: (i) => setState(() => _index = i),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                if (s.envError != null || !s.envReady) _EnvBanner(state: s),
                Expanded(child: pages[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _SideNav({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppPalette.darkSurface : const Color(0xFFF1F5F9);

    final items = [
      _NavItem(
          icon: Icons.security_outlined,
          activeIcon: Icons.shield,
          label: '加固'),
      _NavItem(
          icon: Icons.key_outlined, activeIcon: Icons.key, label: '签名配置'),
      _NavItem(
          icon: Icons.history_outlined,
          activeIcon: Icons.history,
          label: '历史记录'),
    ];

    return Container(
      width: 200,
      color: bg,
      child: Column(
        children: [
          // Logo 区域
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.4),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppPalette.primary, AppPalette.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APK 加固',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'DPT-SHELL',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppPalette.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 导航项
          ...List.generate(items.length, (i) {
            final item = items[i];
            final active = i == index;
            return _NavTile(
              item: item,
              active: active,
              onTap: () => onChanged(i),
            );
          }),
          const Spacer(),
          // 底部版本信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant.withOpacity(0.6),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _NavTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: active ? AppPalette.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  active ? item.activeIcon : item.icon,
                  size: 20,
                  color: active ? AppPalette.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? AppPalette.primary : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnvBanner extends StatelessWidget {
  final AppState state;
  const _EnvBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.envError != null) {
      return Material(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.envError!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!state.envReady) {
      return Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('正在初始化运行环境...'),
            ],
          ),
        ),
      );
    }
    if (state.javaVersion != null) {
      return Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.check_circle,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '运行环境就绪 · Java ${state.javaVersion}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
