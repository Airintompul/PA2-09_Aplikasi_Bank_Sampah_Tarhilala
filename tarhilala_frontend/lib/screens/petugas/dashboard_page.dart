import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart'; 
import '../../services/auth_service.dart';
import '../../services/pickup_service.dart'; // Import Service
import '../../models/setoran_model.dart';   // Import Model
import '../user/widgets/top_navbar.dart';
import 'petugas_rute_page.dart'; 
import 'petugas_setoran_page.dart';

class PetugasDashboardPage extends StatefulWidget {
  const PetugasDashboardPage({super.key});

  @override
  State<PetugasDashboardPage> createState() => _PetugasDashboardPageState();
}

class _PetugasDashboardPageState extends State<PetugasDashboardPage> {
  String nama = "";
  bool isLoading = true;
  final PickupService _pickupService = PickupService(); // Inisialisasi Service
  
  // Data State
  Map<String, dynamic> stats = {
    'total_tugas': 0,
    'selesai': 0,
    'sisa': 0,
    'total_kg': 0,
    'pendapatan': '0',
    'jarak': 0,
  };

  List<SetoranModel> listRute = [];
  SetoranModel? setoranBerikutnya;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await loadUser();
    await fetchDataDashboard();
  }

  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString("name") ?? "Petugas";
    });
  }

  // Fungsi Fetch Data REAL dari API Laravel 
  Future<void> fetchDataDashboard() async {
    setState(() => isLoading = true);
    try {
      // Ambil data asli dari API
      final data = await _pickupService.getSetoranRequests();

      setState(() {
        listRute = data;

        // Hitung Statistik Otomatis
        int selesai = data.where((s) => s.status == 'selesai').length;
        double totalKg = data.fold(0.0, (sum, item) => sum + (item.totalBerat ?? 0));

        stats = {
          'total_tugas': data.length,
          'selesai': selesai,
          'sisa': data.length - selesai,
          'total_kg': totalKg.toInt(),
          'pendapatan': '0', // Bisa dikembangkan dari total_harga di DB
          'jarak': 0,
        };

        // Cari tugas terdekat yang belum selesai
        try {
          setoranBerikutnya = data.firstWhere((s) => s.status != 'selesai');
        } catch (e) {
          setoranBerikutnya = null;
        }

        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching dashboard: $e");
      setState(() => isLoading = false);
    }
  }

  void logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: isLoading 
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: fetchDataDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // 1. HEADER (Navbar + Profil)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const TopNavbar(), 
                    Positioned(
                      top: 45,
                      right: 15,
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: _showLogoutDialog,
                      ),
                    ),
                    Positioned(
                      top: 100, 
                      left: 20,
                      right: 20,
                      child: _buildProfileCard(),
                    ),
                  ],
                ),

                const SizedBox(height: 75),

                // 2. GRID STATISTIK
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard("Tugas hari ini", "${stats['total_tugas']}", "${stats['selesai']} selesai ${stats['sisa']} sisa"),
                      _buildStatCard("Total sampah", "${stats['total_kg']}", "Total hari ini", unit: "Kg"),
                      _buildStatCard("Setoran masuk", "${stats['pendapatan']}", "Estimasi", prefix: "Rp "),
                      _buildStatCard("Jarak rute", "0", "Wilayah Tugas", unit: "km"),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // 3. SETORAN BERIKUTNYA
                _buildSectionLabel("Setoran Berikutnya"),
                if (setoranBerikutnya != null) 
                  _buildNextDepositCard()
                else
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text("Tidak ada tugas tersisa hari ini")),
                  ),

                const SizedBox(height: 25),

                // 4. AKTIVITAS TERBARU
                _buildSectionLabel("Aktivitas Penjemputan"),
                _buildRouteTimeline(),

                const SizedBox(height: 100), 
              ],
            ),
          ),
        ),

      // 5. FLOATING ACTION BUTTON PETA
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PetugasRutePage(ruteData: listRute)),
          );
        },
        backgroundColor: const Color(0xFF154C94),
        elevation: 6,
        child: const Icon(Icons.location_on, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 55, height: 55,
            decoration: BoxDecoration(color: const Color(0xFF91ACCF), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const Text("Driver Lapangan - Aktif", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String sub, {String? unit, String? prefix}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              children: [
                if (prefix != null) TextSpan(text: prefix, style: const TextStyle(fontSize: 14)),
                TextSpan(text: value),
                if (unit != null) TextSpan(text: " $unit", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
          ),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildNextDepositCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PetugasSetoranPage())),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(12), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF154C94), size: 20),
                    const SizedBox(width: 10),
                    Text("ID: #SET-${setoranBerikutnya!.id}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              _detailRow("Nasabah", setoranBerikutnya!.nasabahNama),
              _detailRow("Hasil AI", setoranBerikutnya!.hasilAi ?? "N/A", color: const Color(0xFF154C94)),
              _detailRow("Est. berat", "${setoranBerikutnya!.totalBerat} kg", isLast: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteTimeline() {
    // Tampilkan 3 data terbaru
    var displayList = listRute.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: displayList.asMap().entries.map((entry) {
            var item = entry.value;
            bool isSelesai = item.status == 'selesai';
            return _routeItem(
              item.nasabahNama, 
              item.tanggalPengajuan, 
              item.status.toUpperCase(),
              isSelesai ? Colors.green : Colors.orange,
              isLast: entry.key == displayList.length - 1
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, "Beranda", true),
            _navItem(Icons.assignment, "Transaksi", false),
            const SizedBox(width: 40), 
            _navItem(Icons.receipt_long, "Setoran", false, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PetugasSetoranPage()),
              );
            }),
            _navItem(Icons.person, "Akun", false),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? const Color(0xFF154C94) : Colors.grey, size: 24),
          Text(label, style: TextStyle(color: active ? const Color(0xFF154C94) : Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.black, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _routeItem(String title, String sub, String label, Color color, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            if (!isLast) Container(width: 2, height: 45, color: Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft, 
        child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Logout"), 
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")),
          TextButton(onPressed: () { Navigator.pop(c); logout(); }, child: const Text("Logout")),
        ],
      ),
    );
  }
}