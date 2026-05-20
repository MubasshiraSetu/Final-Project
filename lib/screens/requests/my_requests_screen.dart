// lib/screens/requests/my_requests_screen.dart
//
// Shows a general user's own submitted event requests and their status.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../utils/constants.dart';
import 'request_event_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _service = EventService();
  List<EventModel> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final requests = await _service.fetchMyRequests();
      if (mounted) setState(() { _requests = requests; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openRequest() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RequestEventScreen()),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Requests',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(AppColors.textPrimary),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your event requests',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _openRequest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(AppColors.primaryViolet),
                          Color(0xFF9D4EDD),
                        ]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'New Request',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(AppColors.primaryViolet)))
                  : _requests.isEmpty
                      ? _EmptyState(onRequest: _openRequest)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(AppColors.primaryViolet),
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: _requests.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) =>
                                _RequestCard(request: _requests[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final EventModel request;
  const _RequestCard({required this.request});

  Color _statusColor(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending:  return const Color(AppColors.primaryGold);
      case RequestStatus.approved: return const Color(AppColors.successGreen);
      case RequestStatus.rejected: return const Color(AppColors.errorRed);
    }
  }

  IconData _statusIcon(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending:  return Icons.hourglass_top_rounded;
      case RequestStatus.approved: return Icons.check_circle_rounded;
      case RequestStatus.rejected: return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = request.requestStatus ?? RequestStatus.pending;
    final color = _statusColor(rs);

    return Container(
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundCard),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(request.category.emoji,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  request.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(AppColors.textPrimary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(rs), size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      rs.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (request.description != null &&
              request.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.description!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(AppColors.textSecondary),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2A2A3A), height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              _Info(Icons.calendar_today_rounded,
                  DateFormat('MMM d, yyyy').format(request.eventDate)),
              const SizedBox(width: 14),
              _Info(Icons.access_time_rounded, request.eventTime),
              if (request.location != null) ...[
                const SizedBox(width: 14),
                Expanded(
                    child: _Info(Icons.location_on_rounded, request.location!,
                        expand: true)),
              ],
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'Submitted ${DateFormat('MMM d, h:mm a').format(request.createdAt)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(AppColors.textSecondary),
            ),
          ),

          if (rs == RequestStatus.approved) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(AppColors.successGreen).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded,
                      color: Color(AppColors.successGreen), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Your event is now live as an upcoming event!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(AppColors.successGreen),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (rs == RequestStatus.rejected) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(AppColors.errorRed).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(AppColors.errorRed), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'This request was not approved.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(AppColors.errorRed),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool expand;

  const _Info(this.icon, this.text, {this.expand = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(AppColors.textSecondary)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(AppColors.textSecondary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRequest;
  const _EmptyState({required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('No requests yet',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(AppColors.textPrimary))),
          const SizedBox(height: 8),
          Text('Submit an event request for admin approval',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(AppColors.textSecondary))),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRequest,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Color(AppColors.primaryViolet),
                  Color(0xFF9D4EDD)
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Submit Request',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
