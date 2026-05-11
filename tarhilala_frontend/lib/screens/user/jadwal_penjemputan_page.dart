import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/top_navbar.dart';

class JadwalPenjemputanPage extends StatefulWidget {
  const JadwalPenjemputanPage({super.key});

  @override
  State<JadwalPenjemputanPage> createState() => _JadwalPenjemputanPageState();
}

class _JadwalPenjemputanPageState extends State<JadwalPenjemputanPage> {
  List jadwalList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchJadwal();
  }

  Future<void> fetchJadwal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/api/nasabah/jadwal-nasabah"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          // Sesuaikan dengan struktur LocationController: data -> schedules
          jadwalList = result['data']['schedules'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetch jadwal: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          const TopNavbar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new, size: 20),
                ),
                const SizedBox(width: 15),
                const Text(
                  "Jadwal Penjemputan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F)),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : jadwalList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: jadwalList.length,
                        itemBuilder: (context, index) {
                          return _buildJadwalCard(jadwalList[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(Map item) {
    // Ambil data rute dan driver dari relasi
    final rute = item['rute'] ?? {};
    final driver = item['driver'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Bagian Atas: Hari dan Jam
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E56A0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['hari'].toString().toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  "${item['jam_mulai'].substring(0, 5)} - ${item['jam_selesai'].substring(0, 5)} WIB",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ),
          
          // Bagian Bawah: Detail Rute
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.map_outlined, color: Color(0xFF1E56A0), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "Rute: ${rute['nama_rute'] ?? '-'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rute['wilayah'] ?? '-',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFFF0F4F8),
                      child: Icon(Icons.person, size: 14, color: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Petugas: ${driver['nama'] ?? 'Belum ditentukan'}",
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Tidak ada jadwal tersedia", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}