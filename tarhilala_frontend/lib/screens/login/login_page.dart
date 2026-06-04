import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../register/register_page.dart';
import '../auth/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool loading = false;
  bool _obscurePassword = true;

  void showCustomSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Helper untuk membuat PageRouteBuilder dengan animasi slide + fade
  /// [slideFrom]: arah datangnya halaman baru
  ///   Offset(1, 0)  = dari kanan  → maju ke halaman berikutnya
  ///   Offset(-1, 0) = dari kiri   → kembali ke halaman sebelumnya
  PageRouteBuilder _slideRoute(Widget page, {Offset slideFrom = const Offset(1.0, 0.0)}) {
    return PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 400),
      reverseTransitionDuration: Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: slideFrom,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ));

        final fade = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ));

        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: child,
          ),
        );
      },
    );
  }

  void login() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      showCustomSnackBar("Email dan password wajib diisi");
      return;
    }

    if (!email.text.contains("@")) {
      showCustomSnackBar("Format email tidak valid");
      return;
    }

    setState(() => loading = true);

    var response = await AuthService.login(email.text, password.text);

    setState(() => loading = false);

    if (response['success'] == true) {
      String role = response['data']['role'];

      if (role == "petugas") {
        Navigator.pushReplacementNamed(context, '/petugas');
      } else {
        Navigator.pushReplacementNamed(context, '/user');
      }
    } else {
      String message = response['message'] ?? "Login gagal";
      showCustomSnackBar(message);
    }
  }

  void goToRegister() {
    Navigator.pushReplacement(
      context,
      _slideRoute(RegisterPage()),
    );
  }

  void goToForgotPassword() {
    Navigator.push(
      context,
      _slideRoute(ForgotPasswordPage()),
    );
  }

  Widget inputField(
    controller,
    hint, {
    bool obscure = false,
    bool showToggle = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          suffixIcon: showToggle
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFBFC9D6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: WaveClipper(),
              child: Container(height: 210, color: Color(0xFF1F4F8C)),
            ),

            Transform.translate(
              offset: Offset(0, -50),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    Transform.translate(
                      offset: Offset(0, 60),
                      child: Image.asset(
                        "assets/images/logo_tarhilala.png",
                        width: 220,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "Welcome!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "Please Login to Your Account",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),

                    SizedBox(height: 25),

                    inputField(email, "Enter Your Email"),

                    inputField(
                      password,
                      "Enter Your Password",
                      obscure: _obscurePassword,
                      showToggle: true,
                      onToggle: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: goToForgotPassword, // <-- pakai method baru
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 10),

                    loading
                        ? CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1F4F8C),
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                    SizedBox(height: 15),

                    TextButton(
                      onPressed: goToRegister,
                      child: RichText(
                        text: TextSpan(
                          text: "Don't Have a Account? ",
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width * 0.2, size.height - 120,
      size.width * 0.4, size.height - 60,
    );
    path.quadraticBezierTo(
      size.width * 0.6, size.height - 180,
      size.width * 0.75, size.height - 70,
    );
    path.quadraticBezierTo(
      size.width * 0.9, size.height - 130,
      size.width, size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}