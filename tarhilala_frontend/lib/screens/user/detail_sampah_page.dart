import 'package:flutter/material.dart';
import '../user/widgets/top_navbar.dart';
import 'jual_sampah_page.dart'; 

class DetailSampahPage extends StatefulWidget {
  final Map data;
  const DetailSampahPage({super.key, required this.data});

  @override
  State<DetailSampahPage> createState() => _DetailSampahPageState();
}

class _DetailSampahPageState extends State<DetailSampahPage> {
  // Logic Bottom Navbar dihapus dari sini

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // bottomNavigationBar dihapus agar tampilan lebih bersih
      body: Column(
        children: [
          const TopNavbar(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  
                  // Tombol Kembali & Judul
                  Row(
                    children: [
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
                          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        "Detail Sampah",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 25),

                  // Container Gambar
                  Container(
                    height: 250,
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Hero(
                      tag: 'sampah_${widget.data['id']}',
                      child: Image.network(
                        widget.data['gambar'], 
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Info Section (Nama & Harga)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.data['nama'],
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E56A0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.data['kategori'] ?? 'Kategori',
                                style: const TextStyle(
                                  color: Color(0xFF1E56A0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Harga Estimasi", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            "Rp ${widget.data['harga_per_kg']}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E56A0),
                            ),
                          ),
                          const Text("/Kg", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 25),
                    child: Divider(color: Colors.black12, thickness: 1),
                  ),

                  // Deskripsi
                  const Text(
                    "Tentang Sampah Ini",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.data['deskripsi'] ?? "Informasi mengenai sampah ini belum tersedia secara detail. Pastikan sampah dalam kondisi bersih sebelum disetorkan.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // --- ACTION BUTTON: JUAL SEKARANG ---
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigasi ke halaman Jual Sampah
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const JualSampahPage(showBackButton: true,)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E56A0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 5,
                        shadowColor: const Color(0xFF1E56A0).withOpacity(0.3),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_checkout_rounded, size: 20),
                          SizedBox(width: 10),
                          Text(
                            "Jual Sampah Ini Sekarang",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}