import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/news_service.dart';
import 'widgets/bottom_navbar.dart';
import 'profile_page.dart';
import '../user/semua_sampah_page.dart';
import '../user/detail_sampah_page.dart';
import '../user/detail_berita_page.dart';
import '../user/semua_berita_page.dart';

class UserDashboardPage extends StatefulWidget {
  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  int currentIndex = 0;

  List hargaSampah = [];
  List berita = [];

  @override
  void initState() {
    super.initState();
    loadHargaSampah();
    loadBerita();
  }

  Future<void> loadHargaSampah() async {
    final data = await ProductService.getHargaSampah();

    setState(() {
      hargaSampah = data;
    });
  }

  Future<void> loadBerita() async {
    final data = await NewsService.getBerita();

    setState(() {
      berita = data;
    });
  }

  void logout(BuildContext context) async {
    await AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _getPage() {
    switch (currentIndex) {
      case 0:
        return _dashboardContent();
      case 1:
        return const Center(child: Text("Transaksi"));
      case 2:
        return const Center(child: Text("Jual"));
      case 3:
        return const Center(child: Text("Reward"));
      case 4:
        return const ProfilePage();
      default:
        return _dashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _getPage(),
      bottomNavigationBar: BottomNavbar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
        },
      ),
    );
  }

  Widget _dashboardContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 40),
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
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// BOX SALDO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blue.shade400,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// MENU GRID
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20,
              crossAxisSpacing: 15,
              childAspectRatio: 0.74,
              children: [

                menuItem(Icons.recycling, "Jual Sampah", Colors.blue),
                menuItem(Icons.local_shipping, "Jadwal\nPenjemputan", Colors.orange),
                menuItem(Icons.menu_book, "Panduan\nJual Sampah", Colors.green),
                menuItem(Icons.attach_money, "Harga\nSampah", Colors.blueAccent),

                menuItem(Icons.support_agent, "Bantuan", Colors.red),
                menuItem(Icons.receipt_long, "Transaksi", Colors.purple),
                menuItem(Icons.card_giftcard, "Reward", Colors.deepPurple),
                menuItem(Icons.monetization_on, "Poin", Colors.amber),

              ],
            ),
          ),

          const SizedBox(height: 25),

          /// HARGA SAMPAH
          sectionTitleHarga("Harga Sampah"),

          const SizedBox(height: 15),

          SizedBox(
            height: 180,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 20),
              scrollDirection: Axis.horizontal,
              itemCount: hargaSampah.length,
              itemBuilder: (context, index) {
                return hargaCard(hargaSampah[index]);
              },
            ),
          ),

          const SizedBox(height: 25),

          /// BERITA
          sectionTitleBerita("Berita Pilihan"),

          const SizedBox(height: 15),

          SizedBox(
            height: 200,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 20),
              scrollDirection: Axis.horizontal,
              itemCount: berita.length,
              itemBuilder: (context, index) {

                final item = berita[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailBeritaPage(data: item),
                      ),
                    );
                  },
                  child: Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          child: Image.network(
                            "http://10.0.2.2:8000/${item['thumbnail']}",
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            item['judul'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// TITLE HARGA SAMPAH
  Widget sectionTitleHarga(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SemuaSampahPage(),
                ),
              );
            },
            child: const Text(
              "Lihat Semua",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
              ),
            ),
          ),

        ],
      ),
    );
  }

  /// TITLE BERITA (SUDAH ADA LIHAT SEMUA)
  Widget sectionTitleBerita(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SemuaBeritaPage(),
                ),
              );
            },
            child: const Text(
              "Lihat Semua",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
              ),
            ),
          ),

        ],
      ),
    );
  }

  /// MENU ITEM
  Widget menuItem(IconData icon, String title, Color color) {
    return Column(
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 70,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// CARD HARGA SAMPAH
  Widget hargaCard(Map item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailSampahPage(data: item),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xff9fb6cc),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              width: 65,
              height: 65,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.network(
                  item['gambar'],
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.recycling, size: 40);
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              item['nama'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Rp ${item['harga_per_kg']}/Kg",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}