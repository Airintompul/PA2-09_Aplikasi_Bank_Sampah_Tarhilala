import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://10.0.2.2:8000/api";

  // ===============================================================
  // 🔧 HELPER: standardized return format
  // ===============================================================
  static Map<String, dynamic> _result({
    required bool success,
    required String message,
    dynamic data,
  }) {
    return {
      "success": success,
      "message": message,
      "data": data,
    };
  }

  // ===============================================================
  // 🔧 HELPER: safe POST request
  // ===============================================================
  static Future<Map<String, dynamic>> _post(String endpoint, Map<String, String> body) async {
    var url = Uri.parse("$baseUrl$endpoint");

    try {
      var response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      print("POST $url → ${response.body}");

      var data = jsonDecode(response.body);

      // 🔥 FIX DI SINI
      return {
        "success": data["success"] ?? (response.statusCode == 200),
        "message": data["message"] ?? "Terjadi kesalahan",
        "data": data["data"],
        "token": data["token"],
      };

    } catch (e) {
      return {
        "success": false,
        "message": "Gagal menghubungi server",
        "data": null,
        "token": null,
      };
    }
  }

  // ===============================================================
  // 🔧 LOGIN ADMIN
  // ===============================================================
  static Future<Map<String, dynamic>> loginAdmin(String email, String password) async {
    var res = await _post("/admin/login", {
      "email": email,
      "password": password,
    });

    if (res["success"] == true && res["data"]?["token"] != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", res["data"]["token"]);
      await prefs.setString("role", "admin");
    }

    return res;
  }

    // ===============================================================
    // 🔧 LOGIN USER
    // ===============================================================
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    var res = await _post("/user/login", {
      "email": email,
      "password": password,
    });

    print("LOGIN FULL RESPONSE: $res");

    if (res["success"] == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String token = res["token"] ?? ""; 

      print("TOKEN LOGIN: $token");

      await prefs.setString("token", token);

      var user = res["data"];

      await prefs.setInt("user_id", user["id"]);
      await prefs.setString("name", user["nama"] ?? "");
      await prefs.setString("email", user["email"] ?? "");
      await prefs.setString("role", user["role"] ?? "nasabah");
    }

    return res;
  }

  // ===============================================================
  // 🔧 REGISTER
  // ===============================================================
  static Future<Map<String, dynamic>> register(
      String nama, String email, String telepon, String password) async {
    return await _post("/user/register", {
      "nama": nama,
      "email": email,
      "nomor_telepon": telepon,
      "password": password,
    });
  }

  // ===============================================================
  // 🔧 FORGOT PASSWORD (Send OTP)
  // ===============================================================
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    return await _post("/forgot-password", {
      "email": email,
    });
  }

  // ===============================================================
  // 🔧 VERIFY OTP
  // ===============================================================
  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    return await _post("/verify-otp", {
      "email": email,
      "otp": otp,
    });
  }

  // ===============================================================
  // 🔧 RESET PASSWORD
  // ===============================================================
  static Future<Map<String, dynamic>> resetPassword(String email, String newPassword) async {
    return await _post("/reset-password", {
      "email": email,
      "password": newPassword,
    });
  }

  // ===============================================================
  // 🔧 TOKEN & ROLE
  // ===============================================================
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // ===============================================================
  // 🔧 LOGOUT
  // ===============================================================
  static Future logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ===============================================================
  // 🔧 AUTHORIZED GET
  // ===============================================================
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
      return _result(success: false, message: "Gagal menghubungi server");
    }
  }

  // ===============================================================
  // 🔧 CHECK LOGIN
  // ===============================================================
  static Future<bool> isLoggedIn() async {
    String? token = await getToken();
    return token != null;
  }
}