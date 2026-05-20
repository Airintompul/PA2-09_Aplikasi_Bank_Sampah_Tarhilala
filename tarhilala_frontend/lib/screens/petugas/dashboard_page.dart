import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/pickup_service.dart';
import '../../models/setoran_model.dart';  
import '../user/widgets/top_navbar.dart';
import 'petugas_rute_page.dart'; 
import 'petugas_setoran_page.dart';
import 'petugas_transaksi_page.dart';
import 'petugas_profile_page.dart'; 
import '../petugas/widgets/bottom_navbar.dart'; 

class PetugasDashboardPage extends StatefulWidget {
  const PetugasDashboardPage({super.key});

  @override
  State<PetugasDashboardPage> createState() => _PetugasDashboardPageState();
}

class _PetugasDashboardPageState extends State<PetugasDashboardPage> {
  String nama = "";
  bool isLoading = true;
  final PickupService _pickupService = PickupService(); 
  
  Map<String, dynamic> stats = {
    'total_tugas': 0,
    'selesai': 0,
    'sisa': 0,
    'total_kg': 0,
    'pendapatan': '0',
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

  Future<void> fetchDataDashboard() async {
    setState(() => isLoading = true);
    try {
      final data = await _pickupService.getSetoranRequests();
      setState(() {
        listRute = data;
        int selesai = data.where((s) => s.status == 'selesai').length;
        double totalKg = data.fold(0.0, (sum, item) => sum + (item.totalBerat ?? 0));

        stats = {
          'total_tugas': data.length,
          'selesai': selesai,
          'sisa': data.length - selesai,
          'total_kg': totalKg,
          'pendapatan': '0',
        };

        try {
          setoranBerikutnya = data.firstWhere((s) => s.status != 'selesai');
        } catch (e) {
          setoranBerikutnya = null;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
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
                // 1. HEADER & PROFILE (DIPERBAIKI)
                _buildHeaderSection(),

                // 2. GRID STATISTIK
                _buildStatsGrid(),

                const SizedBox(height: 25),

                // 3. SETORAN BERIKUTNYA
                _buildSectionLabel("Setoran Berikutnya"),
                setoranBerikutnya != null 
                  ? _buildNextDepositCard()
                  : _buildEmptyState("Tidak ada tugas tersisa hari ini"),

                const SizedBox(height: 25),

                // 4. TIMELINE AKTIVITAS
                _buildSectionLabel("Aktivitas Penjemputan"),
                _buildRouteTimeline(),

                const SizedBox(height: 100), 
              ],
            ),
          ),
        ),

      bottomNavigationBar: PetugasBottomNavbar(
        currentIndex: 0, 
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PetugasTransaksiPage()));
          } else if (index == 4) { 
            Navigator.push(context, MaterialPageRoute(builder: (context) => PetugasRutePage(ruteData: listRute)));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PetugasSetoranPage()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PetugasProfilePage()));
          }
        },
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildHeaderSection() {
    return Column(
      children: [
        // TOP NAVBAR
        const TopNavbar(),

        // JARAK AGAR TERPISAH
        const SizedBox(height: 18),

        // CARD DRIVER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildProfileCard(),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: const Icon(Icons.person, color: Color(0xFF154C94), size: 35),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B3D5F))
                ),
                const Text(
                  "Driver Lapangan • Aktif", 
                  style: TextStyle(color: Colors.grey, fontSize: 13)
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: Colors.blue, size: 20),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.3,
        children: [
          _buildStatCard("Tugas hari ini", "${stats['total_tugas']}", "${stats['selesai']} selesai ${stats['sisa']} sisa"),
          _buildStatCard("Total sampah", "${stats['total_kg'].toStringAsFixed(1)}", "Total hari ini", unit: "Kg"),
          _buildStatCard("Setoran masuk", "${stats['pendapatan']}", "Estimasi", prefix: "Rp "),
          _buildStatCard("Jarak rute", "0", "Wilayah Tugas", unit: "km"),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String sub, {String? unit, String? prefix}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF1B3D5F), fontSize: 20, fontWeight: FontWeight.bold),
              children: [
                if (prefix != null) TextSpan(text: prefix, style: const TextStyle(fontSize: 14)),
                TextSpan(text: value),
                if (unit != null) TextSpan(text: " $unit", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildNextDepositCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PetugasSetoranPage())).then((_) => fetchDataDashboard()),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(15), 
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15))
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF154C94), size: 20),
                    const SizedBox(width: 10),
                    Text("TUGAS AKTIF: #SET-${setoranBerikutnya!.id}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3D5F))),
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
    var displayList = listRute.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(15),
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

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(msg, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : Colors.grey.shade100))),
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B3D5F))),
              Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 12),
      child: Align(alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
    );
  }
}