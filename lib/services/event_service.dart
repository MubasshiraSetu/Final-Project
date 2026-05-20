// lib/services/event_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

class EventService {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  // ─── Fetch all events (all authenticated users can view) ─────
Future<List<EventModel>> fetchEvents({EventStatus? status}) async {
  // Start with filter builder
  var filterQuery = _supabase.from('events').select();

  // Apply filters
  if (status != null) {
    filterQuery = filterQuery.eq('status', status.value);
  }

  // Then convert to transform builder for ordering
  final transformQuery = filterQuery.order('event_date', ascending: true);

  final data = await transformQuery;
  return (data as List).map((e) => EventModel.fromMap(e)).toList();
}

  // ─── Realtime stream of events ───────────────────────────────
  Stream<List<EventModel>> eventsStream() {
    return _supabase
        .from('events')
        .stream(primaryKey: ['id'])
        .order('event_date', ascending: true)
        .map((data) => data.map((e) => EventModel.fromMap(e)).toList());
  }

  // ─── Create event (admin only — enforced by RLS) ─────────────
  Future<EventModel> createEvent(EventModel event) async {
    final data = await _supabase
        .from('events')
        .insert({...event.toMap(), 'user_id': _userId})
        .select()
        .single();

    return EventModel.fromMap(data);
  }

  // ─── Update event (admin only — enforced by RLS) ─────────────
  Future<EventModel> updateEvent(String id, EventModel event) async {
    final data = await _supabase
        .from('events')
        .update(event.toMap())
        .eq('id', id)
        .select()
        .single();

    return EventModel.fromMap(data);
  }

  // ─── Update guest count (admin only) ────────────────────────
  Future<void> updateGuestCount(String id, int currentGuests) async {
    await _supabase
        .from('events')
        .update({'current_guests': currentGuests})
        .eq('id', id);
  }

  // ─── Update status (admin only) ─────────────────────────────
  Future<void> updateStatus(String id, EventStatus status) async {
    await _supabase
        .from('events')
        .update({'status': status.value})
        .eq('id', id);
  }

  // ─── Delete event (admin only — enforced by RLS) ─────────────
  Future<void> deleteEvent(String id) async {
    await _supabase.from('events').delete().eq('id', id);
  }

  // ─── Fetch single event ──────────────────────────────────────
  Future<EventModel?> fetchEvent(String id) async {
    try {
      final data = await _supabase
          .from('events')
          .select()
          .eq('id', id)
          .single();
      return EventModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  // ─── Fetch events with food item counts (for dashboard) ──────
  Future<List<Map<String, dynamic>>> fetchEventsWithFoodCount() async {
    final data = await _supabase
        .from('events')
        .select('*, food_items(count)')
        .order('event_date', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ─────────────────────────────────────────────────────────────
  // EVENT REQUEST SYSTEM  (no SQL schema change required)
  // General users insert events with status='cancelled', notes='REQ:pending'
  // Admin approves → status='upcoming', notes='REQ:approved'
  // Admin rejects  → status='cancelled', notes='REQ:rejected'
  // ─────────────────────────────────────────────────────────────

  /// General user submits an event request.
  Future<EventModel> submitEventRequest(EventModel event) async {
    final data = await _supabase
        .from('events')
        .insert({
          ...event.toMap(),
          'user_id': _userId,
          'status': 'cancelled',
          'notes': RequestStatus.pending.tag,
        })
        .select()
        .single();
    return EventModel.fromMap(data);
  }

  /// Fetch ALL event requests (pending + approved + rejected) — admin only.
  Future<List<EventModel>> fetchPendingRequests() async {
    final data = await _supabase
        .from('events')
        .select()
        .like('notes', 'REQ:%')
        .order('created_at', ascending: false);
    return (data as List).map((e) => EventModel.fromMap(e)).toList();
  }

  /// Fetch requests submitted by current user.
  Future<List<EventModel>> fetchMyRequests() async {
    final data = await _supabase
        .from('events')
        .select()
        .eq('user_id', _userId)
        .like('notes', 'REQ:%')
        .order('created_at', ascending: false);
    return (data as List).map((e) => EventModel.fromMap(e)).toList();
  }

  /// Admin approves a request → becomes upcoming event.
  Future<void> approveRequest(String id) async {
    await _supabase.from('events').update({
      'status': 'upcoming',
      'notes': RequestStatus.approved.tag,
    }).eq('id', id);
  }

  /// Admin rejects a request.
  Future<void> rejectRequest(String id) async {
    await _supabase.from('events').update({
      'status': 'cancelled',
      'notes': RequestStatus.rejected.tag,
    }).eq('id', id);
  }
}
