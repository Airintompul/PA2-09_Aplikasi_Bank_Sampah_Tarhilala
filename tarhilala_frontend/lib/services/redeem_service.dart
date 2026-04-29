import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RedeemService {
  static Future<bool> redeemReward(int rewardId, int jumlah) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/api/nasabah/redeem"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "reward_id": rewardId,
        "jumlah": jumlah,
      }),
    );

    return response.statusCode == 200;
  }
}