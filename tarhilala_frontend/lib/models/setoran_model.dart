import 'dart:convert';

class SetoranModel {
  final int id;
  final int nasabahId;
  final int? jadwalId;
  final String tanggalPengajuan;
  final String status;
  final double? totalBerat; // Di SQL: total_berat DECIMAL(10,2)
  final double? totalHarga;
  final String metodePembayaran; // Di SQL: total_harga DECIMAL(12,2)
  final String? catatan;
  final String? createdAt;

  // Field tambahan dari Relasi (JOIN)
  final String nasabahNama; // Dari tabel users
  final String? hasilAi;    // Dari tabel validasi (hasil_ai)
  final double? confidenceScore; // Dari tabel validasi (confidence_score)
  
  // Rincian Item Sampah (Relasi ke tabel detail_setoran)
  final List<DetailSetoranModel> rincianSampah;

  SetoranModel({
    required this.id,
    required this.nasabahId,
    this.jadwalId,
    required this.tanggalPengajuan,
    required this.status,
    this.totalBerat,
    this.totalHarga,
    this.catatan,
    this.createdAt,
    required this.nasabahNama,
    this.hasilAi,
    required this.metodePembayaran,
    this.confidenceScore,
    required this.rincianSampah,
  });

  factory SetoranModel.fromJson(Map<String, dynamic> json) {
    // Parsing List Detail Setoran dari JSON
    var listDetail = json['details'] as List? ?? [];
    List<DetailSetoranModel> rincianParsed = 
        listDetail.map((i) => DetailSetoranModel.fromJson(i)).toList();

    return SetoranModel(
      id: json['id'] ?? 0,
      nasabahId: json['nasabah_id'] ?? 0,
      jadwalId: json['jadwal_id'],
      tanggalPengajuan: json['tanggal_pengajuan'] ?? '',
      status: json['status'] ?? 'menunggu',
      
      totalBerat: json['total_berat'] != null ? double.parse(json['total_berat'].toString()) : null,
      totalHarga: json['total_harga'] != null ? double.parse(json['total_harga'].toString()) : null,
      
      catatan: json['catatan'],
      createdAt: json['created_at'],

      nasabahNama: json['nasabah'] != null ? json['nasabah']['nama'] : "Nasabah",

      metodePembayaran: json['metode_pembayaran'] ?? 'saldo',

      hasilAi: json['ai_validation'] != null ? json['ai_validation']['ai_class'] : null,
      confidenceScore: json['ai_validation'] != null 
          ? double.parse(json['ai_validation']['ai_confidence'].toString()) 
          : null,
          
      rincianSampah: rincianParsed,
    );
  }

  static List<SetoranModel> fromList(List<dynamic> list) {
    return list.map((item) => SetoranModel.fromJson(item)).toList();
  }
}

// Class baru untuk menampung data dari tabel detail_setoran
class DetailSetoranModel {
  final int id;
  final int jenisSampahId;
  final String namaSampah; // Diambil dari relasi ke tabel jenis_sampah
  final double berat;
  final double hargaSatuan;
  final double subtotal;

  DetailSetoranModel({
    required this.id,
    required this.jenisSampahId,
    required this.namaSampah,
    required this.berat,
    required this.hargaSatuan,
    required this.subtotal,
  });

  factory DetailSetoranModel.fromJson(Map<String, dynamic> json) {
    return DetailSetoranModel(
      id: json['id'] ?? 0,
      jenisSampahId: json['jenis_sampah_id'] ?? 0,
      // Mengambil nama sampah dari relasi 'jenis_sampah' di Laravel
      namaSampah: json['jenis_sampah'] != null ? json['jenis_sampah']['nama'] : "Sampah",
      berat: double.parse(json['berat'].toString()),
      hargaSatuan: double.parse(json['harga_satuan'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}

class DetailItemSampah {
  final int id; // ID detail_setoran
  final String namaSampah;
  final double estimasiBerat;
  double hargaSatuan; // Jadikan non-final agar bisa diubah

  DetailItemSampah({required this.id, required this.namaSampah, required this.estimasiBerat, required this.hargaSatuan});

  factory DetailItemSampah.fromJson(Map<String, dynamic> json) {
    return DetailItemSampah(
      id: json['id'],
      namaSampah: json['jenis_sampah']['nama'],
      estimasiBerat: double.parse(json['berat'].toString()),
      hargaSatuan: double.parse(json['harga_satuan'].toString()),
    );
  }
}