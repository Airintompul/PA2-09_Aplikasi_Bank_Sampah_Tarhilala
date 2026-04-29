<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DetailSetoran extends Model
{
    protected $table = 'detail_setoran';

    protected $fillable = [
        'setoran_id',
        'jenis_sampah_id',
        'berat',
        'harga_satuan',
        'subtotal'
    ];

    public $timestamps = false;

    // RELASI INI YANG HILANG DAN HARUS DITAMBAHKAN
    public function jenisSampah()
    {
        // Menghubungkan ke tabel jenis_sampah menggunakan kolom jenis_sampah_id
        return $this->belongsTo(JenisSampah::class, 'jenis_sampah_id');
    }

    public function setoran()
    {
        return $this->belongsTo(Setoran::class, 'setoran_id');
    }
}
