import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'billing/billing_page.dart';
import 'customers/customers_page.dart';
import 'providers/customer_provider.dart';
import 'data/mock_data.dart';
import 'billing/bill_model.dart';
import 'billing/create_new_bill_page.dart';
import 'billing/view_sales_bill_page.dart';
import 'customers/customer_model.dart';
import 'services/metal_rates_service.dart';
import 'package:intl/intl.dart';

void main() {
  initializeSharedMockData();
  runApp(const DashboardApp());
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Jewellery Dashboard',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF03045E)),
          fontFamily: 'Rubik',
        ),
        home: const DashboardLandingPage(),
      ),
    );
  }
}

class DashboardLandingPage extends StatefulWidget {
  const DashboardLandingPage({super.key});

  @override
  State<DashboardLandingPage> createState() => _DashboardLandingPageState();
}

class _DashboardLandingPageState extends State<DashboardLandingPage> {
  // Controls whether the sidebar on larger screens is expanded or collapsed
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;
  String _pieTimeFrame = 'Month';

  // Custom Colors provided
  final Color _appBarColor = const Color(0xFF03045E);
  final Color _sidebarColor = const Color(0xFF90E0EF);

  // Layout Colors
  final Color _pageBackgroundColor = const Color(0xFFF0F2F5); // Pleasant light grey spreading the whole page

  // Metal Colors
  final Color _goldColor = const Color(0xFFFFD700);
  final Color _silverColor = const Color(0xFFC0C0C0);

  // Chart state
  int _selectedYear = DateTime.now().year;
  late final List<int> _availableYears;
  
