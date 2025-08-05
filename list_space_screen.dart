// lib/screens/list_space_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListSpaceScreen extends StatefulWidget {
  const ListSpaceScreen({super.key});

  @override
  State<ListSpaceScreen> createState() => _ListSpaceScreenState();
}

class _ListSpaceScreenState extends State<ListSpaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostNameController = TextEditingController();
  final _hostContactController = TextEditingController();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _hostNameController.text = userDoc.data()?['name'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _hostNameController.dispose();
    _hostContactController.dispose();
    _titleController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("You must be logged in.");

      await FirebaseFirestore.instance.collection('parking_spaces').add({
        'hostUid': user.uid,
        'hostName': _hostNameController.text.trim(),
        'hostContact': _hostContactController.text.trim(),
        'title': _titleController.text.trim(),
        'address': _addressController.text.trim(),
        'pricePerHour': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Parking space listed successfully!"), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to list space: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("List Your Parking Space"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle("Parking Spot Title"),
                TextFormField(controller: _titleController, decoration: const InputDecoration(hintText: "e.g., Secure Basement Parking"), validator: (v) => v!.isEmpty ? 'Please enter a title' : null),
                const SizedBox(height: 24),
                _buildSectionTitle("Address"),
                TextFormField(controller: _addressController, decoration: const InputDecoration(hintText: "Enter the full, searchable address"), maxLines: 3, validator: (v) => v!.isEmpty ? 'Please enter an address' : null),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildSectionTitle("Your Name"),
                      TextFormField(controller: _hostNameController, decoration: const InputDecoration(hintText: "Display name"), validator: (v) => v!.isEmpty ? 'Please enter your name' : null),
                    ])),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                       _buildSectionTitle("Your Contact"),
                      TextFormField(controller: _hostContactController, decoration: const InputDecoration(hintText: "Contact number"), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Please enter a contact number' : null),
                    ])),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle("Price per Hour (in ₹)"),
                TextFormField(controller: _priceController, decoration: const InputDecoration(hintText: "e.g., 50", prefixText: "₹ "), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => v!.isEmpty ? 'Please enter a price' : null),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveListing,
                    icon: _isLoading ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Icons.save_alt_rounded),
                    label: const Text("SAVE LISTING"),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}