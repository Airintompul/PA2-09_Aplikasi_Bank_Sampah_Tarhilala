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
        // 1. Validasi Input Lengkap
        $request->validate([
            'reward_id'         => 'required|exists:reward,id',
            'jumlah'            => 'required|integer|min:1',
            'lokasi_lat'        => 'required',
            'lokasi_lng'        => 'required',
            'alamat_pengiriman' => 'required|string',
            'catatan'           => 'nullable|string'
        ]);

        $reward = Reward::findOrFail($request->reward_id);
        $user = auth()->user();
        $totalPoinDibutuhkan = $reward->poin_dibutuhkan * $request->jumlah;

        if ($reward->stok < $request->jumlah) {
            return response()->json(['status' => 'error', 'message' => 'Stok tidak mencukupi'], 400);
        }

        return DB::transaction(function () use ($reward, $user, $request, $totalPoinDibutuhkan) {
            try {
                // 2. Potong Poin di Finance Service (Port 8001)
                $response = Http::withHeaders([
                    'X-Internal-Key' => env('INTERNAL_API_KEY', 'TarhilalaSecretFinanceKey2024'),
                    'Accept'         => 'application/json'
                ])->post('http://127.0.0.1:8001/api/internal/deduct-points', [
                    'user_id'           => $user->id,
                    'points'            => $totalPoinDibutuhkan,
                    'description'       => "Tukar {$request->jumlah}x {$reward->nama_reward}",
                    'reference_table'   => 'penukaran_reward',
                    'reference_data_id' => null // Akan diupdate setelah ID dibuat jika perlu
                ]);

                if ($response->failed()) {
                    return response()->json(['status' => 'error', 'message' => 'Poin tidak cukup'], 400);
                }

                // 3. Kurangi Stok
                $reward->decrement('stok', $request->jumlah);

                // 4. Simpan Transaksi Penukaran dengan Data Pengiriman
                $penukaran = PenukaranReward::create([
                    'user_id'           => $user->id,
                    'reward_id'         => $reward->id,
                    'jumlah'            => $request->jumlah,
                    'poin_digunakan'    => $totalPoinDibutuhkan,
                    'status'            => 'menunggu', // Status awal
                    'lokasi_lat'        => $request->lokasi_lat,
                    'lokasi_lng'        => $request->lokasi_lng,
                    'alamat_pengiriman' => $request->alamat_pengiriman,
                    'catatan'           => $request->catatan,
                    'tanggal_penukaran' => now()
                ]);

                return response()->json([
                    'status'  => 'success',
                    'message' => 'Penukaran berhasil! Admin akan segera memproses pengiriman.',
                    'data'    => $penukaran
                ], 201);

            } catch (\Exception $e) {
                Log::error("Redeem Error: " . $e->getMessage());
                return response()->json(['status' => 'error', 'message' => 'Gagal terhubung ke layanan keuangan'], 500);
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
    public function confirmReceipt($id)
{
    $penukaran = PenukaranReward::where('id', $id)
                ->where('user_id', auth()->id())
                ->firstOrFail();

    if ($penukaran->status !== 'dikirim') {
        return response()->json(['message' => 'Barang belum dalam pengiriman'], 400);
    }

    $penukaran->update(['status' => 'selesai']);

    return response()->json(['status' => 'success', 'message' => 'Terima kasih telah mengonfirmasi!']);
}
}
