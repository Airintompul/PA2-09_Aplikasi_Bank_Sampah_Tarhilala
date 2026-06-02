import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:tarhilala_frontend/screens/user/widgets/top_navbar.dart';
import '../../services/reward_service.dart';
import '../../services/redeem_service.dart';
import 'detail_reward_page.dart';

class RewardPage extends StatefulWidget {
  final bool showBackButton;
  const RewardPage({super.key, this.showBackButton = false});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> with SingleTickerProviderStateMixin {
  List rewards = [];
  List history = [];
  String userPoin = "0";
  bool loadingRewards = true;
  bool loadingPoin = true;
  bool loadingHistory = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await fetchUserPoin();
    await loadRewards();
    await loadHistory();
  }

  Future<void> fetchUserPoin() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final response = await http.get(
        Uri.parse("http://13.250.117.185/api/profile"),
        headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userPoin = (data['poin'] ?? 0).toString();
          loadingPoin = false;
        });
      }
    } catch (e) {
      setState(() => loadingPoin = false);
    }
  }

  Future<void> loadRewards() async {
    final data = await RewardService.getRewards();
    setState(() {
      rewards = data;
      loadingRewards = false;
    });
  }

  Future<void> loadHistory() async {
    setState(() => loadingHistory = true);
    final data = await RedeemService.getRiwayatRedeem();
    setState(() {
      history = data;
      loadingHistory = false;
    });
  }

  // --- LOGIC: KONFIRMASI TERIMA BARANG ---
  void _handleKonfirmasiTerima(int id) async {
    setState(() => loadingHistory = true);
    
    bool success = await RedeemService.confirmReceipt(id);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil! Hadiah telah diterima."), backgroundColor: Colors.green)
        );
        _initialLoad(); // Refresh semua data termasuk poin
      }
    } else {
      if (mounted) {
        setState(() => loadingHistory = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengonfirmasi."), backgroundColor: Colors.red)
        );
      }
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai': return Colors.green;
      case 'ditolak': return Colors.red;
      case 'dikirim': return Colors.indigo;
      case 'diproses': return Colors.blue;
      default: return Colors.orange;
    }
  }

  String getCleanImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    String cleaned = url.replaceAll("127.0.0.1", "10.0.2.2");
    if (!cleaned.startsWith("http")) cleaned = "http://13.250.117.185/storage/$cleaned";
    return cleaned.replaceAll(" ", "%20");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          const TopNavbar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _initialLoad,
              color: const Color(0xFF3B71CA),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    if (widget.showBackButton)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
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
                                child: const Icon(
                                  Icons.arrow_back_ios_new, 
                                  size: 18, 
                                  color: Colors.black87
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            const Text(
                              "Reward & Poin", // Judul halaman agar konsisten dengan Jual Sampah/Jadwal
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B3D5F),
                              ),
                            ),
                          ],
                        ),
                      ),

                    _buildPointsCard(),
                    const SizedBox(height: 25),
                    _buildTabBar(),
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      // Menggunakan tinggi dinamis berdasarkan konten agar bisa di-scroll di dalam RefreshIndicator
                      height: MediaQuery.of(context).size.height * 0.65, 
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRewardGrid(),
                          _buildHistoryList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B71CA), Color(0xFF54B4D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF3B71CA).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Poin Anda Saat Ini", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 30),
                  const SizedBox(width: 10),
                  Text(
                    userPoin,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const Opacity(
            opacity: 0.2,
            child: Icon(Icons.redeem_rounded, color: Colors.white, size: 60),
          )
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF3B71CA),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [Tab(text: "Tukar Reward"), Tab(text: "Riwayat")],
      ),
    );
  }

  Widget _buildRewardGrid() {
    if (loadingRewards) return const Center(child: CircularProgressIndicator());
    if (rewards.isEmpty) return const Center(child: Text("Tidak ada reward tersedia"));

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.65, 
      ),
      itemCount: rewards.length,
      itemBuilder: (context, index) => _buildRewardGridCard(rewards[index]),
    );
  }

  Widget _buildRewardGridCard(Map item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                getCleanImageUrl(item['gambar']),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: const Color(0xFFF0F4F8),
                  child: const Icon(Icons.redeem, color: Color(0xFF3B71CA), size: 40),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama_reward'] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3D5F)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "${item['poin_dibutuhkan']} Pts",
                      style: const TextStyle(color: Color(0xFF3B71CA), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailRewardPage(data: item)),
                    ).then((_) => _initialLoad()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B71CA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text("Tukar", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (loadingHistory) return const Center(child: CircularProgressIndicator());
    if (history.isEmpty) return const Center(child: Text("Belum ada riwayat penukaran"));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final reward = item['reward'];
        final status = item['status'].toString().toLowerCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      getCleanImageUrl(reward?['gambar']),
                      width: 55, height: 55, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.history, color: Colors.grey, size: 30),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reward?['nama_reward'] ?? "Reward", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B3D5F))),
                        const SizedBox(height: 2),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10, 
                            color: getStatusColor(status), 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "-${item['poin_digunakan']} Poin",
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text("Qty: ${item['jumlah'] ?? 1}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              
              // --- TOMBOL AKSI: MUNCUL JIKA STATUS DIKIRIM ---
              if (status == 'dikirim') ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Color(0xFFF1F3F4), thickness: 1),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleKonfirmasiTerima(item['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Konfirmasi Hadiah Diterima", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }
}