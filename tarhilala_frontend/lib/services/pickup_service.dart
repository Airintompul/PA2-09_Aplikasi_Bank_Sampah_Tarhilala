import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/setoran_model.dart'; 

class PickupService {
  static const String baseUrl = "http://10.0.2.2:8000/api"; 

  // Helper untuk mengambil Token dari SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); 
  }

  // 1. Ambil daftar jenis sampah (Master Data)
  static Future<List> getWasteTypes() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/jenis-sampah"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetch sampah: $e");
    }
    return [];
  }

  // 2. Ambil Profil Lengkap (Nama, Saldo, Poin - Ditarik dari Port 8000)
  // Ini adalah pengganti fungsi getUserStats yang lebih aman dan simpel
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

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error profile: $e");
    }
    return {"nama": "Nasabah", "saldo": 0, "poin": 0};
  }

  // 3. Ambil daftar request penjemputan (Untuk Driver)
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
        final List<dynamic> data = body['data'];
        return SetoranModel.fromList(data);
      } else {
        throw Exception("Gagal mengambil data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error getSetoranRequests: $e");
      throw Exception("Kesalahan koneksi ke server");
    }
  }

  // 4. Update status dasar (Mulai/Batal)
// Di dalam PickupService
Future<bool> updateStatus(int id, String status) async {
  try {
    String? token = await _getToken();
    final response = await http.put( // Gunakan PUT
      Uri.parse("$baseUrl/admin/setoran/$id"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json", // WAJIB: Agar Laravel kirim pesan error JSON bukan HTML
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({'status': status}),
    );

    // DEBUG: Cek di console VS Code jika tetap tidak jalan
    print("Update Status Code: ${response.statusCode}");
    print("Update Response: ${response.body}");

    return response.statusCode == 200;
  } catch (e) {
    print("Error Update Status: $e");
    return false;
  }
}

  // 5. Update Final (Selesai + Foto + Data Aktual per item)
  Future<bool> updateStatusComplete({
    required int id,
    required String status,
    required double beratFinal,
    required double totalHarga,
    required String metode,
    required String catatan,
    required List<Map<String, dynamic>> items,
    File? foto,
  }) async {
    try {
      String? token = await _getToken();
      var uri = Uri.parse("$baseUrl/admin/setoran/$id");
      
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      // Laravel Spoofing (Penting agar file terdeteksi di PUT)
      request.fields['_method'] = 'PUT';
      request.fields['status'] = status;
      request.fields['berat_final'] = beratFinal.toString();
      request.fields['total_harga'] = totalHarga.toString();
      request.fields['metode_pembayaran'] = metode;
      request.fields['catatan'] = catatan;
      request.fields['items'] = jsonEncode(items);

      if (foto != null) {
        request.files.add(await http.MultipartFile.fromPath('bukti_transfer', foto.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Detail Error Server: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updateStatusComplete: $e");
      return false;
    }
  }
}