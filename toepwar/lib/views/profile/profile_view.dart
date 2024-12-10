import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../utils/api_constants.dart';
import '../auth/login_view.dart';
import '../dashboard/widgets/drawer_widget.dart';

class ProfileView extends StatefulWidget {
  final String token;

  ProfileView({required this.token});

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late String username;
  late String email;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/profile'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        username = data['username'];
        email = data['email'];
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'Failed to load profile data';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      drawer: DrawerWidget(  // Use the DrawerWidget here
        token: widget.token, onTransactionChanged: () {  },

      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(child: Text(errorMessage))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                    SizedBox(height: 16),
                    Text(username),
                    Text(email),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to settings
              },
            ),
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Security'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to security settings
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginView(

                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
