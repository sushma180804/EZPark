// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final bool? confirm = await _showConfirmationDialog();
    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _performFullDeletion(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        final password = await _showPasswordReauthDialog();
        if (password != null && password.isNotEmpty) {
          await _reauthenticateAndRetryDeletion(user, password);
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        _showErrorSnackbar("Error: ${e.message}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      _showErrorSnackbar("An unexpected error occurred.");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performFullDeletion(User user) async {
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }
  
  Future<void> _reauthenticateAndRetryDeletion(User user, String password) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
      await _performFullDeletion(user);
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar("Re-authentication failed: ${e.message}");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }

  // --- ADDED DIALOG HELPER FUNCTIONS ---
  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This action is permanent and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPasswordReauthDialog() {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Identity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('For your security, please re-enter your password to continue.'),
            const SizedBox(height: 16),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(passwordController.text), child: const Text('Confirm')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of the build method is unchanged)
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile & Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            Text('Logged in as:', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(user?.email ?? 'No email found', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: _isLoading ? null : _logout,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete My Account'),
                onPressed: _isLoading ? null : _deleteAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}