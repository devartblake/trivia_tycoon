import 'package:flutter/material.dart';

// Sale Info Widget (80% OFF text, image, and icons with numbers)
class SaleInfo extends StatelessWidget {
  const SaleInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blue, // Blue background
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row for Sale Info Text and Image
            Row(
              children: [
                // Image on the left side
                Image.asset('assets/images/cta_banner.png', width: 80, height: 80),
                SizedBox(width: 16),
                // "80% OFF" text on the right side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('80% OFF', style: TextStyle(color: Colors.white, fontSize: 42)),
                      SizedBox(height: 8),
                      Text(
                        'Before \$10',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('\$1.99', style: TextStyle(color: Colors.yellow, fontSize: 22)),
                    ],
                  ),
                ),
              ],
            ),

            // Icons with Numbers in a new row within Sale Info
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _imageWithNumber(Icons.check, '5', 'Check'),
                  _imageWithNumber(Icons.attach_money, '3400', 'Coin'), // For coins
                  _imageWithNumber(Icons.confirmation_number, '400', 'Ticket'), // For tickets
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display icon with number below
  Widget _imageWithNumber(IconData iconData, String number, String label) {
    return Column(
      children: [
        Icon(iconData, size: 40, color: Colors.white), // Icon instead of image
        SizedBox(height: 8),
        Text(number, style: TextStyle(color: Colors.white, fontSize: 16)), // Number below the icon
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 14)), // Label below the number
      ],
    );
  }
}
