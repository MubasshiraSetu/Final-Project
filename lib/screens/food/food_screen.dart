
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/food_model.dart';
import '../../services/auth_provider.dart';
import '../../services/food_service.dart';
import '../../utils/constants.dart';
import 'food_form_screen.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final _service = FoodService();
  List<FoodItem> _items = [];
  List<FoodItem> _filtered = [];
  bool _loading = true;
  String _search = '';
  FoodCategory? _filterCat;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.fetchFoodItems();
      if (mounted) {
        setState(() {
          _items = items;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered = _items.where((item) {
      final matchSearch = item.name.toLowerCase().contains(q) ||
          (item.description?.toLowerCase().contains(q) ?? false);
      final matchCat = _filterCat == null || item.category == _filterCat;
      return matchSearch && matchCat;
    }).toList();
  }

  Future<void> _delete(FoodItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(AppColors.backgroundCard),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete item?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(AppColors.textPrimary))),
        content: Text('"${item.name}" will be permanently removed.',
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
      await _service.deleteFoodItem(item.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Item deleted', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(AppColors.successGreen),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {}
  }

  Future<void> _toggleAvailability(FoodItem item) async {
    try {
      await _service.toggleAvailability(item.id, !item.isAvailable);
      _load();
    } catch (_) {}
  }

  void _openForm({FoodItem? item}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FoodFormScreen(item: item)),
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
                          'Food Menu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(AppColors.textPrimary),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          isAdmin ? 'Tap to edit • Toggle availability' : 'View only',
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
                            Color(AppColors.primaryGold),
                            Color(0xFFFF8C42)
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

            // Search
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
                  hintText: 'Search food items…',
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

            // Category filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filterCat == null,
                    onTap: () => setState(() {
                      _filterCat = null;
                      _applyFilter();
                    }),
                  ),
                  const SizedBox(width: 8),
                  ...FoodCategory.values.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: '${c.emoji} ${c.label}',
                          selected: _filterCat == c,
                          onTap: () => setState(() {
                            _filterCat = _filterCat == c ? null : c;
                            _applyFilter();
                          }),
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(AppColors.primaryGold)))
                  : _filtered.isEmpty
                      ? _EmptyState(
                          isAdmin: isAdmin,
                          onAdd: isAdmin ? () => _openForm() : null)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(AppColors.primaryGold),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _FoodCard(
                              item: _filtered[i],
                              isAdmin: isAdmin,
                              onEdit: isAdmin
                                  ? () => _openForm(item: _filtered[i])
                                  : null,
                              onDelete: isAdmin
                                  ? () => _delete(_filtered[i])
                                  : null,
                              onToggle: isAdmin
                                  ? () => _toggleAvailability(_filtered[i])
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(AppColors.primaryGold).withOpacity(0.2)
              : const Color(AppColors.backgroundCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(AppColors.primaryGold)
                : const Color(0xFF2A2A3A),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? const Color(AppColors.primaryGold)
                : const Color(AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final FoodItem item;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;

  const _FoodCard({
    required this.item,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
    this.onToggle,
  });

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
          onTap: isAdmin ? onEdit : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(AppColors.primaryGold).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(AppColors.primaryGold).withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(item.category.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(AppColors.textPrimary),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '\$${item.price.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(AppColors.primaryGold),
                            ),
                          ),
                        ],
                      ),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(AppColors.textSecondary),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Quantity badge (clean, no served progress bar)
                      if (item.quantity > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 12, color: Color(AppColors.textSecondary)),
                            const SizedBox(width: 4),
                            Text(
                              'Qty: ${item.quantity}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Badge(
                              label: item.category.label,
                              color: const Color(AppColors.accentCyan)),
                          const SizedBox(width: 6),
                          if (item.isVegetarian)
                            _Badge(
                                label: '🌱 Veg',
                                color: const Color(AppColors.successGreen)),
                          const Spacer(),
                          // Availability badge (tap to toggle for admin)
                          GestureDetector(
                            onTap: isAdmin ? onToggle : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: item.isAvailable
                                    ? const Color(AppColors.successGreen)
                                        .withOpacity(0.15)
                                    : const Color(AppColors.errorRed)
                                        .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: item.isAvailable
                                      ? const Color(AppColors.successGreen)
                                          .withOpacity(0.4)
                                      : const Color(AppColors.errorRed)
                                          .withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.isAvailable
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.cancel_outlined,
                                    size: 11,
                                    color: item.isAvailable
                                        ? const Color(AppColors.successGreen)
                                        : const Color(AppColors.errorRed),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    item.isAvailable ? 'Available' : 'Unavailable',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: item.isAvailable
                                          ? const Color(AppColors.successGreen)
                                          : const Color(AppColors.errorRed),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onDelete,
                              child: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Color(AppColors.errorRed)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
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
          const Text('🍽️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No food items yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'Tap + to add your first item'
                : 'No food items have been added yet.',
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
                    Color(AppColors.primaryGold),
                    Color(0xFFFF8C42)
                  ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Add Food Item',
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