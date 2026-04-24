<?php


namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Penarikan extends Model {
    protected $table = 'penarikan';
    protected $fillable = ['user_id', 'jumlah', 'metode', 'status', 'tanggal_pengajuan'];
}
