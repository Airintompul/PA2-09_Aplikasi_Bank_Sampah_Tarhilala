import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login/login_page.dart';
import '../user/dashboard_page.dart';
import '../petugas/dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(controller);

    scaleAnimation = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );

    controller.forward();

    startApp();
  }

  void startApp() async {

    await Future.delayed(const Duration(seconds: 3));

    bool login = await AuthService.isLoggedIn();

    if (!mounted) return;

    if (!login) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    String? role = await AuthService.getRole();

    if (role == 'petugas') {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PetugasDashboardPage()),
      );

    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserDashboardPage()),
      );

    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFC9D6),

      body: Center(
        child: FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: Image.asset(
              "assets/images/logo_tarhilala.png",
              width: 200,
            ),
          ),
        ),
      ),
    );
  }
}