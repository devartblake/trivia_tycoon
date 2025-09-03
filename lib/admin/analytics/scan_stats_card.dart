import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../ui_components/qr_code/models/scan_history_item.dart';
import '../../../ui_components/qr_code/services/qr_history_service.dart';
import '../../../ui_components/qr_code/utils/qr_scan_format_utils.dart';

class AdminScanStatsCard extends StatefulWidget {
  final String userId; // Inject from admin session or dashboard

  const AdminScanStatsCard({super.key, required this.userId});

  @override
  State<AdminScanStatsCard> createState() => _AdminScanStatsCardState();
}

class _AdminScanStatsCardState extends State<AdminScanStatsCard> {
  List<ScanHistoryItem> _scans = [];

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    final scans = await QrHistoryService.instance.getHistory();
    setState(() => _scans = scans);
  }

  @override
  Widget build(BuildContext context) {
    if (_scans.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("No scan data available."),
        ),
      );
    }

    final total = _scans.length;
    final grouped = <String, int>{};
    for (var s in _scans) {
      grouped[s.type] = (grouped[s.type] ?? 0) + 1;
    }

    final topType = grouped.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final firstScan = _scans.last.timestamp;
    final lastScan = _scans.first.timestamp;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Scan Statistics", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text("🔐 User ID: ${widget.userId}"),
            const SizedBox(height: 6),
            Text("📊 Total Scans: $total"),
            Text("🏷️ Most Common Type: ${QrFormatUtils.labelForType(QrFormatUtils.fromName(topType))}"),
            Text("📅 First Scan: ${DateFormat.yMMMd().format(firstScan)}"),
            Text("🕓 Last Scan: ${DateFormat.yMMMd().add_jm().format(lastScan)}"),
          ],
        ),
      ),
    );
  }
}
