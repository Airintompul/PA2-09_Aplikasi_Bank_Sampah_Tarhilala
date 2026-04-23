import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart'; // Import AuthService Anda
import '../../services/pickup_service.dart';

class JualSampahPage extends StatefulWidget {
  const JualSampahPage({super.key});

  @override
  State<JualSampahPage> createState() => _JualSampahPageState();
}

class _JualSampahPageState extends State<JualSampahPage> {
  File? _image;
  bool _isSending = false;
  bool _isLoadingData = true;

  // Data Form
  Position? _currentPosition;
  String _currentAddress = "Mencari lokasi GPS...";
  String _selectedPayment = 'saldo';
  final _catatanController = TextEditingController();
  
  List _jenisSampahDinamis = [];
  List<Map<String, dynamic>> _selectedItems = [];

  // Data AI (Simulasi)
  String _aiLabel = "Belum Terdeteksi";
  double _aiConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // --- INISIALISASI DATA ---
  Future<void> _initData() async {
    try {
      await _determinePosition();
      final data = await PickupService.getWasteTypes(); 
      setState(() {
        _jenisSampahDinamis = data;
        _isLoadingData = false;
      });
    } catch (e) {
      _showErrorDialog("Gagal memuat data awal: $e");
      if(mounted) setState(() => _isLoadingData = false);
    }
  }

  // --- LOGIC GPS ---
  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw "Izin lokasi ditolak pengguna.";
    }
    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() => _currentAddress = "${_currentPosition!.latitude}, ${_currentPosition!.longitude}");
  }

  // --- LOGIC FOTO & AI ---
  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 40);
    if (file != null) {
      setState(() {
        _image = File(file.path);
        _aiLabel = "Sedang Menganalisa...";
      });
      // Simulasi Machine Learning (Langkah 4 Alur Anda)
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _aiLabel = "Plastik / Botol Minuman"; 
        _aiConfidence = 0.95;
      });
    }
  }

  void _addItem() {
    setState(() => _selectedItems.add({"id": null, "berat": TextEditingController()}));
  }

  // --- LOGIC KIRIM (EXCEPTION HANDLING) ---
  Future<void> _submitRequest() async {
    if (_image == null || _selectedItems.isEmpty) {
      _showSnack("Mohon lengkapi foto dan pilih jenis sampah.");
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. Ambil ID dari AuthService secara Dinamis
      int? userId = await AuthService.getUserId();
      if (userId == null) throw "Sesi login hilang. Silakan login kembali.";

      var uri = Uri.parse('${AuthService.baseUrl}/nasabah/setoran/store');
      var request = http.MultipartRequest('POST', uri);

      // 2. Mapping Header
      request.fields['nasabah_id'] = userId.toString();
      request.fields['metode_pembayaran'] = _selectedPayment;
      request.fields['lokasi_lat'] = _currentPosition?.latitude.toString() ?? "0.0";
      request.fields['lokasi_lng'] = _currentPosition?.longitude.toString() ?? "0.0";
      request.fields['catatan'] = _catatanController.text;

      // 3. Mapping Detail Sampah ke JSON
      double totalEstimasi = 0;
      List detailPayload = _selectedItems.map((item) {
        double b = double.tryParse(item['berat'].text) ?? 0;
        totalEstimasi += b;
        return {"id": item['id'], "berat": b};
      }).toList();
      
      request.fields['items'] = jsonEncode(detailPayload);
      request.fields['estimasi_berat'] = totalEstimasi.toString();

      // 4. AI & Lampiran Foto
      request.fields['ai_class'] = _aiLabel;
      request.fields['ai_confidence'] = _aiConfidence.toString();
      request.files.add(await http.MultipartFile.fromPath('foto', _image!.path));

      // 5. Kirim dengan Timeout
      var streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        // Tangkap pesan error dari Laravel
        Map errorMsg = jsonDecode(response.body);
        throw errorMsg['message'] ?? "Gagal memproses request di server.";
      }

    } on SocketException {
      _showErrorDialog("Tidak ada koneksi internet. Pastikan server menyala.");
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if(mounted) setState(() => _isSending = false);
    }
  }

  // --- UI HELPER ---
  void _showErrorDialog(String msg) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Gagal", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      content: Text(msg),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Tutup"))],
    ));
  }

  void _showSuccessDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: const Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle, color: Colors.green, size: 70),
        SizedBox(height: 15),
        Text("Berhasil!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Request Anda sedang menunggu konfirmasi Admin.", textAlign: TextAlign.center),
      ]),
      actions: [Center(child: ElevatedButton(onPressed: () { Navigator.pop(c); Navigator.pop(context); }, child: const Text("Kembali")))],
    ));
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(title: const Text("Request Penjemputan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoArea(),
                const SizedBox(height: 20),
                _buildLocationCard(),
                const SizedBox(height: 25),
                _buildWasteListArea(),
                const SizedBox(height: 25),
                _buildAdditionalInfo(),
                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildPhotoArea() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity, height: 220,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
        child: _image == null 
          ? const Center(child: Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey))
          : ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(_image!, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.location_on, color: Colors.redAccent),
        const SizedBox(width: 10),
        Expanded(child: Text(_currentAddress, style: const TextStyle(fontSize: 12))),
        IconButton(onPressed: _determinePosition, icon: const Icon(Icons.my_location, color: Color(0xFF3B71CA)))
      ]),
    );
  }

  Widget _buildWasteListArea() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("Jenis Sampah", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        TextButton(onPressed: _addItem, child: const Text("+ Tambah Jenis"))
      ]),
      ..._selectedItems.asMap().entries.map((entry) {
        int i = entry.key;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Expanded(flex: 3, child: DropdownButton<int>(
                isExpanded: true, underline: const SizedBox(),
                hint: const Text("Jenis"),
                value: _selectedItems[i]['id'],
                items: _jenisSampahDinamis.map((e) => DropdownMenuItem<int>(value: e['id'], child: Text(e['nama'], style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) => setState(() => _selectedItems[i]['id'] = val),
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: TextField(controller: _selectedItems[i]['berat'], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Kg", border: InputBorder.none))),
              IconButton(onPressed: () => setState(() => _selectedItems.removeAt(i)), icon: const Icon(Icons.delete_outline, color: Colors.redAccent))
            ]),
          ),
        );
      }).toList(),
    ]);
  }

  Widget _buildAdditionalInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Catatan & Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 10),
      TextField(controller: _catatanController, decoration: InputDecoration(hintText: "Contoh: Di belakang toko", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
      const SizedBox(height: 10),
      Row(children: [
        Radio(value: 'saldo', groupValue: _selectedPayment, activeColor: const Color(0xFF3B71CA), onChanged: (v) => setState(() => _selectedPayment = v.toString())),
        const Text("Saldo"),
        Radio(value: 'cash', groupValue: _selectedPayment, activeColor: const Color(0xFF3B71CA), onChanged: (v) => setState(() => _selectedPayment = v.toString())),
        const Text("Tunai"),
      ])
    ]);
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: _isSending ? null : _submitRequest,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B71CA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isSending ? const CircularProgressIndicator(color: Colors.white) : const Text("KIRIM KE ADMIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}