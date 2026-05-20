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
use App\Models\Notifikasi;
use App\Models\User;

// --- IMPORT SUPPORT SYSTEM ---
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http; // Wajib untuk kirim WA
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Barryvdh\DomPDF\Facade\Pdf;

class SetoranController extends Controller
{
    /**
     * Menampilkan daftar request penjemputan aktif (Termasuk yang dibatalkan)
     */
    public function index()
    {
        $requests = Setoran::with([
                'nasabah:id,nama,nomor_telepon',
                'jadwal.driver:id,nama',
                'aiValidation',
                'invoice',
                'details.jenisSampah:id,nama,harga_per_kg'
            ])
            ->whereIn('status', ['menunggu', 'dijadwalkan', 'dalam_penjemputan', 'selesai', 'dibatalkan'])
            ->orderBy('tanggal_pengajuan', 'desc')
            ->limit(50)
            ->get();

        return response()->json(['status' => 'success', 'data' => $requests], 200);
    }

    /**
     * Memperbarui status, Memicu Notifikasi, Alur Finansial, dan WhatsApp Driver
     */
    public function update(Request $request, $id)
    {
        return DB::transaction(function () use ($request, $id) {
            $setoran = Setoran::with(['nasabah', 'details.jenisSampah'])->findOrFail($id);

            // 1. PROTEKSI KETAT
            if ($setoran->status === 'dibatalkan') {
                return response()->json(['status' => 'error', 'message' => 'Gagal! Permintaan ini telah dibatalkan.'], 422);
            }

            if ($setoran->status === 'selesai') {
                return response()->json(['status' => 'error', 'message' => 'Gagal! Transaksi ini sudah selesai.'], 422);
            }

            $request->validate([
                'status' => 'required|in:menunggu,dijadwalkan,dalam_penjemputan,selesai,dibatalkan',
                'items' => 'nullable',
                'berat_final' => 'nullable|numeric',
                'total_harga' => 'nullable|numeric',
                'metode_pembayaran' => 'nullable|in:cash,transfer,saldo',
                'catatan' => 'nullable|string',
                'jadwal_id' => 'nullable|exists:jadwal_penjemputan,id',
            ]);

            // Simpan status lama untuk pengecekan trigger WA
            $statusLama = $setoran->status;

            $items = is_string($request->items) ? json_decode($request->items, true) : $request->items;
            $calculatedTotalHarga = 0;

            // 2. PROSES UPDATE DETAIL SAMPAH (Hanya jika selesai)
            if ($request->status == 'selesai' && !empty($items)) {
                foreach ($items as $item) {
                    if (isset($item['id'])) {
                        $detail = DetailSetoran::find($item['id']);
                        if ($detail) {
                            $subtotal = $item['berat_aktual'] * $detail->harga_satuan;
                            $detail->update(['berat' => $item['berat_aktual'], 'subtotal' => $subtotal]);
                            $calculatedTotalHarga += $subtotal;
                        }
                    }
                }
                $totalFinalHarga = $calculatedTotalHarga;
            } else {
                $totalFinalHarga = $request->total_harga ?? $setoran->total_harga;
            }

            // 3. UPDATE HEADER SETORAN
            $setoran->update([
                'status' => $request->status,
                'berat_final' => $request->berat_final ?? $setoran->berat_final,
                'total_harga' => $totalFinalHarga,
                'metode_pembayaran' => $request->metode_pembayaran ?? $setoran->metode_pembayaran,
                'catatan' => $request->catatan ?? $setoran->catatan,
                'jadwal_id' => $request->jadwal_id ?? $setoran->jadwal_id,
            ]);

            // =========================================================================
            // 4. LOGIKA: NOTIFIKASI DRIVER (HANYA JIKA STATUS DIJADWALKAN)
            // =========================================================================
            if ($request->status == 'dijadwalkan' && $statusLama != 'dijadwalkan') {
                $setoran->load(['jadwal.driver', 'nasabah']);
                $driver = $setoran->jadwal->driver;
                $nasabah = $setoran->nasabah;

                if ($driver) {
                    // A. BUAT NOTIFIKASI INTERNAL (DATABASE) UNTUK DRIVER
                    Notifikasi::create([
                        'user_id' => $driver->id,
                        'judul'   => 'Tugas Penjemputan Baru',
                        'pesan'   => "Anda ditugaskan menjemput sampah nasabah {$nasabah->nama} pada hari {$setoran->jadwal->hari}.",
                        'is_read' => false
                    ]);

                    // B. KIRIM WHATSAPP (OTOMATIS VIA FONNTE)
                    if ($driver->nomor_telepon) {
                        $nomorWA = $driver->nomor_telepon;
                        if (str_starts_with($nomorWA, '0')) { $nomorWA = '62' . substr($nomorWA, 1); }

                        $pesanWA = "🔔 *TUGAS PENJEMPUTAN BARU*\n\n" .
                                   "Halo, *" . $driver->nama . "*!\n" .
                                   "Anda telah ditugaskan untuk menjemput sampah:\n\n" .
                                   "👤 *Nasabah:* " . $nasabah->nama . "\n" .
                                   "📅 *Hari:* " . $setoran->jadwal->hari . "\n" .
                                   "⏰ *Jam:* " . $setoran->jadwal->jam_mulai . "\n" .
                                   "📝 *Catatan:* " . ($setoran->catatan ?? '-') . "\n\n" .
                                   "Mohon segera bersiap. Semangat bekerja! 💪\n_- Admin Tarhilala_";

                        try {
                            Http::withHeaders(['Authorization' => 'Zjcan6Ntbf4cbZ88HF89'])
                                ->post('https://api.fonnte.com/send', ['target' => $nomorWA, 'message' => $pesanWA]);
                        } catch (\Exception $e) { Log::error("WA Driver Error: " . $e->getMessage()); }
                    }
                }
            }

            // 5. LOGIKA NOTIFIKASI APP (Push Notification Internal)
            $notifTitle = ""; $notifBody = "";
            switch ($request->status) {
                case 'dijadwalkan':
                    $notifTitle = "Penjemputan Dijadwalkan";
                    $notifBody = "Permintaan Anda telah dijadwalkan oleh Admin.";
                    break;
                case 'dalam_penjemputan':
                    $notifTitle = "Driver Menuju Lokasi";
                    $notifBody = "Petugas sedang dalam perjalanan menjemput sampah Anda.";
                    break;
                case 'selesai':
                    $notifTitle = "Setoran Selesai";
                    $notifBody = "Sampah telah diterima. Saldo Rp " . number_format($totalFinalHarga) . " sudah masuk.";
                    break;
                case 'dibatalkan':
                    $notifTitle = "Setoran Dibatalkan";
                    $notifBody = "Maaf, permintaan penjemputan Anda dibatalkan oleh Admin.";
                    break;
            }

            if ($notifTitle != "") {
                Notifikasi::create([
                    'user_id' => $setoran->nasabah_id,
                    'judul'   => $notifTitle,
                    'pesan'   => $notifBody,
                    'is_read' => false
                ]);
            }

            // 6. TRIGGER SELESAI (INVOICE & SYNC FINANCE)
            if ($request->status == 'selesai') {
                $finalAmount = $totalFinalHarga;
                $headers = [
                    'X-Internal-Key' => env('INTERNAL_API_KEY', 'TarhilalaSecretFinanceKey2024'),
                    'Accept' => 'application/json'
                ];

                $invoice = Invoice::updateOrCreate(
                    ['setoran_id' => $setoran->id],
                    [
                        'nomor_invoice'   => 'INV-' . strtoupper(Str::random(8)),
                        'total_bayar'     => $finalAmount,
                        'tanggal_invoice' => now()
                    ]
                );

                try {
                    $setoranForPdf = Setoran::with(['nasabah', 'details.jenisSampah', 'invoice'])->find($id);
                    $pdf = Pdf::loadView('pdf.invoice', ['setoran' => $setoranForPdf]);
                    $path = 'invoices/INV_' . $invoice->nomor_invoice . '.pdf';
                    Storage::disk('public')->put($path, $pdf->output());
                    $invoice->update(['file_invoice' => $path]);
                } catch (\Exception $e) { Log::error("Gagal simpan PDF: " . $e->getMessage()); }

                try {
                    Http::withHeaders($headers)->post('http://127.0.0.1:8001/api/internal/add-balance', [
                        'user_id'           => $setoran->nasabah_id,
                        'amount'            => $finalAmount,
                        'setoran_id'        => $setoran->id,
                        'account_type'      => 'saldo',
                        'metode_pembayaran' => $setoran->metode_pembayaran
                    ]);

                    $jumlahPoin = floor($finalAmount / 1000);
                    if ($jumlahPoin > 0) {
                        PoinLog::create([
                            'user_id' => $setoran->nasabah_id, 'poin' => $jumlahPoin,
                            'source_type' => 'setoran', 'source_id' => $setoran->id
                        ]);

                        Http::withHeaders($headers)->post('http://127.0.0.1:8001/api/internal/add-balance', [
                            'user_id'           => $setoran->nasabah_id,
                            'amount'            => $jumlahPoin,
                            'setoran_id'        => $setoran->id,
                            'account_type'      => 'poin',
                            'metode_pembayaran' => 'saldo'
                        ]);
                    }
                } catch (\Exception $e) { Log::error("Finance Microservice Sync Gagal"); }
            }

            return response()->json(['status' => 'success', 'message' => 'Berhasil diperbarui'], 200);
        });
    }

    public function downloadInvoice($id)
    {
        $setoran = Setoran::with('invoice')->findOrFail($id);
        if (!$setoran->invoice || !$setoran->invoice->file_invoice) {
            return response()->json(['message' => 'File belum tersedia'], 404);
        }
        $path = storage_path('app/public/' . $setoran->invoice->file_invoice);
        if (!file_exists($path)) return response()->json(['message' => 'File hilang'], 404);
        return response()->download($path);
    }

    public function verifyAi(Request $request, $id) {
        $validation = AiValidation::where('setoran_id', $id)->firstOrFail();
        $validation->update(['is_correct' => $request->is_correct, 'admin_class' => $request->admin_class]);
        return response()->json(['status' => 'success']);
    }

    public function getDriverLocation($driver_id) {
        $log = GpsLog::where('petugas_id', $driver_id)->latest('recorded_at')->first();
        if (!$log) return response()->json(['status' => 'error'], 404);
        return response()->json(['status' => 'success', 'data' => ['lat' => (float) $log->latitude, 'lng' => (float) $log->longitude]], 200);
    }
}
