import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class NotificationService {
  static const String apiUrl = "http://10.0.2.2:8000/api";

  // Tambahkan fungsi pembantu untuk mendapatkan prefix URL berdasarkan role
  static Future<String> _getPrefix() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Asumsikan saat login Anda menyimpan role di SharedPreferences
    String role = prefs.getString('role') ?? 'nasabah'; 
    
    // Jika role petugas/driver, gunakan prefix 'driver' atau 'petugas' 
    // sesuai yang Anda buat di routes/api.php Laravel
    return (role == 'driver' || role == 'petugas') ? 'petugas' : 'nasabah';
  }

  static Future<List> getNotifications() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String prefix = await _getPrefix(); // Ambil prefix dinamis

      final response = await http.get(
        Uri.parse("$apiUrl/$prefix/notifications"), // URL jadi dinamis
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        return result['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error getNotifications: $e");
      return [];
    }
  }

  static Future<bool> markAsRead(int id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String prefix = await _getPrefix();

      final response = await http.put(
        Uri.parse("$apiUrl/$prefix/notifications/$id/read"), // URL jadi dinamis
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}