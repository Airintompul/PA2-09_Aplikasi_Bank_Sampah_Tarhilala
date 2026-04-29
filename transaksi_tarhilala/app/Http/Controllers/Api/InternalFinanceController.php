<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\{Wallet, WalletTransaction, Transaksi};
use Illuminate\Support\Facades\DB;

class InternalFinanceController extends Controller {

    /**
     * Menambahkan Saldo/Poin ke Wallet Nasabah & Mencatat Transaksi
     */
    public function addBalance(Request $request) {
        // 1. Security Check (API Key Internal)
        if($request->header('X-Internal-Key') !== env('INTERNAL_API_KEY')) {
            return response()->json(['message' => 'Unauthorized Access'], 403);
        }

        return DB::transaction(function() use ($request) {

            // PERBAIKAN: Ambil tipe akun secara dinamis (default ke 'saldo' jika tidak dikirim)
            $type = $request->account_type ?? 'saldo';

            // 2. Catat ke Tabel Transaksi Utama (Hanya jika tipe-nya adalah SALDO UANG)
            if ($type == 'saldo') {
                Transaksi::create([
                    'user_id'           => $request->user_id,
                    'reference_table'   => 'setoran',
                    'reference_data_id' => $request->setoran_id,
                    'jumlah'            => $request->amount,
                    'metode_pembayaran' => $request->metode_pembayaran ?? 'saldo',
                    'status'            => ($request->metode_pembayaran == 'cash') ? 'berhasil' : 'menunggu',
                ]);
            }

            // 3. Update Wallet (Mendukung Saldo atau Poin secara dinamis)
            // Sistem akan mencari wallet berdasarkan user_id DAN account_type
            $wallet = Wallet::firstOrCreate(
                ['user_id' => $request->user_id, 'account_type' => $type]
            );

            // Tambah angka ke kolom current_balance (bisa berupa Rupiah atau jumlah Poin)
            $wallet->increment('current_balance', $request->amount);

            // 4. Catat Mutasi Detail Wallet (wallet_transaction) untuk audit
            WalletTransaction::create([
                'account_id'        => $wallet->id,
                'amount'            => $request->amount,
                'direction'         => 'credit',
                'reference_table'   => 'setoran',
                'reference_data_id' => $request->setoran_id,
                'description'       => "Penambahan $type dari setoran #" . $request->setoran_id
            ]);

            return response()->json([
                'status'  => 'success',
                'message' => ucfirst($type) . ' berhasil diperbarui'
            ]);
        });
    }

    /**
     * Mengambil Jumlah Saldo/Poin Aktif Nasabah
     * Gunakan query param ?type=poin untuk mengambil poin
     */
    public function getBalance(Request $request, $user_id) {
        $type = $request->query('type', 'saldo');

        $wallet = Wallet::where('user_id', $user_id)
                        ->where('account_type', $type)
                        ->first();

        return response()->json([
            'status'  => 'success',
            'type'    => $type,
            'balance' => $wallet ? $wallet->current_balance : 0
        ]);
    }

    /**
     * Memotong Poin Nasabah (Digunakan saat Tukar Reward)
     */
    public function deductPoints(Request $request) {
        if($request->header('X-Internal-Key') !== env('INTERNAL_API_KEY')) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return DB::transaction(function() use ($request) {
            $wallet = Wallet::where('user_id', $request->user_id)
                            ->where('account_type', 'poin')
                            ->first();

            if (!$wallet || $wallet->current_balance < $request->points) {
                return response()->json(['message' => 'Poin Anda tidak cukup'], 400);
            }

            $wallet->decrement('current_balance', $request->points);

            WalletTransaction::create([
                'account_id'  => $wallet->id,
                'amount'      => $request->points,
                'direction'   => 'debit',
                'description' => $request->description ?? 'Penukaran reward'
            ]);

            return response()->json(['status' => 'success', 'message' => 'Poin berhasil dipotong']);
        });
    }
}
