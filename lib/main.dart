import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'billing/billing_page.dart';
import 'customers/customers_page.dart';
import 'providers/customer_provider.dart';
import 'data/mock_data.dart';

void main() {
  initializeSharedMockData();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ],
      child: const DashboardApp(),
    ),
  );
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jewellery Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF03045E)),
      ),
      home: const DashboardLandingPage(),
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

  @override
  void initState() {
    super.initState();
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
          CircleAvatar(
            backgroundColor: _sidebarColor,
            child: Icon(Icons.person, color: _appBarColor),
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
                      const SizedBox(height: 24),
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

  // Helper to build dashboard charts
  Widget _buildDashboardContent(bool shouldStackCharts) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildYearlySalesCard(),
            const SizedBox(height: 24),
            _buildMonthlyPieCard(),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _buildYearlySalesCard()),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildMonthlyPieCard()),
          ],
        ),
      ),
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

  Widget _buildYearlySalesCard() {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
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
            const SizedBox(height: 36),
            SizedBox(
              height: 300,
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

  Widget _buildMonthlyPieCard() {
    double goldTotal = 0;
    double silverTotal = 0;
    
    final now = DateTime.now();
    final monthItems = sharedMockItems.where((item) => item.date.year == now.year && item.date.month == now.month);
    for (var item in monthItems) {
      if (item.description.toLowerCase().contains('gold')) {
        goldTotal += item.totalValue;
      } else if (item.description.toLowerCase().contains('silver')) {
        silverTotal += item.totalValue;
      }
    }
    
    double total = goldTotal + silverTotal;
    int goldPercent = total == 0 ? 50 : ((goldTotal / total) * 100).round();
    int silverPercent = total == 0 ? 50 : 100 - goldPercent;

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Month Percentage',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF03045E),
              ),
            ),
            const SizedBox(height: 48),
            AspectRatio(
              aspectRatio: 1.3,
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
                      Text(
                        _getCurrentMonthName(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: monthFontSize,
                          color: const Color(0xFF03045E),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 48),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildLegendItem(_goldColor, 'Gold'),
                _buildLegendItem(_silverColor, 'Silver'),
              ],
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