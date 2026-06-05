import 'package:flutter/material.dart';
import 'package:tarhilala_frontend/screens/user/widgets/top_navbar.dart';
import 'package:timeago/timeago.dart' as timeago;

class DetailBeritaPage extends StatelessWidget {
  final Map data;

  const DetailBeritaPage({super.key, required this.data});

  // --- LOGIC HELPER URL GAMBAR (KONSISTEN DENGAN DASHBOARD) ---
  String getImageUrl(dynamic item) {
    String path = item is Map ? (item['thumbnail'] ?? item['gambar'] ?? '') : '';
    if (path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    // Gabungkan dengan IP server (Menyesuaikan folder assets Laravel)
    return "http://10.0.2.2:8000/$path";
  }

  @override
  Widget build(BuildContext context) {
    List beritaTerkait = data['berita_terkait'] ?? [];

    String rawDate = data['created_at'] ?? data['tanggal'] ?? DateTime.now().toString();
    String waktuRelatifUtama = "Baru saja";
    try {
      waktuRelatifUtama = timeago.format(DateTime.parse(rawDate), locale: 'id');
    } catch (e) {
      waktuRelatifUtama = "Baru saja";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopNavbar(),

            /// --- HEADER: TOMBOL BACK ---
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
                  const Text(
                    "Detail Berita",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3D5F),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // GAMBAR UTAMA BERITA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  getImageUrl(data), // MENGGUNAKAN HELPER URL
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 250,
                      color: Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // JUDUL BERITA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                data['judul'] ?? "Tanpa Judul",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: Color(0xFF1B3D5F),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // METADATA (Author & Waktu)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B71CA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Official News",
                      style: TextStyle(color: Color(0xFF3B71CA), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "•  $waktuRelatifUtama",
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(thickness: 1, height: 40, color: Color(0xFFF1F1F1)),
            ),

            // ISI KONTEN BERITA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                data['isi'] ?? "Tidak ada konten tersedia.",
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  color: Color(0xFF444444),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // SECTION BERITA TERKAIT
            if (beritaTerkait.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Berita Lainnya",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F)),
                ),
              ),
              const SizedBox(height: 15),
              
              ...beritaTerkait.map((item) {
                String rawItemDate = item['created_at'] ?? DateTime.now().toString();
                String waktuItem = timeago.format(DateTime.parse(rawItemDate), locale: 'id');

                return Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            getImageUrl(item), // MENGGUNAKAN HELPER URL
                            width: 80, height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              Container(width: 80, height: 80, color: Colors.grey[200]),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['judul'] ?? "",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3D5F)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Tarhilala News  •  $waktuItem",
                                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}