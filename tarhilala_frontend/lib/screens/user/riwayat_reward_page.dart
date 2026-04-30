import 'package:flutter/material.dart';
import 'package:tarhilala_frontend/screens/user/widgets/top_navbar.dart';
import '../../services/redeem_service.dart';
import 'package:intl/intl.dart';

class RiwayatRewardPage extends StatefulWidget {
  const RiwayatRewardPage({super.key});

  @override
  State<RiwayatRewardPage> createState() => _RiwayatRewardPageState();
}

class _RiwayatRewardPageState extends State<RiwayatRewardPage> {
  List history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await RedeemService.getRiwayatRedeem();
    setState(() {
      history = data;
      loading = false;
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'selesai': return Colors.green;
      case 'ditolak': return Colors.red;
      default: return Colors.orange; // 'menunggu'
    }
  }

  String getCleanImageUrl(String? url) {
    if (url == null) return "";
    return url.replaceAll("127.0.0.1", "10.0.2.2").replaceAll(" ", "%20");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          const TopNavbar(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new, size: 20),
                ),
                const SizedBox(width: 15),
                const Text("Riwayat Penukaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : history.isEmpty
                    ? const Center(child: Text("Belum ada riwayat penukaran."))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final reward = item['reward'];
                          return _buildHistoryCard(item, reward);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map item, Map? reward) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: reward != null
                ? Image.network(
                    getCleanImageUrl(reward['gambar']),
                    width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.redeem),
                  )
                : const Icon(Icons.redeem),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward?['nama_reward'] ?? 'Reward', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 5),
                Text("${item['poin_digunakan']} Poin", style: const TextStyle(color: Color(0xFF3B71CA), fontSize: 12, fontWeight: FontWeight.bold)),
                Text(item['tanggal_penukaran'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: getStatusColor(item['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item['status'].toUpperCase(),
              style: TextStyle(color: getStatusColor(item['status']), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}