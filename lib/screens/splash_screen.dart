import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      await auth.loadProfile();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundDark),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(AppColors.primaryViolet), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(AppColors.primaryViolet).withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(Icons.celebration_rounded,
                  color: Colors.white, size: 40),
            )
                .animate()
                .scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.5, 0.5))
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(AppColors.primaryViolet), Color(0xFFF59E0B)],
              ).createShader(b),
              child: Text(
                'festivo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              'Events & Food, Simplified',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(AppColors.textSecondary),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            )
                .animate(delay: 500.ms)
                .fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
