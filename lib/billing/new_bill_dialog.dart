import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'billing_item_model.dart';

class NewBillDialog extends StatefulWidget {
  final int nextSlNo;
  final String customerId;
  const NewBillDialog({super.key, required this.nextSlNo, required this.customerId});

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

  void _recalculate() {
    final double gw = double.tryParse(_grossWtCtrl.text) ?? 0.0;
    final double sw = double.tryParse(_stoneWtCtrl.text) ?? 0.0;
    final double mr = double.tryParse(_metalRateCtrl.text) ?? 0.0;
    final double va = double.tryParse(_vaCtrl.text) ?? 0.0;
    
    // Excel Rule 5: Stone value field drops to 0 and becomes internally readOnly if StoneWT < 1.0 logically
    final bool stoneValueEnabled = sw >= 1.0;
    if (!stoneValueEnabled) {
      if (_stoneValueCtrl.text != '0.00' && _stoneValueCtrl.text != '0') {
        _stoneValueCtrl.text = "0.00";
      }
    }
    final double sv = double.tryParse(_stoneValueCtrl.text) ?? 0.0;

    // Excel Rule 1: Net Weight = Gross Wt - Stone Wt
    final double nw = gw - sw;
    final validNw = nw < 0 ? 0.0 : nw;
    if (_netWtCtrl.text != validNw.toStringAsFixed(3)) {
       _netWtCtrl.text = validNw.toStringAsFixed(3);
    }

    // Excel Rule 2: Metal Value = Net Wt * Metal Rate
    final double mv = validNw * mr;
    if (_metalValueCtrl.text != mv.toStringAsFixed(2)) {
       _metalValueCtrl.text = mv.toStringAsFixed(2);
    }

    // Excel Rule 3: Total Value = Metal Value + VA + Stone Value
    final double tv = mv + va + sv;
    if (_totalValueCtrl.text != tv.toStringAsFixed(2)) {
       _totalValueCtrl.text = tv.toStringAsFixed(2);
    }

    // Excel Rule 4: Taxable Value = Total Value - Disc Amt
    final double da = double.tryParse(_discAmtCtrl.text) ?? 0.0;
    final double taxv = tv - da;
    final validTaxv = taxv < 0 ? 0.0 : taxv;
    if (_taxableValueCtrl.text != validTaxv.toStringAsFixed(2)) {
       _taxableValueCtrl.text = validTaxv.toStringAsFixed(2);
    }
  }

  bool get _isFormValid {
    // Description validation checks block submit button
    if (_descCtrl.text.trim().isEmpty || !RegExp(r'^[\w\s\-.,]+$').hasMatch(_descCtrl.text)) {
      return false;
    }
    
    // Numeric field validation checks block submit button
    final numberControllers = [
      _hsnCtrl, _pcsCtrl, _grossWtCtrl, _stoneWtCtrl, _netWtCtrl,
      _metalRateCtrl, _metalValueCtrl, _vaCtrl, _stoneValueCtrl,
      _totalValueCtrl, _discAmtCtrl, _taxableValueCtrl
    ];
    for (var c in numberControllers) {
      if (c.text.trim().isEmpty) return false;
      if (double.tryParse(c.text) == null) return false;
    }

    // Excel Rule 6: Discount Amount cannot be greater than Total Value structurally
    final double da = double.tryParse(_discAmtCtrl.text) ?? 0.0;
    final double tv = double.tryParse(_totalValueCtrl.text) ?? 0.0;
    if (da > tv) return false;

    return true;
  }

