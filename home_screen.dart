
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezpark/screens/profile_screen.dart';
import 'package:ezpark/screens/find_parking_screen.dart';
import 'package:ezpark/screens/list_space_screen.dart';
import 'package:ezpark/screens/activity_screen.dart';

// Returns a beautiful gradient color combination based on accent
List<Color> _getGradientColors(Color accent) {
  if ((accent.r * 255.0).round() & 0xff == 0 &&
      (accent.g * 255.0).round() & 0xff == 191 &&
      (accent.b * 255.0).round() & 0xff == 174 &&
      (accent.a * 255.0).round() & 0xff == 255) {
    // Teal: teal to light blue
    return [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2), accent.withValues(alpha: 0.18)];
  } else if ((accent.r * 255.0).round() & 0xff == 255 &&
             (accent.g * 255.0).round() & 0xff == 82 &&
             (accent.b * 255.0).round() & 0xff == 82 &&
             (accent.a * 255.0).round() & 0xff == 255) {
    // Red: peach to light red
    return [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2), accent.withValues(alpha: 0.18)];
  } else if ((accent.r * 255.0).round() & 0xff == 124 &&
             (accent.g * 255.0).round() & 0xff == 77 &&
             (accent.b * 255.0).round() & 0xff == 255 &&
             (accent.a * 255.0).round() & 0xff == 255) {
    // Purple: lavender to light purple
    return [const Color(0xFFEDE7F6), const Color(0xFFD1C4E9), accent.withValues(alpha: 0.18)];
  }
  // Default: soft white
  return [Colors.white, Colors.white];
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("EZPark"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: "Profile",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("Welcome!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold));
                  }
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final name = userData['name'] ?? 'User';
                  return Text("Hi, $name!", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold));
                },
              ),
              const SizedBox(height: 8),
              const Text(
                "What would you like to do today?",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _buildActionCard(
                context: context,
                icon: Icons.search_rounded,
                title: "Find Parking",
                subtitle: "Browse available spots in a list",
                color: const Color(0xFF00BFAE), // Vibrant teal
                accent: const Color(0xFF00BFAE),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const FindParkingScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildActionCard(
                context: context,
                icon: Icons.add_location_alt_rounded,
                title: "List Your Space",
                subtitle: "Earn money by renting out your spot",
                color: const Color(0xFFFF5252), // Vibrant red
                accent: const Color(0xFFFF5252),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ListSpaceScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildActionCard(
                context: context,
                icon: Icons.history_rounded,
                title: "My Activity",
                subtitle: "View your bookings and listings",
                color: const Color(0xFF7C4DFF), // Vibrant purple
                accent: const Color(0xFF7C4DFF),
                onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ActivityScreen()));
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      color: Colors.transparent,
      shadowColor: accent.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.5), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getGradientColors(accent),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 24.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, size: 32, color: accent),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent)),
                      const SizedBox(height: 6),
                      Text(subtitle, style: TextStyle(fontSize: 15, color: accent.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: accent.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}