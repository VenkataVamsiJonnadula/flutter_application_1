import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/customer_provider.dart';
import '../customers/customer_model.dart';
import '../data/mock_data.dart';
import 'billing_item_model.dart';
import 'bill_model.dart';
import '../services/metal_rates_service.dart';

class CreateNewBillPage extends StatefulWidget {
  final int nextSlNo;
  const CreateNewBillPage({super.key, required this.nextSlNo});

  @override
  State<CreateNewBillPage> createState() => _CreateNewBillPageState();
}

class _CreateNewBillPageState extends State<CreateNewBillPage> {
  int _currentStep = 0;
  
  // Step 1: Customer State
  int _customerTypeTab = 0; // 0: Select Existing, 1: Create New, 2: One-time Customer
  Customer? _selectedCustomer;
  final _customerSearchCtrl = TextEditingController();
  String _customerSearchQuery = "";
  
  // Customer Forms (New / One-time)
  final _customerFormKey = GlobalKey<FormState>();
  final _custNameCtrl = TextEditingController();
  final _custPhoneCtrl = TextEditingController();
  final _custAddressCtrl = TextEditingController();
  
  // Step 2: Bill Items State
  final List<BillItem> _billItems = [];

  // Step 3: General State
  DateTime _billDate = DateTime.now();

  @override
  void dispose() {
    _customerSearchCtrl.dispose();
    _custNameCtrl.dispose();
    _custPhoneCtrl.dispose();
    _custAddressCtrl.dispose();
    super.dispose();
  }

  // --- GETTERS & METRIC CALCS ---
  double get _subtotalTaxable => _billItems.fold(0.0, (sum, item) => sum + item.taxableValue);
  double get _totalDiscount => _billItems.fold(0.0, (sum, item) => sum + item.discAmt);
  double get _grossTotal => _billItems.fold(0.0, (sum, item) => sum + item.totalValue);
  double get _cgst => _subtotalTaxable * 0.015;
  double get _sgst => _subtotalTaxable * 0.015;
  double get _grandTotal => _subtotalTaxable + _cgst + _sgst;

