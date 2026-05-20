import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_button.dart';

class EventFormScreen extends StatefulWidget {
  final EventModel? event;
  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EventService();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _guestsCtrl;

  EventCategory _category = EventCategory.other;
  EventStatus _status = EventStatus.upcoming;
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  bool _saving = false;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _guestsCtrl =
        TextEditingController(text: e?.maxGuests.toString() ?? '0');
    _category = e?.category ?? EventCategory.other;
    _status = e?.status ?? EventStatus.upcoming;
    _eventDate = e?.eventDate;
    if (e != null) {
      final parts = e.eventTime.split(':');
      _eventTime = TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _guestsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(AppColors.primaryViolet),
            surface: Color(AppColors.backgroundCard),
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _eventDate = date);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _eventTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(AppColors.primaryViolet),
            surface: Color(AppColors.backgroundCard),
          ),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _eventTime = t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      _showError('Please select a date');
      return;
    }
    if (_eventTime == null) {
      _showError('Please select a time');
      return;
    }

    setState(() => _saving = true);

    final timeStr =
        '${_eventTime!.hour.toString().padLeft(2, '0')}:${_eventTime!.minute.toString().padLeft(2, '0')}';

    final event = EventModel(
      id: widget.event?.id ?? '',
      userId: '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: _category,
      eventDate: _eventDate!,
      eventTime: timeStr,
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      maxGuests: int.tryParse(_guestsCtrl.text) ?? 0,
      currentGuests: widget.event?.currentGuests ?? 0,
      status: _status,
      createdAt: DateTime.now(),
    );

    try {
      if (_isEdit) {
        await _service.updateEvent(widget.event!.id, event);
      } else {
        await _service.createEvent(event);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('Failed to save. Please try again.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans()),
      backgroundColor: const Color(AppColors.errorRed),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Event' : 'New Event',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _label('Event Title *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: _inputStyle(),
              decoration: _inputDeco('e.g. Birthday Party'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),

            const SizedBox(height: 20),
            _label('Category'),
            const SizedBox(height: 8),
            _CategoryPicker(
              selected: _category,
              onChanged: (c) => setState(() => _category = c),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Date *'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(AppColors.backgroundCard),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF2A2A3A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Color(AppColors.textSecondary)),
                              const SizedBox(width: 8),
                              Text(
                                _eventDate == null
                                    ? 'Pick date'
                                    : DateFormat('MMM d, yyyy')
                                        .format(_eventDate!),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: _eventDate == null
                                      ? const Color(AppColors.textSecondary)
                                      : const Color(AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Time *'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(AppColors.backgroundCard),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF2A2A3A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 16,
                                  color: Color(AppColors.textSecondary)),
                              const SizedBox(width: 8),
                              Text(
                                _eventTime == null
                                    ? 'Pick time'
                                    : _eventTime!.format(context),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: _eventTime == null
                                      ? const Color(AppColors.textSecondary)
                                      : const Color(AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _label('Location'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationCtrl,
              style: _inputStyle(),
              decoration: _inputDeco('Venue or address'),
            ),

            const SizedBox(height: 20),
            _label('Max Guests'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _guestsCtrl,
              style: _inputStyle(),
              keyboardType: TextInputType.number,
              decoration: _inputDeco('0 = unlimited'),
            ),

            const SizedBox(height: 20),
            _label('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              style: _inputStyle(),
              maxLines: 3,
              decoration: _inputDeco('Brief description of the event…'),
            ),

            const SizedBox(height: 20),
            _label('Status'),
            const SizedBox(height: 8),
            _StatusPicker(
              selected: _status,
              onChanged: (s) => setState(() => _status = s),
            ),

            const SizedBox(height: 32),
            GradientButton(
              label: _isEdit ? 'Save Changes' : 'Create Event',
              isLoading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(AppColors.textSecondary),
        ),
      );

  TextStyle _inputStyle() => GoogleFonts.plusJakartaSans(
      color: const Color(AppColors.textPrimary), fontSize: 14);

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(AppColors.primaryViolet), width: 1.5),
        ),
        hintStyle: const TextStyle(
            color: Color(AppColors.textSecondary), fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

class _CategoryPicker extends StatelessWidget {
  final EventCategory selected;
  final ValueChanged<EventCategory> onChanged;

  const _CategoryPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: EventCategory.values.map((c) {
        final sel = c == selected;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel
                  ? const Color(AppColors.primaryViolet)
                  : const Color(AppColors.backgroundCard),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel
                    ? const Color(AppColors.primaryViolet)
                    : const Color(0xFF2A2A3A),
              ),
            ),
            child: Text(
              '${c.emoji} ${c.label}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: sel
                    ? Colors.white
                    : const Color(AppColors.textSecondary),
                fontWeight:
                    sel ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  final EventStatus selected;
  final ValueChanged<EventStatus> onChanged;

  const _StatusPicker({required this.selected, required this.onChanged});

  Color _color(EventStatus s) {
    switch (s) {
      case EventStatus.upcoming:
        return const Color(AppColors.accentCyan);
      case EventStatus.ongoing:
        return const Color(AppColors.successGreen);
      case EventStatus.completed:
        return const Color(AppColors.textSecondary);
      case EventStatus.cancelled:
        return const Color(AppColors.errorRed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: EventStatus.values.map((s) {
        final sel = s == selected;
        return GestureDetector(
          onTap: () => onChanged(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel
                  ? _color(s).withOpacity(0.2)
                  : const Color(AppColors.backgroundCard),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? _color(s) : const Color(0xFF2A2A3A),
              ),
            ),
            child: Text(
              s.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: sel ? _color(s) : const Color(AppColors.textSecondary),
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
