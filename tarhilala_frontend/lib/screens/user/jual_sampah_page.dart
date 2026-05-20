import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; 
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import '../../services/auth_service.dart';
import '../../services/pickup_service.dart';
import 'widgets/top_navbar.dart';

class JualSampahPage extends StatefulWidget {
  // 1. TAMBAHKAN PARAMETER INI
  final bool showBackButton;
  const JualSampahPage({super.key, this.showBackButton = false});

  @override
  State<JualSampahPage> createState() => _JualSampahPageState();
}

class _JualSampahPageState extends State<JualSampahPage> {
  File? _image;
  bool _isSending = false;
  bool _isLoadingData = true;

  final MapController _mapController = MapController();
  
  Position? _currentPosition;
  String _currentAddress = "Mencari lokasi presisi...";
  LatLng _mapCenter = const LatLng(0, 0);

  String _selectedPayment = 'saldo';
  final _catatanController = TextEditingController();
  List _jenisSampahDinamis = [];
  List<Map<String, dynamic>> _selectedItems = [];

  String _aiLabel = "Belum Terdeteksi";
  double _aiConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      await _determinePosition();
      if (!mounted) return;

      final data = await PickupService.getWasteTypes();
      if (!mounted) return;

      setState(() {
        _jenisSampahDinamis = data;
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Gagal memuat data: $e");
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "Izin lokasi ditolak.";
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _mapCenter = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_mapCenter, 16.0);

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        setState(() {
          _currentAddress = "${p.street}, ${p.subLocality}, ${p.locality}";
        });
      }
    } catch (e) {
      debugPrint("GPS Error: $e");
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 40);
    if (file != null) {
      if (!mounted) return;
      setState(() {
        _image = File(file.path);
        _aiLabel = "Menganalisa...";
      });
      
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      setState(() {
        _aiLabel = "Plastik PET / Botol";
        _aiConfidence = 0.95;
      });
    }
  }

  void _addItem() {
    setState(() => _selectedItems.add({"id": null, "berat": TextEditingController()}));
  }

  Future<void> _submitRequest() async {
    if (_image == null || _selectedItems.isEmpty) {
      _showSnack("Lengkapi foto dan jenis sampah!");
      return;
    }

    setState(() => _isSending = true);

    try {
      String? token = await AuthService.getToken();
      int? userId = await AuthService.getUserId();

      var uri = Uri.parse('${AuthService.baseUrl}/nasabah/setoran/store');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['nasabah_id'] = userId.toString();
      request.fields['metode_pembayaran'] = _selectedPayment;
      request.fields['lokasi_lat'] = _currentPosition?.latitude.toString() ?? "0.0";
      request.fields['lokasi_lng'] = _currentPosition?.longitude.toString() ?? "0.0";
      request.fields['catatan'] = _catatanController.text;

      double totalBerat = 0;
      List detailPayload = _selectedItems.map((item) {
        double b = double.tryParse(item['berat'].text) ?? 0;
        totalBerat += b;
        return {"id": item['id'], "berat": b};
      }).toList();

      request.fields['items'] = jsonEncode(detailPayload);
      request.fields['estimasi_berat'] = totalBerat.toString();
      request.fields['ai_class'] = _aiLabel;
      request.fields['ai_confidence'] = _aiConfidence.toString();

      request.files.add(await http.MultipartFile.fromPath('foto', _image!.path));

      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        var errorBody = jsonDecode(response.body);
        throw errorBody['message'] ?? "Gagal memproses di server.";
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Column(
        children: [
          const TopNavbar(),

          /// --- HEADER DINAMIS ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                // 2. LOGIKA TOMBOL KEMBALI
                if (widget.showBackButton) ...[
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
                ],
                const Text(
                  "Jual Sampah",
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
            child: _isLoadingData
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B71CA)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildSectionHeader("Bukti Foto"),
                        _buildPhotoBox(),
                        if(_image != null) _buildAIResult(),
                        
                        const SizedBox(height: 25),
                        _buildSectionHeader("Lokasi Penjemputan (GPS Akurat)"),
                        _buildMapArea(),

                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionHeader("Jenis Sampah"),
                            TextButton(onPressed: _addItem, child: const Text("+ Tambah", style: TextStyle(color: Color(0xFF3B71CA), fontWeight: FontWeight.bold))),
                          ],
                        ),
                        _buildWasteList(),

                        const SizedBox(height: 25),
                        _buildSectionHeader("Catatan & Pembayaran"),
                        _buildAdditionalFields(),
                        
                        const SizedBox(height: 40),
                        _buildSubmitButton(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // (Sisa widget helper Anda tetap sama)
  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3D5F)));
  }

  Widget _buildPhotoBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity, height: 180,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
        child: _image == null
            ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey), Text("Ambil Foto Sampah", style: TextStyle(color: Colors.grey))])
            : ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_image!, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildAIResult() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF3B71CA).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [const Icon(Icons.auto_awesome, color: Color(0xFF3B71CA), size: 18), const SizedBox(width: 8), Text("Prediksi AI: $_aiLabel", style: const TextStyle(color: Color(0xFF3B71CA), fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildMapArea() {
    return Column(
      children: [
        Container(
          height: 200, width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: _mapCenter, initialZoom: 16.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tarhilala.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _mapCenter, width: 40, height: 40,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(15))),
          child: Text(_currentAddress, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey)),
        )
      ],
    );
  }

  Widget _buildWasteList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedItems.length,
      itemBuilder: (context, i) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0, color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(flex: 3, child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true, hint: const Text("Jenis"),
                value: _selectedItems[i]['id'],
                items: _jenisSampahDinamis.map((e) => DropdownMenuItem<int>(value: e['id'], child: Text(e['nama'], style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) => setState(() => _selectedItems[i]['id'] = val),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: TextField(controller: _selectedItems[i]['berat'], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Kg", border: InputBorder.none, contentPadding: EdgeInsets.zero))),
            IconButton(onPressed: () => setState(() => _selectedItems.removeAt(i)), icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20))
          ]),
        ),
      ),
    );
  }

  Widget _buildAdditionalFields() {
    return Column(children: [
      const SizedBox(height: 10),
      TextField(controller: _catatanController, decoration: InputDecoration(hintText: "Catatan: misal rumah pagar biru", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _radioBtn('saldo', 'Saldo'),
          _radioBtn('cash', 'Tunai'),
          _radioBtn('transfer', 'Transfer'),
        ]),
      )
    ]);
  }

  Widget _radioBtn(String val, String label) {
    return Row(children: [
      Radio(value: val, groupValue: _selectedPayment, activeColor: const Color(0xFF3B71CA), onChanged: (v) => setState(() => _selectedPayment = v.toString())),
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 60,
      child: ElevatedButton(
        onPressed: _isSending ? null : _submitRequest,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B71CA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0),
        child: _isSending ? const CircularProgressIndicator(color: Colors.white) : const Text("KIRIM KE ADMIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _showErrorDialog(String msg) {
    if (!mounted) return;
    showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Error"), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Tutup"))]));
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, color: Colors.green, size: 60), SizedBox(height: 15), Text("Berhasil!", style: TextStyle(fontWeight: FontWeight.bold)), Text("Request Anda segera diproses Admin.")]),
      actions: [Center(child: TextButton(onPressed: () { Navigator.pop(c); Navigator.pop(context); }, child: const Text("Kembali")))],
    ));
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}