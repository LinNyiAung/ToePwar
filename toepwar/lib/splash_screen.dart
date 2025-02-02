import 'package:flutter/material.dart';
import 'package:toepwar/views/auth/login_view.dart';
import 'package:toepwar/views/dashboard/dashboard_view.dart';

import 'helpers/auth_storage.dart';
import 'helpers/goal_reminder_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await AuthStorage.isLoggedIn();

    if (isLoggedIn) {
      final user = await AuthStorage.getSavedUser();
      if (user != null) {
        await GoalReminderService.instance.initialize(user.token);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardView(token: user.token),
          ),
        );
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}