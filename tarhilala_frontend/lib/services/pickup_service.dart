import 'dart:convert';
import 'package:http/http.dart' as http;

class PickupService {
  static const String baseUrl = "http://10.0.2.2:8000/api"; 

  // Ambil daftar jenis sampah secara dinamis dari database
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
}