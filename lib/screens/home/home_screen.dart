
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../events/events_screen.dart';
import '../food/food_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'dashboard_tab.dart';
import '../../models/user_model.dart';
import '../requests/my_requests_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadProfile();
    });
  }

  List<Widget> _buildTabs(bool isAdmin) {
    return [
      const DashboardTab(),
      const EventsScreen(),
      const FoodScreen(),
      if (!isAdmin) const MyRequestsScreen(),
      if (isAdmin) const AdminDashboardScreen(),
    ];
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppColors.backgroundCard),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign out?',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: const Color(AppColors.textPrimary)),
        ),
        content: Text(
          'You will be returned to the login screen.',
          style: GoogleFonts.plusJakartaSans(
              color: const Color(AppColors.textSecondary), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(AppColors.textSecondary))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(AppColors.errorRed),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final tabs = _buildTabs(isAdmin);

    // Reset index if it's now out of range
    final safeIndex = _selectedIndex >= tabs.length ? 0 : _selectedIndex;

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(AppColors.backgroundCard),
          border: Border(top: BorderSide(color: Color(0xFF2A2A3A), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: safeIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0)),
                _NavItem(
                    icon: Icons.event_rounded,
                    label: 'Events',
                    selected: safeIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1)),
                _NavItem(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Food',
                    selected: safeIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2)),
                // General users get a "Requests" tab (index 3)
                if (!isAdmin)
                  _NavItem(
                      icon: Icons.inbox_rounded,
                      label: 'Requests',
                      selected: safeIndex == 3,
                      onTap: () => setState(() => _selectedIndex = 3)),
                // Admins get the Admin panel tab (index 3)
                if (isAdmin)
                  _NavItem(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Admin',
                      selected: safeIndex == 3,
                      onTap: () => setState(() => _selectedIndex = 3)),
                _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    selected: false,
                    onTap: _showProfile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfile() {
    final auth = context.read<AuthProvider>();
    final profile = auth.profile;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(AppColors.backgroundCard),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3A),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(AppColors.primaryViolet),
              child: Text(
                (profile?.fullName.isNotEmpty == true
                        ? profile!.fullName[0]
                        : '?')
                    .toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              profile?.fullName ?? 'User',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(AppColors.textPrimary)),
            ),
            const SizedBox(height: 4),
            Text(
              profile?.email ?? '',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: const Color(AppColors.textSecondary)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: profile?.isAdmin == true
                    ? const Color(AppColors.primaryViolet).withOpacity(0.2)
                    : const Color(AppColors.accentCyan).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: profile?.isAdmin == true
                      ? const Color(AppColors.primaryViolet).withOpacity(0.5)
                      : const Color(AppColors.accentCyan).withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    profile?.isAdmin == true
                        ? Icons.admin_panel_settings_rounded
                        : Icons.person_outline_rounded,
                    size: 14,
                    color: profile?.isAdmin == true
                        ? const Color(AppColors.primaryViolet)
                        : const Color(AppColors.accentCyan),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    profile?.role == UserRole.admin ? 'Admin' : 'General',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: profile?.isAdmin == true
                          ? const Color(AppColors.primaryViolet)
                          : const Color(AppColors.accentCyan),
                    ),
                  ),
                ],
              ),
            ),
            if (profile?.phone != null) ...[
              const SizedBox(height: 8),
              Text(
                profile!.phone!,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(AppColors.textSecondary)),
              ),
            ],
            const SizedBox(height: 28),
            const Divider(color: Color(0xFF2A2A3A)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _logout();
                },
                icon: const Icon(Icons.logout_rounded,
                    color: Color(AppColors.errorRed), size: 18),
                label: Text('Sign out',
                    style: GoogleFonts.plusJakartaSans(
                        color: const Color(AppColors.errorRed),
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(AppColors.errorRed)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(AppColors.primaryViolet).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: selected
                    ? const Color(AppColors.primaryViolet)
                    : const Color(AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? const Color(AppColors.primaryViolet)
                    : const Color(AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}