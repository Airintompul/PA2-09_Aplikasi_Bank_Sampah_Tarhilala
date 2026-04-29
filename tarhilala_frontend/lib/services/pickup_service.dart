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

  // Ambil daftar jenis sampah (Publik)
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

  // 1. Ambil semua daftar request setoran (Auth Required)
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
        throw Exception("Gagal mengambil data setoran");
      }
    } catch (e) {
      print("Error getSetoranRequests: $e");
      throw Exception("Kesalahan koneksi ke server");
    }
  }

  // 2. Update status dasar (Contoh: dijadwalkan -> dalam_penjemputan)
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

  // 3. Update Final / Selesai (Mengirim data aktual per item sampah)
  Future<bool> updateStatusComplete({
  required int id,
  required String status,
  required double beratFinal,
  required double totalHarga,
  required String metode,
  required String catatan,
  required List<Map<String, dynamic>> items,
  File? foto, // Tambahkan parameter foto
}) async {
  try {
    String? token = await _getToken();
    var uri = Uri.parse("$baseUrl/admin/setoran/$id");
    
    // Gunakan MultipartRequest karena ada pengiriman File
    var request = http.MultipartRequest('POST', uri); // Laravel PUT sering bermasalah dengan Multipart, gunakan POST dengan _method: PUT
    
    request.headers.addAll({
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    // Spoofing method PUT agar Laravel menerimanya sebagai update
    request.fields['_method'] = 'PUT';
    request.fields['status'] = status;
    request.fields['berat_final'] = beratFinal.toString();
    request.fields['total_harga'] = totalHarga.toString();
    request.fields['metode_pembayaran'] = metode;
    request.fields['catatan'] = catatan;
    request.fields['items'] = jsonEncode(items);

    // Lampirkan Foto jika ada
    if (foto != null) {
      request.files.add(await http.MultipartFile.fromPath('foto_konfirmasi', foto.path));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Gagal: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Error updateStatusComplete: $e");
    return false;
  }
}

// Tambahkan di PickupService
static Future<Map<String, dynamic>> getUserStats(int userId) async {
  try {
    // 1. Ambil Saldo dari Microservice Finance (Port 8001)
    // Catatan: Anda mungkin perlu membuat endpoint ini di Port 8001
    final responseSaldo = await http.get(
      Uri.parse("http://10.0.2.2:8001/api/internal/balance/$userId"),
      headers: {"X-Internal-Key": "TarhilalaSecretFinanceKey2024"},
    );

    // 2. Ambil Poin dari Main Backend (Port 8000)
    final responsePoin = await http.get(
      Uri.parse("http://10.0.2.2:8000/api/nasabah/poin/$userId"),
    );

    return {
      "saldo": jsonDecode(responseSaldo.body)['balance'] ?? 0,
      "poin": jsonDecode(responsePoin.body)['total_poin'] ?? 0,
    };
  } catch (e) {
    return {"saldo": 0, "poin": 0};
  }
}

}

