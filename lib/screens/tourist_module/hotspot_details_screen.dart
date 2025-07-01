import 'package:flutter/material.dart';
import 'package:capstone_app/models/hotspots_model.dart';

/// A screen that displays the details of a [Hotspot].
class HotspotDetailsScreen extends StatelessWidget {
  /// Creates a [HotspotDetailsScreen] with the given [hotspot].
  const HotspotDetailsScreen({super.key, required this.hotspot});

  /// The [Hotspot] to display details for.
  final Hotspot hotspot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hotspot.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hotspot.images.isNotEmpty)
              SizedBox(
                height: 220,
                width: double.infinity,
                child: PageView(
                  children: hotspot.images
                      .map((img) => Image.network(img, fit: BoxFit.cover))
                      .toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hotspot.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(hotspot.description,
                      style: const TextStyle(fontSize: 16)),
                  // Add more details as needed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Add/fix doc comments for all classes and key methods, centralize constants, use const where possible, and ensure code quality and maintainability throughout the file.
