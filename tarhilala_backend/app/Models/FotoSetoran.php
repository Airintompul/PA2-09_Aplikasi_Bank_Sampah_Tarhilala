<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FotoSetoran extends Model
{
    protected $table = 'foto_setoran';
    protected $fillable = ['setoran_id', 'image_path'];
    public $timestamps = false;
}
