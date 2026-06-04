import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/setoran_model.dart';
import '../../services/pickup_service.dart';
import '../user/widgets/top_navbar.dart';
import '../petugas/widgets/bottom_navbar.dart';
import 'petugas_detail_setoran_page.dart';
import '../petugas/dashboard_page.dart';
import 'petugas_transaksi_page.dart';
import 'petugas_rute_page.dart';
import 'petugas_profile_page.dart';

Route _slideRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      final slide = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      final fade = Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
    },
  );
}

class PetugasSetoranPage extends StatefulWidget {
  const PetugasSetoranPage({super.key});

  @override
  State<PetugasSetoranPage> createState() => _PetugasSetoranPageState();
}

class _PetugasSetoranPageState extends State<PetugasSetoranPage> {
  final PickupService _pickupService = PickupService();
  late Future<List<SetoranModel>> _futureSetoran;
  List<SetoranModel> allData = []; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureSetoran = _pickupService.getSetoranRequests();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'selesai': return Colors.green;
      case 'dalam_penjemputan': return const Color(0xFF1E6BC6);
      case 'dijadwalkan': return const Color(0xFFFFB830);
      case 'dibatalkan': return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          const TopNavbar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF154C94).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF154C94), size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Tugas Penjemputan Hari Ini",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0D2744)),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF154C94),
              onRefresh: () async => _loadData(),
              child: FutureBuilder<List<SetoranModel>>(
                future: _futureSetoran,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF154C94)));
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  allData = snapshot.data!;
                  DateTime now = DateTime.now();
                  String todayStr = DateFormat('yyyy-MM-dd').format(now);

                  final filteredList = allData.where((item) {
                    String taskDate = item.tanggalPengajuan.split(" ")[0].trim();
                    bool isToday = taskDate == todayStr;
                    String status = item.status.toLowerCase().trim();
                    bool isActive = status == 'dijadwalkan' || status == 'dalam_penjemputan';
                    return isToday && isActive;
                  }).toList();

                  if (filteredList.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildTaskCard(item);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: PetugasBottomNavbar(
        currentIndex: 3, 
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, _slideRoute(const PetugasDashboardPage()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, _slideRoute(const PetugasTransaksiPage()));
          } else if (index == 2) {
            Navigator.push(context, _slideRoute(PetugasRutePage(ruteData: allData)));
          } else if (index == 4) {
            Navigator.pushReplacement(context, _slideRoute(const PetugasProfilePage()));
          }
        },
      ),
    );
  }

  Widget _buildTaskCard(SetoranModel item) {
    final statusColor = _getStatusColor(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF154C94).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(context, _slideRoute(PetugasDetailSetoranPage(setoran: item)));
            _loadData();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.nasabahNama,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0D2744)),
                      ),
                    ),
                    _buildBadge(item.status, statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text("ID: #SET-${item.id}", style: const TextStyle(color: Color(0xFFAABBCC), fontSize: 11)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF0F4F8)),
                ),
                _rowDetail(Icons.monitor_weight_outlined, "Estimasi Berat", "${item.totalBerat ?? 0} Kg"),
                const SizedBox(height: 8),
                _rowDetail(Icons.calendar_today_rounded, "Tanggal", item.tanggalPengajuan),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("Proses Sekarang", style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 11, color: statusColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF8FA3B8)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFF8FA3B8), fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0D2744))),
      ],
    );
  }

  Widget _buildBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_motion_rounded, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          const Text("Tidak ada tugas hari ini", style: TextStyle(color: Color(0xFF8FA3B8), fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          const Text("Hanya tugas untuk tanggal hari ini yang muncul.", style: TextStyle(color: Color(0xFFAABBCC), fontSize: 12)),
        ],
      ),
    );
  }
}