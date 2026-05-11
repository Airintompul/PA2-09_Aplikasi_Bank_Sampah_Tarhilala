import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Import package ini
import 'package:url_launcher/url_launcher.dart';
import '../../models/setoran_model.dart';
import '../user/widgets/top_navbar.dart';

class PetugasRutePage extends StatefulWidget {
  final List<SetoranModel> ruteData;
  const PetugasRutePage({super.key, required this.ruteData});

  @override
  State<PetugasRutePage> createState() => _PetugasRutePageState();
}

class _PetugasRutePageState extends State<PetugasRutePage> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  
  // Penyimpanan sementara untuk alamat yang berhasil diterjemahkan
  Map<int, String> resolvedAddresses = {}; 

  LatLng _driverLocation = const LatLng(-6.192, 108.8667); 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
    _convertAllCoordinates(); // Terjemahkan semua koordinat saat start
  }

  // Fungsi untuk mengubah koordinat menjadi Nama Jalan
  Future<void> _convertAllCoordinates() async {
    for (var item in widget.ruteData) {
      double lat = double.tryParse(item.lat ?? "0") ?? 0;
      double lng = double.tryParse(item.lng ?? "0") ?? 0;

      if (lat != 0 && lng != 0) {
        try {
          // Proses Reverse Geocoding
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            setState(() {
              // Format Alamat: Nama Jalan, Kelurahan, Kota
              resolvedAddresses[item.id] = "${place.street}, ${place.subLocality}, ${place.locality}";
            });
          }
        } catch (e) {
          debugPrint("Gagal ambil alamat untuk ID ${item.id}: $e");
        }
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLocationTracking() async {
    // ... (kode GPS driver sama seperti sebelumnya) ...
    Position pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _driverLocation = LatLng(pos.latitude, pos.longitude);
        _isLoading = false;
      });
      _mapController.move(_driverLocation, 14.0);
    }
  }

  void _moveToPoint(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 17.0);
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = widget.ruteData.where((item) => item.status != 'selesai').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Column(
        children: [
          const TopNavbar(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.40,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _driverLocation,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tarhilala.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _driverLocation,
                          width: 40, height: 40,
                          child: const Icon(Icons.navigation, color: Colors.blue, size: 30),
                        ),
                        ...filteredData.map((item) {
                          double lat = double.tryParse(item.lat ?? "0") ?? 0;
                          double lng = double.tryParse(item.lng ?? "0") ?? 0;
                          if (lat == 0) return const Marker(point: LatLng(0,0), child: SizedBox());
                          return Marker(
                            point: LatLng(lat, lng),
                            width: 35, height: 35,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 10, left: 10,
                  child: FloatingActionButton.small(
                    heroTag: "btn_back",
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Daftar Penjemputan Aktif", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  if (filteredData.isEmpty)
                    const Center(child: Text("Semua tugas selesai!"))
                  else
                    ...filteredData.asMap().entries.map((entry) {
                      var item = entry.value;
                      bool isLast = entry.key == filteredData.length - 1;
                      double tLat = double.tryParse(item.lat ?? "0") ?? 0;
                      double tLng = double.tryParse(item.lng ?? "0") ?? 0;

                      return _buildTimelineItem(item, isLast, tLat, tLng);
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(SetoranModel item, bool isLast, double lat, double lng) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.circle, size: 16, color: Colors.orange),
            if (!isLast) Container(width: 2, height: 90, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MENAMPILKAN ALAMAT DINAMIS HASIL TRANSLATE KOORDINAT
              Text(
                resolvedAddresses[item.id] ?? "Mencari alamat...", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text("Nasabah: ${item.nasabahNama}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
              
              ElevatedButton.icon(
                onPressed: (lat != 0) ? () => _moveToPoint(lat, lng) : null,
                icon: const Icon(Icons.map, size: 16),
                label: const Text("Cek Map", style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3), 
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ],
    );
  }
}