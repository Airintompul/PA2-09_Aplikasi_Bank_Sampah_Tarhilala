import 'package:flutter/material.dart';
import 'package:tarhilala_frontend/screens/user/widgets/top_navbar.dart';
import 'package:timeago/timeago.dart' as timeago;

class DetailBeritaPage extends StatelessWidget {
  final Map data;

  const DetailBeritaPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    List beritaTerkait = data['berita_terkait'] ?? [];

    String rawDate = data['created_at'] ?? data['tanggal'] ?? DateTime.now().toString();
    String waktuRelatifUtama = timeago.format(DateTime.parse(rawDate), locale: 'id');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopNavbar(),

            /// --- HEADER: TOMBOL BACK & SEARCH BAR RAPI ---
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 20, color: Colors.grey.shade400),
                          const SizedBox(width: 10),
                          Text(
                            "Cari berita...",
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // GAMBAR UTAMA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  "http://10.0.2.2:8000/storage/${data['gambar'] ?? data['thumbnail']}",
                  width: double.infinity,
                  height: 230,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 230,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // JUDUL BERITA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                data['judul'] ?? "Tanpa Judul",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // METADATA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Tarhilala News  •  $waktuRelatifUtama",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(thickness: 0.8, height: 35, color: Color(0xFFEEEEEE)),
            ),

            // ISI BERITA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                data['isi'] ?? "Tidak ada konten.",
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
            ),

            const SizedBox(height: 35),

            // BERITA TERKAIT SECTION
            if (beritaTerkait.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Berita Terkait",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              
              ...beritaTerkait.map((item) {
                String rawItemDate = item['created_at'] ?? item['tanggal'] ?? DateTime.now().toString();
                String waktuRelatifItem = timeago.format(DateTime.parse(rawItemDate), locale: 'id');

                return Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            "http://10.0.2.2:8000/storage/${item['gambar'] ?? item['thumbnail']}",
                            width: 80, height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              Container(width: 80, height: 80, color: Colors.grey[200]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['judul'] ?? "",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Tarhilala News  •  $waktuRelatifItem",
                                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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