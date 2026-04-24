<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\{Penarikan, Wallet, WalletTransaction};
use Illuminate\Support\Facades\DB;

class AdminWithdrawalController extends Controller {

    public function index() {
        // Ambil semua request penarikan terbaru
        $data = Penarikan::orderBy('tanggal_pengajuan', 'desc')->get();
        return response()->json(['status' => 'success', 'data' => $data]);
    }

    public function update(Request $request, $id) {
        return DB::transaction(function() use ($request, $id) {
            $penarikan = Penarikan::findOrFail($id);

            // Jika status dirubah ke SELESAI, potong saldo wallet nasabah
            if($request->status == 'selesai' && $penarikan->status != 'selesai') {
                $wallet = Wallet::where('user_id', $penarikan->user_id)
                                ->where('account_type', 'saldo')
                                ->first();

                if(!$wallet || $wallet->current_balance < $penarikan->jumlah) {
                    return response()->json(['message' => 'Saldo tidak cukup'], 400);
                }

                // Potong Saldo
                $wallet->decrement('current_balance', $penarikan->jumlah);

                // Catat Mutasi Debit (Keluar)
                WalletTransaction::create([
                    'account_id' => $wallet->id,
                    'amount' => $penarikan->jumlah,
                    'direction' => 'debit',
                    'reference_table' => 'penarikan',
                    'reference_data_id' => $penarikan->id,
                    'description' => "Penarikan Saldo via " . $penarikan->metode
                ]);
            }

            $penarikan->update(['status' => $request->status]);
            return response()->json(['status' => 'success', 'message' => 'Status Updated']);
        });
    }
}
