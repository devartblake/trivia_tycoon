import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/theme/themes.dart';

class CompetitionScreen extends StatelessWidget {
  const CompetitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final competitionTheme = AppTheme.fromType(ThemeType.competition, ThemeMode.system);

    return Theme(
      data: competitionTheme.themeData,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Competition Mode"),
          leading: IconButton( // ✅ Back button to return to previous screen
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.pop(); // Navigate back
            },
          ),
        ),
        body: Center(
          child: Text(
            "This screen uses a custom theme!",
            style: TextStyle(fontSize: 20, fontFamily: competitionTheme.fontFamily),
          ),
        ),
      )
    );
  }
}