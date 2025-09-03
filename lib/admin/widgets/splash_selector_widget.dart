import 'package:flutter/material.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../core/services/navigation/splash_type.dart';
import '../../widgets/splash_screen_preview.dart';

class SplashSelectorWidget extends StatefulWidget {
  const SplashSelectorWidget({super.key});

  @override
  State<SplashSelectorWidget> createState() => _SplashSelectorWidgetState();
}

class _SplashSelectorWidgetState extends State<SplashSelectorWidget> {
  SplashType _selectedType = SplashType.vaultUnlock;

  @override
  void initState() {
    super.initState();
    AppSettings.getSplashType().then((type) {
      setState(() => _selectedType = type);
    });
  }

  void _showPreview(SplashType type) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            SplashScreenPreview(type: type),
            Positioned(
              top: 32,
              right: 32,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: SplashType.values.map((type) {
        return Card(
          child: ListTile(
            leading: Image.asset(
              'assets/splash_previews/${type.name}.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
            title: Text(type.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _showPreview(type),
                  child: const Text('Show Preview'),
                ),
                const SizedBox(width: 8),
                Radio<SplashType>(
                  value: type,
                  groupValue: _selectedType,
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _selectedType = val);
                      await AppSettings.setSplashType(val);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    )
    );
  }
}