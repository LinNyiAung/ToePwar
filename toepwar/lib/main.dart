import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:toepwar/splash_screen.dart';
import 'controllers/language_controller.dart';
import 'helpers/notification_service.dart';
import 'l10n/app_localizations.dart';


import 'views/auth/login_view.dart';


// Define global colors
class AppColors {
  static const Color primary = Color(0xFF3D89F6);
  static const Color background = Colors.white;
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF757575);
  static const Color white = Colors.white;
  static const Color grey = Color(0xFFEEEEEE);
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageController(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageController>(
      builder: (context, languageController, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Toe Pwar',
          // Add the navigator key from NotificationService
          navigatorKey: NotificationService.instance.navigatorKey,
          locale: languageController.currentLocale,
          supportedLocales: const [
            Locale('en'),
            Locale('my'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            primaryColor: AppColors.primary,
            cardColor: AppColors.background,

            scaffoldBackgroundColor: AppColors.grey,
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
      },
    );
  }
  }
