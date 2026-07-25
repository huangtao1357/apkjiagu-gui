import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'pages/about_page.dart';
import 'pages/harden_page.dart';
import 'pages/history_page.dart';
import 'pages/sign_configs_page.dart';
import 'providers/app_state.dart';

/// 应用主题色板 —— 淡雅靛蓝 · 薰衣草
/// 主色 indigo (#6366F1) + 辅色 lavender (#A78BFA)
/// 追求：优雅、柔和、轻盈、清新
class AppPalette {
  // 主色阶
  static const primary = Color(0xFF6366F1); // indigo-500
  static const primaryDark = Color(0xFF4F46E5); // indigo-600（渐变尾 / 按压）
  static const primaryLight = Color(0xFF818CF8); // indigo-400（渐变头）
  static const primaryOnDark = Color(0xFFA5ABFF); // 深色背景上的主色文字/图标

  // 辅色阶
  static const accent = Color(0xFFA78BFA); // violet-400 lavender
  static const accentDark = Color(0xFF8B5CF6); // violet-500

  // 浅色令牌
  static const bgLight = Color(0xFFF6F7FE); // 微紫白背景
  static const bgLightGradTop = Color(0xFFF8F9FF);
  static const bgLightGradBottom = Color(0xFFF1F2FC);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceSoftLight = Color(0xFFF4F5FD); // 输入 / 内嵌区域填充
  static const borderLight = Color(0xFFECEDF8); // 极淡发丝线
  static const navLight = Color(0xFFFBFBFF);

  // 深色令牌
  static const darkBg = Color(0xFF14131F); // 深靛炭底
  static const darkBgGradBottom = Color(0xFF17162A);
  static const darkSurface = Color(0xFF1C1B29); // 卡片
  static const darkSurface2 = Color(0xFF232238); // 侧栏 / 抬升面
  static const darkSoft = Color(0xFF262541); // 输入填充
  static const darkBorder = Color(0xFF302E48);
}

/// 柔和多层投影 —— 让卡片"浮"起来，营造轻盈感
class AppShadows {
  /// 浅色卡片：一层贴地 + 一层扩散的靛蓝柔影
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D312E81), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(
      color: Color(0x14312E81),
      blurRadius: 24,
      spreadRadius: -6,
      offset: Offset(0, 12),
    ),
  ];

  /// 浅色轻投影：用于侧栏 logo、悬浮小元素
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x11312E81),
      blurRadius: 14,
      spreadRadius: -4,
      offset: Offset(0, 6),
    ),
  ];

  /// 主色发光投影：用于主 CTA 按钮 / 品牌图标
  static List<BoxShadow> glow(Color c) => [
        BoxShadow(
          color: c.withValues(alpha: 0.35),
          blurRadius: 18,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ];

  /// 深色卡片投影
  static const List<BoxShadow> dark = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 20,
      spreadRadius: -8,
      offset: Offset(0, 10),
    ),
  ];
}

/// 通用「软投影卡片」—— 替代生硬 1px 边框的浮动卡片
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double radius;
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ??
            (isDark ? AppPalette.darkSurface : AppPalette.surfaceLight),
        borderRadius: BorderRadius.circular(radius),
        border: isDark
            ? Border.all(color: AppPalette.darkBorder, width: 1)
            : null,
        boxShadow: isDark ? AppShadows.dark : AppShadows.card,
      ),
      child: child,
    );
  }
}

/// 渐变主按钮 —— 用于关键 CTA（如「开始加固」）
class GradientButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  const GradientButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [AppPalette.primaryLight, AppPalette.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : AppPalette.primary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled ? AppShadows.glow(AppPalette.primary) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 19),
                  child: icon,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
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

