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

  // --- LOGIC: AMBIL SEMUA DATA ---
  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      int? userId = await AuthService.getUserId();
      String? token = await AuthService.getToken();

      final resSetoran = await http.get(
        Uri.parse("${AuthService.baseUrl}/nasabah/setoran/$userId"),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

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

  // --- LOGIC: PEMBATALAN SETORAN ---
  Future<void> _cancelSetoran(int id) async {
    // Tampilkan loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sedang memproses pembatalan..."), duration: Duration(seconds: 1)),
    );

    try {
      String? token = await AuthService.getToken();
      
      // Mengirim request ke endpoint update status atau endpoint cancel khusus
      final response = await http.post(
        Uri.parse("${AuthService.baseUrl}/nasabah/setoran/$id/cancel"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Request setoran berhasil dibatalkan"), backgroundColor: Colors.green),
          );
          _fetchAllData(); // Refresh list data
        }
      } else {
        throw "Gagal membatalkan request. Status: ${response.statusCode}";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- UI: DIALOG KONFIRMASI BATAL ---
  void _confirmCancel(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Batalkan Setoran?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text("Apakah Anda yakin ingin membatalkan permintaan setoran ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tidak")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelSetoran(id);
            },
            child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
            "http://10.0.2.2:8001/$path",
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
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text("Riwayat Transaksi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildSellBanner(),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: TabBar(
                indicatorColor: const Color(0xFF3B71CA),
                labelColor: const Color(0xFF3B71CA),
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: const [Tab(text: "Setoran Sampah"), Tab(text: "Penarikan Saldo")],
              ),
            ),

            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B71CA)))
                : TabBarView(
                    children: [
                      _buildListSetoran(),
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
    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _listRiwayatSetoran.length,
        itemBuilder: (context, index) {
          var item = _listRiwayatSetoran[index];
          return _cardTransaction(
            title: "Request #${item['id']}",
            sub: "Estimasi: ${item['estimasi_berat']} Kg",
            amount: "Rp ${item['total_harga'] ?? '0'}",
            status: item['status'],
            isIncoming: true,
            canCancel: item['status'] == 'menunggu', // Bisa batal jika status 'menunggu'
            onCancel: () => _confirmCancel(item['id']),
            onTap: () {}
          );
        },
      ),
    );
  }

  // --- TAB: PENARIKAN SALDO ---
  Widget _buildListPenarikan() {
    if (_listRiwayatPenarikan.isEmpty) return _buildEmptyState("Belum ada riwayat penarikan");
    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
      ),
    );
  }

  Widget _cardTransaction({
    required String title, 
    required String sub, 
    required String amount, 
    required String status, 
    required bool isIncoming,
    bool hasProof = false,
    bool canCancel = false,
    VoidCallback? onCancel,
    required VoidCallback onTap,
  }) {
    // Logic Warna Status
    Color statusColor = Colors.orange;
    if (status == 'selesai') statusColor = Colors.green;
    if (status == 'dibatalkan' || status == 'ditolak') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
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
          
          // Tombol Batalkan hanya muncul jika status 'menunggu'
          if (canCancel) ...[
            const Divider(height: 25),
            SizedBox(
              width: double.infinity,
              height: 35,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Batalkan Request", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.history_toggle_off, size: 50, color: Colors.grey), const SizedBox(height: 10), Text(msg, style: const TextStyle(color: Colors.grey))]));

  Widget _buildSellBanner() => Container(width: double.infinity, padding: const EdgeInsets.all(25), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B71CA), Color(0xFF54B4D3)]), borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Punya sampah menumpuk?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const Text("Jual sekarang dan dapatkan saldo tambahan!", style: TextStyle(color: Colors.white70, fontSize: 11)), const SizedBox(height: 20), ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JualSampahPage(showBackButton: true))), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF3B71CA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Jual Sekarang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))]));
}