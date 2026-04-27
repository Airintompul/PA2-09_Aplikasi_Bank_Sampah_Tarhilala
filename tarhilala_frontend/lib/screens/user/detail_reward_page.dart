import 'package:flutter/material.dart';
import '../user/widgets/top_navbar.dart';
import '../user/widgets/bottom_navbar.dart';
import 'form_tukar_poin_page.dart';

class DetailRewardPage extends StatelessWidget {
  final Map data;

  const DetailRewardPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          /// 1. TOP NAVBAR (Tarhila Ledger Header)
          const TopNavbar(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),

                  /// 2. TOMBOL KEMBALI & JUDUL HALAMAN
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
                        "Detail Reward",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B3D5F),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// 3. KARTU POIN BIRU (Sesuai desain dashboard/reward)
                  _buildBluePointsCard(),

                  const SizedBox(height: 25),

                  /// 4. KARTU DETAIL REWARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // GAMBAR REWARD MENGGUNAKAN CLIPRRECT
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              Uri.encodeFull("http://10.0.2.2:8000/${data['gambar']}"),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.redeem_rounded, size: 50, color: Color(0xFF3B71CA));
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // NAMA REWARD
                        Text(
                          data['nama_reward'] ?? 'Nama Reward',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B3D5F),
                          ),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Color(0xFFF0F4F8), thickness: 2),
                        ),
                        
                        // INFORMASI POIN & STOK
                        _infoRow("Poin Dibutuhkan", "${data['poin_dibutuhkan']} Poin"),
                        _infoRow("Stok Tersedia", "${data['stok'] ?? 0} unit"),
                        _infoRow("Status Poin", "Tersedia", isBlue: true),
                        
                        const SizedBox(height: 25),
                        
                        const Text(
                          "Gunakan poin yang telah Anda kumpulkan untuk menukarkan reward menarik ini.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // TOMBOL TUKAR
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FormTukarPoinPage(data: data),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E56A0),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Tukar Sekarang", 
                              style: TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                              )
                            ),
                          ),
                        )
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

  /// Widget Kartu Poin Biru (Konsisten dengan FormTukarPoinPage)
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
                "Total Poin Anda",
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

  /// Widget Baris Informasi
  Widget _infoRow(String label, String value, {bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: const TextStyle(color: Colors.grey, fontSize: 14)
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isBlue ? const Color(0xFF3B71CA) : const Color(0xFF1B3D5F),
            ),
          ),
        ],
      ),
    );
  }
}