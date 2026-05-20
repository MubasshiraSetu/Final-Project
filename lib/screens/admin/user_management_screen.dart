// lib/screens/admin/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../utils/constants.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserProfile> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await context.read<AuthProvider>().fetchAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleRole(UserProfile user) async {
    final myId = context.read<AuthProvider>().profile?.id;
    if (user.id == myId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("You can't change your own role.",
            style: GoogleFonts.plusJakartaSans()),
        backgroundColor: const Color(AppColors.errorRed),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    final newRole =
        user.isAdmin ? UserRole.general : UserRole.admin;
    final label = newRole == UserRole.admin ? 'Admin' : 'General User';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppColors.backgroundCard),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Role?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(AppColors.textPrimary))),
        content: Text(
            'Set ${user.fullName} as $label?',
            style: GoogleFonts.plusJakartaSans(
                color: const Color(AppColors.textSecondary), fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.plusJakartaSans(
                      color: const Color(AppColors.textSecondary)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Confirm',
                  style: GoogleFonts.plusJakartaSans(
                      color: const Color(AppColors.primaryViolet),
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await context
        .read<AuthProvider>()
        .updateUserRole(user.id, newRole);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: result.success
            ? const Color(AppColors.successGreen)
            : const Color(AppColors.errorRed),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      if (result.success) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().profile?.id;

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Management',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(AppColors.textPrimary),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Manage roles for all users',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(AppColors.textSecondary)),
                  ),
                ],
              ),
            ),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _StatPill(
                    label: 'Total',
                    count: _users.length,
                    color: const Color(AppColors.primaryViolet),
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    label: 'Admins',
                    count: _users.where((u) => u.isAdmin).length,
                    color: const Color(AppColors.primaryGold),
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    label: 'General',
                    count: _users.where((u) => !u.isAdmin).length,
                    color: const Color(AppColors.accentCyan),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(AppColors.primaryViolet)))
                  : _users.isEmpty
                      ? Center(
                          child: Text(
                          'No users found.',
                          style: GoogleFonts.plusJakartaSans(
                              color: const Color(AppColors.textSecondary)),
                        ))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(AppColors.primaryViolet),
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: _users.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final user = _users[i];
                              final isMe = user.id == myId;
                              return _UserTile(
                                user: user,
                                isMe: isMe,
                                onToggleRole: () => _toggleRole(user),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatPill(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserProfile user;
  final bool isMe;
  final VoidCallback onToggleRole;

  const _UserTile(
      {required this.user, required this.isMe, required this.onToggleRole});

  @override
  Widget build(BuildContext context) {
    final roleColor = user.isAdmin
        ? const Color(AppColors.primaryViolet)
        : const Color(AppColors.accentCyan);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundCard),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: roleColor.withOpacity(0.2),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: roleColor,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.fullName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(AppColors.textPrimary),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(AppColors.primaryGold)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'You',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(AppColors.primaryGold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(AppColors.textSecondary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Role toggle
          GestureDetector(
            onTap: isMe ? null : onToggleRole,
            child: Opacity(
              opacity: isMe ? 0.4 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: roleColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.isAdmin
                          ? Icons.admin_panel_settings_rounded
                          : Icons.person_outline_rounded,
                      size: 13,
                      color: roleColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.role.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
