import 'dart:convert';
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
  
  // Controller untuk item yang sudah ada di request nasabah
  final List<TextEditingController> _weightControllers = [];
  
  // List untuk menampung item tambahan yang ditambahkan oleh Driver
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
        
        // Inisialisasi berat awal sesuai estimasi nasabah
        for (var item in widget.setoran.rincianSampah) {
          _weightControllers.add(TextEditingController(text: item.berat.toString()));
        }
        _isLoadingMaster = false;
        _calculateTotals();
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingMaster = false);
    }
  }

  void _calculateTotals() {
    double tempBerat = 0;
    double tempHarga = 0;

    // 1. Hitung dari item original (Harga statis dari model)
    for (int i = 0; i < widget.setoran.rincianSampah.length; i++) {
      double berat = double.tryParse(_weightControllers[i].text.replaceAll(',', '.')) ?? 0;
      tempBerat += berat;
      tempHarga += (berat * widget.setoran.rincianSampah[i].hargaSatuan);
    }

    // 2. Hitung dari item tambahan driver
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
    if (pickedFile != null) {
      setState(() => _confirmationImage = File(pickedFile.path));
    }
  }

  // --- FUNGSI UTAMA SIMPAN ---
  void _submitSelesai() async {
    if (_confirmationImage == null) {
      _showSnack("Wajib mengambil foto timbangan sebagai bukti!", Colors.red);
      return;
    }

    if (_totalBeratFinal <= 0) {
      _showSnack("Berat total tidak boleh 0 kg!", Colors.orange);
      return;
    }

    setState(() => _isProcessing = true);

    List<Map<String, dynamic>> itemsPayload = [];
    
    // Payload Item Original
    for (int i = 0; i < widget.setoran.rincianSampah.length; i++) {
      itemsPayload.add({
        "id": widget.setoran.rincianSampah[i].id, 
        "berat_aktual": double.tryParse(_weightControllers[i].text.replaceAll(',', '.')) ?? 0
      });
    }

    // Payload Item Tambahan
    for (var extra in _extraItems) {
      if (extra['jenis_sampah_id'] != null) {
        itemsPayload.add({
          "jenis_sampah_id": extra['jenis_sampah_id'], 
          "berat_aktual": double.tryParse(extra['controller'].text.replaceAll(',', '.')) ?? 0
        });
      }
    }

    // Kirim ke Service
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

    if (success) {
      if (mounted) {
        Navigator.pop(context, true); // Kembali ke dashboard & refresh
        _showSnack("Setoran Berhasil Diselesaikan!", Colors.green);
      }
    } else {
      _showSnack("Gagal menyimpan ke server. Periksa koneksi.", Colors.red);
    }
  }

