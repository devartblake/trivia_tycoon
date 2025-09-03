import 'package:flutter/material.dart';
import 'package:trivia_tycoon/screens/store/widgets/ad_remove_options.dart';
import 'package:trivia_tycoon/screens/store/widgets/reward_center.dart';
import 'package:trivia_tycoon/screens/store/widgets/sale_info.dart';
import 'package:trivia_tycoon/screens/store/widgets/try_now_widget.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/images/avatars/default-avatar.png'), // Profile icon
            ),
            Row(
              children: [
                Icon(Icons.check, color: Colors.white),
                SizedBox(width: 8),
                Text('1', style: TextStyle(color: Colors.white)),
                SizedBox(width: 16),
                Icon(Icons.monetization_on, color: Colors.white),
                SizedBox(width: 8),
                Text('1440', style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          // Ad Remove Options Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AdRemoveOptions(),
          ),

          // Gift Section with Sale Info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TryNowWidget(
                  modelPath: 'assets/models/cartoon_character.obj', // Replace with your 3D model path
                  title: "Get your own 3D Avatar",
                ),
                SizedBox(height: 20),
                SaleInfo(),
              ],
            ),
          ),

          // Reward Center Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RewardCenter(),  // Ensure this widget is rendering
          ),
        ],
      ),
    );
  }
}