  void _submit() {
    if (_isFormValid) {
      final newItem = BillItem(
        slNo: widget.nextSlNo,
        date: DateTime.now(),
        customerId: widget.customerId.isEmpty ? 'C9999' : widget.customerId,
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

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    {
      bool isNumber = false, 
      bool isDecimal = false, 
      bool isInt = false,
      bool isDescription = false,
      bool readOnly = false,
    }
  ) {
    return _DirtyTextField(
      label: label,
      controller: controller,
      isNumber: isNumber,
      isDecimal: isDecimal,
      isInt: isInt,
      isDescription: isDescription,
      readOnly: readOnly,
      onChanged: () {
        _recalculate();
        setState(() {});
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label required';
        }
        if (isDescription) {
          if (!RegExp(r'^[\w\s\-.,]+$').hasMatch(value)) {
            return 'No specific special chars allowed';
          }
        }
        if (isNumber || isDecimal || isInt || label == 'HSN/SAC') {
           if (double.tryParse(value) == null) {
              return 'Valid number required';
           }
        }
        if (label == 'Disc Amt.') {
          final double da = double.tryParse(value) ?? 0.0;
          final double tv = double.tryParse(_totalValueCtrl.text) ?? 0.0;
          if (da > tv) {
            return 'Cannot exceed Total Value';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600 ? screenWidth * 0.95 : 550.0;

    final double sw = double.tryParse(_stoneWtCtrl.text) ?? 0.0;
    final bool stoneValueEnabled = sw >= 1.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      elevation: 5,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
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
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField('Description of Goods', _descCtrl, isDescription: true),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTextField('HSN/SAC', _hsnCtrl, isNumber: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('PCS', _pcsCtrl, isNumber: true, isInt: true)),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTextField('Gross Wt.', _grossWtCtrl, isNumber: true, isDecimal: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Stone Wt.', _stoneWtCtrl, isNumber: true, isDecimal: true)),
                        ]
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTextField('Net Wt.', _netWtCtrl, isNumber: true, isDecimal: true, readOnly: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Metal Rate', _metalRateCtrl, isNumber: true, isDecimal: true)),
                        ]
                      ),
                      _buildTextField('Metal Value', _metalValueCtrl, isNumber: true, isDecimal: true, readOnly: true),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTextField('VA.', _vaCtrl, isNumber: true, isDecimal: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Stone Value', _stoneValueCtrl, isNumber: true, isDecimal: true, readOnly: !stoneValueEnabled)),
                        ]
                      ),
                      _buildTextField('Total Value', _totalValueCtrl, isNumber: true, isDecimal: true, readOnly: true),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTextField('Disc Amt.', _discAmtCtrl, isNumber: true, isDecimal: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Taxable Value', _taxableValueCtrl, isNumber: true, isDecimal: true, readOnly: true)),
                        ]
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                    onPressed: _isFormValid ? _submit : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Submit Bill Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      disabledBackgroundColor: Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
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

class _DirtyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumber;
  final bool isDecimal;
  final bool isInt;
  final bool isDescription;
  final bool readOnly;
  final VoidCallback onChanged;
  final String? Function(String?)? validator;

  const _DirtyTextField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.isNumber = false,
    this.isDecimal = false,
    this.isInt = false,
    this.isDescription = false,
    this.readOnly = false,
    this.validator,
  });

  @override
  State<_DirtyTextField> createState() => _DirtyTextFieldState();
}

class _DirtyTextFieldState extends State<_DirtyTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (!_isDirty) {
          setState(() {
            _isDirty = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  TextInputFormatter _decimalFormatter() {
    return FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}'));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        readOnly: widget.readOnly,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: widget.readOnly ? Colors.black54 : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: widget.readOnly ? Colors.grey : const Color(0xFF03045E), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: widget.readOnly ? Colors.grey.shade200 : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: widget.isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: [
          if (widget.isInt || widget.label == 'HSN/SAC') FilteringTextInputFormatter.digitsOnly,
          if (widget.isDecimal) _decimalFormatter(),
        ],
        onChanged: (val) {
          if (!_isDirty) {
            setState(() { _isDirty = true; });
          }
          widget.onChanged();
        },
        autovalidateMode: _isDirty ? AutovalidateMode.always : AutovalidateMode.disabled,
        validator: widget.validator,
      ),
    );
  }
}
