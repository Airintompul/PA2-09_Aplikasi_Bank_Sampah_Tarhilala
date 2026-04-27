import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import 'widgets/top_navbar.dart'; // Import widget TopNavbar Anda
import 'jual_sampah_page.dart';

class RiwayatSetoranPage extends StatefulWidget {
  const RiwayatSetoranPage({super.key});

  @override
  State<RiwayatSetoranPage> createState() => _RiwayatSetoranPageState();
}

class _RiwayatSetoranPageState extends State<RiwayatSetoranPage> {
  List _listRiwayat = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      int? userId = await AuthService.getUserId();
      String? token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("${AuthService.baseUrl}/nasabah/setoran/$userId"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _listRiwayat = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        throw "Gagal memuat data";
      }
    } catch (e) {
      debugPrint("Error Fetching History: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: MENAMPILKAN DETAIL SETORAN ---
  void _showDetail(Map data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailSheet(data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          /// 1. TOP NAVBAR (Sesuai Dashboard & Reward)
          const TopNavbar(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFF3B71CA),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    /// 2. CARD AJAKAN JUAL (Banner Konsisten)
                    _buildSellBanner(),

                    const SizedBox(height: 30),

                    const Text(
                      "Permintaan Penjemputan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3D5F),
                      ),
                    ),
                    const SizedBox(height: 15),

                    /// 3. LIST RIWAYAT
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _listRiwayat.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _listRiwayat.length,
                                itemBuilder: (context, index) {
                                  return _buildRiwayatCard(_listRiwayat[index]);
                                },
                              ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B71CA), Color(0xFF54B4D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B71CA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Punya sampah menumpuk?",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Jual sekarang dan dapatkan saldo tambahan!",
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JualSampahPage())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B71CA),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Jual Sekarang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          )
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(Map data) {
    String status = data['status'] ?? 'menunggu';
    return GestureDetector(
      onTap: () => _showDetail(data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_outlined, color: _getStatusColor(status)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Request #${data['id']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3D5F)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Estimasi: ${data['estimasi_berat']} Kg • ${data['metode_pembayaran'].toString().toUpperCase()}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("Belum ada riwayat setoran", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSheet(Map data) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 25),
          const Text("Detail Transaksi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F))),
          const SizedBox(height: 20),
          
          _detailItem("Order ID", "#SET-${data['id']}"),
          _detailItem("Status", data['status'].toString().toUpperCase(), color: _getStatusColor(data['status'])),
          _detailItem("Waktu", data['tanggal_pengajuan'] ?? '-'),
          const Divider(height: 30),
          
          _detailItem("Estimasi Berat", "${data['estimasi_berat']} Kg"),
          _detailItem("Berat Final", "${data['berat_final'] ?? '0.0'} Kg"),
          _detailItem("Total Harga", "Rp ${data['total_harga'] ?? '0'}", isBold: true, color: const Color(0xFF3B71CA)),
          
          const SizedBox(height: 20),
          const Text("Catatan Nasabah:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Text(data['catatan'] ?? "Tidak ada catatan tambahan.", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B71CA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.bold, fontSize: 13, color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'selesai') return Colors.green;
    if (status == 'menunggu') return Colors.orange;
    if (status == 'dibatalkan') return Colors.red;
    return const Color(0xFF3B71CA);
  }
}