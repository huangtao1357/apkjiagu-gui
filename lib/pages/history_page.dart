import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/history_record.dart';
import '../providers/app_state.dart';
import '../utils/file_utils.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
              Text('加固历史', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
                onPressed: s.refreshHistory,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: s.history.isEmpty
                ? const Center(
                    child: Text('尚无历史记录',
                        style: TextStyle(color: Colors.grey)),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('文件名')),
                          DataColumn(label: Text('大小'), numeric: true),
                          DataColumn(label: Text('加固日期')),
                          DataColumn(label: Text('包名')),
                          DataColumn(label: Text('版本')),
                          DataColumn(label: Text('状态')),
                          DataColumn(label: Text('操作')),
                        ],
                        rows: s.history.map((r) => _row(context, r, s)).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  DataRow _row(BuildContext context, HistoryRecord r, AppState s) {
    Color statusColor;
    switch (r.status) {
      case RecordStatus.success:
        statusColor = Colors.green;
        break;
      case RecordStatus.failed:
        statusColor = Colors.red;
        break;
      case RecordStatus.running:
        statusColor = Colors.blue;
        break;
      case RecordStatus.canceled:
        statusColor = Colors.grey;
        break;
    }
    return DataRow(cells: [
      DataCell(
        SizedBox(
          width: 200,
          child: Tooltip(
            message: r.fileName,
            child: Text(
              r.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      DataCell(Text(_size(r))),
      DataCell(Text(DateFormat('yyyy-MM-dd\nHH:mm:ss').format(r.createdAt))),
      DataCell(Text(r.packageName)),
      DataCell(Text(r.versionName.isEmpty
          ? r.versionCode.toString()
          : '${r.versionName} (${r.versionCode})')),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(r.status.label),
        ],
      )),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '打开所在文件夹',
            onPressed: r.outputPath.isEmpty
                ? null
                : () => revealInExplorer(r.outputPath),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: '删除记录',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('删除记录'),
                  content: Text('删除 "${r.fileName}" 的历史记录？(不会删除文件)'),
                  actions: [
                    TextButton(
                      child: const Text('取消'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    FilledButton(
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
      )),
    ]);
  }

  String _size(HistoryRecord r) {
    final orig = formatBytes(r.originalSize);
    if (r.outputSize != null) {
      return '$orig → ${formatBytes(r.outputSize!)}';
    }
    return orig;
  }
}
