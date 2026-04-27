import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../user/widgets/top_navbar.dart';
import '../user/widgets/bottom_navbar.dart';
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
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await ProductService.getHargaSampah();
    setState(() {
      data = result;
      filteredData = result;
      final uniqueCategories = data.map((item) => item['kategori'].toString()).toSet().toList();
      categories = ["Semua", ...uniqueCategories];
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
      backgroundColor: const Color(0xFFF8F9FA), // Background abu-abu sangat muda
      body: Column(
        children: [
          const TopNavbar(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  
                  // Header dengan Tombol Back yang Lebih Rapi
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        "Daftar Sampah",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1E)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Search Bar Modern
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
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF1E56A0)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 25),

                  // Kategori Horizontal
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
                                  width: 1,
                                ),
                                boxShadow: isActive 
                                  ? [BoxShadow(color: const Color(0xFF1E56A0).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                  : null,
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

                  // Grid Produk
                  filteredData.isEmpty 
                  ? Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text("Sampah tidak ditemukan", style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 20),
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
      bottomNavigationBar: BottomNavbar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else {
            setState(() => currentIndex = index);
          }
        },
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
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['kategori'],
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
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