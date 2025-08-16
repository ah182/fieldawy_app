import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Detect if the system is in dark mode
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Select the appropriate logo and background color
    final logoPath =
        isDarkMode ? 'assets/logo_dark.png' : 'assets/logo_light.png';
    final backgroundColor =
        isDarkMode ? const Color(0xFF1f1d1d) : const Color(0xFFf3f4f7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the appropriate logo
            Image(
              image: AssetImage(logoPath),
              width: 300, // You can adjust the size
            ),
            const SizedBox(height: 34),
            CircularProgressIndicator(
              // Use the app's theme color for the indicator
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
