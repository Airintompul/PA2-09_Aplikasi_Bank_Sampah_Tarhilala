import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../user/widgets/top_navbar.dart';
import '../user/widgets/bottom_navbar.dart';
import 'form_tukar_poin_page.dart';

class DetailRewardPage extends StatefulWidget {
  final Map data;

  const DetailRewardPage({super.key, required this.data});

  @override
  State<DetailRewardPage> createState() => _DetailRewardPageState();
}

class _DetailRewardPageState extends State<DetailRewardPage> {
  String userPoin = "0";
  bool loadingPoin = true;

  @override
  void initState() {
    super.initState();
    fetchUserPoin();
  }

  // --- AMBIL POIN TERBARU DARI API ---
  Future<void> fetchUserPoin() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/api/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userPoin = (data['poin'] ?? 0).toString();
          loadingPoin = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetch poin: $e");
      setState(() => loadingPoin = false);
    }
  }

  // --- HELPER UNTUK MEMBERSIHKAN URL GAMBAR ---
  String getCleanImageUrl(String? url) {
    if (url == null) return "";
    String fixedUrl = url.replaceAll("127.0.0.1", "10.0.2.2");
    return Uri.encodeFull(fixedUrl);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data;
    int poinDibutuhkan = item['poin_dibutuhkan'] ?? 0;
    int stok = item['stok'] ?? 0;
    bool poinCukup = int.parse(userPoin) >= poinDibutuhkan;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          const TopNavbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),

                  /// 2. TOMBOL KEMBALI & JUDUL
                  _buildHeader(context),

                  const SizedBox(height: 20),

                  /// 3. KARTU POIN DINAMIS
                  _buildBluePointsCard(),

                  const SizedBox(height: 25),

                  /// 4. KARTU DETAIL REWARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // GAMBAR DENGAN URL FIX
                        _buildImage(item['gambar']),
                        
                        const SizedBox(height: 20),
                        
                        Text(
                          item['nama_reward'] ?? 'Nama Reward',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F)),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Color(0xFFF0F4F8), thickness: 2),
                        ),
                        
                        // INFORMASI
                        _infoRow("Poin Dibutuhkan", "$poinDibutuhkan Poin"),
                        _infoRow("Stok Tersedia", "$stok unit"),
                        _infoRow("Status Poin", poinCukup ? "Tersedia" : "Poin Tidak Cukup", isBlue: poinCukup),
                        
                        const SizedBox(height: 25),
                        
                        Text(
                          item['deskripsi'] ?? "Gunakan poin yang telah Anda kumpulkan untuk menukarkan reward menarik ini.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // TOMBOL TUKAR (Validasi Stok & Poin)
                        _buildExchangeButton(context, poinCukup, stok),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1B3D5F)),
          ),
        ),
        const SizedBox(width: 15),
        const Text("Detail Reward", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F))),
      ],
    );
  }

  Widget _buildImage(String? img) {
    return Container(
      width: 150, height: 150,
      decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(25)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: img != null
            ? Image.network(
                getCleanImageUrl(img),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.redeem_rounded, size: 50, color: Color(0xFF3B71CA)),
              )
            : const Icon(Icons.redeem_rounded, size: 50, color: Color(0xFF3B71CA)),
      ),
    );
  }

  Widget _buildBluePointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B71CA), Color(0xFF54B4D3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Total Poin Anda", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  loadingPoin 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(userPoin, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const Icon(Icons.stars_rounded, color: Colors.white24, size: 50),
        ],
      ),
    );
  }

  Widget _buildExchangeButton(BuildContext context, bool poinCukup, int stok) {
    bool canExchange = poinCukup && stok > 0;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: !canExchange ? null : () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => FormTukarPoinPage(data: widget.data)));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: canExchange ? const Color(0xFF1E56A0) : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: Text(
          stok == 0 ? "Stok Habis" : (poinCukup ? "Tukar Sekarang" : "Poin Tidak Cukup"),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isBlue ? const Color(0xFF3B71CA) : const Color(0xFF1B3D5F))),
        ],
      ),
    );
  }
}