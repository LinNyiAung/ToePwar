import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../controllers/auth_controller.dart';
import '../../controllers/language_controller.dart';
import '../../l10n/app_localizations.dart';
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

  Future<void> _logout() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('confirmLogout')),
        content: Text(AppLocalizations.of(context).translate('logoutMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).translate('logout'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthController().logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginView()),
            (route) => false,
      );
    }
  }


  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('selectLanguage')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('English'),
                onTap: () {
                  context.read<LanguageController>().changeLanguage('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('မြန်မာ'),
                onTap: () {
                  context.read<LanguageController>().changeLanguage('my');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [

                  Expanded(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                   // Balance the header
                ],
              ),
            ),


            SizedBox(height: 16),
            if (!isLoading && errorMessage.isEmpty) ...[
              Text(
                username,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(height: 1, indent: 72, endIndent: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          AppLocalizations.of(context).translate('profile'),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),

      ),
      drawer: DrawerWidget(
        token: widget.token,
        onTransactionChanged: () {},
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : Column(
        children: [
          _buildProfileHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Card(
                color: Theme.of(context).cardColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: AppLocalizations.of(context).translate('editProfile'),
                      onTap: () {
                        // Navigate to edit profile
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      title: AppLocalizations.of(context).translate('notifications'),
                      onTap: () {
                        // Navigate to notifications
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.language,
                      title: AppLocalizations.of(context).translate('language'),
                      onTap: () {
                        _showLanguageDialog();
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.security,
                      title: AppLocalizations.of(context).translate('security'),
                      onTap: () {
                        // Navigate to security settings
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: AppLocalizations.of(context).translate('helpSupport'),
                      onTap: () {
                        // Navigate to help
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.info_outline,
                      title: AppLocalizations.of(context).translate('about'),
                      onTap: () {
                        // Navigate to about
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: AppLocalizations.of(context).translate('logout'),
                      iconColor: Colors.red,
                      onTap: _logout,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}