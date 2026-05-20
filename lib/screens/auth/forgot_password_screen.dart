import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.resetPassword(_emailCtrl.text);
    if (!mounted) return;
    if (result.success) {
      setState(() => _sent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF16161F),
                      foregroundColor: const Color(0xFFEDEDED),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _sent ? _successView() : _formView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF16161F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A3A)),
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: Color(0xFF7C3AED), size: 28),
          ),
          const SizedBox(height: 24),
          Text(
            'Reset password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFEDEDED),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email and we\'ll send you a reset link.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF8888AA),
            ),
          ),
          const SizedBox(height: 36),
          AppTextField(
            label: 'Email address',
            hint: 'you@example.com',
            controller: _emailCtrl,
            prefixIcon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _send(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 28),
          Consumer<AuthProvider>(
            builder: (_, auth, __) => GradientButton(
              label: 'Send Reset Link',
              isLoading: auth.isLoading,
              onPressed: _send,
              icon: Icons.send_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _successView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0x2210B981),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: Color(0xFF10B981), size: 28),
        ),
        const SizedBox(height: 24),
        Text(
          'Check your inbox!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFEDEDED),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'A password reset link has been sent to\n${_emailCtrl.text}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF8888AA),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 36),
        GradientButton(
          label: 'Back to Login',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
