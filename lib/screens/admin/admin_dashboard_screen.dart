import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import 'user_management_screen.dart';
import 'admin_requests_screen.dart';

/// A dedicated admin dashboard that shows stats and gives direct access
/// to User Management plus other admin-only admin functions.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  int _totalUsers = 0;
  int _adminCount = 0;
  int _generalCount = 0;
  int _totalEvents = 0;
  int _totalFood = 0;
  int _pendingRequests = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final users = await supabase.from('user_list').select('id, role');
      // Count real events: all events EXCEPT pending/rejected requests
      final events = await supabase.from('events').select('id, notes');
      final realEventCount = (events as List).where((e) {
        final notes = e['notes'] as String?;
        return notes == null ||
               (!notes.startsWith('REQ:pending') && !notes.startsWith('REQ:rejected'));
      }).length;
      final food = await supabase.from('food_items').select('id');
      final requests = await supabase.from('events').select('id').like('notes', 'REQ:pending%');

      if (mounted) {
        setState(() {
          _totalUsers = (users as List).length;
          _adminCount = users.where((u) => u['role'] == 'admin').length;
          _generalCount = users.where((u) => u['role'] == 'general').length;
          _totalEvents = realEventCount;
          _totalFood = (food as List).length;
          _pendingRequests = (requests as List).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: const Color(AppColors.primaryViolet),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(AppColors.primaryViolet),
                        Color(AppColors.primaryGold),
                      ]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(AppColors.textPrimary),
                          ),
                        ),
                        Text(
                          'System overview & controls',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _load,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(AppColors.backgroundCard),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2A2A3A)),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          size: 18,
                          color: Color(AppColors.textSecondary)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'System Stats',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(AppColors.textSecondary),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Total Users',
                      value: _loading ? '—' : '$_totalUsers',
                      icon: Icons.people_rounded,
                      color: const Color(AppColors.primaryViolet),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Admins',
                      value: _loading ? '—' : '$_adminCount',
                      icon: Icons.admin_panel_settings_rounded,
                      color: const Color(AppColors.primaryGold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'General',
                      value: _loading ? '—' : '$_generalCount',
                      icon: Icons.person_outline_rounded,
                      color: const Color(AppColors.accentCyan),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Events',
                      value: _loading ? '—' : '$_totalEvents',
                      icon: Icons.event_rounded,
                      color: const Color(AppColors.primaryViolet),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Food Items',
                      value: _loading ? '—' : '$_totalFood',
                      icon: Icons.restaurant_menu_rounded,
                      color: const Color(AppColors.primaryGold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Pending Req.',
                      value: _loading ? '—' : '$_pendingRequests',
                      icon: Icons.inbox_rounded,
                      color: _pendingRequests > 0
                          ? const Color(AppColors.errorRed)
                          : const Color(AppColors.successGreen),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Admin Actions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(AppColors.textSecondary),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              _ActionTile(
                icon: Icons.inbox_rounded,
                color: const Color(AppColors.primaryGold),
                title: 'Event Requests',
                subtitle: 'Review and approve user-submitted event requests',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminRequestsScreen()),
                ),
              ),
              const SizedBox(height: 12),

              _ActionTile(
                icon: Icons.manage_accounts_rounded,
                color: const Color(AppColors.primaryViolet),
                title: 'Manage Users',
                subtitle: 'View all users and manage their roles',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UserManagementScreen()),
                ),
              ),
              const SizedBox(height: 12),

              _ActionTile(
                icon: Icons.info_outline_rounded,
                color: const Color(AppColors.accentCyan),
                title: 'About Festivo',
                subtitle: 'Version info and system details',
                onTap: () => _showAbout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppColors.backgroundCard),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('About Festivo',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(AppColors.textPrimary))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎉 Festivo — University Event & Food Management',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: const Color(AppColors.textPrimary),
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('A role-based platform to manage university events and catering menus with real-time sync.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: const Color(AppColors.textSecondary),
                    height: 1.5)),
            const SizedBox(height: 10),
            Text('Backend: Supabase (PostgreSQL + RLS)',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: const Color(AppColors.textSecondary))),
            Text('Framework: Flutter',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: const Color(AppColors.textSecondary))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(AppColors.primaryViolet),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(AppColors.backgroundCard),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A3A)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(AppColors.textPrimary),
                        )),
                    Text(subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(AppColors.textSecondary),
                        )),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Color(AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}