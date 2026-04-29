<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PenukaranReward extends Model
{
    protected $table = 'penukaran_reward';
    protected $fillable = ['user_id', 'reward_id', 'poin_digunakan', 'status', 'tanggal_penukaran'];
    public $timestamps = false;
}
