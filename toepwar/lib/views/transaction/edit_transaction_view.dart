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
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );

    _selectedType = widget.transaction.type;
    _selectedDate = widget.transaction.date;

    final categoriesMap = ApiConstants.nestedTransactionCategories[_selectedType]!;
    _selectedMainCategory = categoriesMap.keys.firstWhere(
            (mainCategory) => categoriesMap[mainCategory]!.contains(widget.transaction.category),
        orElse: () => categoriesMap.keys.first
    );
    _selectedSubCategory = widget.transaction.category;
  }

  Future<void> _startVoiceInput() async {
    try {
      setState(() => _isListening = true);

      final result = await _voiceHandler.processVoiceInput(context);

      if (result != null) {
        setState(() {
          _selectedType = result['type'];
          _amountController.text = result['amount'].toString();

          // Update date if provided in voice input
          if (result['date'] != null) {
            _selectedDate = result['date'];
          }

          // Find main category for the subcategory
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


  Widget _buildVoiceGuide() {
    return Card(
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
                  '[Action] [Amount] [Currency] for/from [Category] on/from [Date]',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
                Divider(height: 24),
                Text(
                  'Example Phrases:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _buildExamplePhrase('💰 "Update to income 1000 dollars from salary on January 15"'),
                _buildExamplePhrase('🛒 "Change to 50 dollars for groceries from yesterday"'),
                _buildExamplePhrase('🚗 "Update expense to 30 dollars for taxi 3 days ago"'),
                _buildExamplePhrase('🍽️ "Make it 100 dollars for dining out on 3/15"'),
                SizedBox(height: 16),
                Text(
                  'Supported Date Formats:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _buildDateExample('• "yesterday", "today"'),
                _buildDateExample('• "3 days ago"'),
                _buildDateExample('• "January 15" or "Jan 15"'),
                _buildDateExample('• "3/15" (MM/DD format)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateExample(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
        ),
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

  @override
  Widget build(BuildContext context) {
    final categoriesMap = ApiConstants.nestedTransactionCategories[_selectedType]!;

    return Scaffold(
      appBar: AppBar(title: Text('Edit Transaction')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Voice Input Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isListening ? null : _startVoiceInput,
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                        label: Text(_isListening ? 'Listening...' : 'Update by Voice'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          backgroundColor: _isListening ? Colors.red : null,
                        ),
                      ),
                      if (_isListening)
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            'Listening... Speak now',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Voice Guide
              _buildVoiceGuide(),

              SizedBox(height: 16),

              // Manual Input Fields
              Text(
                'Or Edit Details Manually:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Transaction Type',
                  border: OutlineInputBorder(),
                ),
                items: ['income', 'expense'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _selectedMainCategory =
                        ApiConstants.nestedTransactionCategories[_selectedType]!.keys.first;
                    _selectedSubCategory =
                        ApiConstants.nestedTransactionCategories[_selectedType]![_selectedMainCategory]!.first;
                  });
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMainCategory,
                decoration: InputDecoration(
                  labelText: 'Main Category',
                  border: OutlineInputBorder(),
                ),
                items: categoriesMap.keys.map((mainCategory) {
                  return DropdownMenuItem(
                    value: mainCategory,
                    child: Text(mainCategory),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMainCategory = value;
                    _selectedSubCategory = categoriesMap[_selectedMainCategory]!.first;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSubCategory,
                decoration: InputDecoration(
                  labelText: 'Subcategory',
                  border: OutlineInputBorder(),
                ),
                items: categoriesMap[_selectedMainCategory]!.map((subCategory) {
                  return DropdownMenuItem(
                    value: subCategory,
                    child: Text(subCategory),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubCategory = value;
                  });
                },
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate),
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateTransaction,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Update Transaction'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}