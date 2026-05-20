import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../services/auth_provider.dart';
import '../../services/event_service.dart';
import '../../utils/constants.dart';
import 'event_form_screen.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _service = EventService();
  List<EventModel> _events = [];
  List<EventModel> _filtered = [];
  bool _loading = true;
  String _search = '';
  EventStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final events = await _service.fetchEvents();
      // Filter out only pending/rejected requests — approved ones are real events
      final realEvents = events.where((e) =>
          e.requestStatus != RequestStatus.pending &&
          e.requestStatus != RequestStatus.rejected
      ).toList();
      if (mounted) {
        setState(() {
          _events = realEvents;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered = _events.where((e) {
      final matchSearch = e.title.toLowerCase().contains(q) ||
          (e.location?.toLowerCase().contains(q) ?? false) ||
          (e.description?.toLowerCase().contains(q) ?? false);
      final matchStatus = _filterStatus == null || e.status == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  Future<void> _delete(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppColors.backgroundCard),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete event?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(AppColors.textPrimary))),
        content: Text('"${event.title}" will be permanently removed.',
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
              child: Text('Delete',
                  style: GoogleFonts.plusJakartaSans(
                      color: const Color(AppColors.errorRed),
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteEvent(event.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Event deleted', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(AppColors.successGreen),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {}
  }

  void _openForm({EventModel? event}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventFormScreen(event: event)),
    );
    if (result == true) _load();
  }

  void _openDetail(EventModel event) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

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
                          'Events',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(AppColors.textPrimary),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          isAdmin ? 'Tap an event to view details' : 'View only — tap to see details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  GestureDetector(
                    onTap: _load,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(AppColors.backgroundCard),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A3A)),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: Color(AppColors.textSecondary), size: 20),
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _openForm(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(AppColors.primaryViolet),
                            Color(0xFF9D4EDD)
                          ]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                onChanged: (v) => setState(() {
                  _search = v;
                  _applyFilter();
                }),
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(AppColors.textPrimary), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search events…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: const Color(AppColors.backgroundCard),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintStyle: const TextStyle(
                      color: Color(AppColors.textSecondary), fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Status filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filterStatus == null,
                    color: const Color(AppColors.primaryViolet),
                    onTap: () => setState(() {
                      _filterStatus = null;
                      _applyFilter();
                    }),
                  ),
                  const SizedBox(width: 8),
                  ...EventStatus.values.map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: s.label,
                          selected: _filterStatus == s,
                          color: _statusColor(s),
                          onTap: () => setState(() {
                            _filterStatus = _filterStatus == s ? null : s;
                            _applyFilter();
                          }),
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(AppColors.primaryViolet)))
                  : _filtered.isEmpty
                      ? _EmptyState(
                          isAdmin: isAdmin,
                          onAdd: isAdmin ? () => _openForm() : null)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(AppColors.primaryViolet),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _EventCard(
                              event: _filtered[i],
                              isAdmin: isAdmin,
                              onTap: () => _openDetail(_filtered[i]),
                              onEdit: isAdmin
                                  ? () => _openForm(event: _filtered[i])
                                  : null,
                              onDelete: isAdmin
                                  ? () => _delete(_filtered[i])
                                  : null,
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(EventStatus s) {
    switch (s) {
      case EventStatus.upcoming:  return const Color(AppColors.accentCyan);
      case EventStatus.ongoing:   return const Color(AppColors.successGreen);
      case EventStatus.completed: return const Color(AppColors.textSecondary);
      case EventStatus.cancelled: return const Color(AppColors.errorRed);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : const Color(AppColors.backgroundCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : const Color(0xFF2A2A3A),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? color : const Color(AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _EventCard({
    required this.event,
    required this.isAdmin,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color _statusColor() {
    switch (event.status) {
      case EventStatus.upcoming:   return const Color(AppColors.accentCyan);
      case EventStatus.ongoing:    return const Color(AppColors.successGreen);
      case EventStatus.completed:  return const Color(AppColors.textSecondary);
      case EventStatus.cancelled:  return const Color(AppColors.errorRed);
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(event.category.emoji,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.title,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.status.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (event.description != null &&
                    event.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.description!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(AppColors.textSecondary),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (event.maxGuests > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 13,
                          color: const Color(AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      Text(
                        '${event.currentGuests} / ${event.maxGuests} guests',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (event.guestFillPercent ?? 0) / 100,
                      minHeight: 4,
                      backgroundColor: const Color(0xFF2A2A3A),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (event.guestFillPercent ?? 0) >= 90
                            ? const Color(AppColors.errorRed)
                            : const Color(AppColors.primaryViolet),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(color: Color(0xFF2A2A3A), height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Info(
                        icon: Icons.calendar_today_rounded,
                        text: DateFormat('MMM d, yyyy').format(event.eventDate)),
                    const SizedBox(width: 16),
                    _Info(
                        icon: Icons.access_time_rounded,
                        text: event.eventTime),
                    if (event.location != null &&
                        event.location!.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Info(
                            icon: Icons.location_on_rounded,
                            text: event.location!,
                            expand: true),
                      ),
                    ],
                    const Spacer(),
                    if (isAdmin) ...[
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(AppColors.primaryViolet)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit',
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: Color(AppColors.errorRed)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool expand;

  const _Info({required this.icon, required this.text, this.expand = false});

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
  final bool isAdmin;
  final VoidCallback? onAdd;
  const _EmptyState({required this.isAdmin, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No events yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'Tap + to create your first event'
                : 'No events have been created yet.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(AppColors.textSecondary),
            ),
          ),
          if (isAdmin && onAdd != null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAdd,
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
                child: Text(
                  'Create Event',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}