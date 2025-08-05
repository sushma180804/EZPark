// lib/screens/find_parking_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class FindParkingScreen extends StatefulWidget {
  const FindParkingScreen({super.key});
  @override
  State<FindParkingScreen> createState() => _FindParkingScreenState();
}

class _FindParkingScreenState extends State<FindParkingScreen> {
  Future<void> _launchMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch Google Maps.')));
    }
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
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(parkingData['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Price: ₹${parkingData['pricePerHour']?.toStringAsFixed(2) ?? '0.00'}/hr"),
                  const SizedBox(height: 20),
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Your Name'), validator: (v) => v!.isEmpty ? 'Please enter your name' : null),
                  TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'Contact Number'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Please enter a contact number' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: hoursController, decoration: const InputDecoration(labelText: 'Number of Hours'), keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) < 1) ? 'Enter valid hours' : null),
                ],
              ),
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking confirmed successfully!"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find a Parking Spot")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('parking_spaces').orderBy('isAvailable', descending: true).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Something went wrong: ${snapshot.error}'));
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No parking spots have been listed yet.", style: TextStyle(fontSize: 18, color: Colors.grey)));
          
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              final price = data['pricePerHour']?.toStringAsFixed(2) ?? '0.00';
              final bool isAvailable = data['isAvailable'] ?? false;
              String availabilityInfo = "by ${data['hostName'] ?? 'N/A'}";

              if (!isAvailable && data.containsKey('bookedUntil')) {
                final Timestamp bookedUntilTimestamp = data['bookedUntil'];
                final freeTime = bookedUntilTimestamp.toDate();
                availabilityInfo = "Booked until ${freeTime.hour}:${freeTime.minute.toString().padLeft(2, '0')}";
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAvailable
                        ? [Color(0xFFE3F0FF), Color(0xFFF8F8FF)]
                        : [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isAvailable
                          ? Colors.blue.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isAvailable ? Colors.transparent : Colors.grey.shade300,
                    width: 1.2,
                  ),
                ),
                child: InkWell(
                  onTap: isAvailable ? () => _showBookingDialog(document) : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_parking_rounded,
                                color: isAvailable ? Color(0xFF3B5998) : Colors.grey,
                                size: 32),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data['title'] ?? 'No Title',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1C2B33),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          data['address'] ?? 'No Address',
                          style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 4),
                        Text(
                          availabilityInfo,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: isAvailable ? Colors.grey[500] : Colors.red.shade700,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              "₹$price/hr",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            Spacer(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFB3A7F7),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                              icon: Icon(Icons.map_outlined, size: 18),
                              label: Text("Map", style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _launchMaps(data['address']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}