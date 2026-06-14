import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/setoran_model.dart';
import '../services/auth_service.dart'; // Pastikan import AuthService benar

class PickupService {
  // Gunakan IP Emulator atau IP Local
  static const String baseUrl = "http://10.0.2.2:8000/api";

  // Helper Token
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ============================================================
  // 1. DATA SAMPAH (Static agar User & Petugas bisa panggil)
  // ============================================================
  static Future<List> getWasteTypes() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/harga-sampah"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print("Error getWasteTypes: $e");
    }
    return [];
  }

  // ============================================================
  // 2. PROFILE
  // ============================================================
  Future<Map<String, dynamic>> getProfileData() async {
    try {
      String? token = await _getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print("Error profile: $e");
    }
    return {"nama": "Nasabah", "saldo": 0, "poin": 0};
  }

  // ============================================================
  // 3. LIST SETORAN (PETUGAS)
  // ============================================================
  Future<List<SetoranModel>> getSetoranRequests() async {
    try {
      String? token = await _getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/admin/setoran"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return SetoranModel.fromList(data);
      }
    } catch (e) {
      print("Error getSetoranRequests: $e");
    }
    return [];
  }

  // ============================================================
  // 4. UPDATE STATUS SIMPLE (Mulai Jalan / Batal)
  // ============================================================
  Future<bool> updateStatus(int id, String status) async {
    try {
      String? token = await _getToken();
      final response = await http.put(
        Uri.parse("$baseUrl/admin/setoran/$id"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updateStatus: $e");
      return false;
    }
  }

  // ============================================================
  // 5. UPDATE FINAL (PROSES SIMPAN & SELESAIKAN)
  // ============================================================
  Future<bool> updateStatusComplete({
    required int id,
    required String status,
    required double beratFinal,
    required double totalHarga,
    required String metode_pembayaran,
    required String catatan,
    required List<Map<String, dynamic>> items, // Berisi gabungan Item ID dan JenisSampahID
    File? foto,
  }) async {
    try {
      String? token = await _getToken();
      var uri = Uri.parse("$baseUrl/admin/setoran/$id");
      
      // Menggunakan MultipartRequest karena ada pengiriman File Foto
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      // Laravel memerlukan spoofing _method PUT jika menggunakan MultipartRequest (POST)
      request.fields['_method'] = 'PUT'; 
      request.fields['status'] = status;
      request.fields['berat_final'] = beratFinal.toString();
      request.fields['total_harga'] = totalHarga.toString();
      request.fields['metode_pembayaran'] = metode_pembayaran;
      request.fields['catatan'] = catatan;
      
      // SANGAT PENTING: Mengirim List Item sebagai JSON String
      request.fields['items'] = jsonEncode(items);

      // Mengirim Foto Timbangan (Field name sesuaikan dengan backend)
      if (foto != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("DEBUG SERVER RESPONSE: ${response.body}"); // Cek jika ada error di console

      return response.statusCode == 200;
    } catch (e) {
      print("updateStatusComplete ERROR: $e");
      return false;
    }
  }

  // ============================================================
  // 6. JADWAL OPERASIONAL
  // ============================================================
  Future<List<dynamic>> getJadwalOperasional() async {
    try {
      String? token = await _getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/nasabah/jadwal-nasabah"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['schedules'] ?? [];
      }
    } catch (e) {
      print("Error jadwal: $e");
    }
    return [];
  }
}