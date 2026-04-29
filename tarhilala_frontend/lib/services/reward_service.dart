import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RewardService {
  static const String baseUrl = "http://10.0.2.2:8000/api";

  static Future<List> getRewards() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("$baseUrl/admin/rewards"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        
        // AMBIL KEY 'data' (sesuai hasil Thunder Client kamu)
        return body['data'] ?? []; 
      } else {
        print("Gagal ambil reward: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error koneksi reward: $e");
      return [];
    }
  }
}