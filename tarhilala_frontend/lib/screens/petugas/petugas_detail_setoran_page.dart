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

  // ── Warna tema (sama dengan SetoranPage) ──────────────────────────
  static const _primary   = Color(0xFF154C94);
  static const _dark      = Color(0xFF0D2744);
  static const _bg        = Color(0xFFF0F4F8);
  static const _muted     = Color(0xFF8FA3B8);
  static const _hint      = Color(0xFFAABBCC);

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
    } catch (_) {
      if (mounted) setState(() => _isLoadingMaster = false);
    }
  }

  void _calculateTotals() {
    double berat = 0, harga = 0;
    // Hitung item lama
    for (int i = 0; i < widget.setoran.rincianSampah.length; i++) {
      double b = double.tryParse(_weightControllers[i].text.replaceAll(',', '.')) ?? 0;
      berat += b;
      harga += b * widget.setoran.rincianSampah[i].hargaSatuan;
    }
    // Hitung item tambahan
    for (var e in _extraItems) {
      double b = double.tryParse(e['controller'].text.replaceAll(',', '.')) ?? 0;
      berat += b;
      harga += b * (e['harga_satuan'] ?? 0.0);
    }
    setState(() { _totalBeratFinal = berat; _totalHargaFinal = harga; });
  }

  void _addExtraItem() => setState(() => _extraItems.add({
    "jenis_sampah_id": null,
    "harga_satuan": 0.0,
    "controller": TextEditingController(text: "0"),
  }));

  Future<void> _pickImage() async {
    final f = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 50);
    if (f != null) setState(() => _confirmationImage = File(f.path));
  }

  // ─── LOGIC FIX: Penanganan Item Tambahan ─────────────────────────
  void _submitSelesai() async {
    if (_confirmationImage == null) { _showSnack("Wajib foto timbangan sebagai bukti!", Colors.red); return; }
    if (_totalBeratFinal <= 0)      { _showSnack("Berat total tidak boleh 0 kg!", Colors.orange); return; }
    setState(() => _isProcessing = true);

    // GABUNGKAN ITEM LAMA DAN ITEM BARU
    List<Map<String, dynamic>> items = [];

    // 1. Masukkan item yang sudah ada di request awal
    for (int i = 0; i < widget.setoran.rincianSampah.length; i++) {
      items.add({
        "id": widget.setoran.rincianSampah[i].id, // Ini memberitahu Laravel untuk UPDATE
        "berat_aktual": double.tryParse(_weightControllers[i].text.replaceAll(',', '.')) ?? 0
      });
    }

    // 2. Masukkan item tambahan dari driver
    for (var e in _extraItems) {
      if (e['jenis_sampah_id'] != null) {
        double beratEkstra = double.tryParse(e['controller'].text.replaceAll(',', '.')) ?? 0;
        if (beratEkstra > 0) {
          items.add({
            "jenis_sampah_id": e['jenis_sampah_id'], // Ini memberitahu Laravel untuk CREATE baru
            "berat_aktual": beratEkstra
          });
        }
      }
    }

    bool ok = await _pickupService.updateStatusComplete(
      id: widget.setoran.id, 
      status: 'selesai',
      beratFinal: _totalBeratFinal, 
      totalHarga: _totalHargaFinal, // Harga akumulasi yang sudah benar
      metode_pembayaran: _selectedPayment,
      catatan: _noteDriverController.text,
      items: items, 
      foto: _confirmationImage,
    );

    if (mounted) setState(() => _isProcessing = false);
    if (ok && mounted) { 
      Navigator.pop(context, true); 
      _showSnack("Setoran Berhasil Diselesaikan!", Colors.green); 
    }
    else _showSnack("Gagal menyimpan ke server.", Colors.red);
  }

  void _updateStatus(String status) async {
    setState(() => _isProcessing = true);
    bool ok = await _pickupService.updateStatus(widget.setoran.id, status);
    if (mounted) setState(() => _isProcessing = false);
    if (ok && mounted) {
      Navigator.pop(context, true);
      _showSnack("Status diubah ke: ${status.replaceAll('_', ' ')}", Colors.green);
    } else _showSnack("Gagal memperbarui status.", Colors.red);
  }

  // ═══════════════════════════ BUILD ═══════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoadingMaster) return const Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: _primary)));

    final item      = widget.setoran;
    final isProcess = item.status == 'dalam_penjemputan';

    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        const TopNavbar(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 20),
            _header(isProcess),
            _sectionLabel("Informasi Nasabah"),
            _nasabahCard(item),
            _sectionLabel("Input Timbangan"),
            _wasteList(isProcess),
            if (isProcess) ...[
              const SizedBox(height: 8),
              _addExtraBtn(),
              _sectionLabel("Dokumentasi Timbangan"),
              _photoBox(),
              _sectionLabel("Konfirmasi Pembayaran"),
              _paymentSelector(),
            ],
            const SizedBox(height: 24),
            _summaryCard(),
            const SizedBox(height: 20),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator(color: _primary))
            else
              _actionButtons(item),
            const SizedBox(height: 50),
          ]),
        )),
      ]),
    );
  }

  // ─── Widgets Header & Card ────────────────────────────────────────
  Widget _header(bool isProcess) => InkWell(
    onTap: () => Navigator.pop(context),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _dark),
        const SizedBox(width: 10),
        Text(
          isProcess ? "Konfirmasi Berat" : "Detail Pengajuan",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark),
        ),
      ]),
    ),
  );

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(t.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
            color: _muted, letterSpacing: 0.8)),
  );

  Widget _nasabahCard(SetoranModel item) => _card(child: Column(children: [
    _infoRow(Icons.person_outline_rounded,    "Nama Nasabah",  item.nasabahNama),
    _divider(),
    _infoRow(Icons.tag_rounded,               "ID Transaksi",  "#SET-${item.id}", valueColor: _primary),
    _divider(),
    _infoRow(Icons.notes_rounded,             "Catatan Nasabah", item.catatan ?? "-", isLast: true),
  ]));

  Widget _infoRow(IconData icon, String label, String value,
      {bool isLast = false, Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, size: 16, color: _muted),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const Spacer(),
          Text(value, style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13,
              color: valueColor ?? _dark)),
        ]),
      );

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF0F4F8));

  Widget _wasteList(bool isProcess) => Column(children: [
    ...List.generate(widget.setoran.rincianSampah.length, (i) {
      var s = widget.setoran.rincianSampah[i];
      return _wasteCard(s.namaSampah, s.hargaSatuan, _weightControllers[i], isProcess);
    }),
    ...List.generate(_extraItems.length, (i) => _extraWasteCard(i)),
  ]);

  Widget _wasteCard(String name, double harga, TextEditingController ctrl, bool editable) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E6ED), width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.recycling_rounded, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _dark)),
            const SizedBox(height: 2),
            Text("Rp ${NumberFormat('#,###', 'id').format(harga)}/kg",
                style: const TextStyle(fontSize: 11, color: _muted)),
          ])),
          if (editable)
            SizedBox(width: 85, child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateTotals(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _dark),
              decoration: InputDecoration(
                isDense: true, suffixText: " Kg",
                suffixStyle: const TextStyle(color: _muted, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E6ED)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _primary),
                ),
                filled: true, fillColor: _bg,
              ),
            ))
          else
            Text("${ctrl.text} Kg",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _dark)),
        ]),
      );

  Widget _extraWasteCard(int idx) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F1FC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFB5D0F0), width: 0.5),
    ),
    child: Column(children: [
      DropdownButtonFormField<int>(
        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
        hint: const Text("Pilih Sampah Tambahan", style: TextStyle(fontSize: 13, color: _muted)),
        value: _extraItems[idx]['jenis_sampah_id'],
        items: _masterWasteData.map((e) => DropdownMenuItem<int>(
          value: e['id'],
          child: Text("${e['nama']}  (Rp ${e['harga_per_kg']})", style: const TextStyle(fontSize: 13)),
        )).toList(),
        onChanged: (val) {
          var sel = _masterWasteData.firstWhere((x) => x['id'] == val);
          setState(() {
            _extraItems[idx]['jenis_sampah_id'] = val;
            _extraItems[idx]['harga_satuan'] = double.parse(sel['harga_per_kg'].toString());
          });
          _calculateTotals();
        },
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _extraItems[idx]['controller'],
        keyboardType: TextInputType.number,
        onChanged: (_) => _calculateTotals(),
        style: const TextStyle(fontSize: 13, color: _dark),
        decoration: InputDecoration(
          labelText: "Berat (Kg)", isDense: true,
          labelStyle: const TextStyle(color: _muted, fontSize: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFB5D0F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primary),
          ),
        ),
      ),
    ]),
  );

  Widget _addExtraBtn() => TextButton.icon(
    onPressed: _addExtraItem,
    icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: _primary),
    label: const Text("Tambah Jenis Sampah Baru",
        style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 13)),
  );

  Widget _photoBox() => GestureDetector(
    onTap: _pickImage,
    child: Container(
      width: double.infinity, height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _confirmationImage == null ? const Color(0xFFAAC4E0) : _primary,
          width: _confirmationImage == null ? 1 : 1.5,
        ),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.05), blurRadius: 8)],
      ),
      child: _confirmationImage == null
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.add_a_photo_outlined, size: 36, color: Color(0xFFAAC4E0)),
              SizedBox(height: 8),
              Text("Ketuk untuk foto timbangan",
                  style: TextStyle(color: _hint, fontSize: 12)),
            ])
          : ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_confirmationImage!, fit: BoxFit.cover, width: double.infinity)),
    ),
  );

  Widget _paymentSelector() => Row(children: [
    _payBtn("saldo", "SALDO"),
    _payBtn("cash", "TUNAI"),
    _payBtn("transfer", "BANK"),
  ]);

  Widget _payBtn(String val, String label) {
    final active = _selectedPayment == val;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _selectedPayment = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _primary : const Color(0xFFE0E6ED), width: 0.5),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: active ? Colors.white : _muted,
                fontWeight: FontWeight.w800, fontSize: 12)),
      ),
    ));
  }

  Widget _summaryCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1B3D5F),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(children: [
      _sumRow("Total Berat Aktual", "${_totalBeratFinal.toStringAsFixed(2)} Kg"),
      const SizedBox(height: 8),
      _sumRow("Total Pendapatan Nasabah",
          "Rp ${NumberFormat('#,###', 'id').format(_totalHargaFinal)}", big: true),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Divider(color: Colors.white24, height: 1),
      ),
      TextField(
        controller: _noteDriverController,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(
          hintText: "Catatan driver (opsional)",
          hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
          border: InputBorder.none, isDense: true,
        ),
      ),
    ]),
  );

  Widget _sumRow(String label, String value, {bool big = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(value, style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700,
            fontSize: big ? 20 : 14)),
      ]);

  Widget _actionButtons(SetoranModel item) => Column(children: [
    if (item.status == 'dijadwalkan')
      _primaryBtn("KONFIRMASI MULAI JALAN", _primary,
          () => _updateStatus('dalam_penjemputan')),
    if (item.status == 'dalam_penjemputan')
      _primaryBtn("SIMPAN & SELESAIKAN", Colors.green, _submitSelesai),
    const SizedBox(height: 10),
    _outlineBtn("BATALKAN PERMINTAAN", Colors.red, _showCancelDialog),
  ]);

  Widget _primaryBtn(String label, Color color, VoidCallback onTap) =>
      SizedBox(width: double.infinity, height: 54,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 14, letterSpacing: 0.4)),
        ),
      );

  Widget _outlineBtn(String label, Color color, VoidCallback onTap) =>
      SizedBox(width: double.infinity, height: 54,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
        color: _primary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  void _showSnack(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m), backgroundColor: c));

  void _showCancelDialog() => showDialog(
    context: context,
    builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Batalkan permintaan?",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
      content: const Text("Tindakan ini tidak dapat diurungkan.",
          style: TextStyle(color: _muted, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c),
            child: const Text("TIDAK", style: TextStyle(color: _muted))),
        TextButton(onPressed: () { Navigator.pop(c); _updateStatus('dibatalkan'); },
            child: const Text("YA, BATALKAN",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
      ],
    ),
  );
}