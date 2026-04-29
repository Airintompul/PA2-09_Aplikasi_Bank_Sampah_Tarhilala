import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago; // Tambahan import timeago

import 'screens/splash/splash_screen.dart';
import 'screens/login/login_page.dart';
import 'screens/register/register_page.dart';
import 'screens/user/dashboard_page.dart';
import 'screens/petugas/dashboard_page.dart';
import 'screens/auth/forgot_password_page.dart';
import 'screens/auth/otp_verification_page.dart';
import 'screens/auth/reset_password_page.dart';

void main() {
  timeago.setLocaleMessages('id', timeago.IdMessages());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        fontFamily: 'PlusJakartaSans', // 👈 ini kuncinya
      ),

      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),

        '/user': (context) => UserDashboardPage(),
        '/petugas': (context) => PetugasDashboardPage(),

        '/forgot': (context) => ForgotPasswordPage(),
        '/otp': (context) => OtpVerificationPage(),
        '/reset': (context) => ResetPasswordPage(),
      },

      home: const SplashScreen(),
    );
  }
}