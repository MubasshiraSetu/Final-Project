// lib/models/event_model.dart

// ── Request approval status (stored in `notes` field as "REQ:pending" etc.)
// ── No SQL schema change needed — piggybacks on the existing `notes` column.
enum RequestStatus { pending, approved, rejected }

extension RequestStatusExt on RequestStatus {
  String get tag {
    switch (this) {
      case RequestStatus.pending:  return 'REQ:pending';
      case RequestStatus.approved: return 'REQ:approved';
      case RequestStatus.rejected: return 'REQ:rejected';
    }
  }

  String get label {
    switch (this) {
      case RequestStatus.pending:  return 'Pending';
      case RequestStatus.approved: return 'Approved';
      case RequestStatus.rejected: return 'Rejected';
    }
  }

  static RequestStatus? fromNotes(String? notes) {
    if (notes == null) return null;
    if (notes.startsWith('REQ:pending'))  return RequestStatus.pending;
    if (notes.startsWith('REQ:approved')) return RequestStatus.approved;
    if (notes.startsWith('REQ:rejected')) return RequestStatus.rejected;
    return null;
  }
}

enum EventStatus { upcoming, ongoing, completed, cancelled }

enum EventCategory {
  wedding,
  birthday,
  corporate,
  concert,
  festival,
  sports,
  other
}

extension EventStatusExt on EventStatus {
  String get label {
    switch (this) {
      case EventStatus.upcoming:   return 'Upcoming';
      case EventStatus.ongoing:    return 'Ongoing';
      case EventStatus.completed:  return 'Completed';
      case EventStatus.cancelled:  return 'Cancelled';
    }
  }
  String get value => name;
}

extension EventCategoryExt on EventCategory {
  String get label {
    switch (this) {
      case EventCategory.wedding:   return 'Wedding';
      case EventCategory.birthday:  return 'Birthday';
      case EventCategory.corporate: return 'Corporate';
      case EventCategory.concert:   return 'Concert';
      case EventCategory.festival:  return 'Festival';
      case EventCategory.sports:    return 'Sports';
      case EventCategory.other:     return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case EventCategory.wedding:   return '💍';
      case EventCategory.birthday:  return '🎂';
      case EventCategory.corporate: return '💼';
      case EventCategory.concert:   return '🎵';
      case EventCategory.festival:  return '🎉';
      case EventCategory.sports:    return '⚽';
      case EventCategory.other:     return '📅';
    }
  }

  String get value => name;
}

class EventModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final EventCategory category;
  final DateTime eventDate;
  final String eventTime;
  final String? location;
  final int maxGuests;
  final int currentGuests;
  final String? coverImage;
  final EventStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.eventDate,
    required this.eventTime,
    this.location,
    this.maxGuests = 0,
    this.currentGuests = 0,
    this.coverImage,
    this.status = EventStatus.upcoming,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Percentage of guest capacity filled (0–100). Returns null if maxGuests = 0.
  double? get guestFillPercent =>
      maxGuests > 0 ? (currentGuests / maxGuests * 100).clamp(0, 100) : null;

  RequestStatus? get requestStatus => RequestStatusExt.fromNotes(notes);
  bool get isRequest => requestStatus != null;

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      category: EventCategory.values.firstWhere(
        (e) => e.value == map['category'],
        orElse: () => EventCategory.other,
      ),
      eventDate: DateTime.parse(map['event_date']),
      eventTime: map['event_time'] ?? '00:00',
      location: map['location'],
      maxGuests: map['max_guests'] ?? 0,
      currentGuests: map['current_guests'] ?? 0,
      coverImage: map['cover_image'],
      status: EventStatus.values.firstWhere(
        (e) => e.value == map['status'],
        orElse: () => EventStatus.upcoming,
      ),
      notes: map['notes'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.value,
      'event_date': eventDate.toIso8601String().split('T').first,
      'event_time': eventTime,
      'location': location,
      'max_guests': maxGuests,
      'current_guests': currentGuests,
      'cover_image': coverImage,
      'status': status.value,
      'notes': notes,
    };
  }
}
