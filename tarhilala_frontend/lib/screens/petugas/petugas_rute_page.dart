import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; 
import 'package:url_launcher/url_launcher.dart';
import '../../models/setoran_model.dart';
import '../../services/pickup_service.dart';
import '../user/widgets/top_navbar.dart';

class PetugasRutePage extends StatefulWidget {
  final List<SetoranModel>? ruteData;
  const PetugasRutePage({super.key, this.ruteData});

  @override
  State<PetugasRutePage> createState() => _PetugasRutePageState();
}

class _PetugasRutePageState extends State<PetugasRutePage> {
  final MapController _mapController = MapController();
  final PickupService _pickupService = PickupService();
  
  List<SetoranModel> _displayData = [];
  Map<int, String> resolvedAddresses = {}; 
  LatLng _driverLocation = const LatLng(-6.192, 108.8667); 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    bool hasActiveData = widget.ruteData != null && 
                         widget.ruteData!.any((item) => item.status != 'selesai');
    if (hasActiveData) {
      setState(() {
        _displayData = widget.ruteData!;
        _isLoading = false;
      });
      _startLocationTracking();
      _convertAllCoordinates();
    } else {
      await _fetchLatestData();
    }
  }

  Future<void> _fetchLatestData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _pickupService.getSetoranRequests();
      if (mounted) {
        setState(() {
          _displayData = data;
          _isLoading = false;
        });
        _startLocationTracking();
        _convertAllCoordinates();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Gagal fetch rute: $e");
    }
  }

  Future<void> _convertAllCoordinates() async {
    for (var item in _displayData) {
      double lat = double.tryParse(item.lat ?? "0") ?? 0;
      double lng = double.tryParse(item.lng ?? "0") ?? 0;
      if (lat != 0 && lng != 0) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            if (mounted) {
              setState(() {
                resolvedAddresses[item.id] = "${place.street}, ${place.subLocality}, ${place.locality}";
              });
            }
          }
        } catch (e) {
          debugPrint("Gagal ambil alamat untuk ID ${item.id}: $e");
        }
      }
    }
  }

  void _startLocationTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Position pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _driverLocation = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_driverLocation, 14.0);
    }
  }

  void _moveToPoint(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 17.0);
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _displayData.where((item) => item.status == 'dalam_penjemputan').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(
        children: [
          const TopNavbar(),
          // Peta
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.40,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: FlutterMap(
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
                            if (lat == 0) return const Marker(point: LatLng(0, 0), child: SizedBox());
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
                ),
                // Tombol back
                Positioned(
                  top: 10, left: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10)],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D2744), size: 16),
                    ),
                  ),
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF154C94))),
              ],
            ),
          ),
          // Daftar
          Expanded(
            child: _isLoading
                ? const Center(child: Text("Memuat data rute...", style: TextStyle(color: Color(0xFF8FA3B8))))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Daftar Penjemputan Aktif",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0D2744)),
                        ),
                        const SizedBox(height: 16),
                        if (filteredData.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Column(
                                children: [
                                  Icon(Icons.location_off_rounded, size: 50, color: Colors.grey.shade300),
                                  const SizedBox(height: 10),
                                  const Text("Tidak ada penjemputan aktif", style: TextStyle(color: Color(0xFF8FA3B8))),
                                ],
                              ),
                            ),
                          )
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
        // Garis timeline
        Column(
          children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB830),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFFFFB830).withOpacity(0.4), blurRadius: 6)],
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 90, color: const Color(0xFFE0E8F0)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: const Color(0xFF154C94).withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedAddresses[item.id] ?? "Mencari alamat...",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0D2744)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Nasabah: ${item.nasabahNama}",
                    style: const TextStyle(color: Color(0xFF8FA3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton.icon(
                      onPressed: (lat != 0) ? () => _moveToPoint(lat, lng) : null,
                      icon: const Icon(Icons.map_rounded, size: 14),
                      label: const Text("Cek Map", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154C94),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}