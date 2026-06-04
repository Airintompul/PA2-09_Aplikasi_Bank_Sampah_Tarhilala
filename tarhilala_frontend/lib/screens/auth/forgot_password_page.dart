import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login/login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  TextEditingController emailController = TextEditingController();
  bool loading = false;

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

  void sendOtp() async {
    if (emailController.text.isEmpty || !emailController.text.contains("@")) {
      showCustomSnackBar("Masukkan email yang valid");
      return;
    }

    setState(() => loading = true);

    try {
      var response = await AuthService.sendOtp(emailController.text);

      setState(() => loading = false);

      if (response['success'] == true) {
        showCustomSnackBar("OTP berhasil dikirim", isError: false);

        Future.delayed(Duration(milliseconds: 1500), () {
          Navigator.pushNamed(
            context,
            '/otp',
            arguments: emailController.text,
          );
        });
        return;
      }

      String message = response['message'] ?? "Email tidak ditemukan";
      if (response['errors'] != null) {
        message = response['errors'].toString();
      }
      showCustomSnackBar(message);
    } catch (e) {
      setState(() => loading = false);
      showCustomSnackBar("Email tidak terdaftar");
    }
  }

  /// Kembali ke LoginPage dengan slide dari kiri (kebalikan dari saat masuk)
  void goBackToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 400),
        reverseTransitionDuration: Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide = Tween<Offset>(
            begin: Offset(-1.0, 0.0), // datang dari kiri = efek "kembali"
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
      ),
    );
  }

  Widget inputField(controller, hint) {
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
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
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
              child: Container(
                height: 210,
                color: Color(0xFF1F4F8C),
              ),
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
                      "Forgot Password",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "Enter your email to receive an OTP",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),

                    SizedBox(height: 25),

                    inputField(emailController, "Enter Your Email"),

                    loading
                        ? CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1F4F8C),
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                "Send OTP",
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
                      onPressed: goBackToLogin, // <-- pakai method baru
                      child: Text(
                        "Back to Login",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
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
      size.width * 0.2,
      size.height - 120,
      size.width * 0.4,
      size.height - 60,
    );

    path.quadraticBezierTo(
      size.width * 0.6,
      size.height - 180,
      size.width * 0.75,
      size.height - 70,
    );

    path.quadraticBezierTo(
      size.width * 0.9,
      size.height - 130,
      size.width,
      size.height - 60,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}