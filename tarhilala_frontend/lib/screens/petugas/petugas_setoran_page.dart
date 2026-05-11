import 'package:flutter/material.dart';
import '../../models/setoran_model.dart';
import '../../services/pickup_service.dart';
import '../user/widgets/top_navbar.dart';
import '../petugas/widgets/bottom_navbar.dart';
import 'petugas_detail_setoran_page.dart';
import '../petugas/dashboard_page.dart';
import 'petugas_transaksi_page.dart';
import 'petugas_rute_page.dart';
import 'petugas_profile_page.dart'; // 1. PASTIKAN IMPORT INI ADA

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
    switch (status) {
      case 'selesai': return Colors.green;
      case 'dalam_penjemputan': return Colors.blue;
      case 'dijadwalkan': return Colors.orange;
      case 'dibatalkan': return Colors.red;
      default: return Colors.grey;
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF154C94).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF154C94), size: 20),
                ),
                const SizedBox(width: 15),
                const Text(
                  "Tugas Penjemputan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F)),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: FutureBuilder<List<SetoranModel>>(
                future: _futureSetoran,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  allData = snapshot.data!;
                  final filteredList = allData.where((item) {
                    return item.status == 'dijadwalkan' || item.status == 'dalam_penjemputan';
                  }).toList();

                  if (filteredList.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

      // --- BOTTOM NAVBAR PETUGAS ---
      bottomNavigationBar: PetugasBottomNavbar(
        currentIndex: 2, 
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PetugasDashboardPage()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PetugasTransaksiPage()));
          } 
          // 2. LOGIKA NAVIGASI KE AKUN (DITAMBAHKAN)
          else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PetugasProfilePage()));
          }
          else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PetugasRutePage(ruteData: allData)));
          }
        },
      ),
    );
  }

  // --- WIDGET HELPER TETAP SAMA ---

  Widget _buildTaskCard(SetoranModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PetugasDetailSetoranPage(setoran: item)),
            );
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3D5F)),
                      ),
                    ),
                    _buildBadge(item.status),
                  ],
                ),
                const SizedBox(height: 5),
                Text("ID Transaksi: #SET-${item.id}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F1)),
                ),
                _rowDetail(Icons.monitor_weight_outlined, "Estimasi Berat", "${item.totalBerat ?? 0} Kg"),
                const SizedBox(height: 8),
                _rowDetail(Icons.calendar_today_rounded, "Tanggal", item.tanggalPengajuan),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Proses Sekarang",
                      style: TextStyle(color: _getStatusColor(item.status), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 5),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _getStatusColor(item.status)),
                  ],
                )
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
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B3D5F))),
      ],
    );
  }

  Widget _buildBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: _getStatusColor(status), fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_motion_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Tidak ada tugas aktif",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Tugas baru dari Admin akan muncul di sini.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}