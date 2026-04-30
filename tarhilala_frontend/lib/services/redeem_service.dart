import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RedeemService {
  static const String baseUrl = "http://10.0.2.2:8000/api";

  // Fungsi Tukar Poin (Update dari yang tadi)
  static Future<bool> redeemReward(int rewardId, int jumlah) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse("$baseUrl/nasabah/redeem"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "reward_id": rewardId,
        "jumlah": jumlah,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // FUNGSI BARU: AMBIL RIWAYAT
  static Future<List> getRiwayatRedeem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse("$baseUrl/nasabah/riwayat-reward"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }
    return [];
  }
}