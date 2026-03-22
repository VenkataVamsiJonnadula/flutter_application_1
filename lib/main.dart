import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'billing/billing_page.dart';

void main() {
  runApp(const DashboardApp());
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
  final Color _sidebarActiveColor = const Color(0xFF0077B6);

  // Layout Colors
  final Color _pageBackgroundColor = const Color(0xFFF0F2F5); // Pleasant light grey spreading the whole page

  // Metal Colors
  final Color _goldColor = const Color(0xFFFFD700);
  final Color _silverColor = const Color(0xFFC0C0C0);

  // Chart state
  int _selectedYear = DateTime.now().year;
  late final List<int> _availableYears;

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
    final isSmallScreen = MediaQuery.of(context).size.width < 800;
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
      drawer: isSmallScreen
          ? Drawer(
              backgroundColor: _sidebarColor,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: _appBarColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: _sidebarColor,
                          child: Icon(Icons.person, size: 30, color: _appBarColor),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'User Name',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDrawerItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
                  _buildDrawerItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Billing', 1),
                  _buildDrawerItem(Icons.settings_outlined, Icons.settings, 'Settings', 2),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          // NavigationRail acts as the collapsible sidebar on larger screens
          if (!isSmallScreen)
            Container(
              color: _sidebarColor,
              child: NavigationRail(
                extended: _isSidebarExpanded,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: _sidebarColor,
                indicatorColor: _sidebarActiveColor,
                selectedIconTheme: const IconThemeData(color: Colors.white, size: 28),
                unselectedIconTheme: const IconThemeData(color: Colors.black, size: 28),
                selectedLabelTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: Text('Billing'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
              ),
            ),
          // Main Body Content
          Expanded(
            child: _buildMainContent(isMediumScreen),
          ),
        ],
      ),
    );
  }

  // Helper method to build drawer items for small screens
  Widget _buildDrawerItem(IconData unselectedIcon, IconData selectedIcon, String title, int index) {
    final isSelected = _selectedIndex == index;

    return Container(
      color: isSelected ? _sidebarActiveColor : Colors.transparent,
      child: ListTile(
        leading: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          color: isSelected ? Colors.white : Colors.black,
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        selected: isSelected,
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context); // Close the drawer upon selection
        },
      ),
    );
  }

  // Returns the content for the currently selected tab
  Widget _buildMainContent(bool shouldStackCharts) {
    if (_selectedIndex == 1) {
      return const BillingPage();
    }

    if (_selectedIndex != 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForIndex(_selectedIndex),
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              _getTitleForIndex(_selectedIndex),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'This is a blank canvas for your ${_getTitleForIndex(_selectedIndex).toLowerCase()}.\nYou can start adding widgets here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    final chartContent = shouldStackCharts
        ? Column(
            children: [
              _buildYearlySalesCard(),
              const SizedBox(height: 24),
              _buildMonthlyPieCard(),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildYearlySalesCard()),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildMonthlyPieCard()),
            ],
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: chartContent,
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
    final randomSeed = _selectedYear * 10;
    
    List<FlSpot> goldSpots = [];
    List<FlSpot> silverSpots = [];
    for (int i = 0; i < 12; i++) {
      double g = 40 + (i * 2.5) + ((i * randomSeed) % 20).toDouble();
      double s = 20 + (i * 1.8) + (((i+5) * randomSeed) % 15).toDouble();
      goldSpots.add(FlSpot(i.toDouble(), g));
      silverSpots.add(FlSpot(i.toDouble(), s));
    }

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
                  '\$${touchedSpot.y.toInt()}k',
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
          horizontalInterval: 20,
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
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '\$${value.toInt()}k',
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
        maxY: 100,
      ),
      // Animation curves for nice transitions
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildMonthlyPieCard() {
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
                              value: 65,
                              title: '65%',
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
                              value: 35,
                              title: '35%',
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
        return 'Settings Configuration';
      default:
        return 'Empty Page';
    }
  }
}
