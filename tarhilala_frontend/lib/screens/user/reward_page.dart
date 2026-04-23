import 'package:flutter/material.dart';
import 'package:tarhilala_frontend/screens/user/widgets/top_navbar.dart';
import '../../services/reward_service.dart';
import 'detail_reward_page.dart';

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  List rewards = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRewards();
  }

  Future loadRewards() async {
    final data = await RewardService.getRewards();
    setState(() {
      rewards = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          /// 1. TOP NAVBAR (Bawaan tetap ada)
          const TopNavbar(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: loadRewards,
              color: const Color(0xFF1E56A0),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    const SizedBox(height: 20),
                    
                    /// 3. CARD MY POINTS
                    _buildPointsCard(),

                    const SizedBox(height: 25),

                    const Text(
                      "Tukar Poin Reward",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3D5F),
                      ),
                    ),
                    const SizedBox(height: 15),

                    /// 4. LIST REWARD
                    loading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rewards.length,
                            itemBuilder: (context, index) {
                              return _buildRewardCard(rewards[index]);
                            },
                          ),
                    const SizedBox(height: 30),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B71CA), Color(0xFF54B4D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Poin Anda Saat Ini",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(Icons.stars, color: Colors.amber, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "1,200",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Map item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 70,
                height: 70,
                color: const Color(0xFFF0F4F8),
                child: item['gambar'] != null
                    ? Image.network(
                        Uri.encodeFull("http://10.0.2.2:8000/${item['gambar']}"),
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.redeem, color: Color(0xFF1E56A0)),
                      )
                    : const Icon(Icons.redeem, color: Color(0xFF1E56A0), size: 30),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nama_reward'] ?? "Reward",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3D5F)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${item['poin_dibutuhkan']} Poin",
                        style: const TextStyle(
                          color: Color(0xFF3B71CA),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetailRewardPage(data: item)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E56A0),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Tukar", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}