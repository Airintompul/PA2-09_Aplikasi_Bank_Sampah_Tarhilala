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

  // Helper fungsi untuk format tanggal (Cek field tanggal_pengajuan sesuai Controller)
  String formatTanggal(dynamic item) {
    dynamic dateStr = item['tanggal_pengajuan'] ?? item['created_at'] ?? item['tanggal'];
    
    if (dateStr == null || dateStr.toString().isEmpty) return "-";
    try {
      String s = dateStr.toString();
      return s.length >= 10 ? s.substring(0, 10) : s;
    } catch (e) {
      return dateStr.toString();
    }
  }

  // Helper untuk warna status (Dijadwalkan = Biru)
  Color _getStatusColor(dynamic status) {
    String s = status.toString().toLowerCase();
    if (s == 'selesai') return Colors.green;
    if (s == 'menunggu' || s == 'pending') return Colors.orange;
    if (s == 'dijadwalkan') return Colors.blue; // SUDAH BIRU
    return Colors.red;
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
    try {
      String? token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse("${AuthService.baseUrl}/nasabah/setoran/$id/cancel"),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request dibatalkan"), backgroundColor: Colors.green));
          _fetchAllData();
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _confirmCancel(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Batalkan Setoran?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text("Apakah Anda yakin ingin membatalkan permintaan setoran ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tidak")),
          TextButton(onPressed: () { Navigator.pop(context); _cancelSetoran(id); }, child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showBuktiTransfer(String? path) {
    if (path == null) return;
    // URL Backend Admin (Port 8000) biasanya tempat menyimpan file public
    String fullUrl = "http://127.0.0.1:8000/storage/$path";
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Invoice / Bukti", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(fullUrl, errorBuilder: (c, e, s) => const Text("File tidak dapat dibuka (Format PDF atau URL Salah)")),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))],
      ),
    );
  }

  // --- MODAL DETAIL SETORAN ---
  void _showDetailSetoran(dynamic item) {
    String namaPetugas = "Belum Ditugaskan";
    
    // Logika mengambil data driver dari relasi 'jadwal' -> 'driver'
    if (item['jadwal'] != null && item['jadwal']['driver'] != null) {
      namaPetugas = item['jadwal']['driver']['nama'].toString().toUpperCase();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.58,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 15), height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const Text("Detail Setoran Sampah", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A374D))),
            const SizedBox(height: 25),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                children: [
                  _rowDetailImageStyle("Tanggal Pengajuan", formatTanggal(item)),
                  _rowDetailImageStyle("Estimasi", "${item['estimasi_berat'] ?? '0'} Kg"),
                  _rowDetailImageStyle("Petugas", namaPetugas),
                  _rowDetailImageStyle("Status", item['status'].toString().toUpperCase(), color: _getStatusColor(item['status'])),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Pendapatan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text("Rp ${NumberFormat('#,###').format(double.tryParse(item['total_harga']?.toString() ?? '0') ?? 0)}", 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3B71CA))),
                    ],
                  ),
                  const SizedBox(height: 25),
                  if (item['status'].toString().toLowerCase() == 'selesai' && item['invoice'] != null)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _showBuktiTransfer(item['invoice']['file_invoice']),
                        icon: const Icon(Icons.receipt, color: Colors.white),
                        label: const Text("LIHAT INVOICE / STRUK", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF673AB7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                ],
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // --- MODAL DETAIL PENARIKAN ---
  void _showDetailPenarikan(dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.symmetric(vertical: 15), height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Align(alignment: Alignment.centerLeft, child: Text("Detail Penarikan Dana", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A374D)))),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                children: [
                  _rowDetailImageStyle("ID Transaksi", "#WD-${item['id']}"),
                  _rowDetailImageStyle("Waktu Request", formatTanggal(item)),
                  _rowDetailImageStyle("Tujuan Transfer", "${item['metode']} - ${item['nomor_tujuan']}"),
                  _rowDetailImageStyle("Nama Penerima", item['nama_penerima']?.toString().toUpperCase() ?? "-"),
                  _rowDetailImageStyle("Status", item['status'].toString().toUpperCase(), color: _getStatusColor(item['status'])),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Nominal Bersih", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text("Rp ${NumberFormat('#,###').format(double.tryParse(item['jumlah'].toString()) ?? 0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (item['status'].toString().toLowerCase() == 'selesai' && item['bukti_transfer'] != null)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _showBuktiTransfer(item['bukti_transfer']),
                        icon: const Icon(Icons.receipt_long, color: Colors.white),
                        label: const Text("LIHAT BUKTI TRANSFER", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                ],
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _rowDetailImageStyle(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black26, fontSize: 13)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color ?? Colors.black87))),
        ],
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
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text("Riwayat Transaksi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: _buildSellBanner()),
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
                : TabBarView(children: [_buildListSetoran(), _buildListPenarikan()]),
            ),
          ],
        ),
      ),
    );
  }

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
            status: item['status'] ?? "menunggu",
            isIncoming: true,
            canCancel: item['status'] == 'menunggu',
            onCancel: () => _confirmCancel(item['id']),
            onTap: () => _showDetailSetoran(item),
          );
        },
      ),
    );
  }

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
            sub: "Klik untuk Detail",
            amount: "Rp ${NumberFormat('#,###').format(double.tryParse(item['jumlah'].toString()) ?? 0)}",
            status: item['status'] ?? "pending",
            isIncoming: false,
            onTap: () => _showDetailPenarikan(item),
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
    bool canCancel = false,
    VoidCallback? onCancel,
    required VoidCallback onTap,
  }) {
    String displayStatus = status.toLowerCase();
    Color statusColor = _getStatusColor(status);
    String statusText = status.toUpperCase();
    String finalAmount = (displayStatus == 'dibatalkan' || displayStatus == 'ditolak') ? "Rp 0" : amount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
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
                      Text(sub, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(finalAmount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 5),
                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9)),
                  ],
                )
              ],
            ),
            if (canCancel) ...[
              const Divider(height: 25),
              SizedBox(width: double.infinity, height: 35, child: OutlinedButton(onPressed: onCancel, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Batalkan Request", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)))),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.history_toggle_off, size: 50, color: Colors.grey), const SizedBox(height: 10), Text(msg, style: const TextStyle(color: Colors.grey))]));

  Widget _buildSellBanner() => Container(width: double.infinity, padding: const EdgeInsets.all(25), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B71CA), Color(0xFF54B4D3)]), borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Punya sampah menumpuk?", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const Text("Jual sekarang dan dapatkan saldo tambahan!", style: TextStyle(color: Colors.white70, fontSize: 11)), const SizedBox(height: 20), ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JualSampahPage(showBackButton: true))), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF3B71CA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Jual Sekarang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))]));
}