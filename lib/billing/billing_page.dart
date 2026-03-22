import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'billing_item_model.dart';
import 'new_bill_dialog.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  DateTime _billDate = DateTime.now();
  // ignore: unused_field
  String _customerName = "";
  
  late List<BillItem> _items;

  final _horizontalScrollController = ScrollController();
  bool _isHoveringTable = false;

  @override
  void initState() {
    super.initState();
    // Generate dates dynamically in the past for the mock layout
    final now = DateTime.now();
    _items = [
      BillItem(
        slNo: 1,
        date: now.subtract(const Duration(days: 435, hours: 2, minutes: 12)),
        description: "Gold Coin",
        hsnSac: "71189",
        pcs: 1,
        grossWt: 15.000,
        stoneWt: 0.000,
        netWt: 15.000,
        metalRate: 5800.00,
        metalValue: 87000.00,
        va: 0.00,
        stoneValue: 0.00,
        totalValue: 87000.00,
        discAmt: 0.00,
        taxableValue: 87000.00,
      ),
      BillItem(
        slNo: 2,
        date: now.subtract(const Duration(days: 215, hours: 8, minutes: 30)),
        description: "Silver Coin",
        hsnSac: "71189",
        pcs: 3,
        grossWt: 50.000,
        stoneWt: 0.000,
        netWt: 50.000,
        metalRate: 100.00,
        metalValue: 5000.00,
        va: 0.00,
        stoneValue: 0.00,
        totalValue: 5000.00,
        discAmt: 0.00,
        taxableValue: 5000.00,
      ),
      BillItem(
        slNo: 3,
        date: now.subtract(const Duration(days: 35, hours: 16, minutes: 45)),
        description: "Silver Chain",
        hsnSac: "71189",
        pcs: 1,
        grossWt: 20.000,
        stoneWt: 0.000,
        netWt: 20.000,
        metalRate: 100.00,
        metalValue: 2000.00,
        va: 0.00,
        stoneValue: 0.00,
        totalValue: 2000.00,
        discAmt: 0.00,
        taxableValue: 2000.00,
      ),
      BillItem(
        slNo: 4,
        date: now.subtract(const Duration(days: 5, hours: 22, minutes: 10)),
        description: "Gold Ring",
        hsnSac: "71189",
        pcs: 1,
        grossWt: 3.446,
        stoneWt: 0.080,
        netWt: 3.366,
        metalRate: 6500.00,
        metalValue: 21879.00,
        va: 2200.00,
        stoneValue: 400.00,
        totalValue: 24479.00,
        discAmt: 0.00,
        taxableValue: 24479.00,
      ),
      BillItem(
        slNo: 5,
        date: now.subtract(const Duration(days: 1, hours: 5, minutes: 59)),
        description: "Gold Necklace",
        hsnSac: "71189",
        pcs: 1,
        grossWt: 20.558,
        stoneWt: 0.200,
        netWt: 20.358,
        metalRate: 6500.00,
        metalValue: 132327.00,
        va: 13200.00,
        stoneValue: 600.00,
        totalValue: 146127.00,
        discAmt: 127.00,
        taxableValue: 146000.00,
      ),
    ];
    // Initially sort default historic randomly placed items using 'latest first' mechanism 
    _items.sort((a, b) => b.date.compareTo(a.date));
  }

  void _openNewBillDialog() async {
    final BillItem? newItem = await showDialog<BillItem>(
      context: context,
      builder: (context) => NewBillDialog(
        nextSlNo: _items.length + 1,
      ),
    );

    if (newItem != null) {
      setState(() {
        _items.add(newItem);
        // Ensure strictly sorted order dynamically applied after user submission
        _items.sort((a, b) => b.date.compareTo(a.date));
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill item tracked successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFF0077B6),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _billDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _billDate) {
      setState(() {
        _billDate = picked;
      });
    }
  }

  String _formatSimpleDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: _isHoveringTable ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section: Bill Date and Title
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 16,
              children: [
                const Text(
                  'Manage Sales & Bills',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF03045E),
                  ),
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                     const Text(
                      'Bill Config Date: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _formatSimpleDate(_billDate),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Customer Details / Form Action
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Customer Name / Mobile Lookup',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) => _customerName = val,
                  ),
                ),
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  onPressed: _openNewBillDialog,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('New Sales Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    backgroundColor: const Color(0xFF03045E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Items Table Enclosed by Hover Region
            MouseRegion(
              onEnter: (_) => setState(() => _isHoveringTable = true),
              onExit: (_) => setState(() => _isHoveringTable = false),
              child: Listener(
                onPointerSignal: (PointerSignalEvent event) {
                  if (event is PointerScrollEvent && _isHoveringTable) {
                    final double scrollDelta = event.scrollDelta.dy != 0 ? event.scrollDelta.dy : event.scrollDelta.dx;
                    if (_horizontalScrollController.hasClients) {
                      final newOffset = _horizontalScrollController.offset + scrollDelta;
                      _horizontalScrollController.position.jumpTo(
                        newOffset.clamp(
                          _horizontalScrollController.position.minScrollExtent,
                          _horizontalScrollController.position.maxScrollExtent,
                        ),
                      );
                    }
                  }
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFF90E0EF).withValues(alpha: 0.3)),
                          showBottomBorder: true,
                          columns: const [
                            DataColumn(label: Text('SlNo.', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Bill generated Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Description of Goods', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('HSN/SAC', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: NumericText('PCS')),
                            DataColumn(label: NumericText('Gross Wt.')),
                            DataColumn(label: NumericText('Stone Wt.')),
                            DataColumn(label: NumericText('Net Wt.')),
                            DataColumn(label: NumericText('Metal Rate')),
                            DataColumn(label: NumericText('Metal Value')),
                            DataColumn(label: NumericText('VA.')),
                            DataColumn(label: NumericText('Stone Value')),
                            DataColumn(label: NumericText('Total Value')),
                            DataColumn(label: NumericText('Disc Amt.')),
                            DataColumn(label: NumericText('Taxable Value')),
                          ],
                          rows: _items.map((item) {
                            return DataRow(
                              cells: [
                                DataCell(Text(item.slNo.toString())),
                                DataCell(
                                  Text(
                                    DateFormat('dd/MM/yyyy hh:mm a').format(item.date),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0077B6)),
                                  ),
                                ),
                                DataCell(Text(item.description, style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Text(item.hsnSac)),
                                DataCell(Text(item.pcs.toString())),
                                DataCell(Text(item.grossWt.toStringAsFixed(3))),
                                DataCell(Text(item.stoneWt.toStringAsFixed(3))),
                                DataCell(Text(item.netWt.toStringAsFixed(3))),
                                DataCell(Text(item.metalRate.toStringAsFixed(2))),
                                DataCell(Text(item.metalValue.toStringAsFixed(2))),
                                DataCell(Text(item.va.toStringAsFixed(2))),
                                DataCell(Text(item.stoneValue.toStringAsFixed(2))),
                                DataCell(Text(item.totalValue.toStringAsFixed(2))),
                                DataCell(Text(item.discAmt.toStringAsFixed(2))),
                                DataCell(Text(item.taxableValue.toStringAsFixed(2))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 16,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print),
                  label: const Text('Export/Print A5 Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    side: const BorderSide(color: Color(0xFF03045E), width: 2),
                    foregroundColor: const Color(0xFF03045E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save),
                  label: const Text('Save Analytics Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    backgroundColor: const Color(0xFFFFD700), // Gold
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class NumericText extends StatelessWidget {
  final String text;
  const NumericText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold));
  }
}
