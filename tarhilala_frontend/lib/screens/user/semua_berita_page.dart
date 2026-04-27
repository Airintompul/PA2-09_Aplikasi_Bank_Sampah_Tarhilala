import 'package:flutter/material.dart';
import 'package:tarhilala_frontend/screens/user/widgets/top_navbar.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/news_service.dart';
import 'detail_berita_page.dart';

class SemuaBeritaPage extends StatefulWidget {
  const SemuaBeritaPage({super.key});

  @override
  State<SemuaBeritaPage> createState() => _SemuaBeritaPageState();
}

class _SemuaBeritaPageState extends State<SemuaBeritaPage> {
  List beritaAll = []; 
  List beritaFiltered = []; 
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadBerita();
  }

  Future loadBerita() async {
    final data = await NewsService.getBerita();
    setState(() {
      beritaAll = data;
      beritaFiltered = data;
      isLoading = false;
    });
  }

  void _filterBerita(String query) {
    setState(() {
      if (query.isEmpty) {
        beritaFiltered = beritaAll;
      } else {
        beritaFiltered = beritaAll
            .where((item) => item['judul']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unggulan = (_searchController.text.isEmpty && beritaFiltered.isNotEmpty) 
        ? beritaFiltered[0] 
        : null;
    
    final listTampil = (unggulan != null) 
        ? beritaFiltered.sublist(1) 
        : beritaFiltered;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF154C8C)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TopNavbar(),

                  /// --- HEADER: TOMBOL BACK & JUDUL ---
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
                        const SizedBox(width: 15),
                        const Text(
                          "Berita Pilihan",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// --- SEARCH BAR RAPI ---
                  _buildSearchBarSection(),

                  const SizedBox(height: 10),

                  /// --- BERITA UNGGULAN ---
                  if (unggulan != null) ...[
                    _buildBeritaUnggulan(unggulan),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
                      child: Text(
                        "Berita Terbaru",
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1D1E)
                        ),
                      ),
                    ),
                  ],

                  /// --- LIST BERITA ---
                  if (beritaFiltered.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50.0),
                        child: Text("Berita tidak ditemukan"),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: listTampil.length,
                      itemBuilder: (context, index) {
                        return _buildBeritaTerbaruItem(listTampil[index]);
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBarSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
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
        child: TextField(
          controller: _searchController,
          onChanged: _filterBerita,
          decoration: InputDecoration(
            hintText: "Cari berita...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF154C8C), size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildBeritaUnggulan(Map item) {
    String rawDate = item['created_at'] ?? item['tanggal'] ?? DateTime.now().toString();
    String rilis = timeago.format(DateTime.parse(rawDate), locale: 'id');

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailBeritaPage(data: item))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFB8CCE4).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    "http://10.0.2.2:8000/storage/${item['gambar'] ?? item['thumbnail']}",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 200, color: const Color(0xFF154C8C)),
                  ),
                ),
                Positioned(
                  top: 15, left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF154C8C), 
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: const Text(
                      "Unggulan", 
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                    ),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bank Sampah Tarhilala", 
                    style: TextStyle(color: Color(0xFF154C8C), fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['judul'] ?? '', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, height: 1.3)
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Tarhilala News  •  $rilis", 
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBeritaTerbaruItem(Map item) {
    String rawDate = item['created_at'] ?? item['tanggal'] ?? DateTime.now().toString();
    String rilis = timeago.format(DateTime.parse(rawDate), locale: 'id');

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailBeritaPage(data: item))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                "http://10.0.2.2:8000/storage/${item['gambar'] ?? item['thumbnail']}",
                width: 95, height: 95,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 95, height: 95, color: Colors.grey.shade100),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bank Sampah Tarhilala", 
                    style: TextStyle(color: Color(0xFF154C8C), fontSize: 11, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['judul'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Tarhilala News  •  $rilis", 
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}