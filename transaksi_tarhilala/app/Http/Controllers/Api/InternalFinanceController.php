<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\{Wallet, WalletTransaction, Transaksi, Penarikan};
use Illuminate\Support\Facades\DB;

class InternalFinanceController extends Controller {

    /**
     * Menambahkan Saldo atau Poin ke Wallet Nasabah (Dinamis)
     */
    public function addBalance(Request $request) {
        if($request->header('X-Internal-Key') !== env('INTERNAL_API_KEY')) {
            return response()->json(['message' => 'Unauthorized Access'], 403);
        }

        return DB::transaction(function() use ($request) {
            $type = $request->account_type ?? 'saldo';

            // Catat ke Tabel Transaksi Utama jika itu SALDO (UANG)
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

            $wallet = Wallet::firstOrCreate(
                ['user_id' => $request->user_id, 'account_type' => $type]
            );

            $wallet->increment('current_balance', $request->amount);

            WalletTransaction::create([
                'account_id'        => $wallet->id,
                'amount'            => $request->amount,
                'direction'         => 'credit',
                'reference_table'   => 'setoran',
                'reference_data_id' => $request->setoran_id,
                'description'       => "Penambahan " . ucfirst($type) . " dari setoran #" . $request->setoran_id
            ]);

            return response()->json(['status' => 'success', 'message' => ucfirst($type) . ' updated']);
        });
    }

    /**
     * Mengambil Jumlah Saldo/Poin Aktif
     */
    public function getBalance(Request $request, $user_id) {
        $type = $request->query('type', 'saldo');
        $wallet = Wallet::where('user_id', $user_id)->where('account_type', $type)->first();

        return response()->json([
            'status'  => 'success',
            'type'    => $type,
            'balance' => $wallet ? $wallet->current_balance : 0
        ]);
    }

    /**
     * Memotong Poin Nasabah (Reward Redemption)
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

            // PERBAIKAN DI SINI: Masukkan reference_table dan reference_data_id
            WalletTransaction::create([
                'account_id'        => $wallet->id,
                'amount'            => $request->points,
                'direction'         => 'debit',
                'reference_table'   => $request->reference_table, // Diambil dari input
                'reference_data_id' => $request->reference_data_id, // Diambil dari input
                'description'       => $request->description ?? 'Penukaran reward'
            ]);

            return response()->json(['status' => 'success', 'message' => 'Poin dipotong']);
        });
    }

    public function addWithdrawalRequest(Request $request) {
        if($request->header('X-Internal-Key') !== env('INTERNAL_API_KEY')) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        return DB::transaction(function() use ($request) {
            $wallet = Wallet::where('user_id', $request->user_id)->where('account_type', 'saldo')->first();

            if (!$wallet || $wallet->current_balance < $request->jumlah) {
                return response()->json(['message' => 'Saldo tidak mencukupi'], 400);
            }

            // Potong saldo langsung (HOLD DANA)
            $wallet->decrement('current_balance', $request->jumlah);

            $penarikan = Penarikan::create([
                'user_id' => $request->user_id,
                'jumlah' => $request->jumlah,
                'metode' => $request->metode,
                'nomor_tujuan' => $request->nomor_tujuan,
                'nama_penerima' => $request->nama_penerima,
                'status' => 'menunggu',
                'tanggal_pengajuan' => now()
            ]);

            WalletTransaction::create([
                'account_id' => $wallet->id,
                'amount' => $request->jumlah,
                'direction' => 'debit',
                'reference_table' => 'penarikan',
                'reference_data_id' => $penarikan->id,
                'description' => "Penarikan (Hold) via " . $request->metode
            ]);

            return response()->json(['status' => 'success', 'data' => $penarikan], 201);
        });
    }

public function updateWithdrawalStatus(Request $request, $id) {
    return DB::transaction(function() use ($request, $id) {
        $penarikan = Penarikan::findOrFail($id);

        if ($request->status === 'selesai') {
            // TERIMA FILE DARI SERVER 8000
            if ($request->hasFile('bukti_transfer')) {
                $file = $request->file('bukti_transfer');
                $path = $file->store('bukti_transfer', 'public');

                // SIMPAN PATH KE DATABASE
                $penarikan->bukti_transfer = $path;
            }
        } else if ($request->status === 'ditolak') {
            // Refund saldo jika ditolak
            $wallet = Wallet::where('user_id', $penarikan->user_id)->where('account_type', 'saldo')->first();
            $wallet->increment('current_balance', $penarikan->jumlah);
        }

        $penarikan->status = $request->status;
        $penarikan->save();

        return response()->json(['status' => 'success']);
    });
}

    public function withdrawalHistory($user_id)
    {
        try {
            // SESUAIKAN: Jika di tabel namanya 'user_id', pakai 'user_id'
            $data = \App\Models\Penarikan::where('user_id', $user_id)
                    ->orderBy('tanggal_pengajuan', 'desc')
                    ->get();

            return response()->json([
                'status' => 'success', // Ganti ke success
                'data'   => $data
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
                'data' => []
            ], 500);
        }
    }
}
