import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import 'widgets/top_navbar.dart';
import 'jual_sampah_page.dart';

class RiwayatSetoranPage extends StatefulWidget {
  const RiwayatSetoranPage({super.key});

  @override
  State<RiwayatSetoranPage> createState() => _RiwayatSetoranPageState();
}

class _RiwayatSetoranPageState extends State<RiwayatSetoranPage> {
  List _listRiwayatSetoran = [];
  List _listRiwayatPenarikan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      int? userId = await AuthService.getUserId();
      String? token = await AuthService.getToken();

      // 1. Ambil Riwayat Setoran (Port 8000)
      final resSetoran = await http.get(
        Uri.parse("${AuthService.baseUrl}/nasabah/setoran/$userId"),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      // 2. Ambil Riwayat Penarikan (Port 8000 -> Proxy ke 8001)
      final resPenarikan = await http.get(
        Uri.parse("${AuthService.baseUrl}/nasabah/riwayat-penarikan"),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        setState(() {
          _listRiwayatSetoran = jsonDecode(resSetoran.body);
          _listRiwayatPenarikan = jsonDecode(resPenarikan.body)['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Fetching Data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: MENAMPILKAN BUKTI TRANSFER DARI ADMIN ---
  void _showBuktiTransfer(String? path) {
    if (path == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Bukti Transfer Admin", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            "http://10.0.2.2:8001/$path", // Ambil dari Port Finance
            loadingBuilder: (context, child, progress) => progress == null ? child : const CircularProgressIndicator(),
            errorBuilder: (c, e, s) => const Text("Gambar tidak tersedia"),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F9),
        body: Column(
          children: [
            const TopNavbar(),
            
            // BANNER PROMO
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildSellBanner(),
            ),

            // TAB NAVIGATION
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TabBar(
                indicatorColor: const Color(0xFF3B71CA),
                labelColor: const Color(0xFF3B71CA),
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: "Setoran Sampah"),
                  Tab(text: "Penarikan Saldo"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      // TAB 1: LIST SETORAN
                      _buildListSetoran(),
                      // TAB 2: LIST PENARIKAN
                      _buildListPenarikan(),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB: SETORAN SAMPAH ---
  Widget _buildListSetoran() {
    if (_listRiwayatSetoran.isEmpty) return _buildEmptyState("Belum ada riwayat setoran");
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _listRiwayatSetoran.length,
      itemBuilder: (context, index) => _cardTransaction(
        title: "Request #${_listRiwayatSetoran[index]['id']}",
        sub: "Estimasi: ${_listRiwayatSetoran[index]['estimasi_berat']} Kg",
        amount: "Rp ${_listRiwayatSetoran[index]['total_harga'] ?? '0'}",
        status: _listRiwayatSetoran[index]['status'],
        isIncoming: true,
        onTap: () {} // Bisa tambah modal detail jika mau
      ),
    );
  }

  // --- TAB: PENARIKAN SALDO ---
  Widget _buildListPenarikan() {
    if (_listRiwayatPenarikan.isEmpty) return _buildEmptyState("Belum ada riwayat penarikan");
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _listRiwayatPenarikan.length,
      itemBuilder: (context, index) {
        var item = _listRiwayatPenarikan[index];
        return _cardTransaction(
          title: "Tarik via ${item['metode']}",
          sub: "${item['nomor_tujuan']} - ${item['nama_penerima']}",
          amount: "Rp ${NumberFormat('#,###').format(double.parse(item['jumlah'].toString()))}",
          status: item['status'],
          isIncoming: false,
          hasProof: item['bukti_transfer'] != null,
          onTap: () {
            if (item['status'] == 'selesai') _showBuktiTransfer(item['bukti_transfer']);
          }
        );
      },
    );
  }

  Widget _cardTransaction({
    required String title, 
    required String sub, 
    required String amount, 
    required String status, 
    required bool isIncoming,
    bool hasProof = false,
    required VoidCallback onTap,
  }) {
    Color statusColor = status == 'selesai' ? Colors.green : (status == 'ditolak' ? Colors.red : Colors.orange);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isIncoming ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              child: Icon(isIncoming ? Icons.add_chart : Icons.outbox, color: isIncoming ? Colors.green : Colors.red, size: 18),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (hasProof) const Text("• Lihat Bukti Transfer", style: TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 5),
                Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.history_toggle_off, size: 50, color: Colors.grey), const SizedBox(height: 10), Text(msg, style: const TextStyle(color: Colors.grey))]));

  Widget _buildSellBanner() => Container(width: double.infinity, padding: const EdgeInsets.all(25), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B71CA), Color(0xFF54B4D3)]), borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Punya sampah menumpuk?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const Text("Jual sekarang dan dapatkan saldo tambahan!", style: TextStyle(color: Colors.white70, fontSize: 11)), const SizedBox(height: 20), ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JualSampahPage())), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF3B71CA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Jual Sekarang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))]));
}