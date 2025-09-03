import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/qr_scan_format_utils.dart';

class QrScanPreviewModal extends StatelessWidget {
  final String scanText;
  final VoidCallback? onAction;

  const QrScanPreviewModal({
    super.key,
    required this.scanText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final type = QrFormatUtils.detectType(scanText);
    final icon = QrFormatUtils.iconForType(type);
    final label = QrFormatUtils.labelForType(type);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SelectableText(scanText, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (type == QrContentType.url)
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text("Open URL"),
                onPressed: () async {
                  final uri = Uri.parse(scanText);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                  onAction?.call();
                },
              )
            else if (type == QrContentType.userId)
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text("Copy User ID"),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: scanText));
                  onAction?.call();
                },
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Done"),
                onPressed: onAction,
              ),
          ],
        ),
      ),
    );
  }
}
