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
      height: 90,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Background Navbar
          Container(
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, "Beranda", currentIndex == 0, 0),
                _navItem(Icons.assignment_rounded, "Transaksi", currentIndex == 1, 1),
                const SizedBox(width: 60),
                _navItem(Icons.receipt_long_rounded, "Setoran", currentIndex == 3, 3),
                _navItem(Icons.person_rounded, "Akun", currentIndex == 4, 4),
              ],
            ),
          ),

          // 2. Tombol Rute yang Menonjol
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E6BC6), Color(0xFF154C94)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF154C94).withOpacity(0.40),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 3.5),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Rute",
                    style: TextStyle(
                      color: Color(0xFF154C94),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: active ? 44 : 36,
              height: active ? 32 : 28,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF154C94).withOpacity(0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: active ? const Color(0xFF154C94) : Colors.grey.shade400,
                size: active ? 22 : 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: TextStyle(
                color: active ? const Color(0xFF154C94) : Colors.grey.shade400,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}