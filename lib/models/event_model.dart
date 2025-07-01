// ===========================================
// lib/models/event_model.dart
// ===========================================
// Model for events, matching Firestore schema and ERD.

/// Event model representing an event in the system.
class Event {
  /// Unique identifier for the event.
  final String eventId;
  /// Title of the event.
  final String title;
  /// Description of the event.
  final String description;
  /// Location where the event takes place.
  final String location;
  /// Date and time of the event.
  final DateTime date;
  /// Date and time when the event was created.
  final DateTime createdAt;
  /// Status of the event (e.g., active, cancelled).
  final String status;

  /// Creates an [Event] instance.
  const Event({
    required this.eventId,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.createdAt,
    required this.status,
  });

  /// Creates an [Event] from a map (e.g., from Firestore).
  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      eventId: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      date: map['date'] is DateTime
          ? map['date']
          : DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      createdAt: map['created_at'] is DateTime
          ? map['created_at']
          : DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? '',
    );
  }

  /// Converts the [Event] to a map for storage.
  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'title': title,
      'description': description,
      'location': location,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
