import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../user/widgets/top_navbar.dart';

class PetugasRutePage extends StatefulWidget {
  final List<dynamic> ruteData; // Data dari dashboard

  const PetugasRutePage({super.key, required this.ruteData});

  @override
  State<PetugasRutePage> createState() => _PetugasRutePageState();
}

class _PetugasRutePageState extends State<PetugasRutePage> {
  
  // Fungsi untuk buka Google Maps (Satu titik atau semua rute)
  Future<void> _openGoogleMaps(String query) async {
    final url = "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Column(
        children: [
          const TopNavbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // 1. HEADER TITLE CARD
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.reply, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Rute Pengambilan",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. SUMMARY STATS (Titik, Jarak, Selesai, Waktu)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem("5", "Titik"),
                        _buildSummaryItem("10 km", "Total Jarak"),
                        _buildSummaryItem("1/3", "Selesai"),
                        _buildSummaryItem("3", "Sisa Waktu"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. TOMBOL BUKA SEMUA RUTE
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () => _openGoogleMaps("Tempat Pembuangan Sampah Terdekat"),
                      icon: const Icon(Icons.location_on_outlined, color: Colors.white),
                      label: const Text(
                        "Buka Semua Rute di Google Maps",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A8F0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Daftar Titik Pengambilan",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // 4. TIMELINE LIST RUTE
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: widget.ruteData.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;
                        bool isLast = index == widget.ruteData.length - 1;

                        return _buildTimelineItem(item, isLast);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget: Summary Item
  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  // Widget: Timeline Item (Steppers)
  Widget _buildTimelineItem(dynamic item, bool isLast) {
    String status = item['status'] ?? 'menunggu';
    Color color = status == 'selesai' ? Colors.green : (status == 'diproses' ? const Color(0xFF8B6B8E) : Colors.grey);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kolom Garis Timeline
        Column(
          children: [
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(width: 2, height: status == 'diproses' ? 140 : 80, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 15),
        
        // Kolom Konten
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['alamat'] ?? "Alamat",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              Text(
                "${item['nama']}. ${item['ket']} . 07:30",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                "-6.192, 108.8667", // Simulasi Koordinat
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              
              const SizedBox(height: 10),

              // Tombol khusus untuk status tertentu
              if (status == 'selesai')
                _buildSmallMapsButton(item['alamat']),
              
              if (status == 'diproses')
                _buildLargeNavButton(item['alamat']),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    String label = "Menunggu";
    Color bgColor = Colors.grey.shade100;
    Color txtColor = Colors.grey;

    if (status == 'selesai') {
      label = "Selesai";
      bgColor = const Color(0xFFE8F5E9);
      txtColor = Colors.green;
    } else if (status == 'diproses') {
      label = "Berikutnya";
      bgColor = const Color(0xFFFFF9C4);
      txtColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildSmallMapsButton(String alamat) {
    return OutlinedButton.icon(
      onPressed: () => _openGoogleMaps(alamat),
      icon: const Icon(Icons.location_on, size: 14, color: Color(0xFF154C94)),
      label: const Text("Buka Maps", style: TextStyle(fontSize: 10, color: Color(0xFF154C94))),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: const BorderSide(color: Color(0xFF154C94)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }

  Widget _buildLargeNavButton(String alamat) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _openGoogleMaps(alamat),
        icon: const Icon(Icons.person_pin_circle_outlined, color: Colors.white),
        label: const Text("Navigasi ke sini sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF34A8F0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}