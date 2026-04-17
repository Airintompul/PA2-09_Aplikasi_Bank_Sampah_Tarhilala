import 'package:flutter/material.dart';
import '../../services/news_service.dart';
import 'detail_berita_page.dart';

class SemuaBeritaPage extends StatefulWidget {
  const SemuaBeritaPage({super.key});

  @override
  State<SemuaBeritaPage> createState() => _SemuaBeritaPageState();
}

class _SemuaBeritaPageState extends State<SemuaBeritaPage> {

  List berita = [];

  @override
  void initState() {
    super.initState();
    loadBerita();
  }

  Future loadBerita() async {
    final data = await NewsService.getBerita();

    setState(() {
      berita = data;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Semua Berita"),
      ),

      body: ListView.builder(
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
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                  )
                ],
              ),
              child: Row(
                children: [

                  /// GAMBAR
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(15),
                    ),
                    child: Image.network(
                      "http://10.0.2.2:8000/${item['thumbnail']}",
                      width: 110,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// JUDUL
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        item['judul'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}