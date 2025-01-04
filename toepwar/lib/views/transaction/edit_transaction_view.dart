import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../helpers/voice_transaction_handler.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../utils/api_constants.dart';

class EditTransactionView extends StatefulWidget {
  final String token;
  final Transaction transaction;
  final VoidCallback onTransactionChanged;

  EditTransactionView({
    required this.token,
    required this.transaction,
    required this.onTransactionChanged,
  });

  @override
  _EditTransactionViewState createState() => _EditTransactionViewState();
}

class _EditTransactionViewState extends State<EditTransactionView> {
  late final TransactionController _transactionController;
  late final VoiceTransactionHandler _voiceHandler;
  late final TextEditingController _amountController;
  late String _selectedType;
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _transactionController = TransactionController(token: widget.token);
    _voiceHandler = VoiceTransactionHandler(transactionController: _transactionController);
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _selectedType = widget.transaction.type;
    _selectedDate = widget.transaction.date;

    final categoriesMap = ApiConstants.nestedTransactionCategories[_selectedType]!;
    _selectedMainCategory = categoriesMap.keys.firstWhere(
            (mainCategory) => categoriesMap[mainCategory]!.contains(widget.transaction.category),
        orElse: () => categoriesMap.keys.first
    );
    _selectedSubCategory = widget.transaction.category;
  }

  Widget _buildQuickInputCard() {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Update',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            _buildVoiceInputButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceInputButton() {
    return Material(
      color: _isListening ? Colors.red.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isListening ? null : _startVoiceInput,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Colors.purple,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                _isListening ? 'Listening...' : 'Voice Input',
                style: TextStyle(
                  color: _isListening ? Colors.red : Colors.purple,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    label: 'Income',
                    isSelected: _selectedType == 'income',
                    onTap: () => setState(() => _selectedType = 'income'),
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    label: 'Expense',
                    isSelected: _selectedType == 'expense',
                    onTap: () => setState(() => _selectedType = 'expense'),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: isSelected ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionForm() {
    final categoriesMap = ApiConstants.nestedTransactionCategories[_selectedType]!;

    if (!categoriesMap.containsKey(_selectedMainCategory)) {
      _selectedMainCategory = categoriesMap.keys.first;
    }

    if (_selectedMainCategory != null &&
        (!categoriesMap[_selectedMainCategory]!.contains(_selectedSubCategory))) {
      _selectedSubCategory = categoriesMap[_selectedMainCategory]!.first;
    }

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMainCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: categoriesMap.keys.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMainCategory = value;
                    _selectedSubCategory = categoriesMap[value]!.first;
                  });
                }
              },
            ),
            SizedBox(height: 16),
            if (_selectedMainCategory != null)
              DropdownButtonFormField<String>(
                value: _selectedSubCategory,
                decoration: InputDecoration(
                  labelText: 'Subcategory',
                  prefixIcon: Icon(Icons.subject),
                ),
                items: categoriesMap[_selectedMainCategory]!.map((subcategory) {
                  return DropdownMenuItem<String>(
                    value: subcategory,
                    child: Text(subcategory),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSubCategory = value;
                    });
                  }
                },
              ),
            SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceGuide() {
    return Card(
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(Icons.help_outline),
        title: Text('Voice Input Guide'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sentence Structure:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '[Amount] [Currency] + [Category] + [Date]',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
                Divider(height: 24),
                Text(
                  'Example Phrases:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _buildExamplePhrase('💰 "1000 dollars salary January 15"'),
                _buildExamplePhrase('🛒 "50 dollars groceries yesterday"'),
                _buildExamplePhrase('🚗 "30 dollars taxi 3 days ago"'),
                _buildExamplePhrase('🍽️ "100 dollars dining out today"'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplePhrase(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _startVoiceInput() async {
    try {
      setState(() => _isListening = true);

      final result = await _voiceHandler.processVoiceInput(context);

      if (result != null) {
        setState(() {
          _selectedType = result['type'];
          _amountController.text = result['amount'].toString();

          if (result['date'] != null) {
            _selectedDate = result['date'];
          }

          final categoriesMap = ApiConstants.nestedTransactionCategories[_selectedType]!;
          for (var mainCategory in categoriesMap.keys) {
            if (categoriesMap[mainCategory]!.contains(result['category'])) {
              _selectedMainCategory = mainCategory;
              _selectedSubCategory = result['category'];
              break;
            }
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not understand voice input. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing voice input: $e')),
      );
    } finally {
      setState(() => _isListening = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _updateTransaction() async {
    if (_amountController.text.isEmpty || _selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _transactionController.editTransaction(
        id: widget.transaction.id,
        type: _selectedType,
        amount: double.parse(_amountController.text),
        category: _selectedSubCategory!,
        date: _selectedDate,
      );
      widget.onTransactionChanged();
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Edit Transaction',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQuickInputCard(),
              SizedBox(height: 16),
              _buildVoiceGuide(),
              SizedBox(height: 16),
              _buildTransactionTypeSelector(),
              SizedBox(height: 16),
              _buildTransactionForm(),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateTransaction,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Update Transaction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}