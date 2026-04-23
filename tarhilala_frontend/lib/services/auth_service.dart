import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  static const String baseUrl = "http://10.0.2.2:8000/api";

  // =====================================================
  // HELPER RESULT FORMAT
  // =====================================================
  static Map<String, dynamic> _result({
    required bool success,
    required String message,
    dynamic data,
    String? token,
  }) {
    return {
      "success": success,
      "message": message,
      "data": data,
      "token": token
    };
  }

  static Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Mengambil ID yang disimpan saat login (pastikan kuncinya sama yaitu "user_id")
    return prefs.getInt("user_id"); 
  }

  // =====================================================
  // HELPER POST REQUEST
  // =====================================================
  static Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, String> body) async {

    try {

      var url = Uri.parse("$baseUrl$endpoint");

      var response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      print("POST $endpoint → ${response.body}");

      var data = jsonDecode(response.body);

      return _result(
        success: data["success"] ?? response.statusCode == 200,
        message: data["message"] ?? "",
        data: data["data"],
        token: data["token"],
      );

    } catch (e) {

      return _result(
        success: false,
        message: "Tidak dapat terhubung ke server",
      );

    }
  }

  // =====================================================
  // LOGIN (NASABAH / PETUGAS)
  // =====================================================
  static Future<Map<String, dynamic>> login(
      String email, String password) async {

    var res = await _post("/user/login", {
      "email": email,
      "password": password,
    });

    if (res["success"] == true) {

      SharedPreferences prefs = await SharedPreferences.getInstance();

      String token = res["token"] ?? "";

      await prefs.setString("token", token);

      var user = res["data"];

      await prefs.setInt("user_id", user["id"]);
      await prefs.setString("name", user["nama"] ?? "");
      await prefs.setString("email", user["email"] ?? "");
      await prefs.setString("role", user["role"] ?? "nasabah");

    }

    return res;
  }

  // =====================================================
  // REGISTER NASABAH
  // =====================================================
  static Future<Map<String, dynamic>> register(
      String nama,
      String email,
      String telepon,
      String password) async {

    return await _post("/user/register", {
      "nama": nama,
      "email": email,
      "nomor_telepon": telepon,
      "password": password,
    });
  }

  // =====================================================
  // SEND OTP
  // =====================================================
  static Future<Map<String, dynamic>> sendOtp(String email) async {

    return await _post("/forgot-password", {
      "email": email,
    });

  }

  // =====================================================
  // VERIFY OTP
  // =====================================================
  static Future<Map<String, dynamic>> verifyOtp(
      String email, String otp) async {

    return await _post("/verify-otp", {
      "email": email,
      "otp": otp,
    });

  }

  // =====================================================
  // RESET PASSWORD
  // =====================================================
  static Future<Map<String, dynamic>> resetPassword(
      String email, String newPassword) async {

    return await _post("/reset-password", {
      "email": email,
      "password": newPassword,
    });

  }

  // =====================================================
  // GET TOKEN
  // =====================================================
  static Future<String?> getToken() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");

  }

  // =====================================================
  // GET ROLE
  // =====================================================
  static Future<String?> getRole() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");

  }

  // =====================================================
  // LOGOUT
  // =====================================================
  static Future logout() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

  }

  // =====================================================
  // AUTHORIZED GET
  // =====================================================
  static Future<Map<String, dynamic>> authorizedGet(String endpoint) async {

    try {

      String? token = await getToken();

      var url = Uri.parse("$baseUrl$endpoint");

      var response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );

      print("GET $endpoint → ${response.body}");

      var data = jsonDecode(response.body);

      return _result(
        success: data["success"] ?? true,
        message: data["message"] ?? "",
        data: data["data"],
      );

    } catch (e) {

      return _result(
        success: false,
        message: "Gagal menghubungi server",
      );

    }

  }

  // =====================================================
  // CHECK LOGIN
  // =====================================================
  static Future<bool> isLoggedIn() async {

    String? token = await getToken();
    return token != null;

  }

}