import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/responsive_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _resetSent = false;
  String _resetMethod = 'email'; // 'email' or 'phone'

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendResetRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (_resetMethod == 'email') {
        await authService.forgotPassword(email: _emailController.text);
      } else {
        await authService.forgotPassword(phone: _phoneController.text);
      }
      setState(() => _resetSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset instructions sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Password Reset',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Reset password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your email or phone number and we will send password reset instructions.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'email', label: Text('Email')),
                  ButtonSegment(value: 'phone', label: Text('Phone')),
                ],
                selected: {_resetMethod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _resetMethod = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              if (_resetMethod == 'email') ...[
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  enabled: !_resetSent,
                ),
              ] else ...[
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1234567890',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^\+\d{10,15}$').hasMatch(value)) {
                      return 'Please enter a valid phone number with country code';
                    }
                    return null;
                  },
                  enabled: !_resetSent,
                ),
              ],
              const SizedBox(height: 24),
              if (_resetSent) ...[
                const Text(
                  'Check your email/SMS for password reset instructions.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _sendResetRequest,
                  child: const Text('Resend Reset Code'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetRequest,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Send Reset Code'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
