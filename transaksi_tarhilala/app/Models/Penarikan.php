<?php


namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Penarikan extends Model {
    protected $table = 'penarikan';
    protected $fillable = [
        'user_id',
        'jumlah',
        'metode',
        'nomor_tujuan',  // PASTIKAN ADA
        'nama_penerima', // PASTIKAN ADA
        'status',
        'bukti_transfer',
        'tanggal_pengajuan'
    ];

    public $timestamps = false;
}
