import 'package:flutter/material.dart';

class TopNavbar extends StatelessWidget {
  const TopNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        // Menambahkan sedikit bayangan agar lebih terlihat seperti navbar
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Memisahkan grup kiri dan kanan
        children: [
          // Grup Kiri: Logo dan Judul
          Row(
            children: [
              // Ikon Daun / Logo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.eco, 
                  color: Color(0xFF1B3D5F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Teks Judul
              const Text(
                "BANK SAMPAH TARHILALA",
                style: TextStyle(
                  fontSize: 16, // Ukuran sedikit diperkecil agar tidak overflow dengan notifikasi
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3D5F),
                ),
              ),
            ],
          ),

          // Grup Kanan: Ikon Notifikasi
          const Icon(
            Icons.notifications_none_rounded, // Menggunakan icon lonceng
            color: Color(0xFF1B3D5F),
            size: 28,
          ),
        ],
      ),
    );
  }
}