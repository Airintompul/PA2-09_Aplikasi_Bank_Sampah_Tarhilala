import 'package:flutter/material.dart';
import '../../models/setoran_model.dart';
import '../../services/pickup_service.dart';
import 'petugas_detail_setoran_page.dart'; // Import halaman detail

class PetugasSetoranPage extends StatefulWidget {
  const PetugasSetoranPage({super.key});

  @override
  State<PetugasSetoranPage> createState() => _PetugasSetoranPageState();
}

class _PetugasSetoranPageState extends State<PetugasSetoranPage> {
  final PickupService _pickupService = PickupService();
  late Future<List<SetoranModel>> _futureSetoran;

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
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text("Tugas Penjemputan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00BFA5),
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<List<SetoranModel>>(
          future: _futureSetoran,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Tidak ada tugas baru dari Admin."));
            }

            final filteredList = snapshot.data!.where((item) {
              return item.status == 'dijadwalkan' || item.status == 'dalam_penjemputan';
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return InkWell(
                  onTap: () async {
                    // Pindah ke Detail dan refresh saat kembali
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetugasDetailSetoranPage(setoran: item),
                      ),
                    );
                    _loadData();
                  },
                  child: _buildTaskCard(item),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskCard(SetoranModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.nasabahNama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF154C94))),
              _buildBadge(item.status),
            ],
          ),
          const SizedBox(height: 8),
          Text("ID: #SET-${item.id}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(height: 24),
          _rowDetail("Estimasi Total", "${item.totalBerat ?? 0} Kg"),
          _rowDetail("Tgl Pengajuan", item.tanggalPengajuan),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerRight,
            child: Text("Klik untuk Detail >", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _rowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}