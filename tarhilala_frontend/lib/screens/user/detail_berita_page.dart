import 'package:flutter/material.dart';

class DetailBeritaPage extends StatelessWidget {
  final Map data;

  const DetailBeritaPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Mengambil daftar berita terkait dari data jika ada, jika tidak ada pakai list kosong
    List beritaTerkait = data['berita_terkait'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --- HEADER SESUAI KODE ANDA ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 350,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                      ),
                      Positioned(
                        top: -20,
                        child: Image.asset(
                          "assets/images/logo_tarhilala.png",
                          height: 130,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  /// BAR BERITA PILIHAN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.undo, color: Color(0xFF154C8C), size: 20),
                          SizedBox(width: 10),
                          Text(
                            "Berita Pilihan",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.search, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// GAMBAR UTAMA DINAMIS
            Image.network(
              "http://10.0.2.2:8000/${data['thumbnail']}",
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 20),

            /// JUDUL DINAMIS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                data['judul'] ?? "",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// METADATA DINAMIS (Contoh: Penulis & Tanggal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    data['penulis'] ?? "Tarhilala News",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Text("  .  "),
                  Text(
                    data['tanggal'] ?? "Baru saja",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(thickness: 1, height: 30),
            ),

            /// ISI BERITA DINAMIS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                data['isi'] ?? "",
                textAlign: TextAlign.justify,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// BAGIAN BERITA TERKAIT (Dinamis dari List)
            if (beritaTerkait.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Berita Terkait",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              
              // Looping berita lainnya
              ...beritaTerkait.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            "http://10.0.2.2:8000/${item['thumbnail']}",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              Container(width: 80, height: 80, color: Colors.grey[300]),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['kategori'] ?? "Berita",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['judul'] ?? "",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${item['penulis'] ?? 'Admin'} . ${item['tanggal'] ?? ''}",
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}