import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/setoran_model.dart';
import '../../services/pickup_service.dart';

class PetugasDetailSetoranPage extends StatefulWidget {
  final SetoranModel setoran;
  const PetugasDetailSetoranPage({super.key, required this.setoran});

  @override
  State<PetugasDetailSetoranPage> createState() => _PetugasDetailSetoranPageState();
}

class _PetugasDetailSetoranPageState extends State<PetugasDetailSetoranPage> {
  final PickupService _pickupService = PickupService();
  bool _isProcessing = false;
  bool _isLoadingMaster = true;

  // Data State
  List<dynamic> _masterWasteData = [];
  File? _confirmationImage;
  
  // Controller untuk item yang sudah ada
  final List<TextEditingController> _weightControllers = [];
  
  // List untuk item tambahan baru yang ditambahkan driver
  final List<Map<String, dynamic>> _extraItems = [];

  final TextEditingController _noteDriverController = TextEditingController();
  String _selectedPayment = 'saldo';
  double _totalBeratFinal = 0;
  double _totalHargaFinal = 0;

  @override
  void initState() {
    super.initState();
    _fetchMasterAndInit();
  }

  Future<void> _fetchMasterAndInit() async {
    try {
      final master = await PickupService.getWasteTypes();
      setState(() {
        _masterWasteData = master;
        _selectedPayment = widget.setoran.metodePembayaran;
        
        for (var item in widget.setoran.rincianSampah) {
          _weightControllers.add(TextEditingController(text: item.berat.toString()));
        }
        _isLoadingMaster = false;
        _calculateTotals();
      });
    } catch (e) {
      setState(() => _isLoadingMaster = false);
    }
  }

  void _calculateTotals() {
    double tempBerat = 0;
    double tempHarga = 0;

    // 1. Hitung dari item yang sudah ada (Hanya berat yang diubah, harga tetap)
    for (int i = 0; i < widget.setoran.rincianSampah.length; i++) {
      double berat = double.tryParse(_weightControllers[i].text.replaceAll(',', '.')) ?? 0;
      double harga = widget.setoran.rincianSampah[i].hargaSatuan;
      tempBerat += berat;
      tempHarga += (berat * harga);
    }

    // 2. Hitung dari item tambahan baru
    for (var extra in _extraItems) {
      double berat = double.tryParse(extra['controller'].text.replaceAll(',', '.')) ?? 0;
      double harga = extra['harga_satuan'] ?? 0;
      tempBerat += berat;
      tempHarga += (berat * harga);
    }

    setState(() {
      _totalBeratFinal = tempBerat;
      _totalHargaFinal = tempHarga;
    });
  }

  void _addExtraItem() {
    setState(() {
      _extraItems.add({
        "jenis_sampah_id": null,
        "nama_sampah": "",
        "harga_satuan": 0.0,
        "controller": TextEditingController(text: "0"),
      });
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _confirmationImage = File(pickedFile.path));
    }
  }

  void _submitSelesai() async {
    if (_confirmationImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wajib ambil foto konfirmasi!")));
      return;
    }

    setState(() => _isProcessing = true);

    List<Map<String, dynamic>> itemsPayload = [];
    
    // Item Lama
    for (int i = 0; i < widget.setoran.rincianSampah.length; i++) {
      itemsPayload.add({
        "id": widget.setoran.rincianSampah[i].id, // Kirim ID detail_setoran yang ada
        "berat_aktual": double.tryParse(_weightControllers[i].text) ?? 0,
      });
    }

    // Item Baru (Tanpa ID, nanti Laravel yang Handle Create)
    for (var extra in _extraItems) {
      if (extra['jenis_sampah_id'] != null) {
        itemsPayload.add({
          "jenis_sampah_id": extra['jenis_sampah_id'],
          "berat_aktual": double.tryParse(extra['controller'].text) ?? 0,
        });
      }
    }

    bool success = await _pickupService.updateStatusComplete(
      id: widget.setoran.id,
      status: 'selesai',
      beratFinal: _totalBeratFinal,
      totalHarga: _totalHargaFinal,
      metode: _selectedPayment,
      catatan: _noteDriverController.text,
      items: itemsPayload,
      foto: _confirmationImage,
    );

    if (mounted) setState(() => _isProcessing = false);
    if (success && mounted) Navigator.pop(context);
  }

