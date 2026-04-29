import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:tarhilala_frontend/screens/user/widgets/top_navbar.dart';
import '../user/widgets/bottom_navbar.dart';
import '../../services/redeem_service.dart';

class FormTukarPoinPage extends StatefulWidget {
  final Map data;
  const FormTukarPoinPage({super.key, required this.data});

  @override
  State<FormTukarPoinPage> createState() => _FormTukarPoinPageState();
}

class _FormTukarPoinPageState extends State<FormTukarPoinPage> {
  int jumlah = 1;
  bool isAgreed = false;
  String userPoin = "0";
  bool loadingPoin = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchUserPoin();
  }

  // --- AMBIL POIN DINAMIS DARI API ---
  Future<void> fetchUserPoin() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/api/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userPoin = (data['poin'] ?? 0).toString();
          loadingPoin = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetch poin: $e");
      setState(() => loadingPoin = false);
    }
  }

  // --- LOGIKA URL GAMBAR ---
  String getCleanImageUrl(String? url) {
    if (url == null) return "";
    String fixedUrl = url.replaceAll("127.0.0.1", "10.0.2.2");
    return Uri.encodeFull(fixedUrl);
  }

  @override
  Widget build(BuildContext context) {
    int poinSatuan = int.parse(widget.data['poin_dibutuhkan'].toString());
    int stok = widget.data['stok'] ?? 0;
    int totalPoinDibutuhkan = jumlah * poinSatuan;
    bool poinCukup = int.parse(userPoin) >= totalPoinDibutuhkan;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          const TopNavbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),

                  /// 2. HEADER
                  _buildHeader(context),

                  const SizedBox(height: 20),

                  /// 3. KARTU POIN BIRU DINAMIS
                  _buildBluePointsCard(),

                  const SizedBox(height: 25),

                  /// 4. FORM KARTU
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // INFO ITEM
                        _buildItemInfo(),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Color(0xFFF0F4F8), thickness: 2),
                        ),

                        // JUMLAH
                        const Text("Jumlah Penukaran", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F))),
                        const SizedBox(height: 12),
                        _buildQuantitySelector(stok),

                        const SizedBox(height: 25),

                        // RINGKASAN
                        _summaryRow("Total Poin dibutuhkan", "$totalPoinDibutuhkan Poin", isPrimary: true),
                        _summaryRow("Poin Anda Saat Ini", "$userPoin Poin"),

                        const SizedBox(height: 20),

                        // CHECKBOX
                        _buildAgreementCheckbox(),

                        const SizedBox(height: 25),

                        // TOMBOL KONFIRMASI
                        _buildSubmitButton(poinCukup, stok),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1B3D5F)),
          ),
        ),
        const SizedBox(width: 15),
        const Text("Penukaran Poin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F))),
      ],
    );
  }

  Widget _buildBluePointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B71CA), Color(0xFF54B4D3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Poin Anda Saat Ini", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  loadingPoin 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(userPoin, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white24, size: 40),
        ],
      ),
    );
  }

  Widget _buildItemInfo() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 80, height: 80, color: const Color(0xFFF0F4F8),
            child: Image.network(
              getCleanImageUrl(widget.data['gambar']),
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.redeem, color: Color(0xFF1E56A0), size: 30),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.data['nama_reward'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3D5F))),
              const SizedBox(height: 4),
              Text("${widget.data['poin_dibutuhkan']} Poin / item", style: const TextStyle(color: Color(0xFF3B71CA), fontWeight: FontWeight.w600)),
              Text("Stok: ${widget.data['stok']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(int stok) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() => jumlah > 1 ? jumlah-- : null),
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          ),
          Text("$jumlah", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: () => setState(() => jumlah < stok ? jumlah++ : null),
            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementCheckbox() {
    return Row(
      children: [
        Checkbox(value: isAgreed, activeColor: const Color(0xFF1E56A0), onChanged: (val) => setState(() => isAgreed = val!)),
        const Expanded(child: Text("Saya setuju dengan syarat & ketentuan yang berlaku", style: TextStyle(fontSize: 11, color: Colors.grey))),
      ],
    );
  }

  Widget _buildSubmitButton(bool poinCukup, int stok) {
    bool canSubmit = isAgreed && poinCukup && stok > 0 && !isSubmitting;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit ? () => _processRedemption() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? const Color(0xFF1E56A0) : Colors.grey.shade300,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: isSubmitting 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              !poinCukup ? "Poin Tidak Cukup" : "Konfirmasi Penukaran",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isPrimary ? const Color(0xFF1E56A0) : const Color(0xFF1B3D5F))),
        ],
      ),
    );
  }

  // Di dalam file FormTukarPoinPage.dart

void _processRedemption() async {
  setState(() => isSubmitting = true);

  // MEMANGGIL API REAL
  bool success = await RedeemService.redeemReward(
    widget.data['id'], 
    jumlah
  );

  if (mounted) {
    setState(() => isSubmitting = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Penukaran Berhasil! Cek riwayat Anda."), backgroundColor: Colors.green),
      );
      // Kembali ke dashboard dan hapus semua stack halaman reward agar poin ter-refresh
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menukar. Poin tidak cukup atau stok habis."), backgroundColor: Colors.red),
      );
    }
  }
}
}