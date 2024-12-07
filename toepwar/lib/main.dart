import 'package:flutter/material.dart';

import 'views/auth/login_view.dart';

void main() {
  runApp(FinancialApp());
}

class FinancialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Financial Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginView(),
    );
  }
}
