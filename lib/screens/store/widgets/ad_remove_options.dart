import 'package:flutter/material.dart';

// Ad Remove Options Widget
class AdRemoveOptions extends StatelessWidget {
  const AdRemoveOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('REMOVE ADS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
        SizedBox(height: 8),
        Text('Play without interruptions!', style: TextStyle(fontSize: 14), textAlign: TextAlign.center,),
        SizedBox(height: 16),
        _adRemoveOption('365 DAYS', '\$5.99', 'assets/images/cta_banner.png', true),
        // Row for 28 Days and 7 Days
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _adRemoveOption('28 DAYS', '\$3.99', 'assets/images/cta_banner.png', false),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _adRemoveOption('7 DAYS', '\$1.99', 'assets/images/cta_banner.png', false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget for each Ad Remove Option
  Widget _adRemoveOption(String title, String price, String imagePath, bool isBestValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
        ),
        child: Column(
          children: [
            // Image before the days
            Row(
              children: [
                Image.asset(imagePath, width: 40, height: 40), // Image for the option
                SizedBox(width: 16),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            // Price Button on a new line
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
              ),
              child: Text(price, style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
