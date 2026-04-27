import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String baseUrl = "http://10.0.2.2:8000/api";

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  static Future<int> getRoom() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/chat/room"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      },
    );

    print("ROOM RESPONSE: ${res.body}");

    final data = jsonDecode(res.body);

    if (data == null || data['id'] == null) {
      throw Exception("Room ID null. Response: ${res.body}");
    }

    return data['id'];
  }

  static Future<List> getMessages(int roomId) async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/chat/messages/$roomId"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      },
    );

    return jsonDecode(res.body);
  }

  static Future<void> sendMessage(int roomId, String pesan) async {
    final token = await _getToken();

    await http.post(
      Uri.parse("$baseUrl/chat/send"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      },
      body: {
        "chat_room_id": roomId.toString(),
        "pesan": pesan,
      },
    );
  }
}