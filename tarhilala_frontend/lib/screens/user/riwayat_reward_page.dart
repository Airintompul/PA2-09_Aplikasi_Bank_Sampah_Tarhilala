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
    setState(() => loading = true);
    final data = await RedeemService.getRiwayatRedeem();
    setState(() {
      history = data;
      loading = false;
    });
  }

  // --- LOGIC: KONFIRMASI TERIMA BARANG ---
  void _handleKonfirmasiTerima(int id) async {
    // Tampilkan Dialog Konfirmasi
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Terima", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin sudah menerima hadiah ini dengan baik?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Ya, Sudah", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => loading = true);
      // Memanggil fungsi confirm dari service
      bool success = await RedeemService.confirmReceipt(id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terima kasih! Transaksi selesai."), backgroundColor: Colors.green)
        );
        loadData(); // Refresh list
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengonfirmasi."), backgroundColor: Colors.red)
        );
      }
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'selesai': return Colors.green;
      case 'ditolak': return Colors.red;
      case 'dikirim': return Colors.indigo;
      case 'diproses': return Colors.blue;
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
          
          /// --- HEADER CUSTOM (KONSISTEN) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  "Riwayat Penukaran",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B71CA)))
                : history.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            final reward = item['reward'];
                            return _buildHistoryCard(item, reward);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

Widget _buildHistoryCard(Map item, Map? reward) {
  // Paksa status jadi huruf kecil agar pengecekan tidak meleset
  String status = item['status'].toString().toLowerCase();

  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
    ),
    child: Column( // Menggunakan Column agar tombol bisa di bawah
      children: [
        Row(
          children: [
            // ... (bagian icon/gambar reward tetap sama) ...
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reward?['nama_reward'] ?? 'Reward', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text("-${item['poin_digunakan']} Poin", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: getStatusColor(status), 
                  fontSize: 9, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1
                ),
              ),
            )
          ],
        ),

        // --- TOMBOL KONFIRMASI: MUNCUL JIKA STATUS ADALAH 'dikirim' ---
        if (status == 'dikirim') ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFF1F3F4), thickness: 1),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleKonfirmasiTerima(item['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                "Konfirmasi Hadiah Diterima", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
              ),
            ),
          ),
        ]
      ],
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 15),
          const Text("Belum ada penukaran poin.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}