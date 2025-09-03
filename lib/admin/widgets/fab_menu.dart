import 'package:flutter/material.dart';

class FABMenu extends StatefulWidget {
  final void Function()? onAdd;
  final void Function()? onImport;
  final void Function()? onExport;
  final void Function()? onSyncFromServer;
  final void Function()? onSyncToServer;
  final bool showSyncButtons;

  const FABMenu({
    super.key,
    this.onAdd,
    this.onImport,
    this.onExport,
    this.onSyncFromServer,
    this.onSyncToServer,
    this.showSyncButtons = true,
  });

  @override
  State<FABMenu> createState() => _FABMenuState();
}

class _FABMenuState extends State<FABMenu> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(_controller);
  }

  void _toggleMenu() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpanded) ...[
          _buildAction(Icons.add, "Add Question", widget.onAdd),
          _buildAction(Icons.file_upload, "Import", widget.onImport),
          _buildAction(Icons.download, "Export", widget.onExport),
          if (widget.showSyncButtons) ...[
            _buildAction(Icons.cloud_download, "Sync From", widget.onSyncFromServer),
            _buildAction(Icons.cloud_upload, "Sync To", widget.onSyncToServer),
          ],
          const SizedBox(height: 10),
        ],
        FloatingActionButton(
          heroTag: 'fab-toggle',
          onPressed: _toggleMenu,
          child: Icon(_isExpanded ? Icons.close : Icons.menu),
        ),
      ],
    );
  }

  Widget _buildAction(IconData icon, String label, void Function()? onPressed) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FloatingActionButton.extended(
            heroTag: label,
            icon: Icon(icon),
            label: Text(label),
            onPressed: () {
              onPressed?.call();
              _toggleMenu(); // auto-close
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
