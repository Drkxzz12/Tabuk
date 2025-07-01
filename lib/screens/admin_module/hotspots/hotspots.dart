import 'dart:convert';
import 'dart:io';

import 'package:capstone_app/models/hotspots_model.dart';
import 'package:capstone_app/services/hotspot_service.dart';
import 'package:capstone_app/utils/colors.dart';
import 'package:capstone_app/utils/constants.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Factory;

class HotspotsManagementScreen extends StatefulWidget {
  const HotspotsManagementScreen({super.key});

  @override
  State<HotspotsManagementScreen> createState() =>
      _HotspotsManagementScreenState();
}

class _HotspotsManagementScreenState extends State<HotspotsManagementScreen> {
  List<Hotspot> _hotspots = [];
  final Stream<List<Hotspot>> _hotspotsStream =
      HotspotService.getHotspotsStream();

  @override
  void initState() {
    super.initState();
  }

  /// Uploads an image file to Imgbb and returns the image URL.
  Future<String?> uploadImageToImgbb(File imageFile) async {
    const apiKey = 'aae8c93b12878911b39dd9abc8c73376';
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
    final base64Image = base64Encode(await imageFile.readAsBytes());
    final response = await http.post(url, body: {'image': base64Image});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['url'] as String?;
    }
    return null;
  }

  /// Adds a new hotspot.
  Future<void> _addHotspot(Hotspot newHotspot) async {
    // Save using Firestore-compliant model
    await HotspotService.addHotspot(newHotspot);
  }

  /// Edits an existing hotspot.
  Future<void> _editHotspot(Hotspot updatedHotspot) async {
    // Update using Firestore-compliant model
    await HotspotService.updateHotspot(updatedHotspot);
  }

  /// Deletes a hotspot by ID.
  Future<void> _deleteHotspot(String hotspotId) async {
    // Delete using Firestore-compliant model
    await HotspotService.deleteHotspot(hotspotId);
  }

  /// Shows the dialog to add a new hotspot.
  void _showAddHotspotDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => _AddHotspotDialog(
            onAdd: (Hotspot newHotspot) async {
              await _addHotspot(newHotspot);
            },
            uploadImageToImgbb: uploadImageToImgbb,
          ),
    );
  }

  /// Shows the dialog to edit an existing hotspot.
  void _showEditHotspotDialog(Hotspot hotspot, int index) async {
    await showDialog(
      context: context,
      builder:
          (context) => _AddHotspotDialog(
            hotspot: hotspot,
            onAdd: (Hotspot updatedHotspot) async {
              await _editHotspot(updatedHotspot);
            },
            uploadImageToImgbb: uploadImageToImgbb,
            isEdit: true,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.hotspots,
          style: const TextStyle(color: AppColors.textDark),
        ),
        backgroundColor: AppColors.backgroundColor,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddHotspotDialog,
            tooltip: 'Add Hotspot',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: StreamBuilder<List<Hotspot>>(
          stream: _hotspotsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading hotspots'));
            }
            _hotspots = snapshot.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _hotspots.length,
              itemBuilder: (context, index) {
                final hotspot = _hotspots[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () => _showEditHotspotDialog(hotspot, index),
                    leading:
                        hotspot.images.isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                hotspot.images.first,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            )
                            : Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.image,
                                color: Colors.black26,
                                size: 28,
                              ),
                            ),
                    title: Text(
                      hotspot.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppConstants.hotspotTitleFontSize),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotspot.category,
                          style: const TextStyle(
                            fontSize: AppConstants.hotspotCategoryFontSize,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        Text(
                          hotspot.formattedEntranceFee,
                          style: const TextStyle(fontSize: AppConstants.hotspotFeeFontSize),
                        ),
                        Text(
                          'Lat: ${hotspot.latitude != null ? hotspot.latitude!.toStringAsFixed(5) : 'N/A'}, Lng: ${hotspot.longitude != null ? hotspot.longitude!.toStringAsFixed(5) : 'N/A'}',
                          style: const TextStyle(
                            fontSize: AppConstants.hotspotLatLngFontSize,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await _deleteHotspot(hotspot.hotspotId);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AddHotspotDialog extends StatefulWidget {
  final void Function(Hotspot) onAdd;
  final Future<String?> Function(File) uploadImageToImgbb;
  final Hotspot? hotspot;
  final bool isEdit;
  const _AddHotspotDialog({
    required this.onAdd,
    required this.uploadImageToImgbb,
    this.hotspot,
    this.isEdit = false,
  });

  @override
  State<_AddHotspotDialog> createState() => _AddHotspotDialogState();
}

class _AddHotspotDialogState extends State<_AddHotspotDialog> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController operatingHoursController;
  late TextEditingController contactInfoController;
  late TextEditingController localGuideController;

  late TextEditingController transportationController;
  late TextEditingController safetyTipsController;
  late TextEditingController suggestionsController;
  late TextEditingController districtController;
  late TextEditingController municipalityController;
  String selectedCategory = AppConstants.naturalAttraction;
  double? entranceFee = 0.0;
  bool restroom = true;
  bool foodAccess = true;
  PlatformFile? pickedFile;
  String? uploadedImageUrl;
  bool isUploading = false;
  LatLng? pickedLatLng;

  @override
  void initState() {
    super.initState();
    final h = widget.hotspot;
    nameController = TextEditingController(text: h?.name ?? '');
    descriptionController = TextEditingController(text: h?.description ?? '');
    operatingHoursController = TextEditingController(
      text: h?.operatingHours ?? '',
    );
    contactInfoController = TextEditingController(text: h?.contactInfo ?? '');
    localGuideController = TextEditingController(text: h?.localGuide ?? '');

    transportationController = TextEditingController(
      text:
          h != null && h.transportation.isNotEmpty
              ? h.transportation.join(', ')
              : '',
    );
    safetyTipsController = TextEditingController(
      text: h != null && (h.safetyTips?.isNotEmpty ?? false) ? h.safetyTips!.join(', ') : '',
    );
    suggestionsController = TextEditingController(
      text: h != null && (h.suggestions?.isNotEmpty ?? false) ? h.suggestions!.join(', ') : '',
    );
    districtController = TextEditingController(text: h?.district ?? '');
    municipalityController = TextEditingController(text: h?.municipality ?? '');
    selectedCategory = h?.category ?? AppConstants.naturalAttraction;
    entranceFee = h?.entranceFee ?? 0.0;
    restroom = h?.restroom ?? true;
    foodAccess = h?.foodAccess ?? true;
    pickedLatLng = (h != null && h.latitude != null && h.longitude != null)
        ? LatLng(h.latitude!, h.longitude!)
        : null;
    uploadedImageUrl =
        (h != null && h.images.isNotEmpty) ? h.images.first : null;
  }

  /// Picks a location on the map and updates the dialog state.
  Future<void> _pickLocationOnMap() async {
    final bukidnonCenter = const LatLng(8.1500, 125.1000);
    final bukidnonBounds = LatLngBounds(
      southwest: const LatLng(7.5, 124.3),
      northeast: const LatLng(8.9, 125.7),
    );
    LatLng initial = pickedLatLng ?? bukidnonCenter;
    LatLng? tempPickedLatLng = pickedLatLng; // Local variable for dialog

    LatLng? result = await showDialog<LatLng>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Pick Location (Bukidnon Only)'),
            content: SizedBox(
              width: 400,
              height: 400,
              child: StatefulBuilder(
                builder:
                    (context, setDialogState) => GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initial,
                        zoom: 10,
                      ),
                      gestureRecognizers:
                          <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                            ),
                          },
                      webGestureHandling: WebGestureHandling.auto,
                      markers: {
                        if (tempPickedLatLng != null)
                          Marker(
                            markerId: const MarkerId('picked'),
                            position: tempPickedLatLng!,
                            infoWindow: InfoWindow(
                              title: 'Selected Location',
                              snippet: 'Lat: ${tempPickedLatLng != null ? tempPickedLatLng!.latitude.toStringAsFixed(5) : 'N/A'}, Lng: ${tempPickedLatLng != null ? tempPickedLatLng!.longitude.toStringAsFixed(5) : 'N/A'}',
                            ),
                          ),
                      },
                      onTap: (latLng) {
                        // Check if the tapped location is within bounds
                        if (latLng.latitude >=
                                bukidnonBounds.southwest.latitude &&
                            latLng.latitude <=
                                bukidnonBounds.northeast.latitude &&
                            latLng.longitude >=
                                bukidnonBounds.southwest.longitude &&
                            latLng.longitude <=
                                bukidnonBounds.northeast.longitude) {
                          setDialogState(() {
                            tempPickedLatLng = latLng;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select a location within Bukidnon.',
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      minMaxZoomPreference: const MinMaxZoomPreference(8, 18),
                      cameraTargetBounds: CameraTargetBounds(bukidnonBounds),
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                      scrollGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                    ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (tempPickedLatLng != null) {
                    Navigator.pop(context, tempPickedLatLng);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a location on the map.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (result != null) {
      setState(() {
        pickedLatLng = result;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    operatingHoursController.dispose();
    contactInfoController.dispose();
    localGuideController.dispose();

    transportationController.dispose();
    safetyTipsController.dispose();
    suggestionsController.dispose();
    districtController.dispose();
    municipalityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEdit
            ? 'Edit {AppConstants.hotspots}'
            : 'Add {AppConstants.hotspots}',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (result != null && result.files.isNotEmpty) {
                  setState(() {
                    pickedFile = result.files.first;
                    uploadedImageUrl = null;
                  });
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    pickedFile != null
                        ? (kIsWeb
                            ? Image.memory(
                              pickedFile!.bytes!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                            : Image.file(
                              File(pickedFile!.path!),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ))
                        : (uploadedImageUrl != null
                            ? Image.network(
                              uploadedImageUrl!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                            : Container(
                              height: 100,
                              width: 100,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.black26,
                              ),
                            )),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Hotspot Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items:
                  AppConstants.hotspotCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Entrance Fee',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  entranceFee = double.tryParse(value) ?? 0.0;
                });
              },
              controller: TextEditingController(
                text: entranceFee?.toString() ?? '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: operatingHoursController,
              decoration: const InputDecoration(
                labelText: 'Operating Hours',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contactInfoController,
              decoration: const InputDecoration(
                labelText: 'Contact Info',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: localGuideController,
              decoration: const InputDecoration(
                labelText: 'Local Guide',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: transportationController,
              decoration: const InputDecoration(
                labelText: 'Transportation (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: safetyTipsController,
              decoration: const InputDecoration(
                labelText: 'Safety Tips (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: suggestionsController,
              decoration: const InputDecoration(
                labelText: 'Suggestions (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: districtController,
              decoration: const InputDecoration(
                labelText: 'District',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: municipalityController,
              decoration: const InputDecoration(
                labelText: 'Municipality',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(AppConstants.restroom),
              value: restroom,
              onChanged: (value) {
                setState(() {
                  restroom = value;
                });
              },
            ),
            SwitchListTile(
              title: Text(AppConstants.foodAccess),
              value: foodAccess,
              onChanged: (value) {
                setState(() {
                  foodAccess = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    pickedLatLng == null
                        ? 'No location selected'
                        : 'Lat: ${pickedLatLng!.latitude.toStringAsFixed(5)}, Lng: ${pickedLatLng!.longitude.toStringAsFixed(5)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: TextButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Pick on Map'),
                    onPressed: _pickLocationOnMap,
                  ),
                ),
              ],
            ),
            if (isUploading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
  onPressed: isUploading
      ? null
      : () async {
          // Add "if" checks for required fields
          if (nameController.text.isEmpty ||
              descriptionController.text.isEmpty ||
              selectedCategory.isEmpty ||
              districtController.text.isEmpty ||
              municipalityController.text.isEmpty ||
              operatingHoursController.text.isEmpty ||
              contactInfoController.text.isEmpty ||
              pickedLatLng == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please fill all required fields including district and municipality, and pick a location on the map.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Store context-dependent values before async operations
          if (!mounted) return;
          final navigator = Navigator.of(context);
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final successMessage = widget.isEdit
              ? 'Hotspot updated successfully'
              : 'Hotspot added successfully';

          setState(() => isUploading = true);
          String? imageUrl = uploadedImageUrl;
          if (pickedFile != null) {
            if (kIsWeb) {
              final base64Image = base64Encode(pickedFile!.bytes!);
              imageUrl = await uploadImageToImgbbWeb(base64Image);
            } else {
              imageUrl = await widget.uploadImageToImgbb(
                File(pickedFile!.path!),
              );
            }
          }
          setState(() => isUploading = false);

          final newHotspot = Hotspot(
            hotspotId: widget.isEdit && widget.hotspot != null
                ? widget.hotspot!.hotspotId
                : DateTime.now().millisecondsSinceEpoch.toString(),
            name: nameController.text,
            description: descriptionController.text,
            category: selectedCategory,
            location: '', // Add location input if needed
            district: districtController.text,
            municipality: municipalityController.text,
            images: imageUrl != null ? [imageUrl] : [],
            transportation: transportationController.text.isNotEmpty
                ? transportationController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList()
                : [],
            operatingHours: operatingHoursController.text,
            safetyTips: safetyTipsController.text.isNotEmpty
                ? safetyTipsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList()
                : [],
            entranceFee: entranceFee,
            contactInfo: contactInfoController.text,
            localGuide: localGuideController.text,
            restroom: restroom,
            foodAccess: foodAccess,
            suggestions: suggestionsController.text.isNotEmpty
                ? suggestionsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList()
                : [],
            createdAt: widget.isEdit && widget.hotspot != null
                ? widget.hotspot!.createdAt
                : DateTime.now(),
            latitude: pickedLatLng!.latitude,
            longitude: pickedLatLng!.longitude,
          );

          widget.onAdd(newHotspot);

          // Use stored references instead of context after async gap
          if (!mounted) return;
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: AppColors.primaryTeal,
            ),
          );
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryTeal,
    foregroundColor: Colors.white,
  ),
  child: Text(widget.isEdit ? AppConstants.save : AppConstants.save),
)
      ],
    );
  }

  /// Uploads an image to Imgbb using a base64-encoded string (for web).
  Future<String?> uploadImageToImgbbWeb(String base64Image) async {
    const apiKey = 'aae8c93b12878911b39dd9abc8c73376';
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
    final response = await http.post(url, body: {'image': base64Image});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['url'] as String?;
    }
    return null;
  }
}
