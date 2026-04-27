import 'dart:async';
import 'package:flutter/material.dart';
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
import 'package:timeago/timeago.dart' as timeago;

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  int currentIndex = 0;
  List hargaSampah = [];
  List berita = [];
  
  // Controller & Timer untuk Auto Scroll Berita
  late PageController _newsPageController;
  Timer? _newsTimer;
  int _currentNewsPage = 0;

  // Controller & Timer untuk Auto Scroll Harga Sampah
  late PageController _hargaPageController;
  Timer? _hargaTimer;
  int _currentHargaPage = 0;

  @override
  void initState() {
    super.initState();
    _newsPageController = PageController(viewportFraction: 0.9);
    _hargaPageController = PageController(viewportFraction: 0.4); 
    
    loadHargaSampah();
    loadBerita();
  }

  @override
  void dispose() {
    _newsTimer?.cancel();
    _newsPageController.dispose();
    _hargaTimer?.cancel();
    _hargaPageController.dispose();
    super.dispose();
  }

  Future<void> loadHargaSampah() async {
    final data = await ProductService.getHargaSampah();
    setState(() => hargaSampah = data);
    if (hargaSampah.isNotEmpty) {
      _startHargaAutoScroll();
    }
  }

  Future<void> loadBerita() async {
    final data = await NewsService.getBerita();
    setState(() => berita = data);
    if (berita.isNotEmpty) {
      _startNewsAutoScroll();
    }
  }

  void _startNewsAutoScroll() {
    _newsTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentNewsPage < berita.length - 1) {
        _currentNewsPage++;
      } else {
        _currentNewsPage = 0;
      }
      if (_newsPageController.hasClients) {
        _newsPageController.animateToPage(
          _currentNewsPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
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
        _hargaPageController.animateToPage(
          _currentHargaPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _getPage() {
    switch (currentIndex) {
      case 0: return _dashboardContent();
      case 1: return const Center(child: Text("Transaksi"));
      case 2: return const RiwayatSetoranPage();
      case 3: return const RewardPage();
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TopNavbar(),

          // --- SALDO CARD ---
          _buildSaldoCard(),

          // --- MENU GRID ---
          _buildMenuGrid(),

          const SizedBox(height: 25),

          _sectionHeader("Harga Sampah", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SemuaSampahPage()));
          }),

          const SizedBox(height: 12),

          // --- AUTO-ROLL HARGA SAMPAH ---
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _hargaPageController,
              itemCount: hargaSampah.length,
              padEnds: false,
              onPageChanged: (index) => _currentHargaPage = index,
              itemBuilder: (context, index) => _hargaCard(hargaSampah[index]),
            ),
          ),

          const SizedBox(height: 25),

          _sectionHeader("Berita Pilihan", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SemuaBeritaPage()));
          }),

          const SizedBox(height: 12),

          // --- AUTO-ROLL BERITA ---
          SizedBox(
            height: 320,
            child: PageView.builder(
              controller: _newsPageController,
              itemCount: berita.length,
              onPageChanged: (index) => _currentNewsPage = index,
              itemBuilder: (context, index) => _beritaCard(berita[index]),
            ),
          ),

          const SizedBox(height: 30),
        ],
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Saldo Tabungan", style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                    const Text("Rp 100.000", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Tiara Pardosi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Icon(Icons.stars, color: Colors.amber, size: 18),
                    SizedBox(width: 5),
                    Text("1,200 Poin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 15,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
        children: [
          _menuItem(Icons.recycling, "Jual Sampah", const Color(0xFF1E56A0)),
          _menuItem(Icons.calendar_today, "Jadwal Penjemputan", const Color(0xFFF9AB40)),
          _menuItem(Icons.help_outline, "Panduan", const Color(0xFF4FD3C4)),
          _menuItem(Icons.local_offer, "Harga Sampah", const Color(0xFF48A9FE)),
          _menuItem(Icons.support_agent, "Bantuan", const Color(0xFFFF8A80)),
          _menuItem(Icons.receipt_long, "Transaksi", const Color(0xFFBA68C8)),
          _menuItem(Icons.radio_button_checked, "Poin", const Color(0xFF7986CB)),
          _menuItem(Icons.newspaper, "Berita", const Color(0xFFD4A017)),
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
          GestureDetector(
            onTap: onAction,
            child: const Text("Lihat Semua", style: TextStyle(color: Color(0xFF3B71CA), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

Widget _menuItem(IconData icon, String title, Color color) {
  return GestureDetector(
    onTap: () {
      // 👇 HANYA TAMBAHAN INI
      if (title == "Panduan Jual Sampah") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PanduanJualSampahPage(),
          ),
        );
      }
    },
    child: Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

  Widget _hargaCard(Map item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailSampahPage(data: item))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
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