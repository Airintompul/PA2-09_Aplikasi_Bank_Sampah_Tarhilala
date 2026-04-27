import 'package:flutter/material.dart';
import '../user/widgets/top_navbar.dart';

class PanduanJualSampahPage extends StatelessWidget {
  const PanduanJualSampahPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      body: Column(
        children: [
          const TopNavbar(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildInfoBanner(),
                    const SizedBox(height: 32),
                    _buildRestrictedSection(),
                    const SizedBox(height: 40),
                    _buildPackagingGuide(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Center(
          child: Text(
            "Panduan Jual Sampah",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B3D5F),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Positioned(
          left: 0,
          child: GestureDetector(
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
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Color(0xFF1B3D5F),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F0FF), Color(0xFFF0F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            "assets/images/driver.png",
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            "Sebelum mulai mengumpulkan sampah untuk dijual, yuk kenali jenis-jenis sampah yang belum diterima oleh tarhilala untuk saat ini:",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF1B3D5F),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedSection() {
    final List<Map<String, String>> restrictedItems = [
      {"image": "assets/images/sisa_makanan.png", "label": "Sisa Makanan"},
      {"image": "assets/images/sampah_medis.png", "label": "Sampah Medis"},
      {"image": "assets/images/obat_obatan.jpg", "label": "Obat - Obatan"},
      {"image": "assets/images/pampres_bekas.jpeg", "label": "Pampres Bekas"},
      {"image": "assets/images/kayu.jpg", "label": "Kayu"},
      {"image": "assets/images/kain_bekas.jpeg", "label": "Baju Bekas"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Sampah yang belum bisa dijual di Tarhilala",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF1B3D5F),
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: restrictedItems.length,
          itemBuilder: (context, index) {
            return _buildRestrictedCard(
              restrictedItems[index]["image"]!,
              restrictedItems[index]["label"]!,
            );
          },
        ),
      ],
    );
  }

  Widget _buildRestrictedCard(String imagePath, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              imagePath,
              height: 48,
              width: 48,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagingGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Petunjuk Pengemasan Sampah :",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF1B3D5F),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 24),
        
        // Step 1
        _buildStepItem(
          number: "1",
          imagePath: "assets/images/1.png",
          description: "Pastikan semua sampah yang ingin dipacking merupakan sampah yang bernilai ekonomis atau yang diterima oleh Tarhilala",
          showLine: true,
        ),
        
        // Step 2
        _buildStepItem(
          number: "2",
          imagePath: "assets/images/2.png",
          description: "Pisahkan semua sampah sesuai dengan klasifikasi jenisnya (bedakan antara kardus, plastik, kertas, kaleng, botol dll).",
          showLine: true,
        ),
        
        // Step 3
        _buildStepItem(
          number: "3",
          imagePath: "assets/images/3.png",
          description: "Bersihkan sampah dan pastikan sampah kering. Lipat dan rapikan jenis sampah kertas atau kardus. Lepas stiker dan tutup botol pada gelas plastik. Untuk jelantah, saring dan pastikan tidak ada sisa penggorengan",
          showLine: true,
        ),
        
        // Step 4
        _buildStepItem(
          number: "4",
          imagePath: "assets/images/4.png",
          description: "Satukan sampah sesuai klasifikasinya dengan cara diikat tali atau dimasukkan ke dalam karung atau trashbag yang dimiliki.",
          showLine: false,
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required String number,
    required String imagePath,
    required String description,
    required bool showLine,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian nomor + garis
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3D5F),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B3D5F).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (showLine) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 2,
                    height: 80,
                    color: const Color(0xFF1B3D5F).withOpacity(0.15),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Gambar ilustrasi
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              color: const Color(0xFFF2F6FC),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Deskripsi
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF2C3E50),
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
