// ===========================================
// lib/services/recommender_system.dart
// ===========================================
// Provides personalized recommendations for tourists based on Preferences and preferences.

// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone_app/models/hotspots_model.dart';
import 'package:capstone_app/models/tourist_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

/// Service for generating personalized recommendations for tourists.
class TouristRecommendationService {
  static const double _baseWeight = 1.0;
  static const double _destinationTypeWeight = 3.0;
  static const double _vibeWeight = 2.5;
  static const double _companionWeight = 2.0;
  static const double _timingWeight = 1.5;
  static const double _lesserKnownWeight = 1.8;
  static const double _eventWeight = 1.2;

  // Destination type mappings
  static const Map<String, List<String>> _destinationTypeMapping = {
    'Waterfalls': ['waterfall', 'falls', 'cascade'],
    'Mountain Ranges': ['mountain', 'peak', 'summit', 'highland', 'range'],
    'Scenic Lakes': ['lake', 'lagoon', 'pond', 'reservoir'],
    'Caves': ['cave', 'cavern', 'grotto', 'underground'],
    'Nature Parks and Forests': ['park', 'forest', 'nature', 'wildlife', 'botanical'],
    'Farms and Agricultural Tourism Sites': ['farm', 'agriculture', 'plantation', 'agri'],
    'Adventure Parks': ['adventure', 'zip', 'extreme', 'thrill', 'activity'],
    'Historical or Cultural Sites': ['historical', 'cultural', 'heritage', 'museum', 'monument']
  };

  // Vibe mappings
  static const Map<String, List<String>> _vibeMapping = {
    'Peaceful & Relaxing': ['peaceful', 'serene', 'quiet', 'tranquil', 'relaxing'],
    'Thrilling & Adventurous': ['adventure', 'thrill', 'extreme', 'challenging', 'exciting'],
    'Educational & Cultural': ['educational', 'cultural', 'learning', 'historical', 'heritage'],
    'Photo-Worthy / Instagrammable': ['scenic', 'beautiful', 'photogenic', 'instagram', 'stunning']
  };

  // Companion mappings
  static const Map<String, List<String>> _companionMapping = {
    'Solo': ['solo', 'individual', 'personal', 'meditation'],
    'With Friends': ['group', 'friends', 'social', 'party'],
    'With Family': ['family', 'kids', 'children', 'safe', 'accessible'],
    'With Partner': ['romantic', 'couple', 'intimate', 'date']
  };