class ApkJiaguApp extends StatelessWidget {
  const ApkJiaguApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APK 加固工具',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const _HomeShell(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppPalette.primary,
      secondary: AppPalette.accent,
      surface: isDark ? AppPalette.darkSurface : AppPalette.surfaceLight,
    );

    final softFill =
        isDark ? AppPalette.darkSoft : AppPalette.surfaceSoftLight;
    final border = isDark ? AppPalette.darkBorder : AppPalette.borderLight;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppPalette.darkBg : AppPalette.bgLight,
      dividerColor: border,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'Microsoft YaHei UI',
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppPalette.darkSurface : AppPalette.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: isDark
              ? const BorderSide(color: AppPalette.darkBorder, width: 1)
              : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isDark ? AppPalette.primaryOnDark : AppPalette.primary,
          side: BorderSide(
            color: (isDark ? AppPalette.primaryOnDark : AppPalette.primary)
                .withValues(alpha: 0.35),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              isDark ? AppPalette.primaryOnDark : AppPalette.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? const Color(0xFF6B6A82) : const Color(0xFFCBCDE6);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppPalette.primary;
          return isDark ? AppPalette.darkSoft : const Color(0xFFE6E7F4);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppPalette.primary;
          return Colors.transparent;
        }),
        side: BorderSide(
          color: isDark ? AppPalette.darkBorder : const Color(0xFFC7C9E4),
          width: 1.5,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        selectedColor: AppPalette.primary.withValues(alpha: 0.14),
        backgroundColor: softFill,
        side: BorderSide.none,
        labelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppPalette.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppPalette.darkSurface2 : const Color(0xFF2A2740),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: softFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = [
      const HardenPage(),
      const SignConfigsPage(),
      const HistoryPage(),
      const AboutPage(),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [AppPalette.darkBg, AppPalette.darkBgGradBottom]
                : const [
                    AppPalette.bgLightGradTop,
                    AppPalette.bgLightGradBottom,
                  ],
          ),
        ),
        child: Row(
          children: [
            _SideNav(
              index: _index,
              onChanged: (i) => setState(() => _index = i),
            ),
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
      ),
    );
  }
}

class _SideNav extends StatefulWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _SideNav({required this.index, required this.onChanged});

  @override
  State<_SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<_SideNav> {
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
    final bg = isDark ? AppPalette.darkSurface2 : AppPalette.navLight;

    final items = [
      _NavItem(
          icon: Icons.shield_outlined, activeIcon: Icons.shield, label: '加固'),
      _NavItem(
          icon: Icons.vpn_key_outlined, activeIcon: Icons.vpn_key, label: '签名配置'),
      _NavItem(
          icon: Icons.history_outlined,
          activeIcon: Icons.history,
          label: '历史记录'),
      _NavItem(
          icon: Icons.info_outline, activeIcon: Icons.info, label: '关于'),
    ];

    return Container(
      width: 212,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          right: BorderSide(
            color: isDark
                ? AppPalette.darkBorder
                : AppPalette.borderLight.withValues(alpha: 0.9),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 品牌区
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppPalette.primaryLight, AppPalette.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.glow(AppPalette.primary),
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 23),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APK 加固',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DPT · SHELL',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isDark
                            ? AppPalette.primaryOnDark
                            : AppPalette.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 导航项
          ...List.generate(items.length, (i) {
            return _NavTile(
              item: items[i],
              active: i == widget.index,
              onTap: () => widget.onChanged(i),
            );
          }),
          const Spacer(),
          // 底部版本
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _version.isEmpty ? '' : _version,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor =
        isDark ? AppPalette.primaryOnDark : AppPalette.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: active
            ? AppPalette.primary.withValues(alpha: isDark ? 0.18 : 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                // 活动指示条
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3,
                  height: active ? 16 : 0,
                  margin: EdgeInsets.only(right: active ? 9 : 12),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  active ? item.activeIcon : item.icon,
                  size: 19,
                  color: active ? activeColor : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 11),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? activeColor : cs.onSurface,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget banner({
      required Color tint,
      required Widget leading,
      required Widget content,
    }) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: isDark ? 0.16 : 0.09),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tint.withValues(alpha: 0.22), width: 1),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    if (state.envError != null) {
      const errColor = Color(0xFFEF4444);
      return banner(
        tint: errColor,
        leading: const Icon(Icons.error_outline, size: 18, color: errColor),
        content: Text(
          state.envError!,
          style: const TextStyle(
            color: errColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    if (!state.envReady) {
      return banner(
        tint: AppPalette.primary,
        leading: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppPalette.primary,
          ),
        ),
        content: Text(
          '正在初始化运行环境…',
          style: TextStyle(
            color: isDark ? AppPalette.primaryOnDark : AppPalette.primaryDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    if (state.javaVersion != null) {
      const okColor = Color(0xFF10B981);
      return banner(
        tint: okColor,
        leading: const Icon(Icons.check_circle, size: 17, color: okColor),
        content: Text(
          '运行环境就绪 · Java ${state.javaVersion}',
          style: TextStyle(
            color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
