import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart'; // Asumsi Anda menyimpan token di sini

class RewardService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Sesuaikan IP backend Anda

  // Ambil semua daftar reward dari tabel 'reward'
  static Future<List<dynamic>> getRewards() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rewards'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Ambil total poin user saat ini dari tabel 'poin_log'
  static Future<int> getUserPoints() async {
    try {
      final token = await AuthService.getToken(); // Ambil token login
      final response = await http.get(
        Uri.parse('$baseUrl/user/points'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['total_poin'];
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}