<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GpsLog extends Model
{
    use HasFactory;

    protected $table = 'gps_logs';
    public $timestamps = false; // Karena kita menggunakan recorded_at

    protected $fillable = [
        'petugas_id',
        'latitude',
        'longitude',
        'recorded_at'
    ];

    protected $casts = [
        'recorded_at' => 'datetime'
    ];

    public function petugas()
    {
        return $this->belongsTo(User::class, 'petugas_id');
    }
}
