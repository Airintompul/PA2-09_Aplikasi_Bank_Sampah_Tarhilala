<?php

namespace App\Http\Controllers\Api\Nasabah;

use App\Http\Controllers\Controller;
use App\Models\Reward;
use App\Models\PenukaranReward;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class RedeemController extends Controller
{
    public function redeem(Request $request)
    {
        // 1. Validasi Input (Sekarang mendukung jumlah penukaran)
        $request->validate([
            'reward_id' => 'required|exists:reward,id',
            'jumlah'    => 'required|integer|min:1'
        ]);

        $reward = Reward::findOrFail($request->reward_id);
        $user = auth()->user();

        // Hitung total poin yang dibutuhkan
        $totalPoinDibutuhkan = $reward->poin_dibutuhkan * $request->jumlah;

        // 2. Cek stok reward di Database Lokal
        if ($reward->stok < $request->jumlah) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Maaf, stok tidak mencukupi. Tersisa: ' . $reward->stok
            ], 400);
        }

        // Gunakan Transaction agar jika salah satu gagal, semua dibatalkan
        return DB::transaction(function () use ($reward, $user, $request, $totalPoinDibutuhkan) {

            try {
                // 3. Panggil Finance Service (Port 8001) untuk potong poin
                $response = Http::withHeaders([
                    'X-Internal-Key' => env('INTERNAL_API_KEY', 'TarhilalaSecretFinanceKey2024'),
                    'Accept'         => 'application/json'
                ])->post('http://127.0.0.1:8001/api/internal/deduct-points', [
                    'user_id'     => $user->id,
                    'points'      => $totalPoinDibutuhkan,
                    'reward_name' => $reward->nama_reward,
                    'description' => "Tukar {$request->jumlah}x {$reward->nama_reward}"
                ]);

                // Jika Finance Service menolak (Misal: Poin tidak cukup)
                if ($response->failed()) {
                    $errorMsg = $response->json('message') ?? 'Poin Anda tidak mencukupi';
                    return response()->json([
                        'status'  => 'error',
                        'message' => 'Gagal potong poin: ' . $errorMsg
                    ], 400);
                }

                // 4. Jika poin aman, kurangi stok barang di DB Lokal
                $reward->decrement('stok', $request->jumlah);

                // 5. Catat riwayat penukaran di DB Lokal
                $penukaran = PenukaranReward::create([
                    'user_id'           => $user->id,
                    'reward_id'         => $reward->id,
                    'poin_digunakan'    => $totalPoinDibutuhkan,
                    'status'            => 'menunggu',
                    'tanggal_penukaran' => now()
                ]);

                return response()->json([
                    'status'  => 'success',
                    'message' => 'Penukaran berhasil diajukan! Saldo poin Anda telah dipotong.',
                    'data'    => $penukaran
                ], 201);

            } catch (\Exception $e) {
                Log::error("Redeem Error: " . $e->getMessage());
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Layanan Keuangan sedang gangguan. Silakan coba lagi nanti.'
                ], 500);
            }
        });
    }
        public function riwayat(Request $request)
    {
        $user = auth()->user();

        // Ambil riwayat penukaran beserta info barangnya (join ke tabel reward)
        $riwayat = PenukaranReward::with('reward')
                    ->where('user_id', $user->id)
                    ->orderBy('tanggal_penukaran', 'desc')
                    ->get();

        return response()->json([
            'status' => 'success',
            'data'   => $riwayat
        ]);
    }
}
