import 'package:flutter/material.dart';
import 'package:tarhilala_frontend/screens/user/widgets/top_navbar.dart';
import '../user/widgets/bottom_navbar.dart';

class FormTukarPoinPage extends StatefulWidget {
  final Map data;
  const FormTukarPoinPage({super.key, required this.data});

  @override
  State<FormTukarPoinPage> createState() => _FormTukarPoinPageState();
}

class _FormTukarPoinPageState extends State<FormTukarPoinPage> {
  int jumlah = 1;
  bool isAgreed = false;

  @override
  Widget build(BuildContext context) {
    int poinSatuan = int.parse(widget.data['poin_dibutuhkan'].toString());
    int totalPoin = jumlah * poinSatuan;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          /// 1. TOP NAVBAR (Header Tarhila Ledger sesuai gambar 2 & 3)
          const TopNavbar(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),

                  /// 2. TOMBOL KEMBALI & JUDUL (Sesuai gambar 1)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Color(0xFF1B3D5F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        "Penukaran Poin", // Judul disesuaikan dengan gambar 1
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B3D5F),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// 3. KARTU POIN BIRU (Sesuai gambar 4)
                  _buildBluePointsCard(),

                  const SizedBox(height: 25),

                  /// 4. KARTU FORM PENUKARAN
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // INFO ITEM REWARD
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                width: 80,
                                height: 80,
                                color: const Color(0xFFF0F4F8),
                                child: Image.network(
                                  Uri.encodeFull("http://10.0.2.2:8000/${widget.data['gambar']}"),
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
                                  Text(
                                    widget.data['nama_reward'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3D5F)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${widget.data['poin_dibutuhkan']} Poin / item",
                                    style: const TextStyle(color: Color(0xFF3B71CA), fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    "Stok: ${widget.data['stok']}",
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Color(0xFFF0F4F8), thickness: 2),
                        ),

                        // INPUT JUMLAH
                        const Text(
                          "Jumlah Penukaran",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F)),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => setState(() => jumlah > 1 ? jumlah-- : null),
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              ),
                              Text(
                                "$jumlah",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                onPressed: () => setState(() => jumlah++),
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // RINGKASAN POIN
                        _summaryRow("Total Poin dibutuhkan", "$totalPoin Poin", isPrimary: true),
                        _summaryRow("Poin Anda Saat Ini", "1,200 Poin"),

                        const SizedBox(height: 20),

                        // SYARAT & KETENTUAN
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: isAgreed,
                                activeColor: const Color(0xFF1E56A0),
                                onChanged: (val) => setState(() => isAgreed = val!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Saya setuju dengan syarat & ketentuan yang berlaku",
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // TOMBOL KONFIRMASI
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isAgreed ? () => _processRedemption() : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E56A0),
                              disabledBackgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Konfirmasi Penukaran",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
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
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }

  /// Header Aplikasi (Referesi Gambar 2 & 3)
  Widget _buildTopAppHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco, color: Color(0xFF1B3D5F)), // Ikon daun logo
          const SizedBox(width: 10),
          const Text(
            "Tarhila Ledger",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B3D5F),
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_none, color: Colors.grey),
          const SizedBox(width: 15),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Avatar user
          ),
        ],
      ),
    );
  }

  /// Kartu Poin Biru (Referensi Gambar 4)
  Widget _buildBluePointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Poin Anda Saat Ini",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.stars, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "1,200",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Ikon History (Gambar 4 kanan)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history, color: Colors.white, size: 24),
          ),
        ],
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
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPrimary ? const Color(0xFF1E56A0) : const Color(0xFF1B3D5F),
            ),
          ),
        ],
      ),
    );
  }

  void _processRedemption() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Permintaan penukaran reward berhasil dikirim!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }
}