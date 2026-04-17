import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {

  static const baseUrl = "http://10.0.2.2:8000/api";

  static Future<List> getHargaSampah() async {
    final response = await http.get(Uri.parse("$baseUrl/harga-sampah"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      return [];
    }
  }

}