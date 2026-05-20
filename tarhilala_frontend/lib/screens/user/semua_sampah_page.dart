import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../user/widgets/top_navbar.dart';
import 'detail_sampah_page.dart';

class SemuaSampahPage extends StatefulWidget {
  const SemuaSampahPage({super.key});

  @override
  State<SemuaSampahPage> createState() => _SemuaSampahPageState();
}

class _SemuaSampahPageState extends State<SemuaSampahPage> {
  List data = [];
  List filteredData = [];
  List<String> categories = ["Semua"];
  String selectedCategory = "Semua";
  String searchQuery = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => isLoading = true);
    final result = await ProductService.getHargaSampah();
    setState(() {
      data = result;
      filteredData = result;
      final uniqueCategories = data.map((item) => item['kategori'].toString()).toSet().toList();
      categories = ["Semua", ...uniqueCategories];
      isLoading = false;
    });
  }

  void _filterData() {
    setState(() {
      filteredData = data.where((item) {
        final matchesCategory = selectedCategory == "Semua" || item['kategori'] == selectedCategory;
        final matchesSearch = item['nama'].toString().toLowerCase().contains(searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          const TopNavbar(),
          
          /// --- HEADER: TOMBOL BACK & JUDUL (KONSISTEN) ---
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
                  "Daftar Sampah",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E56A0)))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      
                      // SEARCH BAR
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) {
                            searchQuery = value;
                            _filterData();
                          },
                          decoration: InputDecoration(
                            hintText: "Cari jenis sampah...",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF1E56A0), size: 22),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 25),

                      // KATEGORI HORIZONTAL
                      SizedBox(
                        height: 42,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            bool isActive = selectedCategory == categories[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCategory = categories[index];
                                    _filterData();
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isActive ? const Color(0xFF1E56A0) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isActive ? const Color(0xFF1E56A0) : Colors.black12,
                                    ),
                                  ),
                                  child: Text(
                                    categories[index],
                                    style: TextStyle(
                                      color: isActive ? Colors.white : Colors.black87,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 25),

                      // GRID DAFTAR SAMPAH
                      filteredData.isEmpty 
                      ? Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 50),
                              Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              const Text("Sampah tidak ditemukan", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 30),
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredData.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (context, index) {
                            return _buildProductCard(filteredData[index]);
                          },
                        ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailSampahPage(data: item)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Image.network(
                  item['gambar'], 
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nama'], 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1D1E)), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rp ${item['harga_per_kg']}",
                        style: const TextStyle(color: Color(0xFF1E56A0), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        "/Kg",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                      ),
                    ],
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