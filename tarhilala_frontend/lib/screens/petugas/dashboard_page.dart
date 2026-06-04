import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/pickup_service.dart';
import '../../models/setoran_model.dart';  
import '../user/widgets/top_navbar.dart';
import 'petugas_rute_page.dart'; 
import 'petugas_setoran_page.dart';
import 'petugas_transaksi_page.dart';
import 'petugas_profile_page.dart'; 
import '../petugas/widgets/bottom_navbar.dart'; 

// Helper transisi slide — dipakai di semua halaman, tidak perlu file terpisah
Route _slideRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      final fade = Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
    },
  );
}

class PetugasDashboardPage extends StatefulWidget {
  const PetugasDashboardPage({super.key});

  @override
  State<PetugasDashboardPage> createState() => _PetugasDashboardPageState();
}

class _PetugasDashboardPageState extends State<PetugasDashboardPage> {
  String nama = "";
  bool isLoading = true;
  final PickupService _pickupService = PickupService(); 
  
  String jadwalHariIni = "Libur";
  String jamOperasional = "Hari ini tidak bertugas";
  bool isLibur = true;

  Map<String, dynamic> stats = {
    'total_tugas': 0,
    'selesai': 0,
    'sisa': 0,
    'total_kg': 0,
    'pendapatan': '0',
  };