  String _formatSimpleDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _selectDate(BuildContext context) async {
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

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate customer selection
      if (_customerTypeTab == 0 && _selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an existing customer to proceed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      } else if (_customerTypeTab == 1) {
        if (!_customerFormKey.currentState!.validate()) {
          return;
        }
      }
    } else if (_currentStep == 1) {
      if (_billItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one item to the bill.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }
    
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitBill() {
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    String custId = '';
    String custName = '';
    String custPhone = '';
    String custAddress = '';
    bool isOneTime = false;

    if (_customerTypeTab == 0 && _selectedCustomer != null) {
      custId = _selectedCustomer!.id;
      custName = _selectedCustomer!.name;
      custPhone = _selectedCustomer!.phone;
      custAddress = _selectedCustomer!.address;
    } else if (_customerTypeTab == 1) {
      // Save new customer in provider
      final nextCustId = 'C${1000 + provider.customers.length + 1}';
      custId = nextCustId;
      custName = _custNameCtrl.text.trim();
      custPhone = _custPhoneCtrl.text.trim();
      custAddress = _custAddressCtrl.text.trim();
      
      provider.addCustomer(Customer(
        id: custId,
        name: custName,
        phone: custPhone,
        address: custAddress,
        email: '',
        customerSince: DateTime.now(),
      ));
    } else {
      // One-time customer
      custId = 'ONE-TIME';
      final rawName = _custNameCtrl.text.trim();
      final rawPhone = _custPhoneCtrl.text.trim();
      final rawAddress = _custAddressCtrl.text.trim();
      custName = rawName.isEmpty ? 'NA' : rawName;
      custPhone = rawPhone.isEmpty ? 'NA' : rawPhone;
      custAddress = rawAddress.isEmpty ? 'NA' : rawAddress;
      isOneTime = true;
    }

    // Adapt all item dates and customerIds to match the Bill
    final finalizedItems = _billItems.map((item) {
      return BillItem(
        slNo: item.slNo,
        date: _billDate,
        customerId: custId,
        description: item.description,
        hsnSac: item.hsnSac,
        pcs: item.pcs,
        grossWt: item.grossWt,
        stoneWt: item.stoneWt,
        metalRate: item.metalRate,
        va: item.va,
        stoneValue: item.stoneValue,
        discAmt: item.discAmt,
      );
    }).toList();

    final newBill = Bill(
      slNo: widget.nextSlNo,
      invoiceNumber: 'SVJ/${_billDate.year}/${widget.nextSlNo.toString().padLeft(4, '0')}',
      date: _billDate,
      customerId: custId,
      customerName: custName,
      customerPhone: custPhone,
      customerAddress: custAddress,
      items: finalizedItems,
      isOneTime: isOneTime,
    );

    // Save to global mock bills list
    sharedMockItems.insert(0, newBill);

    Navigator.pop(context, true);
  }

  // --- DIALOGS ---
  void _openAddItemDialog() async {
    final BillItem? item = await showDialog<BillItem>(
      context: context,
      builder: (context) => _CreateItemDialog(nextItemSl: _billItems.length + 1),
    );
    if (item != null) {
      setState(() {
        _billItems.add(item);
      });
    }
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildStepConnector(int index) {
    final isActive = _currentStep > index;
    return Expanded(
      child: Container(
        height: 3,
        color: isActive ? Colors.teal : Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildStep(int stepIndex, String title, IconData icon) {
    final isCurrent = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;
    
    Color circleColor = Colors.grey.shade200;
    Color iconColor = Colors.grey.shade500;
    Color textColor = Colors.grey.shade600;
    Widget innerWidget = Icon(icon, color: iconColor, size: 20);

    if (isCurrent) {
      circleColor = const Color(0xFF03045E);
      textColor = const Color(0xFF03045E);
      innerWidget = Icon(icon, color: Colors.white, size: 20);
    } else if (isCompleted) {
      circleColor = Colors.teal;
      textColor = Colors.teal;
      innerWidget = const Icon(Icons.check, color: Colors.white, size: 20);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Allow clicking backwards to any step, or forwards only if they've met criteria
          if (stepIndex < _currentStep) {
            setState(() {
              _currentStep = stepIndex;
            });
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                boxShadow: isCurrent 
                  ? [BoxShadow(color: const Color(0xFF03045E).withAlpha(64), blurRadius: 8, spreadRadius: 2)] 
                  : null,
              ),
              child: Center(child: innerWidget),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentStep + 1} of 3',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  Text(
                    _currentStep == 0 
                        ? 'Customer Details' 
                        : _currentStep == 1 
                            ? 'Bill Items' 
                            : 'Review & Save',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF03045E)),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            _buildStep(0, 'Customer', Icons.person_outline),
            _buildStepConnector(0),
            _buildStep(1, 'Bill Items', Icons.shopping_bag_outlined),
            _buildStepConnector(1),
            _buildStep(2, 'Review', Icons.fact_check_outlined),
          ],
        ),
      ),
    );
  }

  // --- STEP 1: CUSTOMER ---
  Widget _buildStepCustomer(List<Customer> allCustomers) {
    final filteredCustomers = allCustomers.where((c) {
      final query = _customerSearchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) || 
             c.phone.contains(query) || 
             c.id.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date & Tab Selector
        Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Invoice Config Date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
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
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                const Text(
                  'Billing Target Type',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = MediaQuery.of(context).size.width < 600;
                    return ToggleButtons(
                      constraints: BoxConstraints(
                        minWidth: (constraints.maxWidth - 4) / 3,
                        minHeight: 46,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      fillColor: const Color(0xFF03045E),
                      selectedColor: Colors.white,
                      color: const Color(0xFF03045E),
                      borderColor: const Color(0xFF03045E).withAlpha(50),
                      selectedBorderColor: const Color(0xFF03045E),
                      isSelected: [
                        _customerTypeTab == 0,
                        _customerTypeTab == 1,
                        _customerTypeTab == 2,
                      ],
                      onPressed: (index) {
                        setState(() {
                          _customerTypeTab = index;
                          // Reset inputs
                          if (index != 0) {
                            _selectedCustomer = null;
                          } else {
                            _custNameCtrl.clear();
                            _custPhoneCtrl.clear();
                            _custAddressCtrl.clear();
                          }
                        });
                      },
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8), 
                          child: Text(
                            isSmall ? 'Registry' : 'Select Customer', 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8), 
                          child: Text(
                            isSmall ? 'Register' : 'Register Customer', 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8), 
                          child: Text(
                            isSmall ? 'Guest' : 'One-time Customer', 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Dynamic Customer Section Content
        if (_customerTypeTab == 0) ...[
          // SELECT EXISTING
          Card(
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Choose Customer from Registry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF03045E))),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _customerSearchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Search by Name, Phone, or ID',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _customerSearchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedCustomer != null) ...[
                    // Customer Card Selection Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF03045E))),
                                const SizedBox(height: 4),
                                Text('ID: ${_selectedCustomer!.id}  •  Phone: ${_selectedCustomer!.phone}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('Address: ${_selectedCustomer!.address}', style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCustomer = null;
                              });
                            },
                            child: const Text('Change', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Registry List Results
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: filteredCustomers.isEmpty
                      ? const Center(child: Text('No customers match your search.'))
                      : ListView.separated(
                          itemCount: filteredCustomers.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final cust = filteredCustomers[index];
                            final isSel = _selectedCustomer?.id == cust.id;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSel ? Colors.teal : const Color(0xFFCAF0F8),
                                child: Text(
                                  cust.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(color: isSel ? Colors.white : const Color(0xFF03045E), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('ID: ${cust.id}  •  Phone: ${cust.phone}'),
                              trailing: isSel 
                                ? const Icon(Icons.check_circle, color: Colors.teal) 
                                : const Icon(Icons.chevron_right, color: Colors.grey),
                              selected: isSel,
                              onTap: () {
                                setState(() {
                                  _selectedCustomer = cust;
                                });
                              },
                            );
                          },
                        ),
                  )
                ],
              ),
            ),
          )
        ] else ...[
          // CREATE NEW OR ONE-TIME FORM
          Card(
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _customerFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _customerTypeTab == 1 ? 'Quick Profile Registration' : 'One-Time Guest Checkout Details', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _custNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Customer Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_customerTypeTab == 1 && (value == null || value.trim().isEmpty)) {
                          return 'Customer name required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _custPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: const InputDecoration(
                        labelText: 'Customer Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_customerTypeTab == 1) {
                          if (value == null || value.trim().isEmpty) return 'Customer phone required';
                          if (value.trim().length != 10) return 'Phone number must be exactly 10 digits';
                        } else if (_customerTypeTab == 2) {
                          if (value != null && value.trim().isNotEmpty && value.trim().length != 10) {
                            return 'Phone number must be exactly 10 digits';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _custAddressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Residential Address',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_customerTypeTab == 1 && (value == null || value.trim().isEmpty)) {
                          return 'Customer address required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          )
        ]
      ],
    );
  }

  // --- STEP 2: BILL ITEMS ---
  Widget _buildStepItems() {
    String formatCurrencyStr(double value) =>
        NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2).format(value);

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bill Line Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF03045E))),
                ElevatedButton.icon(
                  onPressed: _openAddItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF03045E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_billItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No items added to this bill yet.',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text('Click "Add Item" above to add Gold or Silver items.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else ...[
              // Items List Table
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _billItems.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _billItems[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${index + 1}. ${item.description}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(formatCurrencyStr(item.totalValue), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0077B6))),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text('Net Wt: ${item.netWt.toStringAsFixed(3)}g', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          Text('Rate: ${formatCurrencyStr(item.metalRate)}/g', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          Text('Pcs: ${item.pcs}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          if (item.discAmt > 0)
                            Text('Disc: -${formatCurrencyStr(item.discAmt)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _billItems.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Divider(thickness: 1),
              const SizedBox(height: 16),
              
              // Totals Block
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gross Total:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black54)),
                  Text(formatCurrencyStr(_grossTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              if (_totalDiscount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Discount:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.redAccent)),
                    Text('-${formatCurrencyStr(_totalDiscount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.redAccent)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sub Total (Taxable):', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black54)),
                  Text(formatCurrencyStr(_subtotalTaxable), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CGST @ 1.5%:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black54)),
                  Text(formatCurrencyStr(_cgst), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SGST @ 1.5%:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black54)),
                  Text(formatCurrencyStr(_sgst), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF03045E).withAlpha(13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      const Text('GRAND TOTAL PAYABLE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF03045E))),
                      Text(formatCurrencyStr(_grandTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF03045E))),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItemsList() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    String formatCurrencyStr(double value) =>
        NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2).format(value);

    if (isMobile) {
      return Column(
        children: _billItems.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.description,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF03045E), fontSize: 14),
                      ),
                    ),
                    Text(
                      formatCurrencyStr(item.totalValue),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0077B6), fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pcs: ${item.pcs}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('Net Wt: ${item.netWt.toStringAsFixed(3)}g', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('Rate: ${formatCurrencyStr(item.metalRate)}/g', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FixedColumnWidth(50),
        2: FixedColumnWidth(80),
        3: FixedColumnWidth(100),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
          children: const [
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Pcs', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Net Wt', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        ..._billItems.map((item) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(item.description)),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('${item.pcs}', textAlign: TextAlign.center)),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('${item.netWt.toStringAsFixed(3)}g', textAlign: TextAlign.center)),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(formatCurrencyStr(item.totalValue), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        )),
      ],
    );
  }

  // --- STEP 3: REVIEW ---
  Widget _buildStepReview() {
    String formatCurrencyStr(double value) =>
        NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2).format(value);

    // Fetch customer details based on tab selected
    String name = "";
    String phone = "";
    String address = "";
    String typeLabel = "";

    if (_customerTypeTab == 0 && _selectedCustomer != null) {
      name = _selectedCustomer!.name;
      phone = _selectedCustomer!.phone;
      address = _selectedCustomer!.address;
      typeLabel = "Registered Customer (Registry Selected)";
    } else {
      name = _custNameCtrl.text.trim();
      phone = _custPhoneCtrl.text.trim();
      address = _custAddressCtrl.text.trim();
      typeLabel = _customerTypeTab == 1 ? "New Customer Profile (To Register)" : "One-Time Billing Customer";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Cards
        Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Invoice Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF03045E))),
                const SizedBox(height: 16),
                _buildReviewDetailRow('Customer Name', name, isBold: true),
                _buildReviewDetailRow('Phone Number', phone),
                _buildReviewDetailRow('Billing Address', address),
                _buildReviewDetailRow('Invoice Date', _formatSimpleDate(_billDate)),
                _buildReviewDetailRow('Account Status', typeLabel, color: Colors.teal.shade700),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Items Summary
        Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Products Purchase Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF03045E))),
                const SizedBox(height: 16),
                _buildReviewItemsList(),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                
                // Final Total Block
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gross Total:', style: TextStyle(color: Colors.black54)),
                    Text(formatCurrencyStr(_grossTotal)),
                  ],
                ),
                if (_totalDiscount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Discount:', style: TextStyle(color: Colors.redAccent)),
                      Text('-${formatCurrencyStr(_totalDiscount)}', style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Taxable Subtotal:', style: TextStyle(color: Colors.black54)),
                    Text(formatCurrencyStr(_subtotalTaxable)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CGST (1.5%) & SGST (1.5%):', style: TextStyle(color: Colors.black54)),
                    Text(formatCurrencyStr(_cgst * 2)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        const Text('FINAL BILL PAYABLE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.teal)),
                        Text(formatCurrencyStr(_grandTotal), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.teal.shade900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black45, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color ?? const Color(0xFF03045E),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MAIN LAYOUT BUILDER ---
  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final allCustomers = customerProvider.customers;

    final bool canContinue;
    if (_currentStep == 0) {
      if (_customerTypeTab == 0) {
        canContinue = _selectedCustomer != null;
      } else {
        canContinue = true;
      }
    } else if (_currentStep == 1) {
      canContinue = _billItems.isNotEmpty;
    } else {
      canContinue = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF03045E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Create New Sales Bill', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12.0 : 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBreadcrumbs(),
                const SizedBox(height: 24),
                if (_currentStep == 0)
                  _buildStepCustomer(allCustomers)
                else if (_currentStep == 1)
                  _buildStepItems()
                else
                  _buildStepReview(),
                const SizedBox(height: 32),
                
                // Footer Stepper Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      OutlinedButton.icon(
                        onPressed: _prevStep,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          side: const BorderSide(color: Color(0xFF03045E), width: 2),
                          foregroundColor: const Color(0xFF03045E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    else
                      const SizedBox(),
                    
                    if (_currentStep < 2)
                      ElevatedButton.icon(
                        onPressed: canContinue ? _nextStep : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF03045E),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _submitBill,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Generate Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- SUB WIDGET: ADD ITEM DIALOG ---
class _CreateItemDialog extends StatefulWidget {
  final int nextItemSl;
  const _CreateItemDialog({required this.nextItemSl});

  @override
  State<_CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends State<_CreateItemDialog> {
  final _formKey = GlobalKey<FormState>();

  final _descCtrl = TextEditingController();
  Map<String, dynamic> _currentRates = {};

  @override
  void initState() {
    super.initState();
    _currentRates = MetalRatesService.loadRates();
  }

  final _hsnCtrl = TextEditingController(text: "71189"); // Default jewellery HSN
  final _pcsCtrl = TextEditingController();
  final _grossWtCtrl = TextEditingController();
  final _stoneWtCtrl = TextEditingController();
  final _netWtCtrl = TextEditingController();
  final _metalRateCtrl = TextEditingController();
  final _metalValueCtrl = TextEditingController();
  final _vaCtrl = TextEditingController();
  final _stoneValueCtrl = TextEditingController(text: "0");
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
    
    // Excel Rule 5: Stone value field drops to 0 and becomes internally readOnly if StoneWT <= 0.0 logically
    final bool stoneValueEnabled = sw > 0.0;
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
    if (_descCtrl.text.trim().isEmpty || !RegExp(r'^[\w\s\-.,]+$').hasMatch(_descCtrl.text)) {
      return false;
    }
    
    // Required number fields must not be empty and must be valid numbers
    final requiredNumberControllers = [
      _hsnCtrl, _pcsCtrl, _grossWtCtrl, _netWtCtrl,
      _metalRateCtrl, _metalValueCtrl, _vaCtrl, _stoneValueCtrl,
      _totalValueCtrl, _taxableValueCtrl
    ];
    for (var c in requiredNumberControllers) {
      if (c.text.trim().isEmpty) return false;
      if (double.tryParse(c.text) == null) return false;
    }

    // Optional number fields: if not empty, must be valid numbers
    final optionalNumberControllers = [
      _stoneWtCtrl, _discAmtCtrl
    ];
    for (var c in optionalNumberControllers) {
      final val = c.text.trim();
      if (val.isNotEmpty && double.tryParse(val) == null) {
        return false;
      }
    }

    final double da = double.tryParse(_discAmtCtrl.text) ?? 0.0;
    final double tv = double.tryParse(_totalValueCtrl.text) ?? 0.0;
    if (da > tv) return false;

    return true;
  }

  void _submit() {
    if (_isFormValid) {
      final newItem = BillItem(
        slNo: widget.nextItemSl,
        date: DateTime.now(), // Fallback (overridden by parent save)
        customerId: '', // Fallback (overridden by parent save)
        description: _descCtrl.text.trim(),
        hsnSac: _hsnCtrl.text.trim(),
        pcs: int.tryParse(_pcsCtrl.text) ?? 1,
        grossWt: double.tryParse(_grossWtCtrl.text) ?? 0.0,
        stoneWt: double.tryParse(_stoneWtCtrl.text) ?? 0.0,
        metalRate: double.tryParse(_metalRateCtrl.text) ?? 0.0,
        va: double.tryParse(_vaCtrl.text) ?? 0.0,
        stoneValue: double.tryParse(_stoneValueCtrl.text) ?? 0.0,
        discAmt: double.tryParse(_discAmtCtrl.text) ?? 0.0,
      );
      Navigator.of(context).pop(newItem);
    }
  }

  Widget _buildLiveRatesSuggestions() {
    final gold24 = _currentRates["gold24k"];
    final gold22 = _currentRates["gold22k"];
    final silver = _currentRates["silver"];
    
    if (gold24 == null && gold22 == null && silver == null) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggest Live Rates (Tap to apply):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (gold24 != null)
                ActionChip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.amber.shade700,
                    radius: 8,
                    child: const Text('24', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  label: Text('24K: ₹${gold24.toStringAsFixed(0)}'),
                  onPressed: () {
                    setState(() {
                      _metalRateCtrl.text = gold24.toStringAsFixed(2);
                      if (_descCtrl.text.isEmpty) {
                        _descCtrl.text = 'Gold 24K';
                      }
                      _recalculate();
                    });
                  },
                ),
              if (gold22 != null)
                ActionChip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.orange.shade800,
                    radius: 8,
                    child: const Text('22', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  label: Text('22K: ₹${gold22.toStringAsFixed(0)}'),
                  onPressed: () {
                    setState(() {
                      _metalRateCtrl.text = gold22.toStringAsFixed(2);
                      if (_descCtrl.text.isEmpty) {
                        _descCtrl.text = 'Gold 22K';
                      }
                      _recalculate();
                    });
                  },
                ),
              if (silver != null)
                ActionChip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.blueGrey.shade700,
                    radius: 8,
                    child: const Icon(Icons.blur_on, size: 8, color: Colors.white),
                  ),
                  label: Text('Silver: ₹${silver.toStringAsFixed(1)}'),
                  onPressed: () {
                    setState(() {
                      _metalRateCtrl.text = silver.toStringAsFixed(2);
                      if (_descCtrl.text.isEmpty) {
                        _descCtrl.text = 'Silver';
                      }
                      _recalculate();
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
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
        final isOptional = label == 'Stone Wt.' || label == 'Disc Amt.';
        if (value == null || value.trim().isEmpty) {
          if (isOptional) {
            return null;
          }
          return '$label required';
        }
        if (isDescription) {
          if (!RegExp(r'^[\w\s\-.,]+$').hasMatch(value)) {
            return 'Invalid description formatting';
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
      }
    );
  }

  Widget _buildResponsiveRow(BuildContext context, Widget child1, Widget child2) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          child1,
          child2,
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child1),
          const SizedBox(width: 16),
          Expanded(child: child2),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600 ? screenWidth : 550.0;
    final isMobile = screenWidth < 600;

    final double sw = double.tryParse(_stoneWtCtrl.text) ?? 0.0;
    final bool stoneValueEnabled = sw > 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(20),
      ),
      insetPadding: isMobile ? EdgeInsets.zero : const EdgeInsets.all(16),
      elevation: 5,
      child: Container(
        width: isMobile ? double.infinity : dialogWidth,
        height: isMobile ? double.infinity : null,
        constraints: BoxConstraints(
          maxHeight: isMobile ? double.infinity : MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF03045E),
                borderRadius: isMobile ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Add Bill Item Details',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 1,
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
                      _buildResponsiveRow(
                        context,
                        _buildTextField('HSN/SAC', _hsnCtrl, isNumber: true),
                        _buildTextField('PCS', _pcsCtrl, isNumber: true, isInt: true),
                      ),
                      _buildResponsiveRow(
                        context,
                        _buildTextField('Gross Wt.', _grossWtCtrl, isNumber: true, isDecimal: true),
                        _buildTextField('Stone Wt.', _stoneWtCtrl, isNumber: true, isDecimal: true),
                      ),
                      _buildResponsiveRow(
                        context,
                        _buildTextField('Net Wt.', _netWtCtrl, isNumber: true, isDecimal: true, readOnly: true),
                        _buildTextField('Metal Rate', _metalRateCtrl, isNumber: true, isDecimal: true),
                      ),
                      _buildLiveRatesSuggestions(),
                      _buildTextField('Metal Value', _metalValueCtrl, isNumber: true, isDecimal: true, readOnly: true),
                      _buildResponsiveRow(
                        context,
                        _buildTextField('VA / Making.', _vaCtrl, isNumber: true, isDecimal: true),
                        _buildTextField('Stone Value', _stoneValueCtrl, isNumber: true, isDecimal: true, readOnly: !stoneValueEnabled),
                      ),
                      _buildTextField('Total Value', _totalValueCtrl, isNumber: true, isDecimal: true, readOnly: true),
                      _buildResponsiveRow(
                        context,
                        _buildTextField('Disc Amt.', _discAmtCtrl, isNumber: true, isDecimal: true),
                        _buildTextField('Taxable Value', _taxableValueCtrl, isNumber: true, isDecimal: true, readOnly: true),
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
                    label: const Text('Save Line Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

// --- SHARED DIRTY TEXT FIELD WIDGET ---
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
          if (widget.isDescription) TitleCaseFormatter(),
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

class TitleCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String text = newValue.text;
    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final String char = text[i];
      if (char == ' ') {
        buffer.write(char);
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
      }
    }

    final String newText = buffer.toString();
    
    // Maintain cursor position
    int selectionOffset = newValue.selection.end;
    if (selectionOffset > newText.length) {
      selectionOffset = newText.length;
    } else if (selectionOffset < 0) {
      selectionOffset = 0;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}
