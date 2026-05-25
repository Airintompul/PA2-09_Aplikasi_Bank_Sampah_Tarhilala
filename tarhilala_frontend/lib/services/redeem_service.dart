import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RedeemService {
  static const String baseUrl = "http://10.0.2.2:8000/api";

  // 1. FUNGSI TUKAR POIN (Disesuaikan dengan Alamat & GPS)
  static Future<bool> redeemReward({
    required int rewardId,
    required int jumlah,
    required String lat,
    required String lng,
    required String alamat,
    String? catatan,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("$baseUrl/nasabah/redeem"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "reward_id": rewardId,
          "jumlah": jumlah,
          "lokasi_lat": lat,
          "lokasi_lng": lng,
          "alamat_pengiriman": alamat,
          "catatan": catatan ?? "",
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error RedeemService (Redeem): $e");
      return false;
    }
  }

  // 2. FUNGSI AMBIL RIWAYAT PENUKARAN
  static Future<List> getRiwayatRedeem() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("$baseUrl/nasabah/riwayat-reward"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        return result['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error RedeemService (Riwayat): $e");
      return [];
    }
  }

  // 3. FUNGSI KONFIRMASI TERIMA BARANG (Ending Point di Nasabah)
  static Future<bool> confirmReceipt(int id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("$baseUrl/nasabah/redeem/$id/confirm"), // Sesuai route Laravel
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      // Mengembalikan true jika status 200 (OK)
      return response.statusCode == 200;
    } catch (e) {
      print("Error RedeemService (Confirm): $e");
      return false;
    }
  }
}