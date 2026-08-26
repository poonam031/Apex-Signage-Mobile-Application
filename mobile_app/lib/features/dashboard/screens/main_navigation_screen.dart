import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../site_visit/screens/site_visit_detail_screen.dart';
import '../../jobs/screens/qr_scanner_screen.dart';
import '../../jobs/screens/job_detail_screen.dart';
import '../../inventory/screens/inventory_list_screen.dart';
import '../../attendance/screens/attendance_check_in_screen.dart';
import '../../attendance/screens/salary_slip_screen.dart';
import '../../rewards/screens/leaderboard_screen.dart';
import '../../quotations/screens/quotation_builder_screen.dart';
import '../../quotations/screens/invoice_list_screen.dart';
import '../../petty_cash/screens/petty_cash_screen.dart';
import '../../production/screens/dpr_entry_screen.dart';
import 'super_admin_dashboard.dart';
import 'field_boy_dashboard.dart';
import 'designer_dashboard.dart';
import 'installer_dashboard.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.role;

    final navItems = _getNavItems(role);
    final screens = _getScreens(role);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.print_outlined, size: 22, color: Colors.white),
            const SizedBox(width: 8),
            Text(_getAppTitle(role)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Rewards & Leaderboard',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.how_to_reg_outlined),
            tooltip: 'Smart Attendance Check-In',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceCheckInScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: screens[_currentIndex.clamp(0, screens.length - 1)],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex.clamp(0, navItems.length - 1),
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: navItems,
      ),
    );
  }

  String _getAppTitle(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Apex Signage Admin';
      case 'FIELD_BOY':
        return 'Field Boy Workspace';
      case 'DESIGNER_OPERATOR':
        return 'Designer & Machine Hub';
      case 'INSTALLATION_TEAM':
        return 'Installation Lead';
      default:
        return 'Apex Signage';
    }
  }

  List<BottomNavigationBarItem> _getNavItems(String role) {
    if (role == 'FIELD_BOY') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Tasks'),
        BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Attendance'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Expenses'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Points'),
      ];
    } else if (role == 'DESIGNER_OPERATOR') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'QR Scan'),
        BottomNavigationBarItem(icon: Icon(Icons.print_outlined), activeIcon: Icon(Icons.print), label: 'DPR'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Inventory'),
      ];
    } else if (role == 'INSTALLATION_TEAM') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Installations'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Petty Cash'),
        BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), activeIcon: Icon(Icons.how_to_reg), label: 'Attendance'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Leaderboard'),
      ];
    }

    // Default: Super Admin (Complete Business Control)
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Inventory'),
      BottomNavigationBarItem(icon: Icon(Icons.receipt_outlined), activeIcon: Icon(Icons.receipt), label: 'Invoices'),
      BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined), activeIcon: Icon(Icons.calculate), label: 'Rate Calc'),
      BottomNavigationBarItem(icon: Icon(Icons.request_quote_outlined), activeIcon: Icon(Icons.request_quote), label: 'Salary Slips'),
    ];
  }

  List<Widget> _getScreens(String role) {
    if (role == 'FIELD_BOY') {
      return [
        FieldBoyDashboard(onTabNavigate: (i) => setState(() => _currentIndex = i)),
        const AttendanceCheckInScreen(),
        const PettyCashScreen(),
        const LeaderboardScreen(),
      ];
    } else if (role == 'DESIGNER_OPERATOR') {
      return [
        DesignerDashboard(onTabNavigate: (i) => setState(() => _currentIndex = i)),
        const QrScannerScreen(),
        const DprEntryScreen(),
        const InventoryListScreen(),
      ];
    } else if (role == 'INSTALLATION_TEAM') {
      return [
        InstallerDashboard(onTabNavigate: (i) => setState(() => _currentIndex = i)),
        const PettyCashScreen(),
        const AttendanceCheckInScreen(),
        const LeaderboardScreen(),
      ];
    }

    // Super Admin Screens
    return [
      SuperAdminDashboard(onTabNavigate: (i) => setState(() => _currentIndex = i)),
      const InventoryListScreen(),
      const InvoiceListScreen(),
      const QuotationBuilderScreen(),
      const SalarySlipScreen(),
    ];
  }
}
