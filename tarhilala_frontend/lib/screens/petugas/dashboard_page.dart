import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class PetugasDashboardPage extends StatefulWidget {
  @override
  State<PetugasDashboardPage> createState() => _PetugasDashboardPageState();
}

class _PetugasDashboardPageState extends State<PetugasDashboardPage> {

  String nama = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      nama = prefs.getString("name") ?? "";
    });
  }

  // ===============================
  // LOGOUT
  // ===============================
  void logout() async {

    await AuthService.logout();

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
      (route) => false,
    );

  }

  Widget menuItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0,4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(
              icon,
              size: 40,
              color: Color(0xFF1F4F8C),
            ),

            SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Color(0xFFF2F4F7),

      appBar: AppBar(
        title: Text("Dashboard Petugas"),
        backgroundColor: Color(0xFF1F4F8C),
        actions: [

          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Logout"),
                    content: Text("Apakah anda yakin ingin logout?"),
                    actions: [

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Batal"),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          logout();
                        },
                        child: Text("Logout"),
                      )

                    ],
                  );
                },
              );

            },
          )

        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Selamat Datang,",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),

            SizedBox(height: 4),

            Text(
              nama,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 25),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,

                children: [

                  menuItem(
                    Icons.delete_outline,
                    "Data Sampah",
                    () {
                      Navigator.pushNamed(context, "/sampah");
                    },
                  ),

                  menuItem(
                    Icons.receipt_long,
                    "Transaksi",
                    () {
                      Navigator.pushNamed(context, "/transaksi");
                    },
                  ),

                  menuItem(
                    Icons.article_outlined,
                    "Berita",
                    () {
                      Navigator.pushNamed(context, "/berita");
                    },
                  ),

                  menuItem(
                    Icons.person_outline,
                    "Profil",
                    () {
                      Navigator.pushNamed(context, "/profile");
                    },
                  ),

                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}