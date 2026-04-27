<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Invoice extends Model
{
    protected $table = 'invoice';
    protected $fillable = ['setoran_id', 'nomor_invoice', 'total_bayar', 'file_invoice', 'tanggal_invoice'];
    public $timestamps = false;
}
