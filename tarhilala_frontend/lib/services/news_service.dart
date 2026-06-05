import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {

  static Future<List> getBerita() async {

    final response = await http.get(
      Uri.parse("http://10.0.2.2:8000/api/berita"),
    );

    final data = jsonDecode(response.body);

    return data['data'];
  }

}