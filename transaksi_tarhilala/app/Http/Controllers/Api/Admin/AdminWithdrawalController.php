<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\{Penarikan, Wallet, WalletTransaction};
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class AdminWithdrawalController extends Controller {

    public function index() {
        // Ambil semua request penarikan terbaru
        $data = Penarikan::orderBy('tanggal_pengajuan', 'desc')->get();
        return response()->json(['status' => 'success', 'data' => $data]);
    }

    public function update(Request $request, $id) {
        return DB::transaction(function() use ($request, $id) {
            $penarikan = Penarikan::findOrFail($id);

            // Proteksi: Jika transaksi sudah final (selesai/ditolak), jangan diubah lagi
            if ($penarikan->status == 'selesai' || $penarikan->status == 'ditolak') {
                return response()->json(['message' => 'Transaksi ini sudah bersifat final'], 400);
            }

            // =============================================================
            // LOGIKA 1: JIKA ADMIN MENYETUJUI (SELESAI) + UPLOAD BUKTI
            // =============================================================
            if ($request->status == 'selesai') {
                // Driver/Admin Wajib menyertakan bukti transfer gambar
                if (!$request->hasFile('bukti_transfer')) {
                    return response()->json(['message' => 'Bukti transfer wajib diunggah untuk status selesai'], 422);
                }

                $file = $request->file('bukti_transfer');
                $nama_file = time() . "_bukti_wd_" . $id . "." . $file->getClientOriginalExtension();

                // Simpan ke folder public/uploads/bukti_transfer agar bisa diakses URL oleh Flutter
                $tujuan_upload = public_path('uploads/bukti_transfer');
                $file->move($tujuan_upload, $nama_file);

                // Update kolom bukti_transfer di database
                $penarikan->bukti_transfer = 'uploads/bukti_transfer/' . $nama_file;
            }

            // =============================================================
            // LOGIKA 2: JIKA ADMIN MENOLAK (DITOLAK) -> REFUND SALDO
            // =============================================================
            if ($request->status == 'ditolak') {
                $wallet = Wallet::where('user_id', $penarikan->user_id)
                                ->where('account_type', 'saldo')
                                ->first();

                // Kembalikan dana yang di-hold (Increment)
                if ($wallet) {
                    $wallet->increment('current_balance', $penarikan->jumlah);

                    // Catat riwayat pengembalian di mutasi wallet
                    WalletTransaction::create([
                        'account_id' => $wallet->id,
                        'amount' => $penarikan->jumlah,
                        'direction' => 'credit',
                        'reference_table' => 'penarikan',
                        'reference_data_id' => $penarikan->id,
                        'description' => "Dana dikembalikan: Penarikan ditolak oleh Admin"
                    ]);
                }
            }

            // Update Status Akhir
            $penarikan->status = $request->status;
            $penarikan->save();

            return response()->json([
                'status' => 'success',
                'message' => 'Status Updated. Transaksi ' . $request->status . ' berhasil diproses.'
            ]);
        });
    }
    public function getFinanceStats()
{
    // Menghitung total saldo seluruh nasabah dari tabel wallet
    $totalSaldo = Wallet::where('account_type', 'saldo')->sum('current_balance');

    return response()->json([
        'status' => 'success',
        'data' => [
            'total_saldo' => $totalSaldo
        ]
    ], 200);
}
}
