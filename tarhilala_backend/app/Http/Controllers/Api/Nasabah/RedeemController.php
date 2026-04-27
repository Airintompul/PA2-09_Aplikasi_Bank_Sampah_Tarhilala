<?php

namespace App\Http\Controllers\Api\Nasabah;

use App\Http\Controllers\Controller;
use App\Models\Reward;
use App\Models\PenukaranReward;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;

class RedeemController extends Controller
{
    public function redeem(Request $request)
    {
        $request->validate([
            'reward_id' => 'required|exists:reward,id'
        ]);

        $reward = Reward::findOrFail($request->reward_id);
        $nasabahId = auth()->id(); // Diambil dari token login nasabah

        // 1. Cek stok reward di Main App
        if ($reward->stok <= 0) {
            return response()->json(['message' => 'Maaf, stok reward ini sudah habis'], 400);
        }

        return DB::transaction(function () use ($reward, $nasabahId) {

            // 2. Panggil Finance Service (Port 8001) untuk cek & potong poin
            try {
                $response = Http::withHeaders([
                    'X-Internal-Key' => env('INTERNAL_API_KEY')
                ])->post('http://127.0.0.1:8001/api/internal/deduct-points', [
                    'user_id' => $nasabahId,
                    'points'  => $reward->poin_dibutuhkan,
                    'description' => "Penukaran Reward: " . $reward->nama_reward
                ]);

                if ($response->failed()) {
                    return response()->json([
                        'message' => 'Gagal tukar poin: ' . ($response->json('message') ?? 'Koneksi error')
                    ], 400);
                }

                // 3. Jika poin berhasil dipotong, kurangi stok di Main App
                $reward->decrement('stok');

                // 4. Catat riwayat penukaran
                $penukaran = PenukaranReward::create([
                    'user_id' => $nasabahId,
                    'reward_id' => $reward->id,
                    'poin_digunakan' => $reward->poin_dibutuhkan,
                    'status' => 'menunggu', // Admin nanti yang memproses fisiknya
                    'tanggal_penukaran' => now()
                ]);

                return response()->json([
                    'status' => 'success',
                    'message' => 'Penukaran berhasil diajukan! Silakan hubungi admin untuk pengambilan.',
                    'data' => $penukaran
                ], 201);

            } catch (\Exception $e) {
                return response()->json(['message' => 'Microservice Keuangan tidak merespon'], 500);
            }
        });
    }
}