void _updateStatus(String status) async {
  setState(() => _isProcessing = true);
  
  bool success = await _pickupService.updateStatus(widget.setoran.id, status);
  
  if (mounted) setState(() => _isProcessing = false);

  if (success) {
    if (mounted) {
      // PENTING: Navigator.pop(context, true) akan memberitahu 
      // halaman dashboard bahwa data berubah dan perlu di-refresh.
      Navigator.pop(context, true); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.green, content: Text("Status berhasil diubah ke: ${status.replaceAll('_', ' ')}")),
      );
    }
  } else {
    // Tampilkan pesan error jika gagal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: Colors.red, content: Text("Gagal memperbarui status. Cek log server!")),
    );
  }
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
                  _buildHeaderTitle(isProcess),
                  
                  _buildSectionTitle("Informasi Nasabah"),
                  _buildNasabahCard(item),

                  _buildSectionTitle("Input Timbangan"),
                  _buildWasteList(isProcess),

                  if (isProcess) ...[
                    const SizedBox(height: 12),
                    _buildAddExtraButton(),
                    _buildSectionTitle("Dokumentasi Timbangan"),
                    _buildPhotoBox(),
                    _buildSectionTitle("Konfirmasi Pembayaran"),
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

  // --- UI HELPER COMPONENTS ---

  Widget _buildHeaderTitle(bool isProcess) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Row(children: [
        const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1B3D5F)),
        const SizedBox(width: 10),
        Text(isProcess ? "Konfirmasi Berat" : "Detail Pengajuan", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3D5F))),
      ]),
    );
  }

  Widget _buildNasabahCard(SetoranModel item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(children: [
        _infoRow(Icons.person, "Nama Nasabah", item.nasabahNama),
        const Divider(height: 24),
        _infoRow(Icons.pin_drop, "ID Transaksi", "#SET-${item.id}"),
        const Divider(height: 24),
        _infoRow(Icons.notes, "Catatan Nasabah", item.catatan ?? "-", isLast: true),
      ]),
    );
  }

  Widget _buildWasteList(bool isProcess) {
    return Column(children: [
      ...List.generate(widget.setoran.rincianSampah.length, (index) {
        var s = widget.setoran.rincianSampah[index];
        return _itemWasteCard(s.namaSampah, s.hargaSatuan, _weightControllers[index], isProcess);
      }),
      ...List.generate(_extraItems.length, (index) => _extraWasteCard(index)),
    ]);
  }

  Widget _itemWasteCard(String title, double harga, TextEditingController ctrl, bool isProcess) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE0E6ED))),
      child: Row(children: [
        const Icon(Icons.recycling_rounded, color: Color(0xFF154C94), size: 24),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("Rp ${NumberFormat('#,###', 'id').format(harga)}/kg", style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        if (isProcess)
          SizedBox(width: 85, child: TextField(
            controller: ctrl, keyboardType: TextInputType.number, onChanged: (_)=>_calculateTotals(),
            decoration: const InputDecoration(isDense: true, suffixText: " Kg"),
            textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold),
          ))
        else
          Text("${ctrl.text} Kg", style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _extraWasteCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.shade200)),
      child: Column(children: [
        DropdownButton<int>(
          isExpanded: true,
          hint: const Text("Pilih Sampah Tambahan"),
          value: _extraItems[index]['jenis_sampah_id'],
          items: _masterWasteData.map((e) => DropdownMenuItem<int>(value: e['id'], child: Text("${e['nama']} (Rp ${e['harga_per_kg']})"))).toList(),
          onChanged: (val) {
            var sel = _masterWasteData.firstWhere((x) => x['id'] == val);
            setState(() {
              _extraItems[index]['jenis_sampah_id'] = val;
              _extraItems[index]['harga_satuan'] = double.parse(sel['harga_per_kg'].toString());
            });
            _calculateTotals();
          },
        ),
        TextField(controller: _extraItems[index]['controller'], keyboardType: TextInputType.number, onChanged: (_)=>_calculateTotals(), decoration: const InputDecoration(labelText: "Berat (Kg)")),
      ]),
    );
  }

  Widget _buildPhotoBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity, height: 160,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
        child: _confirmationImage == null
            ? const Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey)
            : ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_confirmationImage!, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildPaymentSelector() {
    return Row(children: [
      _payBtn("saldo", "SALDO"), _payBtn("cash", "TUNAI"), _payBtn("transfer", "BANK"),
    ]);
  }

  Widget _payBtn(String val, String label) {
    bool active = _selectedPayment == val;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _selectedPayment = val),
      child: Container(
        margin: const EdgeInsets.all(4), padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: active ? const Color(0xFF154C94) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    ));
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1B3D5F), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _sumRow("Total Berat Aktual", "${_totalBeratFinal.toStringAsFixed(2)} Kg"),
        const SizedBox(height: 10),
        _sumRow("Total Pendapatan Nasabah", "Rp ${NumberFormat('#,###', 'id').format(_totalHargaFinal)}", isPrice: true),
        const Divider(color: Colors.white24, height: 30),
        TextField(
          controller: _noteDriverController, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Catatan driver (opsional)", hintStyle: TextStyle(color: Colors.white30), border: InputBorder.none),
        ),
      ]),
    );
  }

  Widget _buildActionButtons(SetoranModel item) {
    return Column(children: [
      if (item.status == 'dijadwalkan') _btn("KONFIRMASI MULAI JALAN", const Color(0xFF154C94), () => _updateStatus('dalam_penjemputan')),
      if (item.status == 'dalam_penjemputan') _btn("SIMPAN & SELESAIKAN", Colors.green, _submitSelesai),
      const SizedBox(height: 10),
      _btn("BATALKAN PERMINTAAN", Colors.transparent, () => _showCancelDialog(), isOutlined: true),
    ]);
  }

  // Helper Methods
  Widget _infoRow(IconData i, String l, String v, {bool isLast = false}) => Row(children: [Icon(i, size: 18, color: Colors.blueGrey), const SizedBox(width: 10), Text(l, style: const TextStyle(color: Colors.grey)), const Spacer(), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]);
  Widget _sumRow(String l, String v, {bool isPrice = false}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(color: Colors.white70)), Text(v, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isPrice ? 20 : 14))]);
  Widget _btn(String l, Color c, VoidCallback t, {bool isOutlined = false}) => SizedBox(width: double.infinity, height: 55, child: isOutlined ? OutlinedButton(onPressed: t, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)), child: Text(l, style: const TextStyle(color: Colors.red))) : ElevatedButton(onPressed: t, style: ElevatedButton.styleFrom(backgroundColor: c), child: Text(l, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
  Widget _buildSectionTitle(String t) => Padding(padding: const EdgeInsets.only(top: 25, bottom: 8), child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)));
  Widget _buildAddExtraButton() => TextButton.icon(onPressed: _addExtraItem, icon: const Icon(Icons.add), label: const Text("Tambah Jenis Sampah Baru"));
  void _showSnack(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  void _showCancelDialog() => showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Batalkan?"), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("TIDAK")), TextButton(onPressed: () { Navigator.pop(c); _updateStatus('dibatalkan'); }, child: const Text("YA", style: TextStyle(color: Colors.red)))]));
}