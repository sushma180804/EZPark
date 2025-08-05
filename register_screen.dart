// lib/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful! Please log in to continue."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Registration failed.")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: Stack(
         children: [
           Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/login_bg.jpg'), fit: BoxFit.cover))),
           Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withAlpha(150), Colors.black.withAlpha(180)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
           SafeArea(child: Center(child: SingleChildScrollView(
             padding: const EdgeInsets.all(24.0),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(20),
               child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withAlpha(50))),
                 child: Form(
                   key: _formKey,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.stretch,
                     children: [
                       Text("Join EZPark", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                       const SizedBox(height: 24),
                       _buildTextFormField(controller: _nameController, label: "Full Name"),
                       const SizedBox(height: 16),
                       _buildTextFormField(controller: _emailController, label: "Email ID", keyboardType: TextInputType.emailAddress),
                       const SizedBox(height: 16),
                       _buildPasswordField(),
                       const SizedBox(height: 24),
                       ElevatedButton(
                         onPressed: _isLoading ? null : _registerUser,
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Theme.of(context).colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                         child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                            : const Text("REGISTER", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                       ),
                       TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: Text("Already have an account? Login", style: TextStyle(color: Colors.white.withAlpha(200))))
                     ],
                   )
                 ))
               ),
             ),
           ))),
         ],
       ),
    );
  }
  
  // --- THESE HELPER METHODS ARE NOW INCLUDED ---
  Widget _buildTextFormField({required TextEditingController controller, required String label, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withAlpha(180)),
        filled: true,
        fillColor: Colors.black.withAlpha(50),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your $label';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _isPasswordObscured,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: TextStyle(color: Colors.white.withAlpha(180)),
        filled: true,
        fillColor: Colors.black.withAlpha(50),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white.withAlpha(180),
          ),
          onPressed: () {
            setState(() {
              _isPasswordObscured = !_isPasswordObscured;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your Password';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }
}