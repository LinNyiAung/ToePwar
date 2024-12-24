import 'package:flutter/material.dart';
import 'package:toepwar/views/ai/budget_plan_view.dart';
import 'package:toepwar/views/auth/login_view.dart';
import 'package:toepwar/views/charts/income_structure_view.dart';
import 'package:toepwar/views/dashboard/dashboard_view.dart';
import 'package:toepwar/views/profile/profile_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../controllers/auth_controller.dart';
import '../../../utils/api_constants.dart';
import '../../ai/financial_forecast_view.dart';
import '../../charts/expense_structure_view.dart';
import '../../goals/goals_view.dart';
import '../../reports/financial_report_view.dart';
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
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/profile'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
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
    } catch (e) {
      setState(() {
        errorMessage = 'Network error occurred';
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthController().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginView()),
          (route) => false,
    );
  }

  Widget _buildDrawerHeader() {
    return SizedBox(
      width: 400,
      child: DrawerHeader(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,

        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 35,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 10),
            if (!isLoading && errorMessage.isEmpty) ...[
              Text(
                username,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DashboardView(token: widget.token),
                    ),
                  ),
                ),
                Divider(),
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Text(
                    'Transactions',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: 'Transaction History',
                  onTap: () {
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
                Divider(),
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Text(
                    'Analytics',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.pie_chart,
                  title: 'Expense Analysis',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpenseStructureView(token: widget.token),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.trending_up,
                  title: 'Income Analysis',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IncomeStructureView(token: widget.token),
                    ),
                  ),
                ),
                Divider(),
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Text(
                    'Planning',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.savings,
                  title: 'Saving Goals',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GoalsView(token: widget.token),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.auto_graph,
                  title: 'AI Forecasting',
                  iconColor: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FinancialForecastView(token: widget.token),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.psychology,
                  title: 'AI Budget Plan',
                  iconColor: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BudgetPlanView(token: widget.token),
                    ),
                  ),
                ),
                Divider(),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileView(token: widget.token),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  iconColor: Colors.red,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}