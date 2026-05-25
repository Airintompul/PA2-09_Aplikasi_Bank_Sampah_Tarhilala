<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PenukaranReward extends Model
{
    use HasFactory;

    protected $table = 'penukaran_reward';

    public $timestamps = false;

    // TAMBAHKAN KOLOM BARU DI SINI
    protected $fillable = [
        'user_id',
        'reward_id',
        'jumlah',
        'poin_digunakan',
        'status',
        'lokasi_lat',
        'lokasi_lng',
        'alamat_pengiriman',
        'catatan',
        'tanggal_penukaran'
    ];

    // Relasi ke User
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Relasi ke Reward
    public function reward()
    {
        return $this->belongsTo(Reward::class);
    }
}
