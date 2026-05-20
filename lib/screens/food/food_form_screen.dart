
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/event_model.dart';
import '../../models/food_model.dart';
import '../../services/food_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_button.dart';

class FoodFormScreen extends StatefulWidget {
  final FoodItem? item;
  // FIX: added preselectedEventId so "Add Food" from event detail pre-fills the event
  final String? preselectedEventId;
  const FoodFormScreen({super.key, this.item, this.preselectedEventId});

  @override
  State<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends State<FoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FoodService();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _notesCtrl;

  FoodCategory _category = FoodCategory.other;
  bool _isVegetarian = false;
  bool _isAvailable = true;
  String? _selectedEventId;
  bool _saving = false;

  List<EventModel> _events = [];

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final f = widget.item;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    _descCtrl = TextEditingController(text: f?.description ?? '');
    _priceCtrl = TextEditingController(text: f?.price.toStringAsFixed(2) ?? '0.00');
    _qtyCtrl = TextEditingController(text: f?.quantity.toString() ?? '1');
    _notesCtrl = TextEditingController(text: f?.notes ?? '');
    _category = f?.category ?? FoodCategory.other;
    _isVegetarian = f?.isVegetarian ?? false;
    _isAvailable = f?.isAvailable ?? true;
    // FIX: preselectedEventId takes priority, then item's eventId
    _selectedEventId = widget.preselectedEventId ?? f?.eventId;
    _loadEvents();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      // FIX: load ALL events (not just admin's own) so food can be linked to any event
      final data = await Supabase.instance.client
          .from('events')
          .select()
          .order('event_date', ascending: true);
      if (mounted) {
        setState(() {
          _events = (data as List).map((e) => EventModel.fromMap(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final item = FoodItem(
      id: widget.item?.id ?? '',
      userId: '',
      eventId: _selectedEventId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: _category,
      price: double.tryParse(_priceCtrl.text) ?? 0.0,
      quantity: int.tryParse(_qtyCtrl.text) ?? 1,
      quantityServed: widget.item?.quantityServed ?? 0,
      isVegetarian: _isVegetarian,
      isAvailable: _isAvailable,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      if (_isEdit) {
        await _service.updateFoodItem(widget.item!.id, item);
      } else {
        await _service.createFoodItem(item);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save. Please try again.',
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(AppColors.errorRed),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Item' : 'New Food Item',
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
            _label('Item Name *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              style: _inputStyle(),
              decoration: _inputDeco('e.g. Grilled Chicken, Spring Rolls…'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
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
                      _label('Price (\$)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceCtrl,
                        style: _inputStyle(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDeco('0.00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Quantity'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _qtyCtrl,
                        style: _inputStyle(),
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco('1'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) return 'Min 1';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _label('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              style: _inputStyle(),
              maxLines: 3,
              decoration: _inputDeco('Describe the dish, ingredients, allergens…'),
            ),

            const SizedBox(height: 20),
            _label('Notes (internal)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              style: _inputStyle(),
              maxLines: 2,
              decoration: _inputDeco('Preparation notes, supplier info…'),
            ),

            const SizedBox(height: 20),
            _label('Link to Event (optional)'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(AppColors.backgroundCard),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2A3A)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: (_selectedEventId != null &&
                          _events.any((e) => e.id == _selectedEventId))
                      ? _selectedEventId
                      : null,
                  isExpanded: true,
                  dropdownColor: const Color(AppColors.backgroundCard),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  borderRadius: BorderRadius.circular(14),
                  hint: Text('No event linked',
                      style: GoogleFonts.plusJakartaSans(
                          color: const Color(AppColors.textSecondary),
                          fontSize: 14)),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No event',
                          style: GoogleFonts.plusJakartaSans(
                              color: const Color(AppColors.textSecondary),
                              fontSize: 14)),
                    ),
                    ..._events.map((e) => DropdownMenuItem<String?>(
                          value: e.id,
                          child: Text(
                            '${e.category.emoji} ${e.title}',
                            style: GoogleFonts.plusJakartaSans(
                                color: const Color(AppColors.textPrimary),
                                fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedEventId = v),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Toggles
            _ToggleTile(
              title: 'Vegetarian / Vegan',
              subtitle: 'Mark as vegetarian or vegan friendly',
              value: _isVegetarian,
              onChanged: (v) => setState(() => _isVegetarian = v),
              activeColor: const Color(AppColors.successGreen),
            ),
            const SizedBox(height: 12),
            _ToggleTile(
              title: 'Currently Available',
              subtitle: 'Is this item available for ordering?',
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
              activeColor: const Color(AppColors.accentCyan),
            ),

            const SizedBox(height: 32),
            GradientButton(
              label: _isEdit ? 'Save Changes' : 'Add Item',
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
  final FoodCategory selected;
  final ValueChanged<FoodCategory> onChanged;

  const _CategoryPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FoodCategory.values.map((c) {
        final sel = c == selected;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel
                  ? const Color(AppColors.primaryGold).withOpacity(0.2)
                  : const Color(AppColors.backgroundCard),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel
                    ? const Color(AppColors.primaryGold)
                    : const Color(0xFF2A2A3A),
              ),
            ),
            child: Text(
              '${c.emoji} ${c.label}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: sel
                    ? const Color(AppColors.primaryGold)
                    : const Color(AppColors.textSecondary),
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(AppColors.backgroundCard),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: Row(
        children: [
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
                const SizedBox(height: 2),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }
}