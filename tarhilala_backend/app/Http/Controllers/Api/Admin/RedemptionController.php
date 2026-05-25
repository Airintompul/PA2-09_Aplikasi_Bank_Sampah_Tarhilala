<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\PenukaranReward;
use App\Models\Reward;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class RedemptionController extends Controller
{
    public function index()
    {
        try {
            // Mengambil data penukaran dengan relasi user dan reward
            $data = PenukaranReward::with(['user', 'reward'])
                    ->orderBy('tanggal_penukaran', 'desc')
                    ->get();

            return response()->json([
                'status' => 'success',
                'data'   => $data
            ], 200);

        } catch (\Exception $e) {
            // Jika error, kirim pesan errornya agar bisa dibaca di console browser
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }

public function updateStatus(Request $request, $id)
{
    $request->validate([
        'status' => 'required|in:menunggu,diproses,dikirim,selesai,ditolak'
    ]);

    // Gunakan Transaction agar jika gagal refund, status di DB tidak berubah
        return DB::transaction(function () use ($request, $id) {
            $penukaran = PenukaranReward::findOrFail($id);

            // --- LOGIKA REFUND POIN ---
            // Jika status baru adalah 'ditolak' DAN status sebelumnya BUKAN 'ditolak'
            if ($request->status === 'ditolak' && $penukaran->status !== 'ditolak') {

                // Panggil Server Finance (8001) untuk tambah saldo poin
                $response = Http::withHeaders([
                    'X-Internal-Key' => env('INTERNAL_API_KEY', 'TarhilalaSecretFinanceKey2024'),
                    'Accept'         => 'application/json'
                ])->post('http://127.0.0.1:8001/api/internal/add-balance', [
                    'user_id'           => $penukaran->user_id,
                    'amount'            => $penukaran->poin_digunakan, // Ambil jumlah poin yang tadi dipotong
                    'account_type'      => 'poin', // Penting: tipenya adalah poin
                    'reference_table'   => 'penukaran_reward',
                    'reference_data_id' => $penukaran->id,
                    'description'       => "Refund: Penukaran reward #{$penukaran->id} ditolak Admin"
                ]);

                if ($response->failed()) {
                    throw new \Exception("Gagal mengembalikan poin ke server keuangan.");
                }

                // Kembalikan stok barang karena transaksi batal
                $reward = Reward::find($penukaran->reward_id);
                if ($reward) {
                    $reward->increment('stok', $penukaran->jumlah);
                }
            }

            // Simpan perubahan status
            $penukaran->status = $request->status;
            $penukaran->save();

            return response()->json([
                'status' => 'success',
                'message' => 'Status diperbarui' . ($request->status == 'ditolak' ? ' & Poin dikembalikan' : '')
            ]);
        });
    }
}
