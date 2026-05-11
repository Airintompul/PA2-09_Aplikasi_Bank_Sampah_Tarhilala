import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/setoran_model.dart';
import '../../services/pickup_service.dart';
import '../user/widgets/top_navbar.dart';

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

  List<dynamic> _masterWasteData = [];
  File? _confirmationImage;
  final List<TextEditingController> _weightControllers = [];
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
    for (int i = 0; i < widget.setoran.rincianSampah.length; i++) {
      double berat = double.tryParse(_weightControllers[i].text.replaceAll(',', '.')) ?? 0;
      tempBerat += berat;
      tempHarga += (berat * widget.setoran.rincianSampah[i].hargaSatuan);
    }
    for (var extra in _extraItems) {
      double berat = double.tryParse(extra['controller'].text.replaceAll(',', '.')) ?? 0;
      tempBerat += berat;
      tempHarga += (berat * (extra['harga_satuan'] ?? 0));
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
        "harga_satuan": 0.0,
        "controller": TextEditingController(text: "0"),
      });
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) setState(() => _confirmationImage = File(pickedFile.path));
  }

  void _submitSelesai() async {
    if (_confirmationImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wajib mengambil foto timbangan sebagai bukti!"), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isProcessing = true);
    List<Map<String, dynamic>> itemsPayload = [];
    for (int i = 0; i < widget.setoran.rincianSampah.length; i++) {
      itemsPayload.add({
        "id": widget.setoran.rincianSampah[i].id, 
        "berat_aktual": double.tryParse(_weightControllers[i].text) ?? 0
      });
    }
    for (var extra in _extraItems) {
      if (extra['jenis_sampah_id'] != null) {
        itemsPayload.add({
          "jenis_sampah_id": extra['jenis_sampah_id'], 
          "berat_aktual": double.tryParse(extra['controller'].text) ?? 0
        });
      }
    }
    bool success = await _pickupService.updateStatusComplete(
      id: widget.setoran.id, status: 'selesai', beratFinal: _totalBeratFinal, totalHarga: _totalHargaFinal,
      metode: _selectedPayment, catatan: _noteDriverController.text, items: itemsPayload, foto: _confirmationImage,
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
    final isProcess = item.status == 'dalam_penjemputan';

    if (_isLoadingMaster) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
                  const SizedBox(height: 20),
                  _buildHeaderBackButton(isProcess),
                  
                  _buildSectionTitle("Informasi Nasabah"),
                  _buildNasabahCard(item),

                  _buildSectionTitle("Input Timbangan"),
                  _buildWasteList(isProcess),

                  if (isProcess) ...[
                    const SizedBox(height: 12),
                    _buildAddExtraButton(),
                    _buildSectionTitle("Dokumentasi Timbangan"),
                    _buildPhotoBox(),
                    _buildSectionTitle("Metode Pembayaran"),
                    _buildPaymentSelector(),
                  ],

                  const SizedBox(height: 30),
                  _buildSummarySection(),
                  const SizedBox(height: 25),
                  _isProcessing ? const Center(child: CircularProgressIndicator()) : _buildActionButtons(item),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeaderBackButton(bool isProcess) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Row(
        children: [
          const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1B3D5F)),
          const SizedBox(width: 10),
          Text(
            isProcess ? "Konfirmasi Berat Sampah" : "Detail Pengajuan",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10, left: 5),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildNasabahCard(SetoranModel item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _infoRow(Icons.person_rounded, "Nama Nasabah", item.nasabahNama),
          const Divider(height: 24, color: Color(0xFFF1F1F1)),
          _infoRow(Icons.pin_drop_rounded, "ID Transaksi", "#SET-${item.id}"),
          const Divider(height: 24, color: Color(0xFFF1F1F1)),
          _infoRow(Icons.chat_bubble_outline_rounded, "Pesan Nasabah", item.catatan ?? "-", isLast: true),
        ],
      ),
    );
  }

  Widget _buildWasteList(bool isProcess) {
    return Column(
      children: [
        ...List.generate(widget.setoran.rincianSampah.length, (index) {
          var s = widget.setoran.rincianSampah[index];
          return _itemWasteCard(s.namaSampah, s.hargaSatuan, _weightControllers[index], isProcess);
        }),
        ...List.generate(_extraItems.length, (index) {
          return _extraWasteCard(index);
        }),
      ],
    );
  }

  Widget _itemWasteCard(String title, double harga, TextEditingController ctrl, bool isProcess) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: const Color(0xFFE0E6ED))
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.recycling_rounded, color: Color(0xFF154C94), size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F))),
              Text("Harga: Rp ${NumberFormat.decimalPattern('id').format(harga)}/kg", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
          if (isProcess)
            SizedBox(
              width: 90,
              child: TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateTotals(),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF154C94)),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), 
                  isDense: true, 
                  suffixText: " Kg", 
                  suffixStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFFF5F7F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
                ),
              ),
            )
          else
            Text("${ctrl.text} Kg", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF154C94))),
        ],
      ),
    );
  }

  Widget _extraWasteCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: const Color(0xFF154C94).withOpacity(0.3))
      ),
      child: Column(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              hint: const Text("Pilih Jenis Sampah Tambahan", style: TextStyle(fontSize: 14)),
              value: _extraItems[index]['jenis_sampah_id'],
              items: _masterWasteData.map((e) => DropdownMenuItem<int>(
                value: e['id'], 
                child: Text("${e['nama']} (Rp ${e['harga_per_kg']})", style: const TextStyle(fontSize: 14))
              )).toList(),
              onChanged: (val) {
                var selected = _masterWasteData.firstWhere((x) => x['id'] == val);
                setState(() {
                  _extraItems[index]['jenis_sampah_id'] = val;
                  _extraItems[index]['harga_satuan'] = double.parse(selected['harga_per_kg'].toString());
                });
                _calculateTotals();
              },
            ),
          ),
          const Divider(),
          TextField(
            controller: _extraItems[index]['controller'],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _calculateTotals(),
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              labelText: "Berat Tambahan (Kg)", 
              labelStyle: TextStyle(fontSize: 12),
              isDense: true, 
              border: InputBorder.none
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExtraButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _addExtraItem,
        icon: const Icon(Icons.add_circle_rounded, size: 20),
        label: const Text("Tambahkan Item di Luar List"),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF154C94),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF154C94)))
        ),
      ),
    );
  }

  Widget _buildPhotoBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity, height: 180,
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: const Color(0xFFE0E6ED), width: 2, style: BorderStyle.solid)
        ),
        child: _confirmationImage == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Icon(Icons.camera_alt_rounded, size: 42, color: Color(0xFF154C94)), 
                  SizedBox(height: 10), 
                  Text("Klik untuk Ambil Foto Timbangan", style: TextStyle(color: Colors.grey, fontSize: 13))
                ]
              )
            : ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_confirmationImage!, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildPaymentSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          _payOption("saldo", "Saldo"),
          _payOption("cash", "Tunai"),
          _payOption("transfer", "Transfer"),
        ],
      ),
    );
  }

  Widget _payOption(String val, String label) {
    bool active = _selectedPayment == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPayment = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF154C94) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label, 
            textAlign: TextAlign.center,
            style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3D5F), 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1B3D5F).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          _sumRow("Estimasi Berat Akhir", "${_totalBeratFinal.toStringAsFixed(2)} Kg"),
          const SizedBox(height: 12),
          _sumRow("Total Bayar ke Nasabah", "Rp ${NumberFormat.decimalPattern('id').format(_totalHargaFinal)}", isPrice: true),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: Colors.white10)),
          TextField(
            controller: _noteDriverController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              hintText: "Tambahkan catatan (Contoh: Sampah bersih)", 
              hintStyle: TextStyle(color: Colors.white30, fontSize: 13), 
              border: InputBorder.none,
              icon: Icon(Icons.edit_note, color: Colors.white54)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SetoranModel item) {
    return Column(
      children: [
        if (item.status == 'dijadwalkan')
          _btn("KONFIRMASI MULAI JALAN", const Color(0xFF154C94), () => _updateStatus('dalam_penjemputan')),
        if (item.status == 'dalam_penjemputan')
          _btn("SELESAIKAN & BAYAR", Colors.green.shade600, _submitSelesai),
        const SizedBox(height: 15),
        _btn("BATALKAN PERMINTAAN", Colors.transparent, () => _showCancelDialog(), isOutlined: true),
      ],
    );
  }

  // --- HELPERS ---
  Widget _infoRow(IconData icon, String l, String v, {bool isLast = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2), 
    child: Row(children: [
      Icon(icon, size: 18, color: const Color(0xFF154C94).withOpacity(0.6)), 
      const SizedBox(width: 12), 
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 13)), 
      const Spacer(), 
      Text(v, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F), fontSize: 13))
    ]));

  Widget _sumRow(String l, String v, {bool isPrice = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
    children: [
      Text(l, style: const TextStyle(color: Colors.white70, fontSize: 13)), 
      Text(v, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isPrice ? 20 : 15))
    ]);

  Widget _btn(String l, Color c, VoidCallback t, {bool isOutlined = false}) => SizedBox(
    width: double.infinity, 
    height: 55, 
    child: isOutlined 
      ? OutlinedButton(onPressed: t, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text(l, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))) 
      : ElevatedButton(onPressed: t, style: ElevatedButton.styleFrom(backgroundColor: c, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text(l, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1))));

  void _showCancelDialog() => showDialog(context: context, builder: (c) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text("Batalkan Penjemputan?", style: TextStyle(fontWeight: FontWeight.bold)), 
    content: const Text("Data penjemputan ini akan dihapus dari daftar rute harian Anda."), 
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text("TIDAK", style: TextStyle(color: Colors.grey))), 
      TextButton(onPressed: () { Navigator.pop(c); _updateStatus('dibatalkan'); }, child: const Text("YA, BATALKAN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
    ]));
}