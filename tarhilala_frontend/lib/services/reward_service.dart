import 'dart:convert';
import 'package:http/http.dart' as http;

class RewardService {

  static Future<List> getRewards() async {

    final url = Uri.parse("http://10.0.2.2:8000/api/rewards");

    final response = await http.get(url);

    if (response.statusCode == 200) {

      final data = json.decode(response.body);

      if (data is List) {
        return data;
      }

      return data['data'] ?? [];

    }

    return [];
  }
}