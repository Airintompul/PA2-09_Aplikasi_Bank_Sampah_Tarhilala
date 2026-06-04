import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/setoran_model.dart';
import '../../services/pickup_service.dart';
import '../user/widgets/top_navbar.dart';
import '../petugas/widgets/bottom_navbar.dart'; 
import 'petugas_rute_page.dart';
import 'petugas_setoran_page.dart'; 
import 'petugas_profile_page.dart'; 
import '../petugas/dashboard_page.dart';

Route _slideRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      final slide = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      final fade = Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
    },
  );
}

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
      setState(() => selectedDate = picked);
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          const TopNavbar(),
          _buildSummaryHeader(),
          const SizedBox(height: 12),
          _buildFilterBar(),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF154C94)))
                : filteredList.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
          ),
        ],
      ),
      bottomNavigationBar: PetugasBottomNavbar(
        currentIndex: 1, 
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, _slideRoute(const PetugasDashboardPage()));
          } else if (index == 2) {
            Navigator.push(context, _slideRoute(PetugasRutePage(ruteData: riwayatSelesai)));
          } else if (index == 3) {
            Navigator.pushReplacement(context, _slideRoute(const PetugasSetoranPage()));
          } else if (index == 4) {
            Navigator.pushReplacement(context, _slideRoute(const PetugasProfilePage()));
          }
        },
      ),
    );
  }

  Widget _buildSummaryHeader() {
    double totalKg = filteredList.fold(0, (sum, item) => sum + (item.totalBerat ?? 0));
    double totalRp = filteredList.fold(0, (sum, item) => sum + (item.totalHarga ?? 0));

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF154C94), Color(0xFF1E6BC6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF154C94).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Total Berat", "${totalKg.toStringAsFixed(1)} Kg"),
          Container(width: 1, height: 36, color: Colors.white24),
          _statItem("Total Nilai", NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalRp)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
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
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Cari nasabah...",
                hintStyle: const TextStyle(color: Color(0xFFAABBCC), fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF8FA3B8)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selectedDate != null ? const Color(0xFF154C94) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Icon(Icons.calendar_month, color: selectedDate != null ? Colors.white : const Color(0xFF8FA3B8), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0xFF154C94).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nasabahNama, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0D2744))),
                    const SizedBox(height: 2),
                    Text(item.tanggalPengajuan, style: const TextStyle(color: Color(0xFFAABBCC), fontSize: 10)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${item.totalBerat?.toStringAsFixed(1) ?? '0.0'} Kg",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF154C94)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item.totalHarga ?? 0),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8FA3B8)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text("Data tidak ditemukan", style: TextStyle(color: Color(0xFF8FA3B8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}