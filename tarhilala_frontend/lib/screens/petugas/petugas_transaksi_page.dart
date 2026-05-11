import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/setoran_model.dart';
import '../../services/pickup_service.dart';
import '../user/widgets/top_navbar.dart';
import '../petugas/widgets/bottom_navbar.dart'; 
import 'petugas_rute_page.dart';
import 'petugas_setoran_page.dart'; 
import '../petugas/widgets/bottom_navbar.dart';
import 'petugas_profile_page.dart'; 
import '../petugas/dashboard_page.dart';

class PetugasTransaksiPage extends StatefulWidget {
  const PetugasTransaksiPage({super.key});

  @override
  State<PetugasTransaksiPage> createState() => _PetugasTransaksiPageState();
}

class _PetugasTransaksiPageState extends State<PetugasTransaksiPage> {
  final PickupService _pickupService = PickupService();
  List<SetoranModel> riwayatSelesai = [];
  List<SetoranModel> filteredList = [];
  bool isLoading = true;
  
  DateTime? selectedDate;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  Future<void> fetchRiwayat() async {
    setState(() => isLoading = true);
    try {
      final data = await _pickupService.getSetoranRequests();
      setState(() {
        riwayatSelesai = data.where((s) => s.status == 'selesai').toList();
        riwayatSelesai.sort((a, b) => b.tanggalPengajuan.compareTo(a.tanggalPengajuan));
        filteredList = riwayatSelesai;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      filteredList = riwayatSelesai.where((item) {
        bool matchName = item.nasabahNama.toLowerCase().contains(searchQuery.toLowerCase());
        bool matchDate = true;
        
        if (selectedDate != null) {
          String dateDb = item.tanggalPengajuan.split(" ")[0];
          String dateFilter = DateFormat('yyyy-MM-dd').format(selectedDate!);
          matchDate = dateDb == dateFilter;
        }
        
        return matchName && matchDate;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          const TopNavbar(),
          _buildSummaryHeader(),
          _buildFilterBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? const Center(child: Text("Data tidak ditemukan"))
                    : _buildList(),
          ),
        ],
      ),

      // --- BOTTOM NAVBAR PETUGAS ---
      bottomNavigationBar: PetugasBottomNavbar(
        currentIndex: 1, 
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PetugasDashboardPage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PetugasSetoranPage()));
          } else if (index == 3) {
            // NAVIGASI KE AKUN (DITAMBAHKAN)
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PetugasProfilePage()));
          } else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PetugasRutePage(ruteData: riwayatSelesai)));
          }
        },
      ),
    );
  }

  Widget _buildSummaryHeader() {
    double totalKg = filteredList.fold(0, (sum, item) => sum + (item.totalBerat ?? 0));
    double totalRp = filteredList.fold(0, (sum, item) => sum + (item.totalHarga ?? 0));

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF154C94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Total Berat", "${totalKg.toStringAsFixed(1)} Kg"),
          _statItem("Total Nilai", NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalRp)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) {
                searchQuery = val;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: "Cari nasabah...",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selectedDate != null ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_month, color: selectedDate != null ? Colors.white : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nasabahNama, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(item.tanggalPengajuan, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${item.totalBerat?.toStringAsFixed(1) ?? '0.0'} Kg", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF154C94))),
                  Text(
                    NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item.totalHarga ?? 0),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}