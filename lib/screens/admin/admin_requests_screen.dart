// lib/screens/admin/admin_requests_screen.dart
//
// Admin-only screen to review, approve, or reject user-submitted event requests.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../utils/constants.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen>
    with SingleTickerProviderStateMixin {
  final _service = EventService();
  late TabController _tabController;
  List<EventModel> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final requests = await _service.fetchPendingRequests();
      if (mounted) setState(() { _all = requests; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<EventModel> get _pending =>
      _all.where((r) => r.requestStatus == RequestStatus.pending).toList();
  List<EventModel> get _approved =>
      _all.where((r) => r.requestStatus == RequestStatus.approved).toList();
  List<EventModel> get _rejected =>
      _all.where((r) => r.requestStatus == RequestStatus.rejected).toList();

  Future<void> _approve(EventModel req) async {
    final confirm = await _confirmDialog(
      title: 'Approve request?',
      body:
          '"${req.title}" will be published as an upcoming event visible to all users.',
      confirmLabel: 'Approve',
      confirmColor: const Color(AppColors.successGreen),
    );
    if (confirm != true) return;
    try {
      await _service.approveRequest(req.id);
      _load();
      _snack('✅ Event approved and published!',
          color: const Color(AppColors.successGreen));
    } catch (_) {
      _snack('Failed to approve. Try again.', error: true);
    }
  }

  Future<void> _reject(EventModel req) async {
    final confirm = await _confirmDialog(
      title: 'Reject request?',
      body: '"${req.title}" will be marked as rejected.',
      confirmLabel: 'Reject',
      confirmColor: const Color(AppColors.errorRed),
    );
    if (confirm != true) return;
    try {
      await _service.rejectRequest(req.id);
      _load();
      _snack('Request rejected.', color: const Color(AppColors.textSecondary));
    } catch (_) {
      _snack('Failed to reject. Try again.', error: true);
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppColors.backgroundCard),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(AppColors.textPrimary))),
        content: Text(body,
            style: GoogleFonts.plusJakartaSans(
                color: const Color(AppColors.textSecondary), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(AppColors.textSecondary))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: GoogleFonts.plusJakartaSans(
                    color: confirmColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool error = false, Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans()),
      backgroundColor: color ??
          (error
              ? const Color(AppColors.errorRed)
              : const Color(AppColors.successGreen)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event Requests',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, fontSize: 18)),
            if (_pending.isNotEmpty)
              Text('${_pending.length} pending approval',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(AppColors.primaryGold))),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(AppColors.primaryViolet),
          labelColor: const Color(AppColors.primaryViolet),
          unselectedLabelColor: const Color(AppColors.textSecondary),
          labelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: 'Pending (${_pending.length})'),
            Tab(text: 'Approved (${_approved.length})'),
            Tab(text: 'Rejected (${_rejected.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(AppColors.primaryViolet)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(AppColors.primaryViolet),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RequestList(
                    requests: _pending,
                    emptyText: 'No pending requests',
                    emptyEmoji: '✅',
                    onApprove: _approve,
                    onReject: _reject,
                    showActions: true,
                  ),
                  _RequestList(
                    requests: _approved,
                    emptyText: 'No approved requests yet',
                    emptyEmoji: '📭',
                    showActions: false,
                  ),
                  _RequestList(
                    requests: _rejected,
                    emptyText: 'No rejected requests',
                    emptyEmoji: '📭',
                    showActions: false,
                    allowReinstate: true,
                    onApprove: _approve,
                  ),
                ],
              ),
            ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final List<EventModel> requests;
  final String emptyText;
  final String emptyEmoji;
  final bool showActions;
  final bool allowReinstate;
  final Future<void> Function(EventModel)? onApprove;
  final Future<void> Function(EventModel)? onReject;

  const _RequestList({
    required this.requests,
    required this.emptyText,
    required this.emptyEmoji,
    required this.showActions,
    this.allowReinstate = false,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emptyEmoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(emptyText,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(AppColors.textSecondary))),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _AdminRequestCard(
        request: requests[i],
        showActions: showActions,
        allowReinstate: allowReinstate,
        onApprove: onApprove,
        onReject: onReject,
      ),
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  final EventModel request;
  final bool showActions;
  final bool allowReinstate;
  final Future<void> Function(EventModel)? onApprove;
  final Future<void> Function(EventModel)? onReject;

  const _AdminRequestCard({
    required this.request,
    required this.showActions,
    this.allowReinstate = false,
    this.onApprove,
    this.onReject,
  });

  Future<String?> _getRequesterEmail(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('user_list')
          .select('email, full_name')
          .eq('id', userId)
          .single();
      return '${data['full_name']} (${data['email']})';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundCard),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(request.category.emoji,
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  request.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(AppColors.textPrimary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryViolet).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.category.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(AppColors.primaryViolet),
                  ),
                ),
              ),
            ],
          ),

          if (request.description != null &&
              request.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                request.description!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(AppColors.textSecondary),
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2A2A3A), height: 1),
          const SizedBox(height: 12),

          // Details grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Detail(Icons.calendar_today_rounded,
                  DateFormat('MMM d, yyyy').format(request.eventDate)),
              _Detail(Icons.access_time_rounded, request.eventTime),
              if (request.location != null && request.location!.isNotEmpty)
                _Detail(Icons.location_on_rounded, request.location!),
              if (request.maxGuests > 0)
                _Detail(Icons.people_rounded, '${request.maxGuests} guests'),
            ],
          ),

          const SizedBox(height: 10),

          // Requester info
          FutureBuilder<String?>(
            future: _getRequesterEmail(request.userId),
            builder: (_, snap) {
              final name = snap.data ?? 'Loading...';
              return Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14,
                      color: Color(AppColors.textSecondary)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'By: $name',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(AppColors.textSecondary),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, h:mm a').format(request.createdAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(AppColors.textSecondary),
                    ),
                  ),
                ],
              );
            },
          ),

          // Action buttons (for pending tab)
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onReject?.call(request),
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: Color(AppColors.errorRed)),
                    label: Text('Reject',
                        style: GoogleFonts.plusJakartaSans(
                            color: const Color(AppColors.errorRed),
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(AppColors.errorRed)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => onApprove?.call(request),
                    icon: const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white),
                    label: Text('Approve & Publish',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.successGreen),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Reinstate rejected requests
          if (allowReinstate && onApprove != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onApprove?.call(request),
                icon: const Icon(Icons.refresh_rounded,
                    size: 16, color: Color(AppColors.primaryViolet)),
                label: Text('Approve Now',
                    style: GoogleFonts.plusJakartaSans(
                        color: const Color(AppColors.primaryViolet),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: Color(AppColors.primaryViolet)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Detail(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(AppColors.textSecondary)),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(AppColors.textSecondary))),
      ],
    );
  }
}
