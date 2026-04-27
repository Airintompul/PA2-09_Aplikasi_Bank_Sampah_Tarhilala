<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaksi extends Model
{
    protected $table = 'transaksi';
    protected $fillable = ['user_id', 'reference_table', 'reference_data_id', 'jumlah', 'metode_pembayaran', 'status'];
    // Tabel ini biasanya pakai timestamps default
}
