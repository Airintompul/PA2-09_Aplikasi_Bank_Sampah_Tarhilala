<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WalletTransaction extends Model
{
    protected $table = 'wallet_transaction';
    protected $fillable = ['account_id', 'amount', 'direction', 'reference_table', 'reference_data_id', 'description'];
    // Menggunakan timestamps default
}