  List<SetoranModel> aktivitasHariIni = []; 
  SetoranModel? setoranBerikutnya;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) => _initialLoad());
  }

  Future<void> _initialLoad() async {
    await loadUser();
    await fetchDataDashboard();
    await fetchJadwalOperasional();
  }

  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString("name") ?? "Petugas";
    });
  }

  Future<void> fetchJadwalOperasional() async {
    try {
      String hariIni = DateFormat('EEEE', 'id_ID').format(DateTime.now()).toLowerCase().trim();
      final response = await _pickupService.getJadwalOperasional(); 
      
      final mySchedule = response.firstWhere(
        (j) => 
            j['driver']['nama'].toString().toLowerCase().contains(nama.toLowerCase().trim()) && 
            j['hari'].toString().toLowerCase().trim() == hariIni,
        orElse: () => null,
      );

      setState(() {
        if (mySchedule != null) {
          jadwalHariIni = mySchedule['rute']['nama_rute'];
          jamOperasional = "${mySchedule['jam_mulai']} - ${mySchedule['jam_selesai']} WIB";
          isLibur = false;
        } else if (aktivitasHariIni.isNotEmpty) {
          jadwalHariIni = "Tugas Khusus";
          jamOperasional = "Penugasan Manual";
          isLibur = false;
        } else {
          jadwalHariIni = "Libur";
          jamOperasional = "Hari ini tidak bertugas";
          isLibur = true;
        }
      });
    } catch (e) {
      debugPrint("Error Jadwal: $e");
    }
  }

  Future<void> fetchDataDashboard() async {
    setState(() => isLoading = true);
    try {
      final data = await _pickupService.getSetoranRequests();
      
      DateTime now = DateTime.now();
      String todayStr = DateFormat('yyyy-MM-dd').format(now);
      String monthYearStr = DateFormat('yyyy-MM').format(now);

      setState(() {
        var tasksToday = data.where((s) {
          String dateOnly = s.tanggalPengajuan.split(" ")[0].trim();
          return dateOnly == todayStr && s.status.toLowerCase().trim() != 'dibatalkan';
        }).toList();

        aktivitasHariIni = tasksToday.where((s) {
          String st = s.status.toLowerCase().trim();
          return st == 'dijadwalkan' || st == 'dalam_penjemputan' || st == 'menunggu';
        }).toList();

        int selesaiHariIni = tasksToday.where((s) => s.status.toLowerCase().trim() == 'selesai').length;

        var tasksThisMonth = data.where((s) {
          return s.tanggalPengajuan.startsWith(monthYearStr) && s.status.toLowerCase().trim() == 'selesai';
        }).toList();

        double totalKgBulanIni = tasksThisMonth.fold(0.0, (sum, item) => sum + (item.totalBerat ?? 0));
        double totalRpBulanIni = tasksThisMonth.fold(0.0, (sum, item) => sum + (item.totalHarga ?? 0));

        stats = {
          'total_tugas': tasksToday.length,
          'selesai': selesaiHariIni,
          'sisa': aktivitasHariIni.length,
          'total_kg': totalKgBulanIni,
          'pendapatan': NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(totalRpBulanIni),
        };

        setoranBerikutnya = aktivitasHariIni.isNotEmpty ? aktivitasHariIni.first : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: isLoading 
      ? const Center(child: CircularProgressIndicator(color: Color(0xFF154C94)))
      : RefreshIndicator(
          color: const Color(0xFF154C94),
          onRefresh: _initialLoad,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 4),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildSectionLabel("Setoran Berikutnya (Hari Ini)"),
                setoranBerikutnya != null 
                  ? _buildNextDepositCard()
                  : _buildEmptyState(isLibur ? "Otomatis Libur: Tidak ada jadwal" : "Semua tugas hari ini selesai!"),
                const SizedBox(height: 24),
                _buildSectionLabel("Aktivitas Penjemputan Hari Ini"),
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
            Navigator.pushReplacement(context, _slideRoute(const PetugasTransaksiPage()));
          } else if (index == 2) { 
            Navigator.push(context, _slideRoute(PetugasRutePage(ruteData: aktivitasHariIni)));
          } else if (index == 3) {
            Navigator.pushReplacement(context, _slideRoute(const PetugasSetoranPage()));
          } else if (index == 4) {
            Navigator.pushReplacement(context, _slideRoute(const PetugasProfilePage()));
          }
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        const TopNavbar(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildProfileCard(),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF154C94), Color(0xFF1E6BC6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF154C94).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "Driver Lapangan",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _buildStatCard("Tugas hari ini", "${stats['total_tugas']}", "${stats['selesai']} selesai, ${stats['sisa']} sisa"),
          _buildStatCard("Total sampah", "${stats['total_kg'].toStringAsFixed(1)}", "Bulan Ini", unit: "Kg"),
          _buildStatCard("Setoran masuk", "${stats['pendapatan']}", "Bulan Ini", prefix: "Rp "),
          _buildStatCard("Jadwal Operasional", jadwalHariIni, jamOperasional, isJadwal: true),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String sub, {String? unit, String? prefix, bool isJadwal = false}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF154C94).withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF8FA3B8), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          const SizedBox(height: 7),
          isJadwal 
          ? Text(value, style: TextStyle(color: isLibur ? const Color(0xFFE53935) : const Color(0xFF154C94), fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)
          : RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF0D2744), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                children: [
                  if (prefix != null) TextSpan(text: prefix, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                  if (unit != null) TextSpan(text: " $unit", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8FA3B8))),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: Color(0xFFAABBCC), fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildNextDepositCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => Navigator.push(context, _slideRoute(const PetugasSetoranPage())).then((_) => _initialLoad()),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF154C94).withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF154C94).withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: const Color(0xFF154C94).withOpacity(0.08))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(color: const Color(0xFF154C94), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text("AKTIF: #SET-${setoranBerikutnya!.id}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0D2744), letterSpacing: 0.2)),
                  ],
                ),
              ),
              _detailRow("Nasabah", setoranBerikutnya!.nasabahNama),
              _detailRow("Status", setoranBerikutnya!.status.replaceAll('_', ' ').toUpperCase()),
              _detailRow("Est. berat", "${setoranBerikutnya!.totalBerat} kg", isLast: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF154C94).withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: aktivitasHariIni.isEmpty
              ? [const Text("Tidak ada tugas penjemputan aktif hari ini", style: TextStyle(color: Color(0xFFAABBCC), fontSize: 12))]
              : aktivitasHariIni.map((item) {
                  Color statusColor = item.status.toLowerCase().trim() == 'dalam_penjemputan'
                      ? const Color(0xFF1E6BC6) : const Color(0xFFFFB830);
                  return _routeItem(item.nasabahNama, item.tanggalPengajuan, item.status.toUpperCase(), statusColor);
                }).toList(),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : const Color(0xFFF0F4F8)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8FA3B8), fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0D2744))),
        ],
      ),
    );
  }

  Widget _routeItem(String title, String sub, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)])),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0D2744))),
                Text(sub, style: const TextStyle(color: Color(0xFFAABBCC), fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(label.replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: const TextStyle(color: Color(0xFF6B7E96), fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.2)),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(msg, style: const TextStyle(color: Color(0xFFAABBCC), fontStyle: FontStyle.italic, fontSize: 12)),
      ),
    );
  }
}