  /// Retrieves the tourist Preferences of the currently authenticated user.
  static Future<TouristPreferences?> getUserPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.touristPreferencesCollection)
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return TouristPreferences.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('${AppConstants.errorLoadingTouristPreferences}: $e');
      }
    }
    return null;
  }

  /// Retrieves personalized recommendations for the user based on their Preferences.
  static Future<List<Hotspot>> getPersonalizedRecommendations({int limit = 10}) async {
    try {
      final Preferences = await getUserPreferences();
      if (Preferences == null) {
        throw RecommendationException('No tourist Preferences found', RecommendationErrorType.noPreferences);
      }
      final hotspots = await HotspotCache.getCachedHotspots();
      final scoredHotspots = hotspots.map((hotspot) {
        final score = _calculateRecommendationScore(hotspot, Preferences);
        return ScoredHotspot(hotspot, score);
      }).toList();
      scoredHotspots.sort((a, b) => b.score.compareTo(a.score));
      if (scoredHotspots.isEmpty) {
        throw RecommendationException('No recommendations found', RecommendationErrorType.noData);
      }
      return scoredHotspots.take(limit).map((scored) => scored.hotspot).toList();
    } on RecommendationException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('${AppConstants.errorGettingRecommendations}: $e');
      }
      throw RecommendationException('Network or unknown error', RecommendationErrorType.networkError);
    }
  }

  static double _calculateRecommendationScore(Hotspot hotspot, TouristPreferences Preferences) {
    double score = _baseWeight;

    // Destination type matching (highest weight)
    score += _calculateDestinationTypeScore(hotspot, Preferences) * _destinationTypeWeight;

    // Vibe matching
    score += _calculateVibeScore(hotspot, Preferences) * _vibeWeight;

    // Companion matching
    score += _calculateCompanionScore(hotspot, Preferences) * _companionWeight;

    // Travel timing considerations
    score += _calculateTimingScore(hotspot, Preferences) * _timingWeight;

    // Lesser known preference
    score += _calculateLesserKnownScore(hotspot, Preferences) * _lesserKnownWeight;

    // Event-based considerations
    score += _calculateEventScore(hotspot, Preferences) * _eventWeight;

    return score;
  }

  static double _calculateDestinationTypeScore(Hotspot hotspot, TouristPreferences Preferences) {
    double score = 0.0;
    
    for (String selectedType in Preferences.destinationTypes) {
      final keywords = _destinationTypeMapping[selectedType] ?? [];
      for (String keyword in keywords) {
        if (_containsKeyword(hotspot, keyword)) {
          score += 1.0;
        }
      }
    }
    
    return score;
  }

  static double _calculateVibeScore(Hotspot hotspot, TouristPreferences Preferences) {
    final keywords = _vibeMapping[Preferences.vibe] ?? [];
    double score = 0.0;
    
    for (String keyword in keywords) {
      if (_containsKeyword(hotspot, keyword)) {
        score += 1.0;
      }
    }
    
    return score;
  }

  static double _calculateCompanionScore(Hotspot hotspot, TouristPreferences Preferences) {
    final keywords = _companionMapping[Preferences.companion] ?? [];
    double score = 0.0;
    
    for (String keyword in keywords) {
      if (_containsKeyword(hotspot, keyword)) {
        score += 1.0;
      }
    }

    // Additional logic based on companion type
    switch (Preferences.companion) {
      case 'With Family':
        if (hotspot.restroom && hotspot.foodAccess) score += 0.5;
        if (hotspot.entranceFee != null && hotspot.entranceFee! <= 100) score += 0.3;
        break;
      case 'Solo':
        if (hotspot.localGuide != null && hotspot.localGuide!.isNotEmpty) score += 0.4;
        break;
      case 'With Friends':
        if (hotspot.category.toLowerCase().contains('adventure')) score += 0.6;
        break;
      case 'With Partner':
        if (hotspot.category.toLowerCase().contains('scenic') || 
            hotspot.category.toLowerCase().contains('romantic')) {
          score += 0.5;
        }
        break;
    }
    
    return score;
  }

  static double _calculateTimingScore(Hotspot hotspot, TouristPreferences Preferences) {
    double score = 0.0;
    
    switch (Preferences.travelTiming) {
      case 'Off-Season (Less crowded)':
        // Prefer lesser-known spots during off-season
        if (hotspot.category.toLowerCase().contains('hidden') ||
            hotspot.category.toLowerCase().contains('secret')) {
          score += 1.0;
        }
        break;
      case 'Festival Seasons':
        // Check if hotspot has event-related keywords
        if (_containsKeyword(hotspot, 'festival') || 
            _containsKeyword(hotspot, 'event') ||
            _containsKeyword(hotspot, 'cultural')) {
          score += 1.0;
        }
        break;
      default:
        score += 0.2; // Base score for other timing preferences
    }
    
    return score;
  }

  static double _calculateLesserKnownScore(Hotspot hotspot, TouristPreferences Preferences) {
    double score = 0.0;
    
    switch (Preferences.lesserKnown) {
      case 'Yes, I love discovering hidden gems':
        if (_containsKeyword(hotspot, 'hidden') ||
            _containsKeyword(hotspot, 'secret') ||
            _containsKeyword(hotspot, 'undiscovered') ||
            _containsKeyword(hotspot, 'local')) {
          score += 1.5;
        }
        break;
      case 'No, I prefer popular and established places':
        if (_containsKeyword(hotspot, 'popular') ||
            _containsKeyword(hotspot, 'famous') ||
            _containsKeyword(hotspot, 'well-known')) {
          score += 1.0;
        }
        // Penalize hidden gems for users who prefer popular places
        if (_containsKeyword(hotspot, 'hidden') ||
            _containsKeyword(hotspot, 'secret')) {
          score -= 0.5;
        }
        break;
      case 'Only if they are easy to access':
        if (_containsKeyword(hotspot, 'accessible') ||
            _containsKeyword(hotspot, 'easy') ||
            hotspot.transportation.isNotEmpty) {
          score += 0.8;
        }
        break;
    }
    
    return score;
  }

  static double _calculateEventScore(Hotspot hotspot, TouristPreferences Preferences) {
    double score = 0.0;
    
    if (Preferences.eventRecommendation == 'Yes') {
      if (_containsKeyword(hotspot, 'event') ||
          _containsKeyword(hotspot, 'festival') ||
          _containsKeyword(hotspot, 'cultural')) {
        score += 1.0;
      }
    }
    
    return score;
  }

  static bool _containsKeyword(Hotspot hotspot, String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    if (hotspot.name.toLowerCase().contains(lowerKeyword) ||
        hotspot.description.toLowerCase().contains(lowerKeyword) ||
        hotspot.category.toLowerCase().contains(lowerKeyword)) {
      return true;
    }
    if (hotspot.safetyTips != null && hotspot.safetyTips!.isNotEmpty) {
      for (final tip in hotspot.safetyTips!) {
        if (tip.toLowerCase().contains(lowerKeyword)) return true;
      }
    }
    if (hotspot.suggestions != null && hotspot.suggestions!.isNotEmpty) {
      for (final suggestion in hotspot.suggestions!) {
        if (suggestion.toLowerCase().contains(lowerKeyword)) return true;
      }
    }
    return false;
  }

  // Get recommendations by category
  static Future<List<Hotspot>> getRecommendationsByCategory(String category, {int limit = 5}) async {
    try {
      final Preferences = await getUserPreferences();
      
      final snapshot = await FirebaseFirestore.instance
          .collection('hotspots')
          .where('category', isEqualTo: category)
          .limit(limit * 2) // Get more to allow for filtering
          .get();

      final hotspots = snapshot.docs
          .map((doc) => Hotspot.fromMap(doc.data(), doc.id))
          .toList();

      if (Preferences != null) {
        // Score and sort the hotspots
        final scoredHotspots = hotspots.map((hotspot) {
          final score = _calculateRecommendationScore(hotspot, Preferences);
          return ScoredHotspot(hotspot, score);
        }).toList();

        scoredHotspots.sort((a, b) => b.score.compareTo(a.score));
        
        return scoredHotspots
            .take(limit)
            .map((scored) => scored.hotspot)
            .toList();
      }

      return hotspots.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recommendations by category: $e');
      }
      return [];
    }
  }

  // Enhanced search with filters and Firestore query if possible
  static Future<List<Hotspot>> searchHotspots(
    String query, {
    int limit = 20,
    List<String>? districts,
    List<String>? municipalities,
    List<String>? categories,
  }) async {
    try {
      final Preferences = await getUserPreferences();
      // Try to use Firestore query if only category/district/municipality filters are used (no text query)
      if ((query.isEmpty || query.trim().isEmpty) && ((categories?.isNotEmpty ?? false) || (districts?.isNotEmpty ?? false) || (municipalities?.isNotEmpty ?? false))) {
        var ref = FirebaseFirestore.instance.collection(AppConstants.hotspotsCollection) as Query<Map<String, dynamic>>;
        if (categories != null && categories.isNotEmpty) {
          ref = ref.where('category', whereIn: categories.take(10).toList());
        }
        if (districts != null && districts.isNotEmpty) {
          ref = ref.where('district', whereIn: districts.take(10).toList());
        }
        if (municipalities != null && municipalities.isNotEmpty) {
          ref = ref.where('municipality', whereIn: municipalities.take(10).toList());
        }
        final snapshot = await ref.limit(limit).get();
        final hotspots = snapshot.docs.map((doc) => Hotspot.fromMap(doc.data(), doc.id)).toList();
        return hotspots;
      }
      // Otherwise, use cache and filter client-side
      final allHotspots = await HotspotCache.getCachedHotspots();
      final lowerQuery = query.toLowerCase();
      final matchingHotspots = allHotspots.where((hotspot) {
        final matchesQuery = lowerQuery.isEmpty ||
          hotspot.name.toLowerCase().contains(lowerQuery) ||
          hotspot.description.toLowerCase().contains(lowerQuery) ||
          hotspot.category.toLowerCase().contains(lowerQuery);
        final matchesDistrict = districts == null || districts.isEmpty || districts.contains(hotspot.district);
        final matchesMunicipality = municipalities == null || municipalities.isEmpty || municipalities.contains(hotspot.municipality);
        final matchesCategory = categories == null || categories.isEmpty || categories.contains(hotspot.category);
        return matchesQuery && matchesDistrict && matchesMunicipality && matchesCategory;
      }).toList();
      if (Preferences != null) {
        final scoredHotspots = matchingHotspots.map((hotspot) {
          final score = _calculateRecommendationScore(hotspot, Preferences);
          return ScoredHotspot(hotspot, score);
        }).toList();
        scoredHotspots.sort((a, b) => b.score.compareTo(a.score));
        return scoredHotspots.take(limit).map((scored) => scored.hotspot).toList();
      }
      return matchingHotspots.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error searching hotspots: $e');
      }
      throw RecommendationException('Search failed', RecommendationErrorType.networkError);
    }
  }
}

// Error types for recommendations
enum RecommendationErrorType {
  networkError,
  noPreferences,
  noData,
  authError,
  unknown,
}

class RecommendationException implements Exception {
  final String message;
  final RecommendationErrorType type;
  RecommendationException(this.message, this.type);
  @override
  String toString() => 'RecommendationException($type): $message';
}

/// Simple in-memory cache for hotspots
class HotspotCache {
  static List<Hotspot>? _cachedHotspots;
  static DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(hours: 1);

  static Future<void> _refreshCache() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.hotspotsCollection)
        .get();
    _cachedHotspots = snapshot.docs
        .map((doc) => Hotspot.fromMap(doc.data(), doc.id))
        .toList();
    _lastFetch = DateTime.now();
  }

  static Future<List<Hotspot>> getCachedHotspots() async {
    if (_cachedHotspots == null ||
        _lastFetch == null ||
        DateTime.now().difference(_lastFetch!) > _cacheExpiry) {
      await _refreshCache();
    }
    return _cachedHotspots!;
  }

  static void clearCache() {
    _cachedHotspots = null;
    _lastFetch = null;
  }
}

class ScoredHotspot {
  final Hotspot hotspot;
  final double score;

  ScoredHotspot(this.hotspot, this.score);
}