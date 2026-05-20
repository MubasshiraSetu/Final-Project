import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _agreed = false;

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the terms & conditions'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final result = await auth.register(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
      phone: _phoneCtrl.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (result.success) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x44F59E0B), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x337C3AED), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              // Step indicator
                              Row(
                                children: [
                                  _stepDot(true),
                                  _stepLine(),
                                  _stepDot(false),
                                ],
                              ),
                              const SizedBox(height: 28),

                              Text(
                                'Create account',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFEDEDED),
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Join festivo — where events meet flavour',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF8888AA),
                                ),
                              ),

                              const SizedBox(height: 36),

                              AppTextField(
                                label: 'Full name',
                                hint: 'John Doe',
                                controller: _nameCtrl,
                                prefixIcon: Icons.person_rounded,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Full name is required';
                                  }
                                  if (v.trim().length < 2) {
                                    return 'Name too short';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              AppTextField(
                                label: 'Email address',
                                hint: 'you@example.com',
                                controller: _emailCtrl,
                                prefixIcon: Icons.email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!v.contains('@') || !v.contains('.')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              AppTextField(
                                label: 'Phone number (optional)',
                                hint: '+880 1XX-XXXXXXX',
                                controller: _phoneCtrl,
                                prefixIcon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 18),

                              AppTextField(
                                label: 'Password',
                                hint: 'Min 6 characters',
                                controller: _passCtrl,
                                prefixIcon: Icons.lock_rounded,
                                isPassword: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (v.length < 6) return 'Min 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              AppTextField(
                                label: 'Confirm password',
                                hint: 'Repeat your password',
                                controller: _confirmCtrl,
                                prefixIcon: Icons.lock_outline_rounded,
                                isPassword: true,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _register(),
                                validator: (v) {
                                  if (v != _passCtrl.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Password strength indicator
                              _PasswordStrength(password: _passCtrl.text),

                              const SizedBox(height: 20),

                              // Terms agreement
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _agreed = !_agreed),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: _agreed
                                            ? const Color(0xFF7C3AED)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: _agreed
                                              ? const Color(0xFF7C3AED)
                                              : const Color(0xFF4A4A5A),
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: _agreed
                                          ? const Icon(Icons.check,
                                              size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'I agree to the Terms of Service and Privacy Policy',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: const Color(0xFF8888AA),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 28),

                              Consumer<AuthProvider>(
                                builder: (_, auth, __) => GradientButton(
                                  label: 'Create Account',
                                  isLoading: auth.isLoading,
                                  onPressed: _register,
                                ),
                              ),

                              const SizedBox(height: 24),
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: const Color(0xFF8888AA)),
                                      children: const [
                                        TextSpan(text: 'Already have an account? '),
                                        TextSpan(
                                          text: 'Sign in',
                                          style: TextStyle(
                                            color: Color(0xFF7C3AED),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(bool active) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? const Color(0xFF7C3AED)
              : const Color(0xFF2A2A3A),
        ),
      );

  Widget _stepLine() => Expanded(
        child: Container(
          height: 2,
          color: const Color(0xFF2A2A3A),
        ),
      );
}

class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  int _strength() {
    int s = 0;
    if (password.length >= 6) s++;
    if (password.length >= 10) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final s = _strength();
    final labels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'];
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF059669),
    ];
    final idx = (s - 1).clamp(0, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < s ? colors[idx] : const Color(0xFF2A2A3A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Password strength: ${labels[idx]}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: colors[idx],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
