
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/food_model.dart';
import '../../services/auth_provider.dart';
import '../../services/event_service.dart';
import '../../services/food_service.dart';
import '../../utils/constants.dart';
import 'event_form_screen.dart';
import '../food/food_form_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _eventService = EventService();
  final _foodService = FoodService();

  late EventModel _event;
  List<FoodItem> _foodItems = [];
  bool _loadingFood = true;
  bool _updatingGuests = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadFood();
  }

  Future<void> _loadFood() async {
    setState(() => _loadingFood = true);
    try {
      final items = await _foodService.fetchFoodItems(eventId: _event.id);
      if (mounted) setState(() { _foodItems = items; _loadingFood = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingFood = false);
    }
  }

  Future<void> _refreshEvent() async {
    try {
      final updated = await _eventService.fetchEvent(_event.id);
      if (updated != null && mounted) setState(() => _event = updated);
    } catch (_) {}
  }

  Future<void> _updateGuestCount(int delta) async {
    final newCount = (_event.currentGuests + delta).clamp(0, _event.maxGuests > 0 ? _event.maxGuests : 9999);
    setState(() { _updatingGuests = true; });
    try {
      await _eventService.updateGuestCount(_event.id, newCount);
      await _refreshEvent();
      _changed = true;
    } catch (_) {} finally {
      if (mounted) setState(() => _updatingGuests = false);
    }
  }

  Future<void> _updateStatus(EventStatus status) async {
    try {
      await _eventService.updateStatus(_event.id, status);
      await _refreshEvent();
      _changed = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to ${status.label}',
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(AppColors.successGreen),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {}
  }

  void _openEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventFormScreen(event: _event)),
    );
    if (result == true) {
      _changed = true;
      await _refreshEvent();
    }
  }

  void _openAddFood() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FoodFormScreen(preselectedEventId: _event.id)),
    );
    if (result == true) _loadFood();
  }

  Color _statusColor(EventStatus s) {
    switch (s) {
      case EventStatus.upcoming:  return const Color(AppColors.accentCyan);
      case EventStatus.ongoing:   return const Color(AppColors.successGreen);
      case EventStatus.completed: return const Color(AppColors.textSecondary);
      case EventStatus.cancelled: return const Color(AppColors.errorRed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(AppColors.backgroundDark),
        appBar: AppBar(
          backgroundColor: const Color(AppColors.backgroundDark),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          title: Text(
            'Event Details',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 18),
          ),
          actions: [
            if (isAdmin)
              IconButton(
                onPressed: _openEdit,
                icon: const Icon(Icons.edit_outlined,
                    color: Color(AppColors.primaryViolet)),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async { await _refreshEvent(); await _loadFood(); },
          color: const Color(AppColors.primaryViolet),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Title & category
              Row(
                children: [
                  Text(_event.category.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _event.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(AppColors.textPrimary),
                          ),
                        ),
                        Text(
                          _event.category.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(_event.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusColor(_event.status).withOpacity(0.4)),
                    ),
                    child: Text(
                      _event.status.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(_event.status),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Info grid
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(AppColors.backgroundCard),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A3A)),
                ),
                child: Column(
                  children: [
                    _InfoRow(icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: DateFormat('EEEE, MMM d, yyyy').format(_event.eventDate)),
                    const Divider(color: Color(0xFF2A2A3A), height: 20),
                    _InfoRow(icon: Icons.access_time_rounded,
                        label: 'Time', value: _event.eventTime),
                    if (_event.location != null && _event.location!.isNotEmpty) ...[
                      const Divider(color: Color(0xFF2A2A3A), height: 20),
                      _InfoRow(icon: Icons.location_on_rounded,
                          label: 'Location', value: _event.location!),
                    ],
                  ],
                ),
              ),

              if (_event.description != null && _event.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.backgroundCard),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A3A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(AppColors.textSecondary),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(_event.description!,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(AppColors.textPrimary),
                              height: 1.5)),
                    ],
                  ),
                ),
              ],

              // Guest count manager
              if (_event.maxGuests > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.backgroundCard),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A3A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Guest Count',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(AppColors.textPrimary))),
                          const Spacer(),
                          Text(
                            '${_event.currentGuests} / ${_event.maxGuests}',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(AppColors.primaryViolet)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (_event.guestFillPercent ?? 0) / 100,
                          minHeight: 8,
                          backgroundColor: const Color(0xFF2A2A3A),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            (_event.guestFillPercent ?? 0) >= 90
                                ? const Color(AppColors.errorRed)
                                : const Color(AppColors.primaryViolet),
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _CounterButton(
                              icon: Icons.remove_rounded,
                              onTap: _updatingGuests || _event.currentGuests <= 0
                                  ? null
                                  : () => _updateGuestCount(-1),
                            ),
                            const SizedBox(width: 24),
                            _updatingGuests
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(AppColors.primaryViolet)))
                                : Text(
                                    '${_event.currentGuests}',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(AppColors.textPrimary)),
                                  ),
                            const SizedBox(width: 24),
                            _CounterButton(
                              icon: Icons.add_rounded,
                              onTap: _updatingGuests ||
                                      (_event.maxGuests > 0 &&
                                          _event.currentGuests >= _event.maxGuests)
                                  ? null
                                  : () => _updateGuestCount(1),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Status control (admin)
              if (isAdmin) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.backgroundCard),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A3A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Update Status',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(AppColors.textPrimary))),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: EventStatus.values.map((s) {
                          final sel = _event.status == s;
                          final color = _statusColor(s);
                          return GestureDetector(
                            onTap: sel ? null : () => _updateStatus(s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? color.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: sel ? color : const Color(0xFF2A2A3A)),
                              ),
                              child: Text(
                                s.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                  color: sel ? color : const Color(AppColors.textSecondary),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // Food items for this event
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Menu for this Event',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(AppColors.textPrimary),
                    ),
                  ),
                  const Spacer(),
                  if (isAdmin)
                    GestureDetector(
                      onTap: _openAddFood,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(AppColors.primaryGold),
                            Color(0xFFFF8C42)
                          ]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('Add Food', style: GoogleFonts.plusJakartaSans(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_loadingFood)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(AppColors.primaryGold)),
                ))
              else if (_foodItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.backgroundCard),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A3A)),
                  ),
                  child: Column(
                    children: [
                      const Text('🍽️', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text(
                        isAdmin
                            ? 'No food items linked to this event yet.\nTap "Add Food" to get started.'
                            : 'No food items have been added to this event.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: const Color(AppColors.textSecondary), height: 1.5),
                      ),
                    ],
                  ),
                )
              else
                ..._foodItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FoodChip(item: item),
                )),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(AppColors.primaryViolet).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(AppColors.primaryViolet)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: const Color(AppColors.textSecondary))),
            Text(value, style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: const Color(AppColors.textPrimary))),
          ],
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.3 : 1.0,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(AppColors.primaryViolet).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(AppColors.primaryViolet).withOpacity(0.4)),
          ),
          child: Icon(icon, color: const Color(AppColors.primaryViolet), size: 20),
        ),
      ),
    );
  }
}

class _FoodChip extends StatelessWidget {
  final FoodItem item;
  const _FoodChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundCard),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: Row(
        children: [
          Text(item.category.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: const Color(AppColors.textPrimary))),
                if (item.description != null && item.description!.isNotEmpty)
                  Text(item.description!, style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: const Color(AppColors.textSecondary)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(AppColors.primaryGold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.isAvailable
                      ? const Color(AppColors.successGreen).withOpacity(0.15)
                      : const Color(AppColors.errorRed).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isAvailable ? 'Available' : 'Unavailable',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: item.isAvailable
                        ? const Color(AppColors.successGreen)
                        : const Color(AppColors.errorRed),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}