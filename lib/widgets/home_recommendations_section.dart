// ===========================================
// lib/widgets/home_recommendations_section.dart
// ===========================================
// Widget for displaying personalized home screen recommendations.

import 'package:flutter/material.dart';
import 'package:capstone_app/services/recommender_system.dart';
import 'package:capstone_app/models/hotspots_model.dart';
import 'package:capstone_app/screens/tourist_module/hotspot_details_screen.dart';
import 'package:capstone_app/utils/constants.dart';
import 'package:capstone_app/utils/colors.dart';

/// Section widget for showing recommended hotspots on the home screen.
class HomeRecommendationsSection extends StatelessWidget {
  /// Creates a [HomeRecommendationsSection] widget.
  const HomeRecommendationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Hotspot>>(
      future: TouristRecommendationService.getPersonalizedRecommendations(limit: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load recommendations.'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeRecommendationsSection()),
                  ),
                  child: const Text(AppConstants.retry),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
            child: Text('No recommendations found.'),
          );
        }
        final recommendations = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    AppConstants.recommendedForYou,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FullRecommendationsScreen(),
                        ),
                      );
                    },
                    child: const Text(AppConstants.seeAll),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: AppConstants.cardListHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                itemCount: recommendations.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppConstants.cardListSpacing),
                itemBuilder: (context, index) {
                  final hotspot = recommendations[index];
                  return _HotspotCard(hotspot: hotspot);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Card widget for displaying a single recommended hotspot.
class _HotspotCard extends StatelessWidget {
  /// The hotspot to display in the card.
  final Hotspot hotspot;
  /// Creates a [_HotspotCard].
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
        width: AppConstants.cardWidth,
        height: AppConstants.cardListHeight - 8, // Ensure card fits in carousel
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
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
                        color: AppColors.imagePlaceholder,
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: AppColors.imagePlaceholder,
                      child: Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
            ),
            // Right-side semi-transparent overlay
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: AppConstants.cardWidth * 0.45, // 45% of card width
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(AppConstants.cardBorderRadius),
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
                          fontSize: 20,
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

/// Screen for displaying all recommended hotspots.
class FullRecommendationsScreen extends StatelessWidget {
  /// Creates a [FullRecommendationsScreen] widget.
  const FullRecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.allRecommendations)),
      body: FutureBuilder<List<Hotspot>>(
        future: TouristRecommendationService.getPersonalizedRecommendations(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load recommendations.'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const FullRecommendationsScreen()),
                    ),
                    child: const Text(AppConstants.retry),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No recommendations found.'));
          }
          final recommendations = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: recommendations.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppConstants.cardListSpacing),
            itemBuilder: (context, index) {
              final hotspot = recommendations[index];
              return Card(
                child: ListTile(
                  leading: (hotspot.images.isNotEmpty)
                      // ? CachedNetworkImage(
                      //     imageUrl: hotspot.images.first,
                      //     width: 60,
                      //     height: 60,
                      //     fit: BoxFit.cover,
                      //     errorWidget: (_, __, ___) => const Icon(Icons.image, size: AppConstants.cardIconSize),
                      //   )
                      ? Image.network(hotspot.images.first, width: 60, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: AppConstants.cardIconSize),
                  title: Text(hotspot.name),
                  subtitle: Text(hotspot.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HotspotDetailsScreen(hotspot: hotspot),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
