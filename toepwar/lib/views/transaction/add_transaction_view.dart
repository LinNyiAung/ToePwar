import 'package:flutter/material.dart';
import '../../controllers/transaction_controller.dart';
import '../../helpers/voice_transaction_handler.dart';
import '../../utils/api_constants.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AddTransactionView extends StatefulWidget {
  final String token;
  final VoidCallback onTransactionChanged;

  AddTransactionView({required this.token, required this.onTransactionChanged,});

  @override
  _AddTransactionViewState createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  late final TransactionController _transactionController;
  late final VoiceTransactionHandler _voiceHandler;
  final _amountController = TextEditingController();
  String _selectedType = 'income';
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  bool _isLoading = false;
  bool _isListening = false;
  bool _showVoiceGuide = false;

  @override
  void initState() {
    super.initState();
    _transactionController = TransactionController(token: widget.token);
    _voiceHandler = VoiceTransactionHandler(transactionController: _transactionController);
    _selectedMainCategory =
        ApiConstants.nestedTransactionCategories[_selectedType]!.keys.first;
    _selectedSubCategory =
        ApiConstants.nestedTransactionCategories[_selectedType]![_selectedMainCategory]!.first;
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
                  '[Amount] [Currency] + [Category]',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
                Divider(height: 24),
                Text(
                  'Example Phrases:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _buildExamplePhrase('💰 "1000 dollars salary"'),
                _buildExamplePhrase('🛒 "50 dollars groceries"'),
                _buildExamplePhrase('🚗 "30 dollars taxi"'),
                _buildExamplePhrase('🍽️ "100 dollars dinning out"'),
                SizedBox(height: 16),
                Text(
                  'Tips:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _buildTip('• Speak clearly and at a normal pace'),
                _buildTip('• Include the amount and category'),
                _buildTip('• Wait for the blue microphone indicator'),
                _buildTip('• You can edit details after voice input'),
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

  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
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

  Future<void> _addTransaction() async {
    if (_amountController.text.isEmpty ||
        _selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _transactionController.addTransaction(
        type: _selectedType,
        amount: double.parse(_amountController.text),
        category: _selectedSubCategory!, // Store the subcategory
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
    final categoriesMap = ApiConstants.nestedTransactionCategories[_selectedType]!;

    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
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
                        label: Text(_isListening ? 'Listening...' : 'Add by Voice'),
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
                'Or Enter Details Manually:',
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
                    _selectedSubCategory =
                        categoriesMap[_selectedMainCategory]!.first;
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
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _addTransaction,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Add Transaction'),
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