  double _lastScreenWidth = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.of(context).size.width;
    if (_lastScreenWidth != 0) {
      if (_lastScreenWidth >= 1100 && width < 1100) {
        // Auto-collapse sidebar when moving to tablet/smaller desktop
        _isSidebarExpanded = false;
      } else if (_lastScreenWidth < 1100 && width >= 1100) {
        // Auto-expand sidebar when moving to wide desktop
        _isSidebarExpanded = true;
      }
    } else {
      if (width < 1100) {
        _isSidebarExpanded = false;
      }
    }
    _lastScreenWidth = width;
  }

  Map<String, dynamic> _currentRates = {};

  @override
  void initState() {
    super.initState();
    _currentRates = MetalRatesService.loadRates();
    _availableYears = [
      _selectedYear,
      _selectedYear - 1,
      _selectedYear - 2,
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Check if we are on a small screen to auto-collapse/use Drawer
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    // Check if we are on a medium screen to stack charts vertically
    final isMediumScreen = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      backgroundColor: _pageBackgroundColor, // Applied grey background to the entire page
      appBar: AppBar(
        title: const Text(
          'Jewellery Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: _appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        scrolledUnderElevation: 2.0,
        shadowColor: Theme.of(context).colorScheme.shadow,
        elevation: 1.0,
        leading: isSmallScreen
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  setState(() {
                    _isSidebarExpanded = !_isSidebarExpanded;
                  });
                },
                tooltip: 'Toggle Sidebar',
              ),
        actions: [
          if (!isSmallScreen) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
              tooltip: 'Search',
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
              tooltip: 'Notifications',
            ),
            const SizedBox(width: 8),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: _sidebarColor,
                radius: 16,
                child: Icon(Icons.person, color: _appBarColor, size: 18),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Venkata Vamsi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Administrator',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // Custom Animated Sidebar for Apple-styled Active States
              if (!isSmallScreen)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _isSidebarExpanded ? 240 : 88,
                  color: _sidebarColor,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: _isSidebarExpanded ? 160 : 72,
                        child: SvgPicture.asset(
                          'assets/brand_logo_colored.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAppleStyleSidebarItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
                      _buildAppleStyleSidebarItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Billing', 1),
                      _buildAppleStyleSidebarItem(Icons.people_outline, Icons.people, 'Customers', 2),
                      _buildAppleStyleSidebarItem(Icons.settings_outlined, Icons.settings, 'Settings', 3),
                    ],
                  ),
                ),
              // Main Body Content
              Expanded(
                child: _buildMainContent(isMediumScreen),
              ),
            ],
          ),
          
          // Mobile Floating Bottom Navigation
          if (isSmallScreen)
            Positioned(
              bottom: 12,
              left: 24,
              right: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _sidebarColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMobileNavItem(Icons.dashboard_outlined, Icons.dashboard, 0),
                        _buildMobileNavItem(Icons.receipt_long_outlined, Icons.receipt_long, 1),
                        _buildMobileNavItem(Icons.people_outline, Icons.people, 2),
                        _buildMobileNavItem(Icons.settings_outlined, Icons.settings, 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileNavItem(IconData unselectedIcon, IconData selectedIcon, int index) {
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _appBarColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          color: isSelected ? Colors.white : Colors.black87,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildAppleStyleSidebarItem(IconData unselectedIcon, IconData selectedIcon, String title, int index) {
    return SidebarItemWidget(
      unselectedIcon: unselectedIcon,
      selectedIcon: selectedIcon,
      title: title,
      index: index,
      selectedIndex: _selectedIndex,
      isSidebarExpanded: _isSidebarExpanded,
      appBarColor: _appBarColor,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  // Helper to build settings or empty pages
  Widget _buildEmptyPlaceholder(int index) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForIndex(index),
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            _getTitleForIndex(index),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'This is a blank canvas for your ${_getTitleForIndex(index).toLowerCase()}.\nYou can start adding widgets here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  void _showEditRatesDialog() {
    final gold24Ctrl = TextEditingController(text: (_currentRates["gold24k"] ?? 15272.0).toString());
    final gold22Ctrl = TextEditingController(text: (_currentRates["gold22k"] ?? 13999.0).toString());
    final gold18Ctrl = TextEditingController(text: (_currentRates["gold18k"] ?? 10956.0).toString());
    final silverCtrl = TextEditingController(text: (_currentRates["silver"] ?? 264.9).toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Metal Rates', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF03045E))),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: gold24Ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Gold 24K Rate (₹/gram)',
                      prefixText: '₹ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final num = double.tryParse(val);
                      if (num == null || num <= 0) return 'Enter a valid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: gold22Ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Gold 22K Rate (₹/gram)',
                      prefixText: '₹ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final num = double.tryParse(val);
                      if (num == null || num <= 0) return 'Enter a valid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: gold18Ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Gold 18K Rate (₹/gram)',
                      prefixText: '₹ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final num = double.tryParse(val);
                      if (num == null || num <= 0) return 'Enter a valid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: silverCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Silver Rate (₹/gram)',
                      prefixText: '₹ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Required';
                      final num = double.tryParse(val);
                      if (num == null || num <= 0) return 'Enter a valid price';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03045E),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newRates = {
                    "gold24k": double.parse(gold24Ctrl.text),
                    "gold22k": double.parse(gold22Ctrl.text),
                    "gold18k": double.parse(gold18Ctrl.text),
                    "silver": double.parse(silverCtrl.text),
                  };
                  await MetalRatesService.saveRates(newRates);
                  
                  if (!context.mounted) return;
                  setState(() {
                    _currentRates = MetalRatesService.loadRates();
                  });
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Metal rates updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLiveMetalTicker(bool isMobile) {
    final gold24 = _currentRates["gold24k"] ?? 15272.0;
    final gold22 = _currentRates["gold22k"] ?? 13999.0;
    final gold18 = _currentRates["gold18k"] ?? 10956.0;
    final silver = _currentRates["silver"] ?? 264.9;
    final lastUpdatedStr = _currentRates["lastUpdated"] ?? "";
    
    DateTime? lastUpdateDate;
    if (lastUpdatedStr.isNotEmpty) {
      lastUpdateDate = DateTime.tryParse(lastUpdatedStr)?.toLocal();
    }
    final timeStr = lastUpdateDate != null 
        ? DateFormat('hh:mm a').format(lastUpdateDate) 
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up, color: Color(0xFF0077B6), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Daily Metal Rates (INR)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF03045E)),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Updated at $timeStr',
                    style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Update Rates Manually',
                    child: InkWell(
                      onTap: _showEditRatesDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.edit,
                          size: 14,
                          color: Color(0xFF03045E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          isMobile 
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTickerItem("Gold 24K", "₹${gold24.toStringAsFixed(0)} /g", "📈 +1.2%", Colors.amber.shade700, Colors.amber.shade50)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTickerItem("Gold 22K", "₹${gold22.toStringAsFixed(0)} /g", "📈 +1.1%", Colors.orange.shade800, Colors.orange.shade50)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTickerItem("Gold 18K", "₹${gold18.toStringAsFixed(0)} /g", "📈 +0.9%", Colors.yellow.shade900, Colors.yellow.shade50)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTickerItem("Silver", "₹${silver.toStringAsFixed(1)} /g", "📉 -0.4%", Colors.blueGrey.shade700, Colors.blueGrey.shade50)),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildTickerItem("Gold 24K", "₹${gold24.toStringAsFixed(0)} /g", "📈 +1.2%", Colors.amber.shade700, Colors.amber.shade50)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTickerItem("Gold 22K", "₹${gold22.toStringAsFixed(0)} /g", "📈 +1.1%", Colors.orange.shade800, Colors.orange.shade50)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTickerItem("Gold 18K", "₹${gold18.toStringAsFixed(0)} /g", "📈 +0.9%", Colors.yellow.shade900, Colors.yellow.shade50)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTickerItem("Silver", "₹${silver.toStringAsFixed(1)} /g", "📉 -0.4%", Colors.blueGrey.shade700, Colors.blueGrey.shade50)),
                  ],
                )
        ],
      ),
    );
  }

  Widget _buildTickerItem(String label, String rate, String change, Color textColor, Color bgColor) {
    Color itemBgColor;
    Color borderColor;
    
    if (label.contains('24K')) {
      itemBgColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade200;
    } else if (label.contains('22K')) {
      itemBgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
    } else if (label.contains('18K')) {
      itemBgColor = Colors.yellow.shade50;
      borderColor = Colors.yellow.shade200;
    } else {
      itemBgColor = Colors.blueGrey.shade50;
      borderColor = Colors.blueGrey.shade200;
    }

    final isIncrease = change.contains('+');
    final cleanChange = change.replaceAll('📈', '').replaceAll('📉', '').trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label, 
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: textColor.withValues(alpha: 0.8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    rate, 
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isIncrease ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isIncrease ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 9,
                  color: isIncrease ? Colors.green.shade700 : Colors.red.shade700,
                ),
                const SizedBox(width: 1),
                Text(
                  cleanChange,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isIncrease ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(bool isMobile) {
    final actions = [
      _QuickActionItem(
        label: "New Invoice",
        description: "Generate customer sales bill",
        icon: Icons.add_shopping_cart,
        color: const Color(0xFF03045E),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateNewBillPage(nextSlNo: sharedMockItems.length + 1),
            ),
          ).then((value) {
            if (value == true) {
              setState(() {});
            }
          });
        },
      ),
      _QuickActionItem(
        label: "Add Customer",
        description: "Register new customer info",
        icon: Icons.person_add_alt_1_outlined,
        color: Colors.teal,
        onTap: () {
          setState(() {
            _selectedIndex = 2;
          });
        },
      ),
      _QuickActionItem(
        label: "Summary PDF",
        description: "Monthly store report",
        icon: Icons.picture_as_pdf_outlined,
        color: Colors.red.shade700,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compilation Succeeded! Dashboard PDF report generated successfully.', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Color(0xFF0077B6),
            ),
          );
        },
      ),
    ];

    return Row(
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == actions.length - 1 ? 0 : (isMobile ? 8.0 : 16.0),
            ),
            child: _QuickActionCard(item: item, isMobile: isMobile),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKPIMetricsGrid({
    required bool isMobile,
    required double revenue,
    required int billsCount,
    required double avgValue,
    required int customersCount,
  }) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);
    
    final metrics = [
      _KPIMetricItem(
        title: "Today's Revenue",
        value: formatCurrency.format(revenue),
        icon: Icons.currency_rupee,
        color: const Color(0xFF03045E),
        change: "+12.4% vs yesterday",
        isPositive: true,
      ),
      _KPIMetricItem(
        title: "Active Bills Today",
        value: billsCount.toString(),
        icon: Icons.receipt_long,
        color: Colors.teal.shade800,
        change: "+4 today",
        isPositive: true,
      ),
      _KPIMetricItem(
        title: "Avg Invoice Value",
        value: formatCurrency.format(avgValue),
        icon: Icons.analytics_outlined,
        color: Colors.purple.shade800,
        change: "Stable tickets",
        isPositive: true,
      ),
      _KPIMetricItem(
        title: "Customer Directory",
        value: customersCount.toString(),
        icon: Icons.people_outline,
        color: Colors.orange.shade800,
        change: "+2 new registrations",
        isPositive: true,
      ),
    ];

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
        ),
        itemCount: metrics.length,
        itemBuilder: (context, index) {
          final item = metrics[index];
          return _KPICard(item: item, isMobile: true);
        },
      );
    }

    return Row(
      children: metrics.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _KPICard(item: item, isMobile: false),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivityTimeline(bool isMobile, List<Bill> invoices) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);
    
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Invoices Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF03045E),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1),
          if (invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
              child: Center(child: Text('No invoices found.', style: TextStyle(color: Colors.grey))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoices.length,
              separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
              itemBuilder: (context, index) {
                final bill = invoices[index];
                return _DashboardHoverInvoiceRow(
                  bill: bill,
                  formatCurrency: formatCurrency,
                );
              },
            ),
        ],
      ),
    );
  }

  // Helper to build dashboard charts
  Widget _buildDashboardContent(bool shouldStackCharts) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning, Manager! 🌅' : 'Good Evening, Manager! 🌆';
    
    // Calculations - Use calendar today
    final today = DateTime.now();
    
    final todayBills = sharedMockItems.where((item) => 
        item.date.year == today.year && 
        item.date.month == today.month && 
        item.date.day == today.day
    ).toList();
    
    final double todayRevenue = todayBills.fold(0.0, (sum, item) => sum + item.grandTotal);
    final int todayBillCount = todayBills.length;
    final double avgInvoiceValue = todayBills.isNotEmpty ? (todayRevenue / todayBills.length) : 0.0;
    final customerProvider = Provider.of<CustomerProvider>(context);
    final totalCustomers = customerProvider.customers.length;

    // Last 4 invoices timeline data
    final recentInvoices = sharedMockItems.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayInvoices = recentInvoices.take(4).toList();

    return Stack(
      children: [
        // Centered background SVG logo watermark
        Center(
          child: Opacity(
            opacity: 0.15,
            child: SvgPicture.asset(
              'assets/brand_logo_colored.svg',
              width: 320,
              height: 320,
            ),
          ),
        ),
        
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16.0 : 32.0,
            isMobile ? 16.0 : 32.0,
            isMobile ? 16.0 : 32.0,
            isMobile ? 100.0 : 32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Welcome Header and Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF03045E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Here is your store overview for today.',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Live Metal Price Ticker Banner
              _buildLiveMetalTicker(isMobile),
              const SizedBox(height: 24),

              // 3. Quick Action Buttons Grid (Thumb friendly)
              _buildQuickActionButtons(isMobile),
              const SizedBox(height: 24),

              // 4. Dynamic KPI Metric Cards
              _buildKPIMetricsGrid(
                isMobile: isMobile,
                revenue: todayRevenue,
                billsCount: todayBillCount,
                avgValue: avgInvoiceValue,
                customersCount: totalCustomers,
              ),
              const SizedBox(height: 32),

              // 5. Visual Charts (Line Sales & Pie Category Ratio)
              if (shouldStackCharts) ...[
                _buildYearlySalesCard(true),
                const SizedBox(height: 20),
                _buildMonthlyPieCard(true),
              ] else
                SizedBox(
                  height: 420,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: _buildYearlySalesCard(false)),
                      const SizedBox(width: 20),
                      Expanded(flex: 1, child: _buildMonthlyPieCard(false)),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // 6. Recent Activity Timeline Feed
              _buildRecentActivityTimeline(isMobile, displayInvoices),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // Returns the content for the currently selected tab using IndexedStack for state preservation
  Widget _buildMainContent(bool shouldStackCharts) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildDashboardContent(shouldStackCharts),
        const BillingPage(),
        const CustomersPage(),
        _buildEmptyPlaceholder(3),
      ],
    );
  }

  Widget _buildYearlySalesCard(bool isStacked) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Yearly Sales (Gold & Silver)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF03045E),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: _pageBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF03045E)),
                      items: _availableYears.map((int year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(
                            year.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF03045E)),
                          ),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedYear = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            isStacked
                ? SizedBox(
                    height: 250,
                    child: _buildLineChart(),
                  )
                : Expanded(
                    child: _buildLineChart(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    List<double> goldTotals = List.filled(12, 0.0);
    List<double> silverTotals = List.filled(12, 0.0);
    
    final yearItems = sharedMockItems.where((item) => item.date.year == _selectedYear).toList();
    for (var item in yearItems) {
      int month = item.date.month - 1; 
      if (item.description.toLowerCase().contains('gold')) {
        goldTotals[month] += (item.totalValue / 1000.0); // Scale down for chart (thousands)
      } else if (item.description.toLowerCase().contains('silver')) {
        silverTotals[month] += (item.totalValue / 1000.0); 
      }
    }

    List<FlSpot> goldSpots = [];
    List<FlSpot> silverSpots = [];
    double overallMaxY = 100;

    for (int i = 0; i < 12; i++) {
      if (goldTotals[i] > overallMaxY) overallMaxY = goldTotals[i];
      if (silverTotals[i] > overallMaxY) overallMaxY = silverTotals[i];
      goldSpots.add(FlSpot(i.toDouble(), goldTotals[i]));
      silverSpots.add(FlSpot(i.toDouble(), silverTotals[i]));
    }

    // Round up max to the nearest 100 for clean UI breathing room
    double roundedMaxY = ((overallMaxY / 100).ceil() * 100).toDouble();
    double dynamicInterval = (roundedMaxY / 5).clamp(20.0, double.infinity).toDouble();

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          // High threshold so it snaps to the closest month seamlessly without disappearing
          touchSpotThreshold: 500,
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: barData.color, strokeWidth: 2, dashArray: [4, 4]),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: barData.color ?? Colors.blue,
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => const Color(0xFF03045E).withValues(alpha: 0.9),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '₹${touchedSpot.y.toInt()}k',
                  TextStyle(
                    color: touchedSpot.bar.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: dynamicInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.15), // Very subtle grid
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                if (value.toInt() >= 0 && value.toInt() < 12) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      months[value.toInt()],
                      style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: dynamicInterval,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '₹${value.toInt()}k',
                    style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: goldSpots,
            isCurved: true,
            color: _goldColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _goldColor.withValues(alpha: 0.15),
            ),
          ),
          LineChartBarData(
            spots: silverSpots,
            isCurved: true,
            color: _silverColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _silverColor.withValues(alpha: 0.15),
            ),
          ),
        ],
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: roundedMaxY,
      ),
      // Animation curves for nice transitions
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildTimeFrameButton(String label) {
    final isSelected = _pieTimeFrame == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _pieTimeFrame = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF03045E) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          label == 'Month' ? 'Monthly' : 'Yearly',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyPieCard(bool isStacked) {
    double goldTotal = 0;
    double silverTotal = 0;
    
    final now = DateTime.now();
    final filteredItems = sharedMockItems.where((item) {
      if (_pieTimeFrame == 'Month') {
        return item.date.year == now.year && item.date.month == now.month;
      } else {
        return item.date.year == now.year;
      }
    });

    for (var item in filteredItems) {
      if (item.description.toLowerCase().contains('gold')) {
        goldTotal += item.totalValue;
      } else if (item.description.toLowerCase().contains('silver')) {
        silverTotal += item.totalValue;
      }
    }
    
    double total = goldTotal + silverTotal;
    int goldPercent = total == 0 ? 0 : ((goldTotal / total) * 100).round();
    int silverPercent = total == 0 ? 0 : 100 - goldPercent;

    final centerLabel = _pieTimeFrame == 'Month' ? _getCurrentMonthName() : now.year.toString();
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  const Text(
                    'Current Monthly Sales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF03045E),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTimeFrameButton('Month'),
                          _buildTimeFrameButton('Year'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: isStacked ? 250 : 180,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final shortestSide = constraints.maxWidth < constraints.maxHeight 
                      ? constraints.maxWidth 
                      : constraints.maxHeight;
                      
                  final double centerRadius = shortestSide * 0.28;
                  final double goldRadius = shortestSide * 0.18;
                  final double silverRadius = shortestSide * 0.15;
                  final double titleFontSize = (shortestSide * 0.06).clamp(10.0, 18.0);
                  final double monthFontSize = (shortestSide * 0.1).clamp(14.0, 32.0);

                  if (total == 0) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: centerRadius,
                            sections: [
                              PieChartSectionData(
                                color: Colors.grey.shade100,
                                value: 100,
                                title: '',
                                radius: silverRadius * 0.9,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              centerLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: monthFontSize,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            Text(
                              '₹0',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: titleFontSize * 0.8,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: centerRadius,
                          sections: [
                            PieChartSectionData(
                              color: _goldColor,
                              value: goldPercent.toDouble(),
                              title: '$goldPercent%',
                              radius: goldRadius,
                              titleStyle: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                              ),
                            ),
                            PieChartSectionData(
                              color: _silverColor,
                              value: silverPercent.toDouble(),
                              title: '$silverPercent%',
                              radius: silverRadius,
                              titleStyle: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            centerLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: monthFontSize,
                              color: const Color(0xFF03045E),
                            ),
                          ),
                          Text(
                            total >= 100000 
                                ? '₹${(total / 100000).toStringAsFixed(1)}L' 
                                : total >= 1000 
                                    ? '₹${(total / 1000).toStringAsFixed(1)}K' 
                                    : '₹${total.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: titleFontSize * 0.9,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (total == 0)
              Center(
                child: Column(
                  children: [
                    Text(
                      'No sales recorded in $centerLabel',
                      style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateNewBillPage(
                              nextSlNo: sharedMockItems.length + 1,
                            ),
                          ),
                        ).then((value) {
                          if (value == true) {
                            setState(() {});
                          }
                        });
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Generate Invoice'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF03045E),
                        side: const BorderSide(color: Color(0xFF03045E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              )
            else
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _buildLegendItem(_goldColor, 'Gold (${formatter.format(goldTotal)})'),
                    _buildLegendItem(_silverColor, 'Silver (${formatter.format(silverTotal)})'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getCurrentMonthName() {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[DateTime.now().month - 1];
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.receipt_long;
      case 2:
        return Icons.people;
      case 3:
        return Icons.settings;
      default:
        return Icons.dashboard;
    }
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard Overview';
      case 1:
        return 'Sales Billing';
      case 2:
        return 'Customers Management';
      case 3:
        return 'Settings Configuration';
      default:
        return 'Empty Page';
    }
  }
}

class SidebarItemWidget extends StatefulWidget {
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final String title;
  final int index;
  final int selectedIndex;
  final bool isSidebarExpanded;
  final Color appBarColor;
  final VoidCallback onTap;

  const SidebarItemWidget({
    super.key,
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.isSidebarExpanded,
    required this.appBarColor,
    required this.onTap,
  });

  @override
  State<SidebarItemWidget> createState() => _SidebarItemWidgetState();
}

class _SidebarItemWidgetState extends State<SidebarItemWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedIndex == widget.index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected 
                  ? widget.appBarColor 
                  : (isHovered ? Colors.black.withValues(alpha: 0.05) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
            ),
            transform: Matrix4.translationValues(0, (isHovered && !isSelected) ? -1.0 : 0.0, 0),
            padding: EdgeInsets.symmetric(
              vertical: 12,
              horizontal: widget.isSidebarExpanded ? 16 : 0,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: widget.isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  (isSelected || isHovered) ? widget.selectedIcon : widget.unselectedIcon,
                  color: isSelected 
                      ? Colors.white 
                      : (isHovered ? widget.appBarColor : Colors.black87),
                  size: 24,
                ),
                if (widget.isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        letterSpacing: -0.14,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ), 
        ), 
      ), // Closes MouseRegion
    ); // Closes Padding
  }
}

class _QuickActionItem {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickActionItem({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _KPIMetricItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String change;
  final bool isPositive;

  _KPIMetricItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
    required this.isPositive,
  });
}

class _DashboardHoverInvoiceRow extends StatefulWidget {
  final Bill bill;
  final NumberFormat formatCurrency;
  
  const _DashboardHoverInvoiceRow({
    required this.bill,
    required this.formatCurrency,
  });

  @override
  State<_DashboardHoverInvoiceRow> createState() => _DashboardHoverInvoiceRowState();
}

class _DashboardHoverInvoiceRowState extends State<_DashboardHoverInvoiceRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final formatCurrency = widget.formatCurrency;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
          final customer = customerProvider.getCustomerById(bill.customerId) ??
              Customer(
                id: bill.customerId,
                name: bill.customerName,
                phone: bill.customerPhone.isNotEmpty ? bill.customerPhone : 'NA',
                address: bill.customerAddress.isNotEmpty ? bill.customerAddress : 'NA',
                email: '',
                customerSince: bill.date,
              );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewSalesBillPage(bill: bill, customer: customer),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _isHovering ? Colors.blue.shade50 : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF03045E).withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, color: Color(0xFF03045E), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Inv: ${bill.invoiceNumber}  •  ${DateFormat('dd MMM hh:mm a').format(bill.date)}',
                      style: const TextStyle(color: Colors.black45, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency.format(bill.grandTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF03045E)),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: bill.isOneTime ? Colors.orange.shade50 : Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      bill.isOneTime ? 'Guest' : 'Registry',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: bill.isOneTime ? Colors.orange.shade700 : Colors.teal.shade700,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                color: _isHovering ? const Color(0xFF0077B6) : Colors.grey.shade300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final _QuickActionItem item;
  final bool isMobile;
  
  const _QuickActionCard({
    required this.item,
    required this.isMobile,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isMobile = widget.isMobile;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: isMobile 
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 10)
              : const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
            border: Border.all(
              color: _isHovered ? item.color : item.color.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.04 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
          ),
          child: isMobile 
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: item.color, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.label == "Summary PDF" ? "Summary" : item.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: item.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: item.color,
                      radius: 22,
                      child: Icon(item.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: item.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: item.color.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: item.color.withValues(alpha: 0.5),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _KPICard extends StatefulWidget {
  final _KPIMetricItem item;
  final bool isMobile;

  const _KPICard({
    required this.item,
    required this.isMobile,
  });

  @override
  State<_KPICard> createState() => _KPICardState();
}

class _KPICardState extends State<_KPICard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isMobile = widget.isMobile;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: isMobile ? null : 110,
        padding: isMobile 
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
            : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered 
                ? const Color(0xFF0077B6) 
                : Colors.black.withValues(alpha: 0.08), 
            width: 1.0, 
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.04 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.color.withValues(alpha: 0.20),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    item.icon, 
                    color: item.color, 
                    size: isMobile ? 12 : 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: isMobile ? 11.5 : 13.0, 
                      color: Colors.black54, 
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.value,
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF03045E),
                    ),
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