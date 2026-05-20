// lib/screens/requests/request_event_screen.dart
//
// General users fill this form to REQUEST an event.
// The event is saved with status='cancelled' + notes='REQ:pending'
// so it is invisible in the public event list until an admin approves it.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_button.dart';

class RequestEventScreen extends StatefulWidget {
  const RequestEventScreen({super.key});

  @override
  State<RequestEventScreen> createState() => _RequestEventScreenState();
}

class _RequestEventScreenState extends State<RequestEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EventService();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _guestsCtrl = TextEditingController(text: '0');

  EventCategory _category = EventCategory.other;
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _guestsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      _snack('Please select a date', error: true);
      return;
    }
    if (_eventTime == null) {
      _snack('Please select a time', error: true);
      return;
    }

    setState(() => _saving = true);

    final timeStr =
        '${_eventTime!.hour.toString().padLeft(2, '0')}:${_eventTime!.minute.toString().padLeft(2, '0')}';

    final event = EventModel(
      id: '',
      userId: '',
      title: _titleCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: _category,
      eventDate: _eventDate!,
      eventTime: timeStr,
      location:
          _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      maxGuests: int.tryParse(_guestsCtrl.text) ?? 0,
      createdAt: DateTime.now(),
    );

    try {
      await _service.submitEventRequest(event);
      if (mounted) {
        _snack('Request submitted! Waiting for admin approval.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('Failed to submit. Please try again.', error: true);
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans()),
      backgroundColor: error
          ? const Color(AppColors.errorRed)
          : const Color(AppColors.successGreen),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      appBar: AppBar(
        title: Text('Request an Event',
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
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(AppColors.primaryViolet).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(AppColors.primaryViolet).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(AppColors.primaryViolet), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your request will be reviewed by an admin before it appears as an upcoming event.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(AppColors.primaryViolet),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _label('Event Title *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: _inputStyle(),
              decoration: _inputDeco('e.g. Community Fundraiser Night'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),

            const SizedBox(height: 20),
            _label('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventCategory.values.map((c) {
                final sel = c == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
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
                        child: _pickerBox(
                          icon: Icons.calendar_today_rounded,
                          text: _eventDate == null
                              ? 'Pick date'
                              : DateFormat('MMM d, yyyy').format(_eventDate!),
                          filled: _eventDate != null,
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
                        child: _pickerBox(
                          icon: Icons.access_time_rounded,
                          text: _eventTime == null
                              ? 'Pick time'
                              : _eventTime!.format(context),
                          filled: _eventTime != null,
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
            _label('Expected Guests'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _guestsCtrl,
              style: _inputStyle(),
              keyboardType: TextInputType.number,
              decoration: _inputDeco('0 = not sure'),
            ),

            const SizedBox(height: 20),
            _label('Description / Purpose *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              style: _inputStyle(),
              maxLines: 4,
              decoration: _inputDeco(
                  'Tell the admin what this event is about, why it should be approved…'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please add a description' : null,
            ),

            const SizedBox(height: 32),
            GradientButton(
              label: 'Submit Request',
              isLoading: _saving,
              onPressed: _submit,
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

  Widget _pickerBox(
      {required IconData icon, required String text, required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundCard),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: filled
              ? const Color(AppColors.primaryViolet).withOpacity(0.5)
              : const Color(0xFF2A2A3A),
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: filled
                  ? const Color(AppColors.primaryViolet)
                  : const Color(AppColors.textSecondary)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: filled
                    ? const Color(AppColors.textPrimary)
                    : const Color(AppColors.textSecondary),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

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
          borderSide: const BorderSide(
              color: Color(AppColors.primaryViolet), width: 1.5),
        ),
        hintStyle: const TextStyle(
            color: Color(AppColors.textSecondary), fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
