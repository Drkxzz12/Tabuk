// ===========================================
// lib/screens/tourist_module/trips/trips_screen.dart
// ===========================================
// Screen for displaying and managing user trips.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'trip_basic_info_screen.dart';
import '../../../services/trip_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/trip_model.dart' as firestoretrip;

/// Screen for displaying and managing user trips.
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with SingleTickerProviderStateMixin {
  // UI and label constants
  static const int _tabCount = 2;
  static const String _collectionName = 'trip_planning';
  static const String _archivedStatus = 'Archived';
  static const String _planningStatus = 'Planning';
  static const String _myTripsLabel = 'My Trips';
  static const String _activeTabLabel = 'Active';
  static const String _archivedTabLabel = 'Archived';
  static const String _tripAddedMsg = 'Trip to {destination} added successfully!';
  static const String _tripArchivedMsg = 'Trip to {destination} archived';
  static const String _tripRestoredMsg = 'Trip to {destination} restored';
  static const String _tripDeletedMsg = 'Trip deleted';
  static const double _snackBarMargin = 16.0;
  static const double _snackBarBorderRadius = 8.0;
  static const int _snackBarDurationSec = 2;

  late TabController _tabController;
  late Stream<QuerySnapshot> _tripStream;
  String? _userId;

  /// Gets the current user ID from AuthService.
  String getUserId() {
    return AuthService.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _tabController.addListener(_handleTabChange);
    _userId = getUserId();
    _tripStream = FirebaseFirestore.instance
        .collection(_collectionName)
        .where('user_id', isEqualTo: _userId)
        .snapshots();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  /// Adds a new trip to Firestore and shows a success message
  Future<void> _addNewTrip(firestoretrip.Trip trip) async {
    try {
      final newTrip = firestoretrip.Trip(
        tripPlanId: trip.tripPlanId.isNotEmpty ? trip.tripPlanId : const Uuid().v4(),
        title: trip.title,
        startDate: trip.startDate,
        endDate: trip.endDate,
        transportation: trip.transportation,
        spots: trip.spots,
        userId: _userId ?? '',
        status: trip.status,
      );
      await TripService.saveTrip(newTrip);
      _showSnackBar(_tripAddedMsg.replaceFirst('{destination}', trip.title), Colors.green);
    } catch (e) {
      _showSnackBar('Failed to add trip: $e', Colors.red);
    }
  }

  /// Archives a trip and shows a message
  Future<void> _archiveTrip(firestoretrip.Trip trip) async {
    try {
      final archivedTrip = firestoretrip.Trip(
        tripPlanId: trip.tripPlanId,
        title: trip.title,
        startDate: trip.startDate,
        endDate: trip.endDate,
        transportation: trip.transportation,
        spots: trip.spots,
        userId: trip.userId,
        status: _archivedStatus,
      );
      await TripService.saveTrip(archivedTrip);
      _showSnackBar(_tripArchivedMsg.replaceFirst('{destination}', trip.title), Colors.blue);
    } catch (e) {
      _showSnackBar('Failed to archive trip: $e', Colors.red);
    }
  }

  /// Restores an archived trip and shows a message
  Future<void> _restoreTrip(firestoretrip.Trip trip) async {
    try {
      final restoredTrip = firestoretrip.Trip(
        tripPlanId: trip.tripPlanId,
        title: trip.title,
        startDate: trip.startDate,
        endDate: trip.endDate,
        transportation: trip.transportation,
        spots: trip.spots,
        userId: trip.userId,
        status: _planningStatus,
      );
      await TripService.saveTrip(restoredTrip);
      _showSnackBar(_tripRestoredMsg.replaceFirst('{destination}', trip.title), Colors.blue);
    } catch (e) {
      _showSnackBar('Failed to restore trip: $e', Colors.red);
    }
  }

  /// Deletes a trip and shows a message
  Future<void> _deleteTrip(String tripPlanId) async {
    try {
      await TripService.deleteTrip(tripPlanId);
      _showSnackBar(_tripDeletedMsg, Colors.red);
    } catch (e) {
      _showSnackBar('Failed to delete trip: $e', Colors.red);
    }
  }

  /// Shows a SnackBar with the given message and color
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(_snackBarMargin),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_snackBarBorderRadius)),
        duration: const Duration(seconds: _snackBarDurationSec),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _tripStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final trips = snapshot.data?.docs
                .map((doc) {
                  final data = doc.data();
                  if (data is Map<String, dynamic>) {
                    return firestoretrip.Trip.fromMap(data);
                  }
                  return null;
                })
                .whereType<firestoretrip.Trip>()
                .toList() ??
            [];
        final myTrips = trips.where((t) => t.status != _archivedStatus).toList();
        final archivedTrips = trips.where((t) => t.status == _archivedStatus).toList();
        return DefaultTabController(
          length: _tabCount,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(_myTripsLabel),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [Tab(text: _activeTabLabel), Tab(text: _archivedTabLabel)],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildTripList(myTrips, false),
                _buildTripList(archivedTrips, true),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TripBasicInfoScreen(
                      destination: "New Destination",
                    ),
                  ),
                );
                if (result != null && result is Map<String, dynamic>) {
                  // If the trip comes from destination selection, save it
                  final trip = firestoretrip.Trip.fromMap(result);
                  if (result['fromDestinationSelection'] == true) {
                    await TripService.saveTrip(trip);
                    _showSnackBar(_tripAddedMsg.replaceFirst('{destination}', trip.title), Colors.green);
                  } else {
                    _addNewTrip(trip);
                  }
                  if (_tabController.index != 0) {
                    _tabController.animateTo(0);
                  }
                }
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  /// Shows the edit trip form/modal and saves changes/// Shows the edit trip form/modal and saves changes
  Future<void> _editTrip(firestoretrip.Trip trip) async {
    final TextEditingController nameController = TextEditingController(text: trip.title);
    DateTime startDate = trip.startDate;
    DateTime endDate = trip.endDate;
    String transportation = trip.transportation;
    List<String> spots = List<String>.from(trip.spots);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Trip'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Destination'),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a destination' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    startDate = picked;
                                    if (endDate.isBefore(startDate)) {
                                      endDate = startDate.add(const Duration(days: 1));
                                    }
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Start Date'),
                                child: Text('${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    endDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'End Date'),
                                child: Text('${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: transportation.isNotEmpty ? transportation : null,
                        items: ['Car', 'Plane', 'Bus', 'Boat']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              transportation = val;
                            });
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Transportation'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: spots.join(', '),
                        decoration: const InputDecoration(labelText: 'Spots (comma separated)'),
                        onChanged: (val) {
                          spots = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      try {
                        final updatedTrip = firestoretrip.Trip(
                          tripPlanId: trip.tripPlanId,
                          title: nameController.text.trim(),
                          startDate: startDate,
                          endDate: endDate,
                          transportation: transportation,
                          spots: spots,
                          userId: _userId ?? '',
                          status: trip.status,
                        );
                        await TripService.saveTrip(updatedTrip);
                        
                        // Close the dialog first
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                        
                        // Then show the snackbar using the main widget's context
                        if (mounted) {
                          _showSnackBar('Trip updated!', Colors.green);
                        }
                      } catch (e) {
                        // Handle error case
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update trip: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  /// Builds the trip list for active or archived trips
  Widget _buildTripList(List<firestoretrip.Trip> trips, bool isArchived) {
    return ListView.builder(
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return ListTile(
          title: Text(trip.title),
          subtitle: Text(trip.title), // UI label is 'Destination'
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isArchived)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editTrip(trip),
                  tooltip: 'Edit',
                ),
              if (!isArchived)
                IconButton(
                  icon: const Icon(Icons.archive),
                  onPressed: () => _archiveTrip(trip),
                  tooltip: 'Archive',
                ),
              if (isArchived)
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () => _restoreTrip(trip),
                  tooltip: 'Restore',
                ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteTrip(trip.tripPlanId),
                tooltip: 'Delete',
              ),
            ],
          ),
        );
      },
    );
  }
}
