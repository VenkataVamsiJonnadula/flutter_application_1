import 'package:intl/intl.dart';

const double gstPercentage = 3.0; // e.g., 3.0 for 3%

class BillItem {
  final int slNo;
  final DateTime date;
  final String customerId;
  final String description;
  final String hsnSac;
  final int pcs;
  
  // Weights (Keep as double, but restricted to 3 decimal places for jewelry)
  final double grossWt;
  final double stoneWt;
  
  // Rates & Inputs
  final double metalRate;
  final double va;            // Value Addition / Making charges
  final double stoneValue;
  final double discAmt;       // Discount Amount

  BillItem({
    required this.slNo,
    required this.date,
    required this.customerId,
    required this.description,
    required this.hsnSac,
    required this.pcs,
    required this.grossWt,
    required this.stoneWt,
    required this.metalRate,
    required this.va,
    required this.stoneValue,
    required this.discAmt,
  });

  // --- AUTOMATICALLY CALCULATED GETTERS ---

  // Net Weight = Gross Weight - Stone Weight
  double get netWt => double.parse((grossWt - stoneWt).toStringAsFixed(3));

  // Metal Value = Net Weight * Metal Rate
  double get metalValue => double.parse((netWt * metalRate).toStringAsFixed(2));

  // Total Value = Metal Value + VA + Stone Value
  double get totalValue => double.parse((metalValue + va + stoneValue).toStringAsFixed(2));

  // Taxable Value = Total Value - Discount
  double get taxableValue => double.parse((totalValue - discAmt).toStringAsFixed(2));


  // --- HELPER METHODS FOR YOUR UI & PDF PRINTING ---
  
  // Returns string formatted currency (e.g., 1,500.50)
  String formatCurrency(double value) {
    return NumberFormat.currency(symbol: '', decimalDigits: 2).format(value);
  }

  // Getters inside BillItem to make PDF generation effortless:
  double get cgstAmount => double.parse(((taxableValue * (gstPercentage / 2)) / 100).toStringAsFixed(2));
  double get sgstAmount => double.parse(((taxableValue * (gstPercentage / 2)) / 100).toStringAsFixed(2));
  double get igstAmount => double.parse(((taxableValue * gstPercentage) / 100).toStringAsFixed(2));
}
