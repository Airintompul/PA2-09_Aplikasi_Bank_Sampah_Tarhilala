import 'dart:convert';

class SetoranModel {
  final int id;
  final int nasabahId;
  final int? jadwalId;
  final String tanggalPengajuan;
  final String status;
  final double? totalBerat; 
  final double? totalHarga;
  final String metodePembayaran; 
  final String? catatan;
  final String? createdAt;

  // Field tambahan dari Relasi (JOIN)
  final String nasabahNama; 
  final String? alamat; 
  final String? lat;    
  final String? lng;    
  final String? hasilAi;    
  final double? confidenceScore; 
  
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
    this.alamat,
    this.lat,
    this.lng,
    this.hasilAi,
    required this.metodePembayaran,
    this.confidenceScore,
    required this.rincianSampah,
  });

  factory SetoranModel.fromJson(Map<String, dynamic> json) {
    var listDetail = json['details'] as List? ?? [];
    List<DetailSetoranModel> rincianParsed = 
        listDetail.map((i) => DetailSetoranModel.fromJson(i)).toList();

    return SetoranModel(
      id: json['id'] ?? 0,
      nasabahId: json['nasabah_id'] ?? 0,
      jadwalId: json['jadwal_id'],
      tanggalPengajuan: json['tanggal_pengajuan'] ?? '',
      status: json['status'] ?? 'menunggu',
      
      // --- PERBAIKAN LOGIKA BERAT DI SINI ---
      // Jika berat_final ada (sudah selesai), pakai itu. 
      // Jika tidak ada, coba pakai estimasi_berat.
      totalBerat: json['berat_final'] != null 
          ? double.parse(json['berat_final'].toString()) 
          : (json['estimasi_berat'] != null 
              ? double.parse(json['estimasi_berat'].toString()) 
              : 0.0),
      // --------------------------------------

      totalHarga: json['total_harga'] != null ? double.parse(json['total_harga'].toString()) : 0.0,
      
      catatan: json['catatan'],
      createdAt: json['created_at'],
      metodePembayaran: json['metode_pembayaran'] ?? 'saldo',

      nasabahNama: json['nasabah'] != null ? json['nasabah']['nama'] : "Nasabah",
      lat: json['lokasi_lat']?.toString(), 
      lng: json['lokasi_lng']?.toString(),
      alamat: null, 

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

class DetailSetoranModel {
  final int id;
  final int jenisSampahId;
  final String namaSampah; 
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
      namaSampah: json['jenis_sampah'] != null ? json['jenis_sampah']['nama'] : "Sampah",
      berat: double.parse(json['berat'].toString()),
      hargaSatuan: double.parse(json['harga_satuan'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}