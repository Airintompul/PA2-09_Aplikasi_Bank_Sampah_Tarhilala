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
    // 1. Validasi Input
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

    // --- LOGIKA POIN LOKAL (TANPA MIGRASI) ---
    // Hitung total poin dari tabel log
    $totalPoinUser = \App\Models\PoinLog::where('user_id', $user->id)->sum('poin');

    // Cek kecukupan poin
    if ($totalPoinUser < $totalPoinDibutuhkan) {
        return response()->json([
            'status' => 'error',
            'message' => 'Poin tidak cukup. Anda butuh ' . $totalPoinDibutuhkan . ' poin.'
        ], 400);
    }

    if ($reward->stok < $request->jumlah) {
        return response()->json(['status' => 'error', 'message' => 'Stok tidak mencukupi'], 400);
    }

    return DB::transaction(function () use ($reward, $user, $request, $totalPoinDibutuhkan) {
        try {
            // 2. POTONG POIN LOKAL (Memasukkan nilai NEGATIF ke PoinLog)
            \App\Models\PoinLog::create([
                'user_id'     => $user->id,
                'poin'        => -$totalPoinDibutuhkan, // Nilai Minus (Contoh: -5)
                'source_type' => 'redeem',
                'source_id'   => $reward->id
            ]);

            // 3. Kurangi Stok Reward
            $reward->decrement('stok', $request->jumlah);

            // 4. Simpan Transaksi Penukaran
            $penukaran = PenukaranReward::create([
                'user_id'           => $user->id,
                'reward_id'         => $reward->id,
                'jumlah'            => $request->jumlah,
                'poin_digunakan'    => $totalPoinDibutuhkan,
                'status'            => 'menunggu',
                'lokasi_lat'        => $request->lokasi_lat,
                'lokasi_lng'        => $request->lokasi_lng,
                'alamat_pengiriman' => $request->alamat_pengiriman,
                'catatan'           => $request->catatan,
                'tanggal_penukaran' => now()
            ]);

            return response()->json([
                'status'  => 'success',
                'message' => 'Penukaran berhasil! Admin akan segera memproses.',
                'data'    => $penukaran
            ], 201);

        } catch (\Exception $e) {
            Log::error("Redeem Error: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => 'Gagal memproses penukaran'], 500);
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
