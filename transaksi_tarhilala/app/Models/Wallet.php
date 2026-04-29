<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Wallet extends Model {
    protected $table = 'wallet';
    protected $fillable = ['user_id', 'account_type', 'current_balance'];

    public $timestamps = false;

    public function transactions() {
        return $this->hasMany(WalletTransaction::class, 'account_id');
    }
}
