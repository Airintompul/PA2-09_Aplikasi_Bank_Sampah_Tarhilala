<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\{Setoran, DetailSetoran, FotoSetoran, AiValidation, Notifikasi, Invoice, PoinLog, User, JenisSampah};
use Illuminate\Support\Facades\{DB, Http, Str, Storage, Log};
use Barryvdh\DomPDF\Facade\Pdf;

class NasabahSetoranController extends Controller
{
    /**
     * Menampilkan daftar setoran nasabah
     */
    public function index($nasabah_id)
    {
        try {
            $data = Setoran::with(['invoice', 'details.jenisSampah'])
                ->where('nasabah_id', $nasabah_id)
                ->orderBy('tanggal_pengajuan', 'desc')
                ->get();
            return response()->json($data);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Nasabah mengirim request penjemputan (Langkah 1-5)
     */
    public function store(Request $request)
    {
        try {
            return DB::transaction(function () use ($request) {
                $nasabah = User::find($request->nasabah_id);
                if (!$nasabah) throw new \Exception("Nasabah tidak ditemukan.");

                // 1. Simpan Header Setoran
                $setoran = Setoran::create([
                    'nasabah_id'        => $nasabah->id,
                    'estimasi_berat'    => $request->estimasi_berat,
                    'metode_pembayaran' => $request->metode_pembayaran,
                    'lokasi_lat'        => $request->lokasi_lat,
                    'lokasi_lng'        => $request->lokasi_lng,
                    'status'            => 'menunggu',
                    'catatan'           => $request->catatan,
                    'tanggal_pengajuan' => now()
                ]);

                // 2. Simpan Detail Sampah
                $items = json_decode($request->items, true);
                if (!empty($items)) {
                    foreach ($items as $item) {
                        $jenis = JenisSampah::find($item['id']);
                        if ($jenis) {
                            DetailSetoran::create([
                                'setoran_id'      => $setoran->id,
                                'jenis_sampah_id' => $jenis->id,
                                'berat'           => $item['berat'],
                                'harga_satuan'    => $jenis->harga_per_kg,
                                'subtotal'        => $item['berat'] * $jenis->harga_per_kg
                            ]);
                        }
                    }
                }

                // 3. Upload Foto & Data AI
                if ($request->hasFile('foto')) {
                    $path = $request->file('foto')->store('uploads/setoran', 'public');
                    FotoSetoran::create(['setoran_id' => $setoran->id, 'image_path' => $path]);
                    AiValidation::create([
                        'setoran_id'    => $setoran->id,
                        'image_path'    => $path,
                        'ai_class'      => $request->ai_class ?? 'Unknown',
                        'ai_confidence' => $request->ai_confidence ?? 0,
                    ]);
                }

                // 4. Notifikasi Admin
                $admin = User::where('role', 'admin')->first();
                if ($admin) {
                    Notifikasi::create([
                        'user_id' => $admin->id,
                        'judul'   => 'Request Setoran Baru',
                        'pesan'   => 'Ada request baru dari nasabah: ' . $nasabah->nama
                    ]);
                }

                return response()->json(['status' => 'success', 'message' => 'Request berhasil dikirim!', 'id' => $setoran->id], 201);
            });
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Membatalkan request setoran oleh Nasabah
     */
    public function cancel($id)
    {
        try {
            // 1. Cari data setoran
            $setoran = Setoran::find($id);

            if (!$setoran) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Data setoran tidak ditemukan'
                ], 404);
            }

            // 2. Cek apakah status masih 'menunggu'
            // Jika sudah dijadwalkan atau selesai, tidak boleh dibatalkan
            if ($setoran->status !== 'menunggu') {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Gagal! Setoran sudah diproses atau sudah selesai.'
                ], 422);
            }

            // 3. Update status menjadi dibatalkan
            $setoran->update(['status' => 'dibatalkan']);

            // 4. (Opsional) Beri notifikasi ke Admin bahwa ada pembatalan
            $admin = User::where('role', 'admin')->first();
            if ($admin) {
                Notifikasi::create([
                    'user_id' => $admin->id,
                    'judul'   => 'Setoran Dibatalkan',
                    'pesan'   => 'Nasabah telah membatalkan request setoran #' . $setoran->id
                ]);
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Request setoran berhasil dibatalkan'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Driver menyelesaikan penjemputan (Langkah 10-15)
     * DISINKRONKAN DENGAN MICROSERVICE FINANCE & INVOICE PDF
     */
    public function finishPickup(Request $request, $id)
    {
        try {
            return DB::transaction(function () use ($request, $id) {
                $setoran = Setoran::with(['nasabah', 'details.jenisSampah'])->findOrFail($id);

                // 1. Update Berat Final & Status
                $setoran->update([
                    'berat_final' => $request->berat_final,
                    'status'      => 'selesai'
                ]);

                $totalHarga = DetailSetoran::where('setoran_id', $id)->sum('subtotal');
                $setoran->update(['total_harga' => $totalHarga]);

                // 2. GENERATE & SIMPAN INVOICE PDF
                $newInvoice = Invoice::updateOrCreate(
                    ['setoran_id' => $setoran->id],
                    [
                        'nomor_invoice'   => 'INV-' . strtoupper(Str::random(8)),
                        'total_bayar'     => $totalHarga,
                        'tanggal_invoice' => now()
                    ]
                );

                try {
                    $pdf = Pdf::loadView('pdf.invoice', ['setoran' => $setoran->load('invoice')]);
                    $pdfPath = 'invoices/INV_' . $newInvoice->nomor_invoice . '.pdf';
                    Storage::disk('public')->put($pdfPath, $pdf->output());
                    $newInvoice->update(['file_invoice' => $pdfPath]);
                } catch (\Exception $e) { Log::error("Gagal buat PDF: " . $e->getMessage()); }

                // 3. SINKRONISASI KE MICROSERVICE FINANCE (PORT 8001)
                $headers = ['X-Internal-Key' => env('INTERNAL_API_KEY', 'TarhilalaSecretFinanceKey2024'), 'Accept' => 'application/json'];

                // A. Kirim Saldo Uang
                try {
                    Http::withHeaders($headers)->post('http://127.0.0.1:8001/api/internal/add-balance', [
                        'user_id'           => $setoran->nasabah_id,
                        'amount'            => $totalHarga,
                        'setoran_id'        => $setoran->id,
                        'account_type'      => 'saldo',
                        'metode_pembayaran' => $setoran->metode_pembayaran
                    ]);
                } catch (\Exception $e) { Log::error("Finance Sync Fail"); }

                // 4. LOGIKA POIN (Lokal & Microservice)
                $jumlahPoin = floor($totalHarga / 1000);
                if ($jumlahPoin > 0) {
                    PoinLog::create([
                        'user_id' => $setoran->nasabah_id,
                        'poin' => $jumlahPoin,
                        'source_type' => 'setoran', 'source_id' => $setoran->id
                    ]);

                    try {
                        Http::withHeaders($headers)->post('http://127.0.0.1:8001/api/internal/add-balance', [
                            'user_id'      => $setoran->nasabah_id,
                            'amount'       => $jumlahPoin,
                            'setoran_id'   => $setoran->id,
                            'account_type' => 'poin',
                            'metode_pembayaran' => 'saldo'
                        ]);
                    } catch (\Exception $e) { Log::error("Poin Sync Fail"); }
                }

                // 5. Notifikasi Selesai ke Nasabah
                Notifikasi::create([
                    'user_id' => $setoran->nasabah_id,
                    'judul'   => 'Setoran Selesai',
                    'pesan'   => 'Terima kasih, sampah Anda telah dijemput. Saldo Rp ' . number_format($totalHarga) . ' berhasil masuk.'
                ]);

                return response()->json(['status' => 'success', 'message' => 'Transaksi Berhasil Diselesaikan']);
            });
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}
