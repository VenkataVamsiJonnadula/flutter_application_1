import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/customer_provider.dart';
import 'customer_model.dart';
import '../data/mock_data.dart';

class CustomerProfilePage extends StatefulWidget {
  final Customer customer;
  final VoidCallback onBack;

  const CustomerProfilePage({super.key, required this.customer, required this.onBack});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customer.name);
    _phoneCtrl = TextEditingController(text: widget.customer.phone);
    _addressCtrl = TextEditingController(text: widget.customer.address);
    _emailCtrl = TextEditingController(text: widget.customer.email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final updated = Customer(
        id: widget.customer.id,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        customerSince: widget.customer.customerSince,
      );
      Provider.of<CustomerProvider>(context, listen: false).updateCustomer(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${updated.name} profile updated!'), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPhone = false, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: const Color(0xFF0077B6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF03045E), width: 2)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)] : [],
        validator: (value) {
          if (isOptional && (value == null || value.trim().isEmpty)) return null;
          if (value == null || value.trim().isEmpty) return '$label is required';
          if (isPhone && value.trim().length != 10) return 'Phone number must be exactly 10 digits';
          return null;
        },
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmall = screenWidth < 900;
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: isSmall 
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: screenWidth < 400 ? 20 : 24),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: screenWidth < 400 ? 11 : 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: TextStyle(fontSize: screenWidth < 400 ? 14 : 18, fontWeight: FontWeight.bold, color: const Color(0xFF03045E))),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF03045E))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerBills = sharedMockItems.where((b) =>
      (widget.customer.id.isNotEmpty && b.customerId == widget.customer.id) ||
      (b.customerName.trim().toLowerCase() == widget.customer.name.trim().toLowerCase())
    ).toList();
    customerBills.sort((a, b) => b.date.compareTo(a.date)); // Latest to oldest

    final totalSales = customerBills.length;
    final totalRevenue = customerBills.fold(0.0, (curr, next) => curr + next.grandTotal);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: widget.onBack),
        title: Row(
          children: [
            Text('Customers', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.chevron_right, color: Colors.grey, size: 20)),
            Expanded(child: Text(widget.customer.name, style: const TextStyle(color: Color(0xFF03045E), fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width < 600 ? 16 : 32,
          MediaQuery.of(context).size.width < 600 ? 16 : 32,
          MediaQuery.of(context).size.width < 600 ? 16 : 32,
          MediaQuery.of(context).size.width < 600 ? 100 : 32, // Extra bottom padding for floating nav
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Panel
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0077B6),
                  radius: 40,
                  child: Text(widget.customer.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.customer.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF03045E))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE8F4FA), borderRadius: BorderRadius.circular(6)), child: Text(widget.customer.id, style: const TextStyle(color: Color(0xFF0077B6), fontWeight: FontWeight.w700))),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(widget.customer.address, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Metrics Row
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMetricCard(context, 'Customer Since', DateFormat('MMM dd, yyyy').format(widget.customer.customerSince), Icons.event_available, Colors.purple),
                  SizedBox(width: MediaQuery.of(context).size.width < 600 ? 8 : 16),
                  _buildMetricCard(context, 'Total Invoices', totalSales.toString(), Icons.receipt_long, const Color(0xFF0077B6)),
                  SizedBox(width: MediaQuery.of(context).size.width < 600 ? 8 : 16),
                  _buildMetricCard(context, 'Total Revenue', currencyFormatter.format(totalRevenue), Icons.account_balance_wallet, Colors.teal),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Editor Settings Tab
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF03045E))),
                    const SizedBox(height: 24),
                    if (MediaQuery.of(context).size.width < 600) ...[
                      _buildTextField('Full Name', _nameCtrl, Icons.person),
                      _buildTextField('Phone Number', _phoneCtrl, Icons.phone, isPhone: true),
                      _buildTextField('Email Address', _emailCtrl, Icons.email_outlined, isOptional: true),
                      _buildTextField('Residential Address', _addressCtrl, Icons.location_on_outlined),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Full Name', _nameCtrl, Icons.person)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildTextField('Phone Number', _phoneCtrl, Icons.phone, isPhone: true)),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Email Address', _emailCtrl, Icons.email_outlined, isOptional: true)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildTextField('Residential Address', _addressCtrl, Icons.location_on_outlined)),
                        ],
                      ),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('Update Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0077B6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Invoice Tables
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: const Text('Sales History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF03045E))),
            ),
            const SizedBox(height: 16),
            if (customerBills.isEmpty)
               Container(
                 padding: const EdgeInsets.all(40),
                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                 alignment: Alignment.center,
                 child: Text('No invoice records found for this customer.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
               )
            else
               Container(
                 width: double.infinity,
                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                 child: ClipRRect(
                   borderRadius: BorderRadius.circular(16),
                   child: Material(
                     color: Colors.transparent,
                     child: LayoutBuilder(
                       builder: (context, constraints) {
                         return ScrollConfiguration(
                           behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
                           child: SingleChildScrollView(
                             scrollDirection: Axis.horizontal,
                             child: ConstrainedBox(
                               constraints: BoxConstraints(minWidth: constraints.maxWidth),
                               child: DataTable(
                                 headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                                 columns: const [
                                   DataColumn(label: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold))),
                                   DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                   DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                                   DataColumn(label: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold))),
                                 ],
                                 rows: customerBills.map((bill) => DataRow(
                                   cells: [
                                     DataCell(Text('INV-${bill.slNo.toString().padLeft(4, '0')}', style: const TextStyle(color: Color(0xFF0077B6), fontWeight: FontWeight.bold))),
                                     DataCell(Text(DateFormat('dd MMM yyyy').format(bill.date))),
                                     DataCell(Text(bill.description)),
                                     DataCell(Text(currencyFormatter.format(bill.grandTotal), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal))),
                                   ]
                                 )).toList(),
                               ),
                             ),
                           ),
                         );
                       }
                     ),
                   ),
                 ),
               ),
          ],
        ),
      ),
    );
  }
}


