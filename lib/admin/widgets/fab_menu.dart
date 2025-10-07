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
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _rotation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _toggleMenu() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded) ...[
          _buildAction(
            Icons.add,
            "Add Question",
            const Color(0xFF10B981),
            widget.onAdd,
          ),
          _buildAction(
            Icons.file_upload,
            "Import",
            const Color(0xFF3B82F6),
            widget.onImport,
          ),
          _buildAction(
            Icons.download,
            "Export",
            const Color(0xFFF59E0B),
            widget.onExport,
          ),
          if (widget.showSyncButtons) ...[
            _buildAction(
              Icons.cloud_download,
              "Sync From",
              const Color(0xFF6366F1),
              widget.onSyncFromServer,
            ),
            _buildAction(
              Icons.cloud_upload,
              "Sync To",
              const Color(0xFFEF4444),
              widget.onSyncToServer,
            ),
          ],
          const SizedBox(height: 12),
        ],
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isExpanded
                  ? [const Color(0xFFEF4444), const Color(0xFFF87171)]
                  : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_isExpanded ? const Color(0xFFEF4444) : const Color(0xFF6366F1))
                    .withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleMenu,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: RotationTransition(
                  turns: _rotation,
                  child: Icon(
                    _isExpanded ? Icons.close : Icons.menu,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAction(
      IconData icon,
      String label,
      Color color,
      void Function()? onPressed,
      ) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  onPressed?.call();
                  _toggleMenu();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
