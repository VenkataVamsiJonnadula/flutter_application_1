import 'billing_item_model.dart';

class Bill {
  final int slNo;
  final String invoiceNumber;
  final DateTime date;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final List<BillItem> items;
  final bool isOneTime;

  Bill({
    required this.slNo,
    required this.invoiceNumber,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    this.isOneTime = false,
  });

  // --- AUTOMATICALLY CALCULATED GETTERS ---

  // Total pieces in the bill
  int get pcs => items.fold(0, (sum, item) => sum + item.pcs);

  // Total gross weight in the bill
  double get grossWt => double.parse(
        items.fold(0.0, (sum, item) => sum + item.grossWt).toStringAsFixed(3),
      );

  // Total net weight in the bill
  double get netWt => double.parse(
        items.fold(0.0, (sum, item) => sum + item.netWt).toStringAsFixed(3),
      );

  // Total discount at bill level is the sum of discounts of all items
  double get discAmt => double.parse(
        items.fold(0.0, (sum, item) => sum + item.discAmt).toStringAsFixed(2),
      );

  // Total value is the sum of total values of all items
  double get totalValue => double.parse(
        items.fold(0.0, (sum, item) => sum + item.totalValue).toStringAsFixed(2),
      );

  // Taxable value is the sum of taxable values of all items
  double get taxableValue => double.parse(
        items.fold(0.0, (sum, item) => sum + item.taxableValue).toStringAsFixed(2),
      );

  // Dynamic description summarizing all items
  String get description {
    if (items.isEmpty) return 'No Items';
    if (items.length == 1) return items.first.description;
    
    // Create a unique, comma-separated list of item descriptions
    final descriptions = items.map((item) => item.description).toSet().toList();
    return '${items.length} items (${descriptions.join(', ')})';
  }

  // Getters for tax calculations (using gstPercentage from billing_item_model.dart)
  double get cgstAmount => double.parse(
        ((taxableValue * (gstPercentage / 2)) / 100).toStringAsFixed(2),
      );

  double get sgstAmount => double.parse(
        ((taxableValue * (gstPercentage / 2)) / 100).toStringAsFixed(2),
      );

  double get igstAmount => double.parse(
        ((taxableValue * gstPercentage) / 100).toStringAsFixed(2),
      );

  // Final bill value inclusive of GST and all item totals
  double get grandTotal => double.parse(
        (taxableValue + cgstAmount + sgstAmount).toStringAsFixed(2),
      );
}
