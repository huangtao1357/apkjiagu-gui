import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/history_record.dart';
import '../providers/app_state.dart';
import '../utils/file_utils.dart';

/// 表格列定义：(标题, 宽度)
const List<(String, double)> _columns = [
  ('文件名', 230),
  ('大小', 170),
  ('加固日期', 140),
  ('包名', 200),
  ('版本', 140),
  ('状态', 116),
  ('操作', 104),
];

double get _tableWidth =>
    _columns.fold(0.0, (sum, c) => sum + c.$2);

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _hCtrl = ScrollController();
  final _vCtrl = ScrollController();

  @override
  void dispose() {
    _hCtrl.dispose();
    _vCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('加固历史', style: Theme.of(context).textTheme.headlineSmall),
              if (s.history.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppPalette.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${s.history.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.primary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('刷新'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                ),
                onPressed: s.refreshHistory,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '记录每次加固的输入输出与结果状态',
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: s.history.isEmpty
                ? _emptyState(context)
                : AppCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Scrollbar(
                        controller: _hCtrl,
                        thumbVisibility: false,
                        child: SingleChildScrollView(
                          controller: _hCtrl,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: _tableWidth,
                            child: Column(
                              children: [
                                _headerRow(context),
                                Divider(
                                    height: 1,
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.6)),
                                Expanded(
                                  child: Scrollbar(
                                    controller: _vCtrl,
                                    thumbVisibility: true,
                                    child: ListView.separated(
                                      controller: _vCtrl,
                                      itemCount: s.history.length,
                                      separatorBuilder: (_, _) => Divider(
                                        height: 1,
                                        color: cs.outlineVariant
                                            .withValues(alpha: 0.4),
                                      ),
                                      itemBuilder: (context, i) =>
                                          _dataRow(context, s.history[i], s),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      color: isDark ? AppPalette.darkSurface2 : AppPalette.surfaceSoftLight,
      child: Row(
        children: _columns
            .map((c) => _cell(
                  c.$2,
                  Text(
                    c.$1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  /// 固定宽度单元格
  Widget _cell(double width, Widget child) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: child,
      ),
    );
  }

  Widget _dataRow(BuildContext context, HistoryRecord r, AppState s) {
    final cs = Theme.of(context).colorScheme;
    Color statusColor;
    switch (r.status) {
      case RecordStatus.success:
        statusColor = const Color(0xFF10B981);
        break;
      case RecordStatus.failed:
        statusColor = const Color(0xFFEF4444);
        break;
      case RecordStatus.running:
        statusColor = AppPalette.primary;
        break;
      case RecordStatus.canceled:
        statusColor = cs.onSurfaceVariant;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _cell(
            _columns[0].$2,
            Tooltip(
              message: r.fileName,
              child: Text(
                r.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface),
              ),
            ),
          ),
          _cell(_columns[1].$2,
              Text(_size(r), style: _bodyStyle(cs))),
          _cell(
            _columns[2].$2,
            Text(DateFormat('yyyy-MM-dd\nHH:mm:ss').format(r.createdAt),
                style: _bodyStyle(cs)),
          ),
          _cell(
            _columns[3].$2,
            Text(r.packageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _bodyStyle(cs)),
          ),
          _cell(
            _columns[4].$2,
            Text(
                r.versionName.isEmpty
                    ? r.versionCode.toString()
                    : '${r.versionName} (${r.versionCode})',
                style: _bodyStyle(cs)),
          ),
          _cell(
            _columns[5].$2,
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      r.status.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _cell(
            _columns[6].$2,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  color: AppPalette.primary,
                  tooltip: '打开所在文件夹',
                  visualDensity: VisualDensity.compact,
                  onPressed: r.outputPath.isEmpty
                      ? null
                      : () => revealInExplorer(r.outputPath),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: const Color(0xFFEF4444),
                  tooltip: '删除记录',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('删除记录'),
                        content:
                            Text('删除 "${r.fileName}" 的历史记录？(不会删除文件)'),
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
                    if (ok == true) await s.deleteHistory(r.id);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _bodyStyle(ColorScheme cs) =>
      TextStyle(fontSize: 12.5, height: 1.35, color: cs.onSurface);

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
            child: Icon(Icons.history_rounded,
                size: 36, color: AppPalette.primary.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          Text(
            '尚无历史记录',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '完成一次加固后，记录会显示在这里',
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _size(HistoryRecord r) {
    final orig = formatBytes(r.originalSize);
    if (r.outputSize != null) {
      return '$orig → ${formatBytes(r.outputSize!)}';
    }
    return orig;
  }
}
