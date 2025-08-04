// ===========================================
// lib/services/trip_service.dart
// ===========================================
// Handles CRUD operations for trip planning in Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import '../utils/constants.dart';

/// Service for saving, retrieving, and deleting trips in Firestore.
class TripService {
  /// Saves a trip to Firestore.
  static Future<void> saveTrip(Trip trip) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.tripPlanningCollection)
          .doc(trip.tripPlanId)
          .set(trip.toMap());
    } catch (e) {
      throw Exception('${AppConstants.errorSavingTrip}: $e');
    }
  }

  /// Retrieves all trips for a given user.
  static Future<List<Trip>> getTrips(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.tripPlanningCollection)
          .where('user_id', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => Trip.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('${AppConstants.errorLoadingTrips}: $e');
    }
  }

  /// Deletes a trip by its ID.
  static Future<void> deleteTrip(String tripPlanId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.tripPlanningCollection)
          .doc(tripPlanId)
          .delete();
    } catch (e) {
      throw Exception('${AppConstants.errorDeletingTrip}: $e');
    }
  }
}
