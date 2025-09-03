import 'package:flutter/material.dart';
import 'package:trivia_tycoon/admin/widgets/splash_selector_widget.dart';

class SplashSelectorScreen extends StatelessWidget {
  const SplashSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Splash Screen'),
        backgroundColor: Colors.orangeAccent.shade200,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SplashSelectorWidget(),
      ),
    );
  }
}