  void _updateStatus(String status) async {
    setState(() => _isProcessing = true);
    bool success = await _pickupService.updateStatus(widget.setoran.id, status);
    if (mounted) setState(() => _isProcessing = false);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.setoran;
    final isPickupProcess = item.status == 'dalam_penjemputan';

    if (_isLoadingMaster) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(title: Text(isPickupProcess ? "Konfirmasi Penjemputan" : "Detail Request"), backgroundColor: const Color(0xFF154C94)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("REFERENSI NASABAH"),
            _buildNasabahCard(item),
            
            const SizedBox(height: 25),
            _buildSectionTitle("RINCIAN SAMPAH & TIMBANGAN"),
            _buildWasteList(isPickupProcess),

            if (isPickupProcess) ...[
              const SizedBox(height: 10),
              TextButton.icon(onPressed: _addExtraItem, icon: const Icon(Icons.add_circle_outline), label: const Text("Tambah Jenis Sampah Baru")),
              
              const SizedBox(height: 25),
              _buildSectionTitle("BUKTI PENGAMBILAN"),
              _buildPhotoBox(),

              const SizedBox(height: 25),
              _buildSectionTitle("RINGKASAN & PEMBAYARAN"),
              _buildSummaryCard(),
            ],

            const SizedBox(height: 30),
            if (_isProcessing) 
              const Center(child: CircularProgressIndicator())
            else
              _buildActionButtons(item),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildNasabahCard(SetoranModel item) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        _infoRow("Nasabah", item.nasabahNama),
        _infoRow("ID Request", "#SET-${item.id}"),
        _infoRow("Catatan Nasabah", item.catatan ?? "-"),
      ]),
    );
  }

  Widget _buildWasteList(bool isProcess) {
    return Column(children: [
      // List Item yang sudah di-request Nasabah
      ...List.generate(widget.setoran.rincianSampah.length, (index) {
        var s = widget.setoran.rincianSampah[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(s.namaSampah, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Master Harga: Rp ${s.hargaSatuan}"),
            trailing: isProcess 
              ? SizedBox(width: 80, child: TextField(controller: _weightControllers[index], keyboardType: TextInputType.number, onChanged: (_)=>_calculateTotals(), decoration: const InputDecoration(suffixText: "Kg")))
              : Text("${s.berat} Kg"),
          ),
        );
      }),
      // List Item Tambahan dari Driver
      ...List.generate(_extraItems.length, (index) {
        return Card(
          color: Colors.blue.shade50,
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              DropdownButton<int>(
                isExpanded: true,
                hint: const Text("Pilih Jenis Sampah Tambahan"),
                value: _extraItems[index]['jenis_sampah_id'],
                items: _masterWasteData.map((e) => DropdownMenuItem<int>(value: e['id'], child: Text("${e['nama']} (Rp ${e['harga_per_kg']})"))).toList(),
                onChanged: (val) {
                  var selected = _masterWasteData.firstWhere((x) => x['id'] == val);
                  setState(() {
                    _extraItems[index]['jenis_sampah_id'] = val;
                    _extraItems[index]['harga_satuan'] = double.parse(selected['harga_per_kg'].toString());
                  });
                  _calculateTotals();
                },
              ),
              TextField(controller: _extraItems[index]['controller'], keyboardType: TextInputType.number, onChanged: (_)=>_calculateTotals(), decoration: const InputDecoration(labelText: "Berat Tambahan (Kg)")),
            ]),
          ),
        );
      }),
    ]);
  }

  Widget _buildPhotoBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity, height: 150,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
        child: _confirmationImage == null 
          ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 40, color: Colors.grey), Text("Ambil Foto Sampah & Timbangan")])
          : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_confirmationImage!, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        _rowSum("Total Berat", "${_totalBeratFinal.toStringAsFixed(2)} Kg"),
        _rowSum("Total Bayar", "Rp ${_totalHargaFinal.toStringAsFixed(0)}", isBold: true),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _radio('saldo'), _radio('cash'), _radio('transfer'),
        ]),
        TextField(controller: _noteDriverController, decoration: const InputDecoration(hintText: "Catatan Tambahan Driver")),
      ]),
    );
  }

  Widget _buildActionButtons(SetoranModel item) {
    return Column(children: [
      if (item.status == 'dijadwalkan')
        _btn("MULAI PENJEMPUTAN", Colors.blue, () => _updateStatus('dalam_penjemputan')),
      if (item.status == 'dalam_penjemputan')
        _btn("SIMPAN & SELESAIKAN", Colors.green, _submitSelesai),
      const SizedBox(height: 10),
      _btn("BATALKAN TUGAS", Colors.red.shade400, () => _showCancelDialog(), isOutlined: true),
    ]);
  }

  // Helpers
  Widget _rowSum(String l, String v, {bool isBold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text(v, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14))]));
  Widget _radio(String v) => Row(children: [Radio(value: v, groupValue: _selectedPayment, onChanged: (x) => setState(() => _selectedPayment = x.toString())), Text(v.toUpperCase(), style: const TextStyle(fontSize: 10))]);
  Widget _btn(String l, Color c, VoidCallback t, {bool isOutlined = false}) => SizedBox(width: double.infinity, height: 50, child: isOutlined ? OutlinedButton(onPressed: t, child: Text(l, style: TextStyle(color: c))) : ElevatedButton(onPressed: t, style: ElevatedButton.styleFrom(backgroundColor: c), child: Text(l, style: const TextStyle(color: Colors.white))));
  Widget _infoRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(color: Colors.grey)), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]));
  Widget _buildSectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)));
  void _showCancelDialog() => showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Batalkan?"), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("TIDAK")), TextButton(onPressed: () { Navigator.pop(c); _updateStatus('dibatalkan'); }, child: const Text("YA, BATAL", style: TextStyle(color: Colors.red)))]));
}