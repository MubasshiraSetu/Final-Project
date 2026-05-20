// lib/services/food_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_model.dart';

class FoodService {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  // ─── Fetch all food items (all authenticated users can view) ─
 Future<List<FoodItem>> fetchFoodItems({String? eventId}) async {
  if (eventId != null) {
    final data = await _supabase
        .from('food_items')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => FoodItem.fromMap(e)).toList();
  } else {
    final data = await _supabase
        .from('food_items')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => FoodItem.fromMap(e)).toList();
  }
}

  // ─── Realtime stream of food items ──────────────────────────
  Stream<List<FoodItem>> foodItemsStream({String? eventId}) {
    var stream = _supabase
        .from('food_items')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return stream.map((data) {
      var items = data.map((e) => FoodItem.fromMap(e)).toList();
      if (eventId != null) {
        items = items.where((i) => i.eventId == eventId).toList();
      }
      return items;
    });
  }

  // ─── Create food item (admin only — enforced by RLS) ─────────
  Future<FoodItem> createFoodItem(FoodItem item) async {
    final data = await _supabase
        .from('food_items')
        .insert({...item.toMap(), 'user_id': _userId})
        .select()
        .single();

    return FoodItem.fromMap(data);
  }

  // ─── Update food item (admin only — enforced by RLS) ─────────
  Future<FoodItem> updateFoodItem(String id, FoodItem item) async {
    final data = await _supabase
        .from('food_items')
        .update(item.toMap())
        .eq('id', id)
        .select()
        .single();

    return FoodItem.fromMap(data);
  }

  // ─── Delete food item (admin only — enforced by RLS) ─────────
  Future<void> deleteFoodItem(String id) async {
    await _supabase.from('food_items').delete().eq('id', id);
  }

  // ─── Toggle availability (admin only) ────────────────────────
  Future<void> toggleAvailability(String id, bool isAvailable) async {
    await _supabase
        .from('food_items')
        .update({'is_available': isAvailable})
        .eq('id', id);
  }

  // ─── Update quantity served (admin only) ─────────────────────
  Future<void> updateQuantityServed(String id, int quantityServed) async {
    await _supabase
        .from('food_items')
        .update({'quantity_served': quantityServed})
        .eq('id', id);
  }

  // ─── Fetch summary stats for an event ───────────────────────
  Future<Map<String, dynamic>> fetchEventFoodStats(String eventId) async {
    final data = await _supabase
        .from('food_items')
        .select()
        .eq('event_id', eventId);

    final items = (data as List).map((e) => FoodItem.fromMap(e)).toList();
    final totalItems = items.length;
    final availableItems = items.where((i) => i.isAvailable).length;
    final totalValue = items.fold<double>(
        0, (sum, i) => sum + (i.price * i.quantity));
    final totalServed = items.fold<int>(0, (sum, i) => sum + i.quantityServed);

    return {
      'total_items': totalItems,
      'available_items': availableItems,
      'total_value': totalValue,
      'total_served': totalServed,
    };
  }
}
