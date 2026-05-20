import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/app_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.login(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
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
      body: Stack(
        children: [
          // Background glow blobs
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x557C3AED), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x33F59E0B), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),

                        // Logo mark
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFF59E0B)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.celebration_rounded,
                              color: Colors.white, size: 28),
                        ),

                        const SizedBox(height: 32),
                        Text(
                          'Welcome back',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFEDEDED),
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to manage your events & food',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF8888AA),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 44),

                        AppTextField(
                          label: 'Email address',
                          hint: 'you@example.com',
                          controller: _emailCtrl,
                          prefixIcon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        AppTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passCtrl,
                          prefixIcon: Icons.lock_rounded,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 6) return 'Min 6 characters';
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF7C3AED),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => GradientButton(
                            label: 'Sign In',
                            isLoading: auth.isLoading,
                            onPressed: _login,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Color(0xFF2A2A3A))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF8888AA),
                                      fontSize: 13)),
                            ),
                            const Expanded(child: Divider(color: Color(0xFF2A2A3A))),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Register button (outlined)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const RegisterScreen(),
                                transitionsBuilder: (_, anim, __, child) =>
                                    SlideTransition(
                                  position: Tween<Offset>(
                                          begin: const Offset(1, 0),
                                          end: Offset.zero)
                                      .animate(anim),
                                  child: child,
                                ),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2A2A3A)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              foregroundColor: const Color(0xFFEDEDED),
                            ),
                            child: Text(
                              'Create an account',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
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
            ),
          ),
        ],
      ),
    );
  }
}
