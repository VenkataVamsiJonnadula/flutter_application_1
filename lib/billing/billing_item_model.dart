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
  double get grandTotal => double.parse((taxableValue + cgstAmount + sgstAmount).toStringAsFixed(2));

  /// Factory constructor for backward calculation from Total Paid Amount (inclusive of 3% GST)
  /// Automatically balances via Making Charges (if paid > base cost) or Discount (if paid < base cost)
  factory BillItem.fromTotalPaid({
    required int slNo,
    required DateTime date,
    required String customerId,
    required String description,
    required String hsnSac,
    required int pcs,
    required double grossWt,
    required double stoneWt,
    required double metalRate,
    required double stoneValue,
    required double totalPaidAmount,
    double discAmt = 0.0,
  }) {
    // 1. Separate 3% GST from total paid amount
    final double rawGst = totalPaidAmount * (gstPercentage / (100 + gstPercentage));
    final double halfGst = double.parse((rawGst / 2).toStringAsFixed(2));
    final double totalGst = halfGst * 2;

    // 2. Target Taxable Base Value before GST
    final double targetTaxable = double.parse((totalPaidAmount - totalGst).toStringAsFixed(2));

    // 3. Net Weight and Base Metal Value
    final double calculatedNetWt = double.parse((grossWt - stoneWt).toStringAsFixed(3));
    final double calculatedMetalValue = double.parse((calculatedNetWt * metalRate).toStringAsFixed(2));

    // 4. Base cost without making charges: Metal Value + Stone Value
    final double baseCost = calculatedMetalValue + stoneValue;

    double calculatedVa = 0.0;
    double calculatedDisc = discAmt;

    if (targetTaxable >= baseCost) {
      // Paid price is higher than base metal + stone cost: Add Making Charges (VA)
      calculatedVa = double.parse((targetTaxable - baseCost).toStringAsFixed(2));
      calculatedDisc = 0.0;
    } else {
      // Paid price is lower than base metal + stone cost: Set Making Charges to 0 and add Discount
      calculatedVa = 0.0;
      calculatedDisc = double.parse((baseCost - targetTaxable).toStringAsFixed(2));
    }

    return BillItem(
      slNo: slNo,
      date: date,
      customerId: customerId,
      description: description,
      hsnSac: hsnSac,
      pcs: pcs,
      grossWt: grossWt,
      stoneWt: stoneWt,
      metalRate: metalRate,
      va: calculatedVa,
      stoneValue: stoneValue,
      discAmt: calculatedDisc,
    );
  }
}
