import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import 'customer_model.dart';
import 'customer_profile_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String _searchQuery = "";
  Customer? _selectedCustomer;
  
  // Pagination State
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
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
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF03045E)), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    if (_selectedCustomer != null) {
      // Embed the profile safely within existing UX bounds
      return CustomerProfilePage(
        customer: _selectedCustomer!,
        onBack: () {
          setState(() {
            _selectedCustomer = null;
          });
        },
      );
    }

    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final allCustomers = provider.customers;
        final filteredCustomers = _searchQuery.isEmpty
            ? allCustomers
            : allCustomers.where((c) {
                final q = _searchQuery.toLowerCase();
                return c.name.toLowerCase().contains(q) ||
                       c.phone.toLowerCase().contains(q) ||
                       c.id.toLowerCase().contains(q) ||
                       c.address.toLowerCase().contains(q);
              }).toList();

        final now = DateTime.now();
        final newThisMonth = allCustomers.where((c) => c.customerSince.month == now.month && c.customerSince.year == now.year).length;

        // Pagination calculation
        int totalItems = filteredCustomers.length;
        int totalPages = (totalItems / _rowsPerPage).ceil();
        if (_currentPage >= totalPages && totalPages > 0) {
          _currentPage = totalPages - 1;
        } else if (totalPages == 0) {
          _currentPage = 0;
        }

        final paginatedCustomers = filteredCustomers
            .skip(_currentPage * _rowsPerPage)
            .take(_rowsPerPage)
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isMobile = screenWidth < 600;
            final isTablet = screenWidth >= 600 && screenWidth < 1000;
            
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16.0 : 32.0,
                  isMobile ? 16.0 : 32.0,
                  isMobile ? 16.0 : 32.0,
                  isMobile ? 100.0 : 32.0, // Extra padding at bottom for floating nav
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 16,
                      children: [
                        Text(
                          'Customer Database',
                          style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w800, color: const Color(0xFF03045E)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Add Customer form coming next!')),
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 12 : 16),
                            backgroundColor: const Color(0xFF0077B6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // KPIs
                    if (isMobile)
                      Column(
                        children: [
                          Row(children: [_buildOverviewCard('Total Customers', allCustomers.length.toString(), Icons.people_alt, const Color(0xFF0077B6))]),
                          const SizedBox(height: 16),
                          Row(children: [_buildOverviewCard('New This Month', newThisMonth.toString(), Icons.trending_up, Colors.green)]),
                          const SizedBox(height: 16),
                          Row(children: [_buildOverviewCard('Active Searches', filteredCustomers.length.toString(), Icons.person_search, Colors.orange)]),
                        ],
                      )
                    else if (isTablet)
                      Column(
                        children: [
                          Row(
                            children: [
                              _buildOverviewCard('Total Customers', allCustomers.length.toString(), Icons.people_alt, const Color(0xFF0077B6)),
                              const SizedBox(width: 16),
                              _buildOverviewCard('New This Month', newThisMonth.toString(), Icons.trending_up, Colors.green),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildOverviewCard('Active Searches', filteredCustomers.length.toString(), Icons.person_search, Colors.orange),
                              const Spacer(),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          _buildOverviewCard('Total Customers', allCustomers.length.toString(), Icons.people_alt, const Color(0xFF0077B6)),
                          const SizedBox(width: 16),
                          _buildOverviewCard('New This Month', newThisMonth.toString(), Icons.trending_up, Colors.green),
                          const SizedBox(width: 16),
                          _buildOverviewCard('Active Searches', filteredCustomers.length.toString(), Icons.person_search, Colors.orange),
                        ],
                      ),
                    
                    const SizedBox(height: 24),

                    // Main Content Area
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Search directory (Name, ID, Phone, Address)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.search, color: Color(0xFF0077B6)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF03045E), width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                  _currentPage = 0; // Reset page on search
                                });
                              },
                            ),
                          ),
                          const Divider(height: 1, thickness: 1),
                          
                          if (filteredCustomers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_search_outlined, size: 80, color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No matching records found',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            if (isMobile)
                              _buildMobileCards(paginatedCustomers)
                            else
                              _buildModernTable(paginatedCustomers),
                            
                            // Pagination Controls
                            const Divider(height: 1, thickness: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Showing ${_currentPage * _rowsPerPage + 1} to ${(_currentPage * _rowsPerPage + paginatedCustomers.length)} of $totalItems',
                                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        onPressed: _currentPage > 0
                                            ? () => setState(() => _currentPage--)
                                            : null,
                                        color: const Color(0xFF0077B6),
                                        disabledColor: Colors.grey.shade300,
                                      ),
                                      if (!isMobile) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          'Page ${_currentPage + 1} of $totalPages',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right),
                                        onPressed: _currentPage < totalPages - 1
                                            ? () => setState(() => _currentPage++)
                                            : null,
                                        color: const Color(0xFF0077B6),
                                        disabledColor: Colors.grey.shade300,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernTable(List<Customer> customers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(color: Colors.grey.shade50),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('Customer Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
              Expanded(child: Text('Record ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
              Expanded(child: Text('Phone Connect', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
              Expanded(flex: 2, child: Text('Local Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
              const SizedBox(width: 40),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: customers.length,
          separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
          itemBuilder: (context, index) {
            final customer = customers[index];
            return _HoverTableRow(
              customer: customer,
              onTap: () {
                setState(() {
                  _selectedCustomer = customer;
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMobileCards(List<Customer> customers) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
      itemBuilder: (context, index) {
        final customer = customers[index];
        return InkWell(
          onTap: () {
            setState(() {
              _selectedCustomer = customer;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFCAF0F8),
                  radius: 24,
                  child: Text(
                    customer.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF03045E)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.phone,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03045E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF03045E).withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    customer.id,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF03045E), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HoverTableRow extends StatefulWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _HoverTableRow({required this.customer, required this.onTap});

  @override
  State<_HoverTableRow> createState() => _HoverTableRowState();
}

class _HoverTableRowState extends State<_HoverTableRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _isHovering ? Colors.blue.shade50 : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFCAF0F8),
                      radius: 16,
                      child: Text(
                        widget.customer.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.customer.name, 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(widget.customer.id, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0077B6))),
              ),
              Expanded(
                child: Text(widget.customer.phone, style: const TextStyle(color: Colors.black87)),
              ),
              Expanded(
                flex: 2,
                child: Text(widget.customer.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87)),
              ),
              Icon(Icons.chevron_right, color: _isHovering ? const Color(0xFF0077B6) : Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
