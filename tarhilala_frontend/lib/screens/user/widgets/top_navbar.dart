import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../notification_page.dart'; // Pastikan path import ini benar

class TopNavbar extends StatefulWidget {
  const TopNavbar({super.key});

  @override
  State<TopNavbar> createState() => _TopNavbarState();
}

class _TopNavbarState extends State<TopNavbar> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  // --- LOGIC: AMBIL JUMLAH NOTIFIKASI BELUM DIBACA ---
  Future<void> _fetchUnreadCount() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/api/notifications/unread-count"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _unreadCount = jsonDecode(response.body)['unread'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error notif navbar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Grup Kiri: Logo dan Judul
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.eco, 
                  color: Color(0xFF1B3D5F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "BANK SAMPAH TARHILALA",
                style: TextStyle(
                  fontSize: 14, // Ukuran disesuaikan agar stabil di semua device
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3D5F),
                ),
              ),
            ],
          ),

          // Grup Kanan: Ikon Notifikasi dengan Badge Merah
          GestureDetector(
            onTap: () async {
              // Buka halaman notifikasi
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
              // Setelah kembali dari halaman notif, refresh angka (biasanya jadi 0)
              _fetchUnreadCount();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1B3D5F),
                  size: 30,
                ),
                // TITIK MERAH (Hanya muncul jika ada pesan baru)
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadCount > 9 ? '9+' : '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}