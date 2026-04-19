import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../data/mock_data.dart';
import 'billing_item_model.dart';
import 'new_bill_dialog.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  bool _isLoading = true;
  bool _isChangingPage = false;
  int _currentPage = 0;
  int _rowsPerPage = 10;

  DateTime _billDate = DateTime.now();
  // ignore: unused_field
  String _customerName = "";
  
  // Filter & Sort State
  String _searchQuery = "";
  final List<String> _activeQuickFilters = []; // Multi-select filters
  int _sortColumnIndex = 1; // Default sort by Date (index 1)
  bool _sortAscending = false;

  DateTime? _customFromDate;
  DateTime? _customToDate;
  RangeValues _totalValueRange = const RangeValues(0, 2000000); // Default to a wide range up to 20 Lakhs
  bool _isValueFilterActive = false;

  List<BillItem> _items = [];

  String _getCustomerName(String id) {
    try {
       final provider = Provider.of<CustomerProvider>(context, listen: false);
       return provider.getCustomerById(id)?.name ?? id;
    } catch (_) {
       return id;
    }
  }

  List<BillItem> get _filteredAndSortedItems {
    Iterable<BillItem> filtered = _items;

    // 1. Search Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) => 
        _getCustomerName(item.customerId).toLowerCase().contains(query) || 
        item.description.toLowerCase().contains(query) ||
        item.slNo.toString().contains(query) ||
        item.hsnSac.toLowerCase().contains(query) ||
        item.grossWt.toString().contains(query) ||
        item.netWt.toString().contains(query) ||
        item.totalValue.toString().contains(query)
      );
    }

    // 2. Quick Multi-Filters
    if (_activeQuickFilters.isNotEmpty) {
      // Find the earliest cutoff date from selected date filters
      DateTime? cutoff;
      final now = DateTime.now();
      
      if (_activeQuickFilters.contains("Past 6 Months")) {
        cutoff = DateTime(now.year, now.month - 6, now.day);
      } else if (_activeQuickFilters.contains("Past 3 Months")) {
        cutoff = DateTime(now.year, now.month - 3, now.day);
      } else if (_activeQuickFilters.contains("Past 1 Month")) {
        cutoff = DateTime(now.year, now.month - 1, now.day);
      }

      if (cutoff != null) {
        filtered = filtered.where((item) => item.date.isAfter(cutoff!));
      }

      // Custom Date Range Filters
      for (final filter in _activeQuickFilters) {
        if (filter.contains(' - ')) {
          final parts = filter.split(' - ');
          if (parts.length == 2) {
            try {
              final fromParts = parts[0].split('/');
              final toParts = parts[1].split('/');
              if (fromParts.length == 3 && toParts.length == 3) {
                final fromDate = DateTime(int.parse(fromParts[2]), int.parse(fromParts[1]), int.parse(fromParts[0]));
                final toDate = DateTime(int.parse(toParts[2]), int.parse(toParts[1]), int.parse(toParts[0]), 23, 59, 59);
                filtered = filtered.where((item) => 
                  item.date.isAfter(fromDate.subtract(const Duration(seconds: 1))) && 
                  item.date.isBefore(toDate)
                );
              }
            } catch (_) {}
          }
        }
      }

      // Material filters
      final bool hasGold = _activeQuickFilters.contains("Gold");
      final bool hasSilver = _activeQuickFilters.contains("Silver");
      
      if (hasGold || hasSilver) {
        // If both are selected, include items that have EITHER gold OR silver
        filtered = filtered.where((item) => 
          (hasGold && item.description.toLowerCase().contains("gold")) ||
          (hasSilver && item.description.toLowerCase().contains("silver"))
        );
      }
    }

    // Apply Total Value Range Filter
    if (_isValueFilterActive) {
      filtered = filtered.where((item) => 
        item.totalValue >= _totalValueRange.start && 
        item.totalValue <= _totalValueRange.end
      );
    }

    // 3. Sorting
    var resultList = filtered.toList();
    if (resultList.isNotEmpty) {
      resultList.sort((a, b) {
        int cmp = 0;
        switch (_sortColumnIndex) {
          case 0: cmp = a.slNo.compareTo(b.slNo); break;
          case 1: cmp = a.date.compareTo(b.date); break;
          case 2: cmp = _getCustomerName(a.customerId).compareTo(_getCustomerName(b.customerId)); break;
          case 3: cmp = a.description.compareTo(b.description); break;
          case 5: cmp = a.pcs.compareTo(b.pcs); break;
          case 6: cmp = a.grossWt.compareTo(b.grossWt); break;
          case 8: cmp = a.netWt.compareTo(b.netWt); break;
          case 13: cmp = a.totalValue.compareTo(b.totalValue); break;
          default: cmp = a.date.compareTo(b.date); break;
        }
        return _sortAscending ? cmp : -cmp;
      });
    }

    return resultList;
  }

  final _horizontalScrollController = ScrollController();
  bool _isHoveringTable = false;

  @override
  void initState() {
    super.initState();
    // Simulate loading to prevent UI freeze and show progress
    Future.delayed(const Duration(milliseconds: 800), () {
      _loadData();
    });
  }

  void _updatePagination({int? newPage, int? newRowsPerPage}) {
    if (newPage == _currentPage && newRowsPerPage == null) return;
    
    setState(() {
      _isChangingPage = true;
    });

    // Provide a brief delay so the UI thread registers the loading state / animation
    // before synchronously generating the large DataTable rows.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          if (newPage != null) _currentPage = newPage;
          if (newRowsPerPage != null) {
            _rowsPerPage = newRowsPerPage;
            _currentPage = 0;
          }
          _isChangingPage = false;
        });
      }
    });
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
    _updatePagination(newPage: 0);
  }

  void _loadData() {
    initializeSharedMockData();
    _items = sharedMockItems;
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _openNewBillDialog() async {
    final BillItem? newItem = await showDialog<BillItem>(
      context: context,
      builder: (context) => NewBillDialog(
        nextSlNo: _items.length + 1,
        customerId: _customerName,
      ),
    );

    if (newItem != null) {
      setState(() {
        _items.add(newItem);
        // Ensure strictly sorted order dynamically applied after user submission
        _items.sort((a, b) => b.date.compareTo(a.date));
      });
      _updatePagination(newPage: 0); // Refresh view
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill item tracked successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFF0077B6),
        ),
      );
    }
  }

  void _openAdvancedFilterDrawer() {
    DateTime? localFromDate = _customFromDate;
    DateTime? localToDate = _customToDate;
    RangeValues localValueRange = _totalValueRange;

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      barrierLabel: 'Close Advanced Filter',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDrawerState) {
            return Align(
              alignment: Alignment.centerRight,
              child: Material(
                elevation: 16,
                child: Container(
                  color: const Color(0xFFF0F2F5),
                  width: 320,
                  height: double.infinity,
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Advanced Filters',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      const Text('Custom Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF03045E))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: localFromDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDrawerState(() => localFromDate = picked);
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(localFromDate == null ? 'From Date' : _formatSimpleDate(localFromDate!)),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.white,
                          elevation: 1,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: localToDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDrawerState(() => localToDate = picked);
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(localToDate == null ? 'To Date' : _formatSimpleDate(localToDate!)),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.white,
                          elevation: 1,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Total Value Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF03045E))),
                      const SizedBox(height: 16),
                      RangeSlider(
                        values: localValueRange,
                        min: 0,
                        max: 2000000,
                        divisions: 200,
                        labels: RangeLabels(
                          '₹${localValueRange.start.toStringAsFixed(0)}',
                          '₹${localValueRange.end.toStringAsFixed(0)}',
                        ),
                        activeColor: const Color(0xFF0077B6),
                        onChanged: (values) {
                          setDrawerState(() => localValueRange = values);
                        },
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setDrawerState(() {
                              localFromDate = null;
                              localToDate = null;
                              localValueRange = const RangeValues(0, 2000000);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            side: const BorderSide(color: Color(0xFF03045E)),
                            foregroundColor: const Color(0xFF03045E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Reset Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _customFromDate = localFromDate;
                              _customToDate = localToDate;
                              _totalValueRange = localValueRange;
                              
                              // Check if value range was actually modified from default limits
                              _isValueFilterActive = _totalValueRange.start > 0 || _totalValueRange.end < 2000000;

                              if (_customFromDate != null && _customToDate != null) {
                                final customFilterString = "${_formatSimpleDate(_customFromDate!)} - ${_formatSimpleDate(_customToDate!)}";
                                _activeQuickFilters.removeWhere((f) => f.contains(' - ') && f.contains('/'));
                                _activeQuickFilters.add(customFilterString);
                              }

                              _activeQuickFilters.removeWhere((f) => f.startsWith('₹'));
                              if (_isValueFilterActive) {
                                final valueFilterString = "₹${_totalValueRange.start.toStringAsFixed(0)} - ₹${_totalValueRange.end.toStringAsFixed(0)}";
                                _activeQuickFilters.add(valueFilterString);
                              }
                            });
                            _updatePagination(newPage: 0);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: const Color(0xFF03045E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
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
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width < 600 ? 16 : 32,
          MediaQuery.of(context).size.width < 600 ? 16 : 32,
          MediaQuery.of(context).size.width < 600 ? 16 : 32,
          MediaQuery.of(context).size.width < 600 ? 100 : 32,
        ),
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
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 600;
                return Flex(
                  direction: isSmall ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: isSmall ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                  children: [
                    if (isSmall)
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Bills',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (val) {
                          _customerName = val;
                          _searchQuery = val;
                          _updatePagination();
                        },
                      )
                    else
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search Bills',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (val) {
                            _customerName = val;
                            _searchQuery = val;
                            _updatePagination();
                          },
                        ),
                      ),
                    if (isSmall) const SizedBox(height: 16),
                    if (isSmall)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openNewBillDialog,
                              icon: const Icon(Icons.add_shopping_cart, size: 20),
                              label: const Text('New Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                backgroundColor: const Color(0xFF03045E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openAdvancedFilterDrawer,
                              icon: const Icon(Icons.tune, size: 20),
                              label: const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                side: const BorderSide(color: Color(0xFF03045E), width: 2),
                                foregroundColor: const Color(0xFF03045E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      const SizedBox(width: 16),
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
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _openAdvancedFilterDrawer,
                        icon: const Icon(Icons.tune),
                        label: const Text('Advanced Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          side: const BorderSide(color: Color(0xFF03045E), width: 2),
                          foregroundColor: const Color(0xFF03045E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ]
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Quick Filter Chips 
            // On mobile, standard chips are hidden to save space, but custom applied chips remain visible to be dismissible
            LayoutBuilder(
              builder: (context, constraints) {
                final filters = ["All", "Past 1 Month", "Past 3 Months", "Past 6 Months", "Gold", "Silver"];
                final customFilters = _activeQuickFilters.where((f) => !filters.contains(f)).toList();
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    children: [
                      const Text(
                        'Quick Filters: ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ...filters.map((filter) {
                              final isSelected = filter == "All" 
                                  ? _activeQuickFilters.isEmpty 
                                  : _activeQuickFilters.contains(filter);
                                  
                              return ChoiceChip(
                                label: Text(
                                  filter,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : const Color(0xFF03045E),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF0077B6),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.3),
                                ),
                                showCheckmark: false,
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (filter == "All") {
                                      _activeQuickFilters.clear();
                                      _customFromDate = null;
                                      _customToDate = null;
                                      _totalValueRange = const RangeValues(0, 2000000);
                                      _isValueFilterActive = false;
                                    } else {
                                      if (selected) {
                                        _activeQuickFilters.add(filter);
                                      } else {
                                        _activeQuickFilters.remove(filter);
                                      }
                                    }
                                  });
                                  _updatePagination(newPage: 0);
                                },
                              );
                            }),
                            ...customFilters.map((customFilter) {
                              return InputChip(
                                label: Text(
                                  customFilter,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFF0077B6),
                                deleteIconColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                side: const BorderSide(color: Colors.transparent),
                                onDeleted: () {
                                  setState(() {
                                    _activeQuickFilters.remove(customFilter);
                                    
                                    if (customFilter.startsWith('₹')) {
                                      _totalValueRange = const RangeValues(0, 2000000);
                                      _isValueFilterActive = false;
                                    } else if (customFilter.contains(' - ')) {
                                      _customFromDate = null;
                                      _customToDate = null;
                                    }

                                    if (_activeQuickFilters.isEmpty) {
                                      _customFromDate = null;
                                      _customToDate = null;
                                      _totalValueRange = const RangeValues(0, 2000000);
                                      _isValueFilterActive = false;
                                    }
                                  });
                                  _updatePagination(newPage: 0);
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Items Table Enclosed by Hover Region
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF0077B6)),
                      SizedBox(height: 16),
                      Text('Loading billing records...', style: TextStyle(color: Color(0xFF03045E), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            else
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
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          child: _isChangingPage 
                            ? const SizedBox(
                                height: 300,
                                width: 800, // Fixed width placeholder
                                child: Center(
                                  child: CircularProgressIndicator(color: Color(0xFF0077B6)),
                                ),
                              )
                            : _filteredAndSortedItems.isEmpty
                                ? SizedBox(
                                    height: 300,
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'No Records Found',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF03045E),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Try adjusting your search or filters to find what you are looking for.',
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : DataTable(
                                    key: ValueKey('page_${_currentPage}_$_rowsPerPage'),
                                    headingRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFF90E0EF).withValues(alpha: 0.3)),
                                    showBottomBorder: true,
                                sortColumnIndex: _sortColumnIndex,
                                sortAscending: _sortAscending,
                                columns: [
                                  DataColumn(label: const Text('SlNo.', style: TextStyle(fontWeight: FontWeight.bold)), onSort: _sort),
                                  DataColumn(label: const Text('Bill Date', style: TextStyle(fontWeight: FontWeight.bold)), onSort: _sort),
                                  DataColumn(label: const Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold)), onSort: _sort),
                                  DataColumn(label: const Text('Description of Goods', style: TextStyle(fontWeight: FontWeight.bold)), onSort: _sort),
                                  DataColumn(label: const Text('HSN/SAC', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: const NumericText('PCS'), onSort: _sort),
                                  DataColumn(label: const NumericText('Gross Wt.'), onSort: _sort),
                                  DataColumn(label: const NumericText('Stone Wt.')),
                                  DataColumn(label: const NumericText('Net Wt.'), onSort: _sort),
                                  DataColumn(label: const NumericText('Metal Rate')),
                                  DataColumn(label: const NumericText('Metal Value')),
                                  DataColumn(label: const NumericText('VA.')),
                                  DataColumn(label: const NumericText('Stone Value')),
                                  DataColumn(label: const NumericText('Total Value'), onSort: _sort),
                                  DataColumn(label: const NumericText('Disc Amt.')),
                                  DataColumn(label: const NumericText('Taxable Value')),
                                ],
                          rows: _filteredAndSortedItems.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).map((item) {
                            return DataRow(
                              cells: [
                                DataCell(Text(item.slNo.toString())),
                                DataCell(
                                  Text(
                                    DateFormat('dd/MM/yyyy hh:mm a').format(item.date),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0077B6)),
                                  ),
                                ),
                                DataCell(Text(_getCustomerName(item.customerId), style: const TextStyle(fontWeight: FontWeight.w500))),
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
            ),
            if (!_isLoading) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  Text(
                    'Showing ${_filteredAndSortedItems.isEmpty ? 0 : (_currentPage * _rowsPerPage) + 1} - ${((_currentPage + 1) * _rowsPerPage) > _filteredAndSortedItems.length ? _filteredAndSortedItems.length : ((_currentPage + 1) * _rowsPerPage)} of ${_filteredAndSortedItems.length} records',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Rows per page: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF03045E))),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _rowsPerPage,
                        focusColor: Colors.transparent,
                        underline: const SizedBox(),
                        items: [10, 20, 50].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            FocusScope.of(context).unfocus();
                            _updatePagination(newRowsPerPage: newValue);
                          }
                        },
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        color: const Color(0xFF03045E),
                        onPressed: _currentPage > 0 && !_isChangingPage
                            ? () => _updatePagination(newPage: _currentPage - 1)
                            : null,
                      ),
                      Text(
                        'Page ${_currentPage + 1} of ${(_filteredAndSortedItems.isEmpty ? 1 : (_filteredAndSortedItems.length / _rowsPerPage).ceil())}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF03045E)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: const Color(0xFF03045E),
                        onPressed: (_currentPage + 1) * _rowsPerPage < _filteredAndSortedItems.length && !_isChangingPage
                            ? () => _updatePagination(newPage: _currentPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
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