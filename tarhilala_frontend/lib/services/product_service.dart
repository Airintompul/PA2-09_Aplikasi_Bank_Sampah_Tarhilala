import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {

  static const baseUrl = "http://10.0.2.2:8000/api";

  // PASTIKAN URL NYA BENAR (Gunakan IP 10.0.2.2 untuk emulator)
    static Future<List> getHargaSampah() async {
      final response = await http.get(Uri.parse("http://10.0.2.2:8000/api/harga-sampah"));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data']; // Pastikan sesuai struktur JSON Laravel Anda
      } else {
        // Cetak ini untuk melihat HTML error jika gagal
        print("Error Server: ${response.body}"); 
        return [];
      }
    }
}