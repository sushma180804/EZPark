// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(17.448294, 78.391487), // Hyderabad
    zoom: 12,
  );

  final Set<Marker> _markers = {};
  // The unused _mapController variable has been removed.

  @override
  void initState() {
    super.initState();
    _loadParkingSpots();
  }

  void _loadParkingSpots() {
    FirebaseFirestore.instance
        .collection('parking_spaces')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      
      final Set<Marker> newMarkers = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['location'] != null && data['location'] is GeoPoint) {
            final GeoPoint location = data['location'];
            final marker = Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(location.latitude, location.longitude),
              infoWindow: InfoWindow(
                title: data['title'],
                snippet: "Tap here to book for ₹${data['pricePerHour']?.toStringAsFixed(2) ?? '0.00'}/hr",
              ),
              onTap: () {
                // A small delay ensures the info window is visible before the dialog appears
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _showBookingDialog(doc);
                  }
                });
              },
            );
            newMarkers.add(marker);
        }
      }
      
      if(mounted) {
        setState(() {
          _markers.clear();
          _markers.addAll(newMarkers);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Parking Near You"),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialCameraPosition,
        markers: _markers,
        // The onMapCreated callback is removed as we no longer have a controller to assign.
      ),
    );
  }

  Future<void> _showBookingDialog(DocumentSnapshot parkingDoc) async {
    final parkingData = parkingDoc.data() as Map<String, dynamic>;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final hoursController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (mounted) nameController.text = userDoc.data()?['name'] ?? '';
    }
    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Your Booking'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(parkingData['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Price: ₹${parkingData['pricePerHour']?.toStringAsFixed(2) ?? '0.00'}/hr"),
              const SizedBox(height: 20),
              TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Your Name'), validator: (v) => v!.isEmpty ? 'Please enter your name' : null),
              TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'Contact Number'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Please enter a contact number' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: hoursController,
                decoration: const InputDecoration(labelText: 'Number of Hours'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) < 1) ? 'Enter valid hours' : null,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _confirmBooking(parkingDoc, nameController.text.trim(), phoneController.text.trim(), int.parse(hoursController.text.trim()));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Book Now'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmBooking(DocumentSnapshot parkingDoc, String bookerName, String bookerPhone, int hours) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final parkingData = parkingDoc.data() as Map<String, dynamic>;
    final bookingTime = DateTime.now();
    final freeUpTime = bookingTime.add(Duration(hours: hours));
    
    WriteBatch batch = FirebaseFirestore.instance.batch();
    DocumentReference bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
    batch.set(bookingRef, {
      'parkingSpaceId': parkingDoc.id, 'parkingTitle': parkingData['title'], 'hostUid': parkingData['hostUid'],
      'driverUid': user.uid, 'bookerName': bookerName, 'bookerContact': bookerPhone,
      'bookingTime': bookingTime, 'hoursBooked': hours, 'freeUpTime': freeUpTime, 'status': 'confirmed',
    });
    DocumentReference spaceRef = FirebaseFirestore.instance.collection('parking_spaces').doc(parkingDoc.id);
    batch.update(spaceRef, {'isAvailable': false, 'bookedUntil': freeUpTime});
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking confirmed successfully!"), backgroundColor: Colors.green),
      );
    }
  }
}