<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class PoinLog extends Model {
    protected $table = 'poin_log';
    protected $fillable = ['user_id', 'poin', 'source_type', 'source_id'];
    public $timestamps = false;
}
