import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // Wajib: pub add geolocator
import 'package:geocoding/geocoding.dart'; // Wajib: pub add geocoding
import 'package:tarhilala_frontend/screens/user/widgets/top_navbar.dart';
import '../user/widgets/bottom_navbar.dart';
import '../../services/redeem_service.dart';

class FormTukarPoinPage extends StatefulWidget {
  final Map data;
  const FormTukarPoinPage({super.key, required this.data});

  @override
  State<FormTukarPoinPage> createState() => _FormTukarPoinPageState();
}

class _FormTukarPoinPageState extends State<FormTukarPoinPage> {
  int jumlah = 1;
  bool isAgreed = false;
  String userPoin = "0";
  bool loadingPoin = true;
  bool isSubmitting = false;
  bool isFetchingLocation = false;

  // Controller Input Baru
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  String _lat = "";
  String _lng = "";

  @override
  void initState() {
    super.initState();
    fetchUserPoin();
  }

  // --- AMBIL POIN DINAMIS DARI API ---
  Future<void> fetchUserPoin() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/api/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userPoin = (data['poin'] ?? 0).toString();
          loadingPoin = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetch poin: $e");
      setState(() => loadingPoin = false);
    }
  }

  // --- AMBIL LOKASI GPS OTOMATIS ---
  Future<void> _determinePosition() async {
    setState(() => isFetchingLocation = true);
    
    try {
      // 1. Cek Izin & Layanan (Wajib)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "GPS HP mati. Mohon aktifkan GPS.";
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "Izin lokasi ditolak.";
      }

      // 2. Ambil Lokasi Terakhir (Sangat Cepat/Instan sebagai cadangan)
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      Position currentPos;

      if (lastPosition != null) {
        currentPos = lastPosition;
      } else {
        // 3. Jika tidak ada lokasi terakhir, ambil posisi sekarang (Low Accuracy agar cepat)
        currentPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low, // Paling cepat dapat sinyal
          timeLimit: const Duration(seconds: 5), // Batas waktu 5 detik
        );
      }

      setState(() {
        _lat = currentPos.latitude.toString();
        _lng = currentPos.longitude.toString();
      });

      // 4. Ubah Koordinat jadi Nama Jalan (Geocoding)
      // Bagian ini sering gagal di emulator, kita beri try-catch khusus
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          currentPos.latitude, currentPos.longitude
        ).timeout(const Duration(seconds: 5));

        if (placemarks.isNotEmpty) {
          Placemark p = placemarks[0];
          setState(() {
            _alamatController.text = "${p.street}, ${p.subLocality}, ${p.locality}";
          });
        }
      } catch (e) {
        // Jika geocoding gagal, minimal koordinat lat/lng sudah dapat
        _alamatController.text = "Lokasi ditemukan, tapi gagal mengambil nama jalan. Mohon ketik alamat manual.";
        debugPrint("Geocoding Error: $e");
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Info: $e"), backgroundColor: Colors.orange)
      );
    } finally {
      setState(() => isFetchingLocation = false);
    }
  }

  // Fungsi tambahan jika GPS macet
  Future<Position> _getLastKnownPosition() async {
    Position? position = await Geolocator.getLastKnownPosition();
    if (position != null) return position;
    // Jika benar-benar tidak ada, lempar error
    throw "Gagal mendapatkan sinyal GPS. Coba di luar ruangan.";
  }

  String getCleanImageUrl(String? url) {
    if (url == null) return "";
    String fixedUrl = url.replaceAll("127.0.0.1", "127.0.0.1");
    return Uri.encodeFull(fixedUrl);
  }

  @override
  Widget build(BuildContext context) {
    int poinSatuan = int.parse(widget.data['poin_dibutuhkan'].toString());
    int stok = widget.data['stok'] ?? 0;
    int totalPoinDibutuhkan = jumlah * poinSatuan;
    bool poinCukup = int.parse(userPoin) >= totalPoinDibutuhkan;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          const TopNavbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildBluePointsCard(),
                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildItemInfo(),
                        const Divider(height: 40, thickness: 1),

                        const Text("Jumlah Penukaran", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F))),
                        const SizedBox(height: 12),
                        _buildQuantitySelector(stok),

                        const SizedBox(height: 25),

                        // --- SECTION LOKASI ---
                        const Text("Lokasi Pengiriman", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F))),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: isFetchingLocation ? null : _determinePosition,
                          icon: isFetchingLocation 
                            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location, size: 18),
                          label: Text(isFetchingLocation ? "Mencari Lokasi..." : "Gunakan Lokasi Saat Ini (GPS)"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3B71CA),
                            side: const BorderSide(color: Color(0xFF3B71CA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _alamatController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Alamat Lengkap (No Rumah/Blok)",
                            hintStyle: const TextStyle(fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _catatanController,
                          decoration: InputDecoration(
                            hintText: "Catatan (Contoh: Titip satpam)",
                            hintStyle: const TextStyle(fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),

                        const SizedBox(height: 25),
                        _summaryRow("Total Poin dibutuhkan", "$totalPoinDibutuhkan Poin", isPrimary: true),
                        _summaryRow("Poin Anda Saat Ini", "$userPoin Poin"),
                        const SizedBox(height: 20),
                        _buildAgreementCheckbox(),
                        const SizedBox(height: 25),
                        _buildSubmitButton(poinCukup, stok),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1B3D5F)),
          ),
        ),
        const SizedBox(width: 15),
        const Text("Konfirmasi Redeem", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F))),
      ],
    );
  }

  Widget _buildBluePointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B71CA), Color(0xFF54B4D3)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Saldo Poin", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              loadingPoin 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(userPoin, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.stars_rounded, color: Colors.white24, size: 50),
        ],
      ),
    );
  }

  Widget _buildItemInfo() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            getCleanImageUrl(widget.data['gambar']),
            width: 70, height: 70, fit: BoxFit.cover,
            errorBuilder: (c, e, s) => const Icon(Icons.redeem, size: 40),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.data['nama_reward'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${widget.data['poin_dibutuhkan']} Poin / item", style: const TextStyle(color: Color(0xFF3B71CA), fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(int stok) {
    return Row(
      children: [
        IconButton(onPressed: () => setState(() => jumlah > 1 ? jumlah-- : null), icon: const Icon(Icons.remove_circle, color: Colors.red)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: Text("$jumlah", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        IconButton(onPressed: () => setState(() => jumlah < stok ? jumlah++ : null), icon: const Icon(Icons.add_circle, color: Colors.green)),
        const Spacer(),
        Text("Stok: $stok", style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAgreementCheckbox() {
    return Row(
      children: [
        Checkbox(value: isAgreed, activeColor: const Color(0xFF1E56A0), onChanged: (val) => setState(() => isAgreed = val!)),
        const Expanded(child: Text("Data yang saya masukkan sudah benar.", style: TextStyle(fontSize: 11, color: Colors.grey))),
      ],
    );
  }

  Widget _buildSubmitButton(bool poinCukup, int stok) {
      // Tombol aktif hanya jika semua syarat terpenuhi
      bool canSubmit = isAgreed && poinCukup && stok > 0 && !isSubmitting && _alamatController.text.isNotEmpty;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canSubmit ? () => _processRedemption() : null,
          style: ElevatedButton.styleFrom(
            // Warna background: Biru jika aktif, Abu-abu jika tidak aktif
            backgroundColor: canSubmit ? const Color(0xFF1E56A0) : Colors.grey.shade400,
            
            // Warna teks & icon saat tombol AKTIF
            foregroundColor: Colors.white,

            // --- INI KUNCINYA ---
            // Warna teks & icon saat tombol NON-AKTIF (Disabled)
            // Kita paksa jadi putih agar tidak berubah jadi abu-abu pudar
            disabledForegroundColor: Colors.white, 
            disabledBackgroundColor: Colors.grey.shade400,
            // --------------------

            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: canSubmit ? 2 : 0,
          ),
          child: isSubmitting 
            ? const SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : Text(
                !poinCukup ? "Poin Tidak Cukup" : "Tukar Sekarang",
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: Colors.white, // Memastikan warna teks tetap putih
                ),
              ),
        ),
      );
    }

  Widget _summaryRow(String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isPrimary ? const Color(0xFF1E56A0) : Colors.black)),
        ],
      ),
    );
  }

  void _processRedemption() async {
    setState(() => isSubmitting = true);

    bool success = await RedeemService.redeemReward(
      rewardId: widget.data['id'], 
      jumlah: jumlah,
      lat: _lat,
      lng: _lng,
      alamat: _alamatController.text,
      catatan: _catatanController.text
    );

    if (mounted) {
      setState(() => isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil! Admin akan segera memproses."), backgroundColor: Colors.green));
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menukar."), backgroundColor: Colors.red));
      }
    }
  }
}