import 'package:flutter/material.dart';
import 'package:toepwar/views/dashboard/dashboard_view.dart';

import '../../transaction/transaction_history_view.dart';


class DrawerWidget extends StatelessWidget {
  final String token;
  final VoidCallback onTransactionChanged;

  DrawerWidget({
    required this.token,
    required this.onTransactionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
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
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardView(
                    token: token,

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
                    token: token,
                    onTransactionChanged: onTransactionChanged,
                  ),
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
            },
          ),
        ],
      ),
    );
  }
}
