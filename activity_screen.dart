// lib/screens/activity_screen.dart
import 'package:flutter/material.dart';
// --- THE FIX IS ON THIS LINE ---
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return const Scaffold(body: Center(child: Text("Please log in to see your activity.")));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Activity"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "My Bookings", icon: Icon(Icons.drive_eta_rounded)),
              Tab(text: "My Listings", icon: Icon(Icons.home_work_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildQueryStream(
              FirebaseFirestore.instance
                  .collection('bookings')
                  .where('driverUid', isEqualTo: currentUserUid)
                  .orderBy('bookingTime', descending: true),
              "You haven't booked any spots yet.",
              (doc) {
                final data = doc.data() as Map<String, dynamic>;
                final bookingTime = (data['bookingTime'] as Timestamp).toDate();
                return ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                  title: Text(data['parkingTitle'] ?? 'No Title'),
                  subtitle: Text('Booked on: ${bookingTime.day}/${bookingTime.month}/${bookingTime.year}'),
                );
              },
            ),
            _buildQueryStream(
              FirebaseFirestore.instance
                  .collection('parking_spaces')
                  .where('hostUid', isEqualTo: currentUserUid)
                  .orderBy('createdAt', descending: true),
              "You haven't listed any spots yet.",
              (doc) {
                final data = doc.data() as Map<String, dynamic>;
                final bool isAvailable = data['isAvailable'] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.local_parking, color: isAvailable ? Colors.blue : Colors.grey),
                    title: Text(data['title'] ?? 'No Title'),
                    subtitle: Text(isAvailable ? 'Available for booking' : 'Currently Booked'),
                    trailing: isAvailable
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: "Delete Listing",
                            onPressed: () => _deleteListing(context, doc),
                          )
                        : ElevatedButton(
                            onPressed: () => _markAsAvailable(context, doc),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text("Make Available"),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteListing(BuildContext context, DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete this listing?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('parking_spaces').doc(doc.id).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing deleted successfully."), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAsAvailable(BuildContext context, DocumentSnapshot doc) async {
    await FirebaseFirestore.instance.collection('parking_spaces').doc(doc.id).update({
      'isAvailable': true,
      'bookedUntil': FieldValue.delete(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Spot is now available for booking again."), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildQueryStream(Query query, String emptyMessage, Widget Function(DocumentSnapshot) itemBuilder) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(emptyMessage, style: const TextStyle(fontSize: 16, color: Colors.grey)));
        }
        return ListView(
          padding: const EdgeInsets.only(top: 8),
          children: snapshot.data!.docs.map(itemBuilder).toList(),
        );
      },
    );
  }
}