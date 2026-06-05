import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  // Gunakan baseUrl yang sudah didefinisikan
  static const baseUrl = "http://10.0.2.2:8000/api";

  static Future<List> getHargaSampah() async {
    try {
      // Ambil token dari memori (jika route butuh login)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("$baseUrl/harga-sampah"), // Gunakan variabel baseUrl
        headers: {
          "Accept": "application/json", // WAJIB ADA: Agar server kirim JSON bukan HTML
          "Authorization": "Bearer $token", // Tambahkan ini jika route dilindungi auth
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        
        // Pastikan key ['data'] memang ada di response JSON Laravel Anda
        if (decodedData.containsKey('data')) {
          return decodedData['data'];
        }
        return [];
      } else {
        // Jika error, cetak pesan aslinya untuk debug
        print("Error Server (${response.statusCode}): ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception di ProductService: $e");
      return [];
    }
  }
}