// lib/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ezpark/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  // State variable to track password visibility
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // AuthGate will handle navigation
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed.")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address to reset password.")),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset link sent! Check your email inbox.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "An error occurred.")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                        const Icon(Icons.local_parking_rounded, size: 60, color: Colors.white),
                        const SizedBox(height: 16),
                        Text("Welcome Back", style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                       _buildTextFormField(controller: _emailController, label: "Email ID"),
                       const SizedBox(height: 16),
                       // Use the new password widget
                       _buildPasswordField(),
                       Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Align(
                           alignment: Alignment.centerRight,
                           child: TextButton(
                             onPressed: _isLoading ? null : _forgotPassword,
                             child: Text("Forgot Password?", style: TextStyle(color: Colors.white.withAlpha(200))),
                           ),
                         ),
                       ),
                       const SizedBox(height: 16),
                       ElevatedButton(
                         onPressed: _isLoading ? null : _loginUser,
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Theme.of(context).colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                         child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                            : const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                       ),
                       TextButton(
                         onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen())),
                         child: Text("New to EZPark? Create Account", style: TextStyle(color: Colors.white.withAlpha(200))),
                       )
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

  // Helper for the Email field
  Widget _buildTextFormField({required TextEditingController controller, required String label}) {
     return TextFormField(
      controller: controller,
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

  // Helper specifically for the Password field with the visibility toggle
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
        return null;
      },
    );
  }
}