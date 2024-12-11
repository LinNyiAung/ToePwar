import 'package:flutter/material.dart';
import 'package:toepwar/views/auth/login_view.dart';
import 'package:toepwar/views/charts/income_structure_view.dart';
import 'package:toepwar/views/dashboard/dashboard_view.dart';
import 'package:toepwar/views/profile/profile_view.dart'; // Import profile view
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../utils/api_constants.dart';
import '../../charts/expense_structure_view.dart';
import '../../goals/goals_view.dart';
import '../../transaction/transaction_history_view.dart';


class DrawerWidget extends StatefulWidget {
  final String token;
  final VoidCallback onTransactionChanged;

  DrawerWidget({
    required this.token,
    required this.onTransactionChanged,
  });

  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  late String username;
  late String email;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 150,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          // Display user info under "Menu"
          isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Column(
            children: [
              ListTile(
                title: Text(username),
                subtitle: Text(email),
                leading: Icon(Icons.person),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileView(
                        token: widget.token,
                      ),
                    ),
                  );
                },
              ),
              Divider(),
            ],
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardView(
                    token: widget.token,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Transaction History'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionHistoryView(
                    token: widget.token,
                    onTransactionChanged: widget.onTransactionChanged,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('Expense Charts'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpenseStructureView(token: widget.token,),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('Income Charts'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IncomeStructureView(token: widget.token,),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.savings),
            title: Text('Saving Goals'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoalsView(token: widget.token),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              // Add your logout functionality here
              Navigator.pop(context); // Close the drawer
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
    );
  }
}
