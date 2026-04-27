<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Setoran extends Model
{
    protected $table = 'setoran';
    protected $fillable = [
        'nasabah_id', 'jadwal_id', 'estimasi_berat', 'berat_final',
        'total_harga', 'metode_pembayaran', 'lokasi_lat', 'lokasi_lng',
        'status', 'catatan', 'tanggal_pengajuan'
    ];
    public $timestamps = false; // Karena tabel setoran tidak punya updated_at

    // Relasi ke detail (opsional tapi berguna)
    public function details() {
        return $this->hasMany(DetailSetoran::class, 'setoran_id');
    }

    public function nasabah() {
        return $this->belongsTo(User::class, 'nasabah_id');
    }

    public function aiValidation()
    {
        return $this->hasOne(AiValidation::class, 'setoran_id');
    }

    public function jadwal()
    {
        return $this->belongsTo(JadwalPenjemputan::class, 'jadwal_id');
    }
}
