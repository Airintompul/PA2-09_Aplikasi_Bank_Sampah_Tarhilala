import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  // Pastikan baseUrl ini sesuai dengan rute di Laravel Anda
  static const String baseUrl = "http://10.0.2.2:8000/api/nasabah";

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

    debugPrint("ROOM RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      
      // PERBAIKAN: Gunakan 'room_id' bukan 'id' sesuai output Laravel Anda
      if (data['room_id'] != null) {
        return data['room_id'];
      } else {
        throw Exception("Key 'room_id' tidak ditemukan. Response: ${res.body}");
      }
    } else {
      throw Exception("Gagal memuat room chat. Status: ${res.statusCode}");
    }
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

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      return [];
    }
  }

  static Future<bool> sendMessage(int roomId, String pesan) async {
    final token = await _getToken();

    final res = await http.post(
      Uri.parse("$baseUrl/chat/send"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json", // Wajib kirim JSON
      },
      body: jsonEncode({
        "chat_room_id": roomId,
        "pesan": pesan,
      }),
    );

    debugPrint("SEND MESSAGE RESPONSE: ${res.body}");
    
    return res.statusCode == 200 || res.statusCode == 201;
  }
}