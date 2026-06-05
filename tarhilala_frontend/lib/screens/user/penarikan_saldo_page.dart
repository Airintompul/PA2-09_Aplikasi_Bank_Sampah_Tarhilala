import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'widgets/top_navbar.dart';

class TransaksiPage extends StatefulWidget {
  // 1. TAMBAHKAN PARAMETER INI
  final bool showBackButton;
  const TransaksiPage({super.key, this.showBackButton = false});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  String currentSaldo = "0";
  List riwayatWd = [];
  bool isLoading = true;

  final _jumlahController = TextEditingController();
  final _nomorTujuanController = TextEditingController();
  final _namaPenerimaController = TextEditingController();
  String _selectedMetode = 'BCA';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final resProfile = await http.get(
        Uri.parse("http://10.0.2.2:8000/api/profile"),
        headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
      );
      
      final resHistory = await http.get(
        Uri.parse("http://10.0.2.2:8000/api/nasabah/riwayat-penarikan"),
        headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
      );

      if (mounted && resHistory.statusCode == 200 && resProfile.statusCode == 200) {
        final profileData = jsonDecode(resProfile.body);
        final historyData = jsonDecode(resHistory.body);

        setState(() {
          currentSaldo = profileData['saldo'].toString();
          riwayatWd = historyData['data'] ?? []; 
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Load Data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _submitWithdrawal() async {
    if (_jumlahController.text.isEmpty || _nomorTujuanController.text.isEmpty || _namaPenerimaController.text.isEmpty) {
      _showSnack("Lengkapi seluruh data bank Anda", Colors.orange);
      return;
    }

    int? nominal = int.tryParse(_jumlahController.text);
    if (nominal == null || nominal < 50000) {
      _showSnack("Batas minimal penarikan adalah Rp 50.000", Colors.red);
      return;
    }

    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/api/nasabah/tarik-saldo"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({
          "jumlah": nominal, 
          "metode": _selectedMetode,
          "nomor_tujuan": _nomorTujuanController.text,
          "nama_penerima": _namaPenerimaController.text
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _jumlahController.clear();
        _nomorTujuanController.clear();
        _namaPenerimaController.clear();
        _showSnack("Berhasil diajukan! Menunggu transfer Admin.", Colors.green);
        _loadData();
      } else {
        final err = jsonDecode(response.body);
        _showSnack(err['message'] ?? "Gagal", Colors.red);
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnack("Koneksi gagal", Colors.red);
      setState(() => isLoading = false);
    }
  }

  // --- UI: DETAIL & BUKTI (Kode tetap sama) ---
  void _showDetailPenarikan(Map item) {
    String status = item['status'].toString();
    Color statusColor = status == 'selesai' ? Colors.green : (status == 'ditolak' ? Colors.red : Colors.orange);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            const Text("Detail Penarikan Dana", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F))),
            const SizedBox(height: 20),
            _rowDetail("ID Transaksi", "#WD-${item['id']}"),
            _rowDetail("Waktu Request", item['tanggal_pengajuan'] ?? '-'),
            _rowDetail("Tujuan Transfer", "${item['metode']} - ${item['nomor_tujuan']}"),
            _rowDetail("Nama Penerima", item['nama_penerima']?.toString().toUpperCase() ?? '-'),
            _rowDetail("Status", status.toUpperCase(), color: statusColor),
            const Divider(height: 30),
            _rowDetail("Nominal Bersih", "Rp ${NumberFormat('#,###').format(double.parse(item['jumlah'].toString()))}", isBold: true),
            const SizedBox(height: 25),
            if (status == 'selesai' && item['bukti_transfer'] != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(context); _showBuktiDialog(item['bukti_transfer']); },
                  icon: const Icon(Icons.image_search, size: 18, color: Colors.white),
                  label: const Text("LIHAT BUKTI TRANSFER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }

  void _showBuktiDialog(String imagePath) {
    String imageUrl = "http://10.0.2.2:8001/storage/$imagePath";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bukti Transfer Admin", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl, loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()), errorBuilder: (context, error, stackTrace) => const Text("Bukti transfer tidak dapat dimuat."))),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          const TopNavbar(),

          /// --- HEADER: DINAMIS BERDASARKAN showBackButton ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                // HANYA MUNCUL JIKA showBackButton = true
                if (widget.showBackButton) ...[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, 
                          size: 18, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
                
                const Text(
                  "Penarikan Saldo",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E56A0)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSaldoCard(),
                        const SizedBox(height: 25),
                        _buildWithdrawForm(),
                        const SizedBox(height: 30),
                        const Text("Riwayat Penarikan", 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3D5F))),
                        const SizedBox(height: 15),
                        _buildHistoryList(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS (Kode tetap sama) ---
  Widget _buildSaldoCard() {
    double saldo = double.tryParse(currentSaldo) ?? 0;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B71CA), Color(0xFF54B4D3)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Saldo Aktif", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 5),
          Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(saldo), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildWithdrawForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Informasi Rekening", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 15),
          _inputField(_jumlahController, "Nominal (Min Rp 50.000)", Icons.payments_outlined, isNumber: true),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedMetode,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.account_balance, size: 20), labelText: "Bank / E-Wallet", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: ['BCA', 'MANDIRI', 'BRI', 'DANA', 'GOPAY'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedMetode = v!),
          ),
          const SizedBox(height: 12),
          _inputField(_nomorTujuanController, "Nomor Rekening / HP", Icons.credit_card, isNumber: true),
          const SizedBox(height: 12),
          _inputField(_namaPenerimaController, "Nama Pemilik", Icons.person_outline),
          const SizedBox(height: 25),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _submitWithdrawal, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E56A0), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0), child: const Text("Tarik Saldo Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))
      ]),
    );
  }

  Widget _buildHistoryList() {
    if (riwayatWd.isEmpty) return const Center(child: Text("Belum ada riwayat transaksi", style: TextStyle(color: Colors.grey)));
    return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: riwayatWd.length, itemBuilder: (context, i) {
        var item = riwayatWd[i];
        String status = item['status'].toString();
        Color statusColor = status == 'selesai' ? Colors.green : (status == 'ditolak' ? Colors.red : Colors.orange);
        return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade100)), child: ListTile(onTap: () => _showDetailPenarikan(item), leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.1), child: Icon(Icons.history, color: statusColor, size: 20)), title: Text("Rp ${NumberFormat('#,###').format(double.parse(item['jumlah'].toString()))}", style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${item['metode']} • Klik Detail"), trailing: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9))));
    });
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) => TextField(controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: InputDecoration(prefixIcon: Icon(icon, size: 20), labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
  Widget _rowDetail(String label, String val, {Color? color, bool isBold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)), Text(val, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.bold, color: color ?? Colors.black87, fontSize: 13))]));
  void _showSnack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
}