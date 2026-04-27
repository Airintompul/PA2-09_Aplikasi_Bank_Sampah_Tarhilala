<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setoran;
use App\Models\GpsLog;
use App\Models\DetailSetoran;
use App\Models\JenisSampah;
use App\Models\AiValidation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http; // Wajib diimport untuk memanggil Microservice

class SetoranController extends Controller
{
    /**
     * Menampilkan semua daftar request penjemputan (JSON)
     */
    public function index()
    {
        $requests = Setoran::with(['nasabah:id,nama', 'jadwal.driver:id,nama', 'aiValidation'])
            ->orderBy('tanggal_pengajuan', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $requests
        ], 200);
    }

    public function verifyAi(Request $request, $id)
{
    $validation = \App\Models\AiValidation::where('setoran_id', $id)->firstOrFail();

    $validation->update([
        'is_correct' => $request->is_correct, // boolean: 1 (Benar), 0 (Salah)
        'admin_class' => $request->admin_class // Input teks jika AI salah menebak
    ]);

    return response()->json(['status' => 'success', 'message' => 'Validasi AI berhasil disimpan']);
}

    /**
     * Memperbarui status penjemputan dan mengirim data ke Microservice Keuangan
     */
    public function update(Request $request, $id)
    {
        // 1. Ambil data setoran beserta detail item sampahnya
        $setoran = Setoran::with('nasabah')->findOrFail($id);
        $details = DetailSetoran::where('setoran_id', $id)->get();

        $request->validate([
            'status' => 'required|in:menunggu,dijadwalkan,dalam_penjemputan,selesai,dibatalkan',
            'berat_final' => 'nullable|numeric',
            'catatan' => 'nullable|string'
        ]);

        $data = $request->only(['status', 'berat_final', 'catatan', 'jadwal_id']);

        // =============================================================
        // LOGIC PERHITUNGAN HARGA DINAMIS & MICROSERVICE
        // =============================================================
        if ($request->status == 'selesai' && $request->berat_final) {

            $totalHarga = 0;

            // Periksa apakah ada detail item sampah
            if ($details->count() > 0) {
                // Hitung rasio (Berat Final / Estimasi Awal)
                // Digunakan untuk membagi berat final ke tiap jenis sampah secara proporsional
                $ratio = $request->berat_final / $setoran->estimasi_berat;

                foreach ($details as $item) {
                    // Hitung berat asli tiap item berdasarkan rasio
                    $beratAsliItem = $item->berat * $ratio;
                    $subtotalBaru = $beratAsliItem * $item->harga_satuan;

                    // Update data di tabel detail_setoran
                    $item->update([
                        'berat' => $beratAsliItem,
                        'subtotal' => $subtotalBaru
                    ]);

                    $totalHarga += $subtotalBaru;
                }
            }

            $data['total_harga'] = $totalHarga;

            // 2. Kirim data ke Microservice Finance (Port 8001)
            try {
                $response = Http::withHeaders([
                    'X-Internal-Key' => env('INTERNAL_API_KEY', 'TarhilalaSecretFinanceKey2024')
                ])->post('http://127.0.0.1:8001/api/internal/add-balance', [
                    'user_id'    => $setoran->nasabah_id,
                    'amount'     => $totalHarga,
                    'setoran_id' => $setoran->id
                ]);

                if ($response->failed()) {
                    return response()->json([
                        'status'  => 'error',
                        'message' => 'Gagal sinkronisasi saldo: ' . $response->json('message')
                    ], 500);
                }

            } catch (\Exception $e) {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Microservice Keuangan mati. Transaksi dibatalkan.'
                ], 500);
            }
        }
        // =============================================================

        $setoran->update($data);

        return response()->json([
            'status' => 'success',
            'message' => 'Status selesai, harga dihitung dinamis & saldo terkirim',
            'data' => $setoran->load('nasabah')
        ], 200);
    }

    /**
     * Mengambil lokasi GPS Driver terbaru
     */
    public function getDriverLocation($driver_id)
    {
        $log = GpsLog::where('petugas_id', $driver_id)
            ->latest('recorded_at')
            ->first();

        if (!$log) {
            return response()->json([
                'status' => 'error',
                'message' => 'Lokasi driver tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'lat' => (float) $log->latitude,
                'lng' => (float) $log->longitude,
                'updated_at' => $log->recorded_at
            ]
        ], 200);
    }
}
