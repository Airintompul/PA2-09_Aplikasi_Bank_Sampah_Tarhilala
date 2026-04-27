<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DetailSetoran extends Model
{
    protected $table = 'detail_setoran';
    protected $fillable = ['setoran_id', 'jenis_sampah_id', 'berat', 'harga_satuan', 'subtotal'];
    public $timestamps = false;

    public function setoran() {
        return $this->belongsTo(Setoran::class);
    }
}
