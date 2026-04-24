<?php

namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class WalletTransaction extends Model {
    protected $table = 'wallet_transaction';
    protected $fillable = ['account_id', 'amount', 'direction', 'reference_table', 'reference_data_id', 'description'];

    public function wallet() {
        return $this->belongsTo(Wallet::class, 'account_id');
    }
}
