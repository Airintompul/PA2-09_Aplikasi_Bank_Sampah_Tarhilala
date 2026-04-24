<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\{Wallet, WalletTransaction};
use Illuminate\Support\Facades\DB;

class InternalFinanceController extends Controller {
    public function addBalance(Request $request) {
        // Cek API Key Rahasia agar tidak bisa ditembak sembarangan
        if($request->header('X-Internal-Key') !== env('INTERNAL_API_KEY')) {
            return response()->json(['message' => 'Unauthorized Access'], 403);
        }

        return DB::transaction(function() use ($request) {
            // Ambil atau buat wallet saldo nasabah
            $wallet = Wallet::firstOrCreate(
                ['user_id' => $request->user_id, 'account_type' => 'saldo']
            );

            // 1. Tambah Balance Utama
            $wallet->increment('current_balance', $request->amount);

            // 2. Catat Mutasi Kredit (Masuk)
            WalletTransaction::create([
                'account_id' => $wallet->id,
                'amount' => $request->amount,
                'direction' => 'credit',
                'reference_table' => 'setoran',
                'reference_data_id' => $request->setoran_id,
                'description' => "Hasil setoran sampah #" . $request->setoran_id
            ]);

            return response()->json(['status' => 'success', 'balance' => $wallet->current_balance]);
        });
    }

    public function deductPoints(Request $request) {
    // Security Check
    if($request->header('X-Internal-Key') !== env('INTERNAL_API_KEY')) {
        return response()->json(['message' => 'Forbidden'], 403);
    }

    return DB::transaction(function() use ($request) {
        // Cari dompet poin milik nasabah
        $wallet = Wallet::where('user_id', $request->user_id)
                        ->where('account_type', 'poin')
                        ->first();

        // Cek kecukupan poin
        if (!$wallet || $wallet->current_balance < $request->points) {
            return response()->json(['message' => 'Poin Anda tidak cukup'], 400);
        }

        // Potong Poin
        $wallet->decrement('current_balance', $request->points);

        // Catat mutasi poin (debit)
        WalletTransaction::create([
            'account_id' => $wallet->id,
            'amount' => $request->points,
            'direction' => 'debit',
            'description' => $request->description
        ]);

        return response()->json(['status' => 'success', 'message' => 'Poin dipotong']);
    });
}
}
