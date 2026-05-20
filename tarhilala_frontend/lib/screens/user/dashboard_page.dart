import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:tarhilala_frontend/screens/user/jual_sampah_page.dart';
import '../../services/product_service.dart';
import '../../services/news_service.dart';
import 'widgets/bottom_navbar.dart'; 
import 'widgets/top_navbar.dart';    
import 'profile_page.dart';
import '../user/semua_sampah_page.dart';
import '../user/riwayat_setoran_page.dart';
import '../user/detail_sampah_page.dart';
import '../user/detail_berita_page.dart';
import '../user/semua_berita_page.dart';
import '../user/reward_page.dart';
import '../user/panduan_jual_sampah_page.dart';
import '../user/penarikan_saldo_page.dart';
import '../user/jadwal_penjemputan_page.dart';
import '../user/chat_page.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  int currentIndex = 0;
  List hargaSampah = [];
  List berita = [];
  
  // Data Dinamis User
  String namaUser = "Nasabah";
  String saldoUser = "0";
  String poinUser = "0";
  bool isLoadingStats = true;
  bool isBalanceVisible = false; 

  late PageController _newsPageController;
  Timer? _newsTimer;
  int _currentNewsPage = 0;
  late PageController _hargaPageController;
  Timer? _hargaTimer;
  int _currentHargaPage = 0;

  @override
  void initState() {
    super.initState();
    _newsPageController = PageController(viewportFraction: 0.9);
    _hargaPageController = PageController(viewportFraction: 0.4); 
    
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await loadUserData(); // Ambil Nama, Saldo, Poin
    await loadHargaSampah();
    await loadBerita();
  }

  // --- LOGIKA AMBIL DATA USER DINAMIS ---
  Future<void> loadUserData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  if (token == null) {
    print("Token tidak ditemukan!");
    return;
  }

  try {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:8000/api/profile"), // Pastikan URL benar
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      setState(() {
        // 1. Ambil Nama (Key JSON: 'nama')
        namaUser = data['nama'] ?? "Nasabah";

        // 2. Ambil Saldo (JSON mengirim String "50000.00", kita ubah ke Rupiah)
        // Kita gunakan double.parse agar aman jika backend mengirim string
        double rawSaldo = double.tryParse(data['saldo'].toString()) ?? 0;
        saldoUser = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
            .format(rawSaldo);

        // 3. Ambil Poin (Key JSON: 'poin')
        poinUser = (data['poin'] ?? 0).toString();
        
        isLoadingStats = false;
      });
      
      print("Data Ter-update: $namaUser, $saldoUser, $poinUser");
    } else {
      print("Gagal ambil data: ${response.statusCode}");
    }
  } catch (e) {
    print("Error di Flutter: $e");
    setState(() => isLoadingStats = false);
  }
}

  @override
  void dispose() {
    _newsTimer?.cancel();
    _newsPageController.dispose();
    _hargaTimer?.cancel();
    _hargaPageController.dispose();
    super.dispose();
  }

  // --- REFRESH DATA ---
  Future<void> _onRefresh() async {
    await _initialLoad();
  }

  Future<void> loadHargaSampah() async {
    final data = await ProductService.getHargaSampah();
    setState(() => hargaSampah = data);
    if (hargaSampah.isNotEmpty) _startHargaAutoScroll();
  }

  Future<void> loadBerita() async {
    final data = await NewsService.getBerita();
    setState(() => berita = data);
    if (berita.isNotEmpty) _startNewsAutoScroll();
  }

  void _startNewsAutoScroll() {
    _newsTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentNewsPage < berita.length - 1) {
        _currentNewsPage++;
      } else {
        _currentNewsPage = 0;
      }
      if (_newsPageController.hasClients) {
        _newsPageController.animateToPage(_currentNewsPage, duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
      }
    });
  }

  void _startHargaAutoScroll() {
    _hargaTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentHargaPage < hargaSampah.length - 1) {
        _currentHargaPage++;
      } else {
        _currentHargaPage = 0;
      }
      if (_hargaPageController.hasClients) {
        _hargaPageController.animateToPage(_currentHargaPage, duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
      }
    });
  }

  Widget _getPage() {
    switch (currentIndex) {
      case 0: return _dashboardContent();
      case 1: return const TransaksiPage(showBackButton: false,);
      case 2: return const JualSampahPage(showBackButton: false);
      case 3: return const RewardPage(showBackButton: false,);
      case 4: return const ProfilePage();
      default: return _dashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: _getPage(),
      bottomNavigationBar: BottomNavbar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
      ),
    );
  }

  Widget _dashboardContent() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopNavbar(),
            _buildSaldoCard(),
            _buildMenuGrid(),
            const SizedBox(height: 25),
            _sectionHeader("Harga Sampah", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SemuaSampahPage()));
            }),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _hargaPageController,
                itemCount: hargaSampah.length,
                padEnds: false,
                itemBuilder: (context, index) => _hargaCard(hargaSampah[index]),
              ),
            ),
            const SizedBox(height: 25),
            _sectionHeader("Berita Pilihan", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SemuaBeritaPage()));
            }),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _newsPageController,
                itemCount: berita.length,
                itemBuilder: (context, index) => _beritaCard(berita[index]),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSaldoCard() {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B71CA), Color(0xFF54B4D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris Pertama (Judul + Ikon Mata)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Saldo Tabungan", style: TextStyle(color: Colors.white70, fontSize: 13)),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isBalanceVisible = !isBalanceVisible;
                  });
                },
                child: Icon(
                  isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    isBalanceVisible ? saldoUser : "Rp •••", 
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      // Hilangkan const jika ingin menggunakan dynamic letterSpacing
                      letterSpacing: isBalanceVisible ? 0 : 2, 
                    )
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(namaUser, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 18),
                  const SizedBox(width: 5),
                  Text("$poinUser Poin", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          )
        ],
      ),
    ),
  );
}

  // --- UI LAINNYA TETAP SAMA ---
  Widget _menuItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F))),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 15, crossAxisSpacing: 10, childAspectRatio: 0.8,
        children: [
          _menuItem(Icons.recycling, "Jual Sampah", const Color(0xFF1E56A0), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatSetoranPage()));
          }),
          _menuItem(Icons.calendar_today, "Jadwal", const Color(0xFFF9AB40), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const JadwalPenjemputanPage()));
          }),
          _menuItem(Icons.help_outline, "Panduan", const Color(0xFF4FD3C4), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PanduanJualSampahPage()));
          }),
          _menuItem(Icons.local_offer, "Harga", const Color(0xFF48A9FE), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SemuaSampahPage()));
          }),
          _menuItem(Icons.support_agent, "Bantuan", const Color(0xFFFF8A80), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage()));
          }),
          _menuItem(Icons.receipt_long, "Transaksi", const Color(0xFFBA68C8), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TransaksiPage(showBackButton: true,)));
          }),
          _menuItem(Icons.radio_button_checked, "Poin", const Color(0xFF7986CB), () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const RewardPage(showBackButton: true) 
                )
              );
            }),
          _menuItem(Icons.newspaper, "Berita", const Color(0xFFD4A017), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SemuaBeritaPage()));
          }),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onAction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          GestureDetector(onTap: onAction, child: const Text("Lihat Semua", style: TextStyle(color: Color(0xFF3B71CA), fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _hargaCard(Map item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailSampahPage(data: item))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(item['gambar'], height: 50, errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Colors.green)),
            const SizedBox(height: 10),
            Text(item['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            Text("Rp ${item['harga_per_kg']}", style: const TextStyle(color: Color(0xFF3B71CA), fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _beritaCard(Map item) {
    String rawDate = item['created_at'] ?? item['tanggal'] ?? DateTime.now().toString();
    String waktuRelatif = timeago.format(DateTime.parse(rawDate), locale: 'id');
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailBeritaPage(data: item))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                "http://10.0.2.2:8000/storage/${item['gambar'] ?? item['thumbnail']}",
                height: 180, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey[200]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bank Sampah Tarhila", style: TextStyle(color: Color(0xFF3B71CA), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(item['judul'] ?? "Tanpa Judul", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Text("Tarhila News • $waktuRelatif", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}