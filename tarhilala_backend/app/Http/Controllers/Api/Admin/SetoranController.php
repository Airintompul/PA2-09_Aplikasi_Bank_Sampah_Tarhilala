<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
// --- IMPORT MODELS ---
use App\Models\Setoran;
use App\Models\DetailSetoran;
use App\Models\GpsLog;
use App\Models\JenisSampah;
use App\Models\AiValidation;
use App\Models\Invoice;
use App\Models\PoinLog;

// --- IMPORT SUPPORT SYSTEM ---
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str; // INI PERBAIKANNYA: Gunakan namespace ini

class SetoranController extends Controller
{
    /**
     * Menampilkan semua daftar request penjemputan
     */
    public function index()
    {
        $requests = Setoran::with([
                'nasabah:id,nama,nomor_telepon',
                'jadwal.driver:id,nama',
                'aiValidation',
                'details.jenisSampah:id,nama,harga_per_kg'
            ])
            ->orderBy('tanggal_pengajuan', 'desc')
            ->get();

        return response()->json(['status' => 'success', 'data' => $requests], 200);
    }

    /**
     * Memperbarui status penjemputan dan memicu alur Finansial Otomatis
     */
    public function update(Request $request, $id)
    {
        return DB::transaction(function () use ($request, $id) {
            $setoran = Setoran::with('nasabah')->findOrFail($id);

            $request->validate([
                'status' => 'required|in:menunggu,dijadwalkan,dalam_penjemputan,selesai,dibatalkan',
                'items' => 'nullable',
                'berat_final' => 'nullable|numeric',
                'total_harga' => 'nullable|numeric',
                'metode_pembayaran' => 'nullable|in:cash,transfer,saldo',
                'catatan' => 'nullable|string',
            ]);

            // Dekode data items (Handle Flutter MultipartRequest yang mengirim String JSON)
            $items = $request->items;
            if (is_string($items)) {
                $items = json_decode($items, true);
            }

            $calculatedTotalHarga = 0;

            // 1. PROSES UPDATE & TAMBAH JENIS SAMPAH (INPUT AKTUAL)
            if ($request->status == 'selesai' && !empty($items)) {
                foreach ($items as $item) {
                    if (isset($item['id'])) {
                        // A. UPDATE ITEM YANG SUDAH ADA
                        $detail = DetailSetoran::find($item['id']);
                        if ($detail) {
                            $subtotal = $item['berat_aktual'] * $detail->harga_satuan;
                            $detail->update([
                                'berat' => $item['berat_aktual'],
                                'subtotal' => $subtotal
                            ]);
                            $calculatedTotalHarga += $subtotal;
                        }
                    } else if (isset($item['jenis_sampah_id'])) {
                        // B. TAMBAH JENIS SAMPAH BARU (Dari Master Data)
                        $masterSampah = JenisSampah::find($item['jenis_sampah_id']);
                        if ($masterSampah) {
                            $subtotal = $item['berat_aktual'] * $masterSampah->harga_per_kg;
                            DetailSetoran::create([
                                'setoran_id' => $id,
                                'jenis_sampah_id' => $masterSampah->id,
                                'berat' => $item['berat_aktual'],
                                'harga_satuan' => $masterSampah->harga_per_kg,
                                'subtotal' => $subtotal
                            ]);
                            $calculatedTotalHarga += $subtotal;
                        }
                    }
                }
                $totalFinalHarga = $calculatedTotalHarga;
            } else {
                $totalFinalHarga = $request->total_harga ?? $setoran->total_harga;
            }

            // 2. UPDATE HEADER SETORAN (Gunakan kolom sesuai database Anda)
            $setoran->update([
                'status' => $request->status,
                'berat_final' => $request->berat_final ?? $setoran->berat_final,
                'total_harga' => $totalFinalHarga,
                // Jika request kosong, gunakan data lama di DB
                'metode_pembayaran' => $request->metode_pembayaran ?? $setoran->metode_pembayaran,
                'catatan' => $request->catatan ?? $setoran->catatan,
                'jadwal_id' => $request->jadwal_id ?? $setoran->jadwal_id,
            ]);

            // 3. TRIGGER FINANSIAL (Hanya jika SELESAI)
            if ($request->status == 'selesai') {

                // A. Buat Invoice
                Invoice::create([
                    'setoran_id' => $setoran->id,
                    'nomor_invoice' => 'INV-' . strtoupper(Str::random(8)),
                    'total_bayar' => $totalFinalHarga,
                    'tanggal_invoice' => now()
                ]);

                // B. Tambah Poin (Pastikan Fillable di PoinLog sudah: user_id, poin, source_type, source_id)
                $jumlahPoin = floor($totalFinalHarga / 1000);
                if ($jumlahPoin > 0) {
                    PoinLog::create([
                        'user_id'     => $setoran->nasabah_id,
                        'poin'        => $jumlahPoin,
                        'source_type' => 'setoran',
                        'source_id'   => $setoran->id
                    ]);
                }

                // C. Sinkronisasi ke Microservice Finance (Port 8001)
                try {
                    Http::withHeaders([
                        'X-Internal-Key' => env('INTERNAL_API_KEY', 'TarhilalaSecretFinanceKey2024')
                    ])->post('http://127.0.0.1:8001/api/internal/add-balance', [
                        'user_id'           => $setoran->nasabah_id,
                        'amount'            => $totalFinalHarga,
                        'setoran_id'        => $setoran->id,
                        'metode_pembayaran' => $request->metode_pembayaran
                    ]);
                } catch (\Exception $e) {
                    Log::error("Finance Microservice Connection Error: " . $e->getMessage());
                }
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Setoran berhasil diproses & data finansial telah dibuat.'
            ], 200);
        });
    }

    public function verifyAi(Request $request, $id)
    {
        $validation = AiValidation::where('setoran_id', $id)->firstOrFail();
        $validation->update([
            'is_correct' => $request->is_correct,
            'admin_class' => $request->admin_class
        ]);
        return response()->json(['status' => 'success']);
    }

    /**
     * Helper Lokasi Driver
     */
    public function getDriverLocation($driver_id)
    {
        $log = GpsLog::where('petugas_id', $driver_id)->latest('recorded_at')->first();
        if (!$log) return response()->json(['status' => 'error', 'message' => 'Lokasi tidak ditemukan'], 404);
        return response()->json(['status' => 'success', 'data' => ['lat' => (float) $log->latitude, 'lng' => (float) $log->longitude]], 200);
    }
}
