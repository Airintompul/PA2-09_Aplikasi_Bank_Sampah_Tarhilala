import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/setoran_model.dart';

class PickupService {
  static const String baseUrl = "http://13.250.117.185/api";

  // =========================
  // TOKEN HELPER
  // =========================
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // =========================
  // 1. MASTER WASTE
  // =========================
  static Future<List> getWasteTypes() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/jenis-sampah"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }

      print("getWasteTypes ERROR: ${response.body}");
    } catch (e) {
      print("Error fetch sampah: $e");
    }
    return [];
  }

  // =========================
  // 2. PROFILE
  // =========================
  Future<Map<String, dynamic>> getProfileData() async {
    try {
      String? token = await _getToken();

      if (token == null) {
        print("TOKEN NULL");
        return {"nama": "Nasabah", "saldo": 0, "poin": 0};
      }

      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      }

      print("Profile ERROR: ${response.body}");
    } catch (e) {
      print("Error profile: $e");
    }

    return {"nama": "Nasabah", "saldo": 0, "poin": 0};
  }

  // =========================
  // 3. LIST SETORAN
  // =========================
  Future<List<SetoranModel>> getSetoranRequests() async {
    try {
      String? token = await _getToken();

      if (token == null) {
        print("TOKEN NULL");
        return [];
      }

      final response = await http.get(
        Uri.parse("$baseUrl/admin/setoran"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return SetoranModel.fromList(data);
      }

      print("Setoran ERROR: ${response.body}");
      return [];
    } catch (e) {
      print("Error getSetoranRequests: $e");
      return [];
    }
  }

  // =========================
  // 4. UPDATE STATUS SIMPLE
  // =========================
  Future<bool> updateStatus(int id, String status) async {
    try {
      String? token = await _getToken();

      if (token == null) return false;

      final response = await http.put(
        Uri.parse("$baseUrl/admin/setoran/$id"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({'status': status}),
      );

      print("updateStatus => ${response.statusCode}");
      print(response.body);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("Error updateStatus: $e");
      return false;
    }
  }

  // =========================
  // 5. UPDATE FINAL (CORE FINANCE)
  // =========================
  Future<bool> updateStatusComplete({
    required int id,
    required String status,
    required double beratFinal,
    required double totalHarga,
    required String metode_pembayaran,
    required String catatan,
    required List<Map<String, dynamic>> items,
    File? foto,
  }) async {
    try {
      String? token = await _getToken();

      if (token == null) {
        print("TOKEN NULL");
        return false;
      }

      // VALIDASI METODE
      if (metode_pembayaran.isEmpty) {
        print("ERROR: metode_pembayaran kosong");
        return false;
      }

      if (!['saldo', 'cash', 'transfer'].contains(metode_pembayaran)) {
        print("ERROR: metode tidak valid");
        return false;
      }

      var uri = Uri.parse("$baseUrl/admin/setoran/$id");
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      // method spoofing Laravel
      request.fields['_method'] = 'PUT';

      // DATA UTAMA
      request.fields['status'] = status;
      request.fields['berat_final'] = beratFinal.toString();
      request.fields['total_harga'] = totalHarga.toString();
      request.fields['metode_pembayaran'] = metode_pembayaran;
      request.fields['catatan'] = catatan;
      request.fields['items'] = jsonEncode(items);

      // DEBUG (penting untuk tracing bug)
      print("=== REQUEST DEBUG ===");
      print("metode: $metode_pembayaran");
      print("total: $totalHarga");

      // FILE UPLOAD
      if (foto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'bukti_transfer',
            foto.path,
          ),
        );
      }

      var streamed = await request.send();
      var response = await http.Response.fromStream(streamed);

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("updateStatusComplete ERROR: $e");
      return false;
    }
  }

  // =========================
  // 6. JADWAL OPERASIONAL
  // =========================
  Future<List<dynamic>> getJadwalOperasional() async {
    try {
      String? token = await _getToken();

      if (token == null) return [];

      final response = await http.get(
        Uri.parse("$baseUrl/nasabah/jadwal-nasabah"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        return data['data']?['schedules'] ?? [];
      }

      print("Jadwal ERROR: ${response.body}");
      return [];
    } catch (e) {
      print("Error getJadwalOperasional: $e");
      return [];
    }
  }
}