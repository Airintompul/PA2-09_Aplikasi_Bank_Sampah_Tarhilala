import 'package:flutter/material.dart';

class PetugasBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PetugasBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90, // Tinggi total untuk menampung tonjolan tombol
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Background Navbar (Putih dengan Shadow)
          Container(
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, "Beranda", currentIndex == 0, 0),
                _navItem(Icons.assignment_rounded, "Transaksi", currentIndex == 1, 1),
                
                // Memberi ruang kosong di tengah agar tidak tertutup tombol Rute
                const SizedBox(width: 60), 
                
                _navItem(Icons.receipt_long_rounded, "Setoran", currentIndex == 2, 2),
                _navItem(Icons.person_rounded, "Akun", currentIndex == 3, 3),
              ],
            ),
          ),

          // 2. Tombol Rute yang Menonjol Keluar
          Positioned(
            top: 0, // Mengatur agar posisi menjorok ke atas
            child: GestureDetector(
              onTap: () => onTap(4), // Index 4 untuk Rute
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF154C94),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF154C94).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Rute",
                    style: TextStyle(
                      color: Color(0xFF154C94),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, int index) {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? const Color(0xFF154C94) : Colors.grey.shade400,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF154C94) : Colors.grey.shade400,
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}