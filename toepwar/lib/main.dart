import 'package:flutter/material.dart';
import 'package:toepwar/splash_screen.dart';

import 'views/auth/login_view.dart';


// Define global colors
class AppColors {
  static const Color primary = Color(0xFF3f8dfd);
  static const Color background = Colors.white;
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF757575);
  static const Color white = Colors.white;
}

void main() {
  runApp(FinancialApp());
}

class FinancialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Financial Management App',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputBackground,
          labelStyle: TextStyle(color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.all(20),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ),
      home: SplashScreen(),
    );
  }
}
