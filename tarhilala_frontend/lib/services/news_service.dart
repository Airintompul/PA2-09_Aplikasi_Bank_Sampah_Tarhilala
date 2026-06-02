import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {

  static Future<List> getBerita() async {

    final response = await http.get(
      Uri.parse("http://13.250.117.185/api/berita"),
    );

    final data = jsonDecode(response.body);

    return data['data'];
  }

}