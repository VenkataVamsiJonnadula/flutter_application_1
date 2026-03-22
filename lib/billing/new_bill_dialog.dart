import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'billing_item_model.dart';

class NewBillDialog extends StatefulWidget {
  final int nextSlNo;
  const NewBillDialog({super.key, required this.nextSlNo});

  @override
  State<NewBillDialog> createState() => _NewBillDialogState();
}

class _NewBillDialogState extends State<NewBillDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _descCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();
  final _pcsCtrl = TextEditingController();
  final _grossWtCtrl = TextEditingController();
  final _stoneWtCtrl = TextEditingController();
  final _netWtCtrl = TextEditingController();
  final _metalRateCtrl = TextEditingController();
  final _metalValueCtrl = TextEditingController();
  final _vaCtrl = TextEditingController();
  final _stoneValueCtrl = TextEditingController();
  final _totalValueCtrl = TextEditingController();
  final _discAmtCtrl = TextEditingController();
  final _taxableValueCtrl = TextEditingController();

  @override
  void dispose() {
    _descCtrl.dispose();
    _hsnCtrl.dispose();
    _pcsCtrl.dispose();
    _grossWtCtrl.dispose();
    _stoneWtCtrl.dispose();
    _netWtCtrl.dispose();
    _metalRateCtrl.dispose();
    _metalValueCtrl.dispose();
    _vaCtrl.dispose();
    _stoneValueCtrl.dispose();
    _totalValueCtrl.dispose();
    _discAmtCtrl.dispose();
    _taxableValueCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newItem = BillItem(
        slNo: widget.nextSlNo,
        date: DateTime.now(), // Real-time timestamp generated when bill item created exactly as requested
        description: _descCtrl.text.trim(),
        hsnSac: _hsnCtrl.text.trim(),
        pcs: int.tryParse(_pcsCtrl.text) ?? 1,
        grossWt: double.tryParse(_grossWtCtrl.text) ?? 0.0,
        stoneWt: double.tryParse(_stoneWtCtrl.text) ?? 0.0,
        netWt: double.tryParse(_netWtCtrl.text) ?? 0.0,
        metalRate: double.tryParse(_metalRateCtrl.text) ?? 0.0,
        metalValue: double.tryParse(_metalValueCtrl.text) ?? 0.0,
        va: double.tryParse(_vaCtrl.text) ?? 0.0,
        stoneValue: double.tryParse(_stoneValueCtrl.text) ?? 0.0,
        totalValue: double.tryParse(_totalValueCtrl.text) ?? 0.0,
        discAmt: double.tryParse(_discAmtCtrl.text) ?? 0.0,
        taxableValue: double.tryParse(_taxableValueCtrl.text) ?? 0.0,
      );
      Navigator.of(context).pop(newItem);
    }
  }

  TextInputFormatter _decimalFormatter() {
    return FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}'));
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, bool isDecimal = false, bool isInt = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF03045E), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: [
          if (isInt) FilteringTextInputFormatter.digitsOnly,
          if (isDecimal) _decimalFormatter(),
        ],
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Field Required';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mobile first responsiveness logic inside Dialog
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600 ? screenWidth * 0.95 : 550.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      elevation: 5,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
            // Dark Header matching App Theme
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF03045E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'New Sales Bill Item',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            // Form body with strict scroll padding
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField('Description of Goods', _descCtrl),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('HSN/SAC', _hsnCtrl)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('PCS', _pcsCtrl, isNumber: true, isInt: true)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Gross Wt.', _grossWtCtrl, isNumber: true, isDecimal: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Stone Wt.', _stoneWtCtrl, isNumber: true, isDecimal: true)),
                        ]
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Net Wt.', _netWtCtrl, isNumber: true, isDecimal: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Metal Rate', _metalRateCtrl, isNumber: true, isDecimal: true)),
                        ]
                      ),
                      _buildTextField('Metal Value', _metalValueCtrl, isNumber: true, isDecimal: true),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('VA.', _vaCtrl, isNumber: true, isDecimal: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Stone Value', _stoneValueCtrl, isNumber: true, isDecimal: true)),
                        ]
                      ),
                      _buildTextField('Total Value', _totalValueCtrl, isNumber: true, isDecimal: true),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Disc Amt.', _discAmtCtrl, isNumber: true, isDecimal: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Taxable Value', _taxableValueCtrl, isNumber: true, isDecimal: true)),
                        ]
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Persistent Actions Bottom Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 16,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade700, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check),
                    label: const Text('Submit Bill Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
