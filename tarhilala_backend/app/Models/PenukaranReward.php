<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PenukaranReward extends Model
{
    protected $table = 'penukaran_reward';
    protected $fillable = ['user_id', 'reward_id', 'poin_digunakan', 'status', 'tanggal_penukaran'];
    public $timestamps = false;

    public function reward()
    {
        // Menghubungkan ke model Reward menggunakan kolom reward_id
        return $this->belongsTo(Reward::class, 'reward_id');
    }
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
