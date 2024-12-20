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
    final categoriesMap =
    ApiConstants.nestedTransactionCategories[_selectedType]!;

    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isListening ? null : _startVoiceInput,
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              label: Text(_isListening ? 'Listening...' : 'Add by Voice'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
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
                  // Reset categories when type changes
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
                    child: Text(mainCategory)
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMainCategory = value;
                  // Reset subcategory to first in the new main category
                  _selectedSubCategory =
                      categoriesMap[_selectedMainCategory]!.first;
                });
              },
            ),
            SizedBox(height: 16),

            // Subcategory Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSubCategory,
              decoration: InputDecoration(
                labelText: 'Subcategory',
                border: OutlineInputBorder(),
              ),
              items: categoriesMap[_selectedMainCategory]!.map((subCategory) {
                return DropdownMenuItem(
                    value: subCategory,
                    child: Text(subCategory)
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
            ),
          ],
        ),
      ),
    );
  }
}
