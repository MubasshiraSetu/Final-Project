import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_provider.dart';
import '../../utils/constants.dart';
import '../events/event_form_screen.dart';
import '../food/food_form_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _eventCount = 0;
  int _foodCount = 0;
  int _upcomingCount = 0;
  int _availableFoodCount = 0;
  int _userCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;

      final events = await supabase.from('events').select('id, status');
      final food = await supabase.from('food_items').select('id, is_available');
      final users = await supabase.from('user_list').select('id');

      if (mounted) {
        setState(() {
          _eventCount = (events as List).length;
          _upcomingCount = events.where((e) => e['status'] == 'upcoming').length;
          _foodCount = (food as List).length;
          _availableFoodCount = food.where((f) => f['is_available'] == true).length;
          _userCount = (users as List).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // FIX: Quick actions now navigate to the correct screens
  void _goCreateEvent() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EventFormScreen()),
    );
    if (result == true) _loadStats();
  }

  void _goAddFood() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FoodFormScreen()),
    );
    if (result == true) _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;
    final isAdmin = authProvider.isAdmin;
    final firstName = profile?.fullName.split(' ').first ?? 'there';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadStats,
        color: const Color(AppColors.primaryViolet),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              Color(AppColors.primaryGold)
                            ]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.celebration_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(colors: [
                            Color(AppColors.primaryViolet),
                            Color(AppColors.primaryGold)
                          ]).createShader(b),
                          child: Text(
                            'festivo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Refresh button
                        GestureDetector(
                          onTap: _loadStats,
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
                        const SizedBox(width: 10),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? const Color(AppColors.primaryViolet)
                                    .withOpacity(0.15)
                                : const Color(AppColors.accentCyan)
                                    .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isAdmin
                                  ? const Color(AppColors.primaryViolet)
                                      .withOpacity(0.4)
                                  : const Color(AppColors.accentCyan)
                                      .withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAdmin
                                    ? Icons.admin_panel_settings_rounded
                                    : Icons.person_outline_rounded,
                                size: 13,
                                color: isAdmin
                                    ? const Color(AppColors.primaryViolet)
                                    : const Color(AppColors.accentCyan),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAdmin ? 'Admin' : 'General',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isAdmin
                                      ? const Color(AppColors.primaryViolet)
                                      : const Color(AppColors.accentCyan),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Greeting
                    Text(
                      '${_greeting()}, $firstName 👋',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(AppColors.textPrimary),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAdmin
                          ? 'You have full access to manage events & food.'
                          : 'Here\'s an overview of all events and menus.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(AppColors.textSecondary),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Events',
                            value: _loading ? '—' : '$_eventCount',
                            subLabel: _loading ? '' : '$_upcomingCount upcoming',
                            icon: Icons.event_rounded,
                            gradient: const [
                              Color(AppColors.primaryViolet),
                              Color(0xFF9D4EDD)
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _StatCard(
                            label: 'Food Items',
                            value: _loading ? '—' : '$_foodCount',
                            subLabel: _loading
                                ? ''
                                : '$_availableFoodCount available',
                            icon: Icons.restaurant_menu_rounded,
                            gradient: const [
                              Color(AppColors.primaryGold),
                              Color(0xFFFF8C42)
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (isAdmin) ...[
                      const SizedBox(height: 14),
                      _StatCard(
                        label: 'Registered Users',
                        value: _loading ? '—' : '$_userCount',
                        subLabel: '',
                        icon: Icons.people_rounded,
                        gradient: const [
                          Color(AppColors.accentCyan),
                          Color(0xFF00B4D8),
                        ],
                        fullWidth: true,
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Quick actions (admin only)
                    if (isAdmin) ...[
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // FIX: onTap now actually navigates
                      _QuickActionCard(
                        emoji: '🎉',
                        title: 'Create an Event',
                        subtitle: 'Weddings, birthdays, concerts & more',
                        onTap: _goCreateEvent,
                      ),
                      const SizedBox(height: 12),
                      _QuickActionCard(
                        emoji: '🍽️',
                        title: 'Add Food Item',
                        subtitle: 'Manage menus for your events',
                        onTap: _goAddFood,
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(AppColors.primaryViolet)
                                .withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Text(isAdmin ? '🔑' : '👁️',
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAdmin ? 'Admin Access' : 'View Access',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(AppColors.primaryViolet),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isAdmin
                                      ? 'You can create, edit, and delete events and food items. You can also manage user roles.'
                                      : 'You can view all events and food items. Contact an admin to make changes.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(AppColors.textSecondary),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final IconData icon;
  final List<Color> gradient;
  final bool fullWidth;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.icon,
    required this.gradient,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundCard),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: fullWidth
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 14),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(AppColors.textSecondary),
                  ),
                ),
                if (subLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: gradient[0].withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard(
      {required this.emoji,
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
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(AppColors.textSecondary),
                      ),
                    ),
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
