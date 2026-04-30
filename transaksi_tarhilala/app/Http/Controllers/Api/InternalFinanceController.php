<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\{Wallet, WalletTransaction, Transaksi};
use Illuminate\Support\Facades\DB;

class InternalFinanceController extends Controller {

    /**
     * Menambahkan Saldo atau Poin ke Wallet Nasabah
     */
    public function addBalance(Request $request) {
        // 1. Keamanan API Key Internal
        if($request->header('X-Internal-Key') !== env('INTERNAL_API_KEY')) {
            return response()->json(['message' => 'Unauthorized Access'], 403);
        }

        return DB::transaction(function() use ($request) {

            // 2. Ambil tipe akun secara dinamis (saldo atau poin)
            $type = $request->account_type ?? 'saldo';

            // 3. Jika tipenya SALDO (UANG), catat di tabel riwayat transaksi utama
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

            // 4. Cari atau buat Brankas (Wallet) yang sesuai dengan user dan tipenya
            $wallet = Wallet::firstOrCreate(
                ['user_id' => $request->user_id, 'account_type' => $type]
            );

            // 5. Tambahkan nilai ke kolom current_balance
            $wallet->increment('current_balance', $request->amount);

            // 6. Catat Mutasi Detail Wallet agar riwayat keluar masuknya tercatat
            WalletTransaction::create([
                'account_id'        => $wallet->id,
                'amount'            => $request->amount,
                'direction'         => 'credit',
                'reference_table'   => 'setoran',
                'reference_data_id' => $request->setoran_id,
                'description'       => "Penambahan " . ucfirst($type) . " dari setoran #" . $request->setoran_id
            ]);

            return response()->json([
                'status'  => 'success',
                'message' => ucfirst($type) . ' berhasil diperbarui',
                'new_balance' => $wallet->current_balance
            ]);
        });
    }

    /**
     * Mengambil Jumlah Saldo/Poin Aktif
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
     * Memotong Poin Nasabah
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
