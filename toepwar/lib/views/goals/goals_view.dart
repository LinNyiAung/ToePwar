import 'package:flutter/material.dart';
import '../../controllers/goal_controller.dart';
import '../../models/goal_model.dart';
import '../dashboard/widgets/drawer_widget.dart';


class GoalsView extends StatefulWidget {
  final String token;

  GoalsView({required this.token});

  @override
  _GoalsViewState createState() => _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView> {
  late final GoalController _goalController;
  late Future<List<Goal>> _goals;

  @override
  void initState() {
    super.initState();
    _goalController = GoalController(token: widget.token);
    _goals = _goalController.getGoals();
  }

  Future<void> _refreshGoals() async {
    setState(() {
      _goals = _goalController.getGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Saving Goals', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshGoals,
          ),
        ],
      ),
      drawer: DrawerWidget(  // Use the DrawerWidget here
        token: widget.token, onTransactionChanged: () {  },

      ),
      body: FutureBuilder<List<Goal>>(
        future: _goals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final goals = snapshot.data ?? [];

          if (goals.isEmpty) {
            return Center(child: Text('No saving goals yet'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _buildGoalCard(goal);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
  Widget _buildGoalCard(Goal goal) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Row(
                  children: [
                    if (goal.completed)
                      Icon(Icons.check_circle, color: Colors.green)
                    else
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showEditGoalDialog(goal),
                      ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmation(goal),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal.progress / 100,
              backgroundColor: Colors.grey[200],
              // Set a default color for incomplete goals
              color: goal.completed ? Colors.green : Theme.of(context).primaryColor,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${goal.currentAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${goal.progress.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: goal.completed ? Colors.green : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deadline: ${_formatDate(goal.deadline)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (goal.completed && goal.completionDate != null)
                  Text(
                    'Completed: ${_formatDate(goal.completionDate!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }


  Future<void> _showDeleteConfirmation(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _goalController.deleteGoal(goal.id);
        _refreshGoals();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Goal deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _showEditGoalDialog(Goal goal) async {
    final nameController = TextEditingController(text: goal.name);
    final amountController = TextEditingController(text: goal.targetAmount.toString());
    DateTime? selectedDate = goal.deadline;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Saving Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
                child: Text('Select Deadline'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  amountController.text.isEmpty ||
                  selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                await _goalController.updateGoal(
                  goalId: goal.id,
                  name: nameController.text,
                  targetAmount: double.parse(amountController.text),
                  deadline: selectedDate!,
                );
                Navigator.pop(context);
                _refreshGoals();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Goal updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddGoalDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Saving Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
                child: Text('Select Deadline'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  amountController.text.isEmpty ||
                  selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                await _goalController.addGoal(
                  name: nameController.text,
                  targetAmount: double.parse(amountController.text),
                  deadline: selectedDate!,
                );
                Navigator.pop(context);
                _refreshGoals();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}