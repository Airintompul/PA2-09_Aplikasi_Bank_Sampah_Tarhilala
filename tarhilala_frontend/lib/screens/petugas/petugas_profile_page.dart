import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../user/widgets/top_navbar.dart';
import '../petugas/widgets/bottom_navbar.dart';
import '../user/change_email_page.dart';
import '../petugas/dashboard_page.dart';
import 'petugas_transaksi_page.dart';
import 'petugas_setoran_page.dart';
import 'petugas_rute_page.dart';

class PetugasProfilePage extends StatefulWidget {
  const PetugasProfilePage({super.key});

  @override
  State<PetugasProfilePage> createState() => _PetugasProfilePageState();
}

class _PetugasProfilePageState extends State<PetugasProfilePage> {
  String name = "";
  String email = "";
  String role = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? 'Nama tidak tersedia';
      email = prefs.getString('email') ?? 'Email tidak tersedia';
      role = prefs.getString('role') ?? 'Driver Lapangan';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          // 1. TOP NAVBAR
          const TopNavbar(),

          // 2. BODY CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // CARD INFORMASI USER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: Color(0xFF154C94),
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1B3D5F),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF154C94).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF154C94),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // MENU LIST
                  _buildMenuSection(),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),

      // 3. BOTTOM NAVBAR PETUGAS
      bottomNavigationBar: PetugasBottomNavbar(
        currentIndex: 3, // Index 3 adalah menu Akun
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PetugasDashboardPage()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PetugasTransaksiPage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PetugasSetoranPage()));
          } else if (index == 4) {
            // Logika pindah ke Rute/Map jika data listRute tersedia
          }
        },
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _menuItem(Icons.lock_reset_rounded, "Ubah Password", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangeEmailPage()),
            );
          }),
          _menuItem(Icons.logout_rounded, "Keluar", _showLogoutDialog, isLast: true),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: const Color(0xFF154C94)),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          onTap: onTap,
        ),
        if (!isLast)
          const Divider(height: 1, indent: 55, endIndent: 20, color: Color(0xFFF1F1F1)),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin keluar dari akun petugas?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}