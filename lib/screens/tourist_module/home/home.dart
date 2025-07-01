import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:capstone_app/models/hotspots_model.dart';
import 'package:capstone_app/services/recommender_system.dart';
import 'package:capstone_app/screens/tourist_module/hotspot_details_screen.dart';
import '../../../utils/constants.dart';
import '../../../utils/colors.dart';

/// Home screen for tourists, showing personalized, trending, nearby, and seasonal hotspot recommendations.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Fetches all home recommendations for the user.
  Future<Map<String, List<Hotspot>>> getHomeRecommendations() async {
    return {
      'forYou': await TouristRecommendationService.getPersonalizedRecommendations(limit: AppConstants.homeForYouLimit),
      'trending': await getTrendingHotspots(limit: AppConstants.homeTrendingLimit),
      'nearby': await getNearbyRecommendations(limit: AppConstants.homeNearbyLimit),
      'seasonal': await getSeasonalRecommendations(limit: AppConstants.homeSeasonalLimit),
    };
  }

  /// Fetches trending hotspots based on user interactions in the last 30 days.
  Future<List<Hotspot>> getTrendingHotspots({int limit = 5}) async {
    // COMMENTED OUT: Firestore query requires a composite index. Uncomment after creating the index in Firestore Console.
    /*
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await FirebaseFirestore.instance
          .collection('user_interactions')
          .where('timestamp', isGreaterThan: thirtyDaysAgo)
          .where('action', whereIn: ['view', 'like'])
          .get();
      final Map<String, int> hotspotCounts = {};
      for (final doc in snapshot.docs) {
        final hotspotId = doc.data()['hotspotId'] as String;
        hotspotCounts[hotspotId] = (hotspotCounts[hotspotId] ?? 0) + 1;
      }
      final sortedHotspots = hotspotCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topHotspotIds = sortedHotspots
          .take(limit)
          .map((e) => e.key)
          .toList();
      final List<Hotspot> trendingHotspots = [];
      for (final id in topHotspotIds) {
        final doc = await FirebaseFirestore.instance
            .collection('hotspots')
            .doc(id)
            .get();
        if (doc.exists) {
          trendingHotspots.add(Hotspot.fromMap(doc.data()!, doc.id));
        }
      }
      return trendingHotspots;
    } catch (e) {
      // Optionally log error
      return [];
    }
    */
    // TEMPORARY: Return empty list until Firestore index is created.
    return [];
  }

  /// Fetches nearby recommendations (currently uses personalized recommendations).
  Future<List<Hotspot>> getNearbyRecommendations({int limit = 5}) async {
    return await TouristRecommendationService.getPersonalizedRecommendations(limit: limit);
  }

  /// Fetches seasonal recommendations based on the current month.
  Future<List<Hotspot>> getSeasonalRecommendations({int limit = 3}) async {
    final currentMonth = DateTime.now().month;
    String seasonKeyword = '';
    if (currentMonth >= 12 || currentMonth <= 2) {
      seasonKeyword = AppConstants.seasonChristmas;
    } else if (currentMonth >= 3 && currentMonth <= 5) {
      seasonKeyword = AppConstants.seasonSummer;
    } else {
      seasonKeyword = AppConstants.seasonFestival;
    }
    return await TouristRecommendationService.searchHotspots(seasonKeyword, limit: limit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.homeTitle),
        backgroundColor: AppColors.backgroundColor,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppConstants.homeTopSpacing),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.homeHorizontalPadding),
              child: Text(
                AppConstants.homeWelcome,
                style: TextStyle(fontSize: AppConstants.homeWelcomeFontSize, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppConstants.homeSectionSpacing),
            FutureBuilder<Map<String, List<Hotspot>>>(
              future: getHomeRecommendations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.homeHorizontalPadding),
                    child: Text(AppConstants.homeNoRecommendations),
                  );
                }
                final data = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RecommendationCarousel(
                      title: AppConstants.homeForYou,
                      hotspots: data['forYou'] ?? [],
                      color: AppColors.homeForYouColor,
                    ),
                    const SizedBox(height: AppConstants.homeCarouselSpacing),
                    _RecommendationCarousel(
                      title: AppConstants.homeTrending,
                      hotspots: data['trending'] ?? [],
                      color: AppColors.homeTrendingColor,
                    ),
                    const SizedBox(height: AppConstants.homeCarouselSpacing),
                    _RecommendationCarousel(
                      title: AppConstants.homeNearby,
                      hotspots: data['nearby'] ?? [],
                      color: AppColors.homeNearbyColor,
                    ),
                    const SizedBox(height: AppConstants.homeCarouselSpacing),
                    _RecommendationCarousel(
                      title: AppConstants.homeSeasonal,
                      hotspots: data['seasonal'] ?? [],
                      color: AppColors.homeSeasonalColor,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppConstants.homeBottomSpacing),
          ],
        ),
      ),
    );
  }
}

/// Carousel widget for displaying a horizontal list of hotspot cards.
class _RecommendationCarousel extends StatelessWidget {
  final String title;
  final List<Hotspot> hotspots;
  final Color color;
  const _RecommendationCarousel({required this.title, required this.hotspots, required this.color});

  @override
  Widget build(BuildContext context) {
    if (hotspots.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.homeHorizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: AppConstants.homeCarouselBarWidth,
                    height: AppConstants.homeCarouselBarHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppConstants.homeCarouselBarRadius),
                    ),
                  ),
                  const SizedBox(width: AppConstants.homeCarouselBarSpacing),
                  Text(
                    title,
                    style: const TextStyle(fontSize: AppConstants.homeCarouselTitleFontSize, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: AppConstants.homeCarouselHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.homeHorizontalPadding),
            itemCount: hotspots.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppConstants.homeCarouselCardSpacing),
            itemBuilder: (context, index) {
              final hotspot = hotspots[index];
              return _HotspotCard(hotspot: hotspot);
            },
          ),
        ),
      ],
    );
  }
}

/// Card widget for displaying a single hotspot in the carousel.
class _HotspotCard extends StatelessWidget {
  final Hotspot hotspot;
  const _HotspotCard({required this.hotspot});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HotspotDetailsScreen(hotspot: hotspot),
          ),
        );
      },
      child: Container(
        width: AppConstants.homeCardWidth,
        height: AppConstants.homeCarouselHeight - 16, // Ensure card fits in carousel
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.homeCardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: AppConstants.homeCardShadowBlur,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: (hotspot.images.isNotEmpty)
                  ? Image.network(
                      hotspot.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: AppConstants.homeCardImageIconSize, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: AppConstants.homeCardImageIconSize, color: Colors.grey),
                    ),
            ),
            // Right-side semi-transparent overlay
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: AppConstants.homeCardWidth * 0.45, // 45% of card width
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(AppConstants.homeCardRadius),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        hotspot.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          fontSize: 22,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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