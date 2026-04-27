<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\{Setoran, DetailSetoran, FotoSetoran, AiValidation, Notifikasi, Transaksi, Invoice, PoinLog, Wallet, WalletTransaction, User, JenisSampah};
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class NasabahSetoranController extends Controller
{
    public function index($nasabah_id)
{
    try {
        // Ambil data setoran milik nasabah tertentu
        $data = \App\Models\Setoran::where('nasabah_id', $nasabah_id)
                ->orderBy('tanggal_pengajuan', 'desc')
                ->get();

        return response()->json($data, 200);
    } catch (\Exception $e) {
        // Kirim error sebagai JSON agar Flutter tidak FormatException
        return response()->json([
            'status' => 'error',
            'message' => $e->getMessage()
        ], 500);
    }
}
    // LANGKAH 1 - 5: NASABAH MENGIRIM REQUEST (DINAMIS)
    public function store(Request $request)
{
    try {
        return DB::transaction(function () use ($request) {

            // 1. Validasi User
            $nasabah = User::find($request->nasabah_id);
            if (!$nasabah) {
                return response()->json(['status' => 'error', 'message' => 'Nasabah ID tidak ditemukan di database.'], 404);
            }

            // 2. Simpan Header Setoran
            // PASTIKAN jadwal_id di DB sudah NULLABLE
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

            // 3. Simpan Detail Sampah
            $items = json_decode($request->items, true);
            if (!empty($items)) {
                foreach ($items as $item) {
                    $jenis = JenisSampah::find($item['id']);
                    if (!$jenis) {
                        throw new \Exception("Jenis sampah dengan ID " . $item['id'] . " tidak ada.");
                    }

                    DetailSetoran::create([
                        'setoran_id'      => $setoran->id,
                        'jenis_sampah_id' => $jenis->id,
                        'berat'           => $item['berat'],
                        'harga_satuan'    => $jenis->harga_per_kg,
                        'subtotal'        => $item['berat'] * $jenis->harga_per_kg
                    ]);
                }
            }

            // 4. Upload Foto & AI
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

            // 5. Notifikasi Admin (Gunakan first agar tidak crash jika admin kosong)
            $admin = User::where('role', 'admin')->first();
            if ($admin) {
                Notifikasi::create([
                    'user_id' => $admin->id,
                    'judul'   => 'Request Setoran Baru',
                    'pesan'   => 'Ada request baru dari nasabah: ' . $nasabah->nama
                ]);
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Request penjemputan berhasil dikirim!',
                'id' => $setoran->id
            ], 201);
        });
    } catch (\Exception $e) {
        // INI KUNCI AGAR TIDAK MUNCUL HTML ERROR DI FLUTTER
        return response()->json([
            'status' => 'error',
            'message' => 'Gagal simpan: ' . $e->getMessage()
        ], 500);
    }
}

    // LANGKAH 10 - 15: DRIVER SELESAIKAN PENJEMPUTAN (DINAMIS)
    public function finishPickup(Request $request, $id)
    {
        try {
            return DB::transaction(function () use ($request, $id) {
                // Ambil data setoran beserta detailnya
                $setoran = Setoran::with('details')->findOrFail($id);

                // 10. Update Berat Final & Status
                $setoran->update([
                    'berat_final' => $request->berat_final,
                    'status'      => 'selesai'
                ]);

                // 11. Perhitungan Harga Final (Dinamis: Mengambil SUM dari detail_setoran)
                $totalHarga = DetailSetoran::where('setoran_id', $id)->sum('subtotal');
                $setoran->update(['total_harga' => $totalHarga]);

                // 12. Proses Pembayaran
                Transaksi::create([
                    'user_id'           => $setoran->nasabah_id,
                    'jumlah'            => $totalHarga,
                    'metode_pembayaran' => $setoran->metode_pembayaran,
                    'status'            => 'berhasil'
                ]);

                // Update Wallet jika metode pembayaran adalah 'saldo'
                if ($setoran->metode_pembayaran == 'saldo') {
                    $wallet = Wallet::firstOrCreate(['user_id' => $setoran->nasabah_id, 'account_type' => 'saldo']);
                    WalletTransaction::create([
                        'account_id' => $wallet->id,
                        'amount'     => $totalHarga,
                        'direction'  => 'credit',
                        'description'=> 'Hasil setoran sampah #' . $setoran->id
                    ]);
                }

                // 13. Generate Invoice
                Invoice::create([
                    'setoran_id'      => $setoran->id,
                    'nomor_invoice'   => 'INV-' . strtoupper(Str::random(8)),
                    'total_bayar'     => $totalHarga,
                    'tanggal_invoice' => now()
                ]);

                // 14. Poin Reward (Dinamis: Misal Rp 1.000 = 1 Poin)
                $poinDihasilkan = floor($totalHarga / 1000);
                PoinLog::create([
                    'user_id' => $setoran->nasabah_id,
                    'poin'    => $poinDihasilkan,
                    'source_type' => 'setoran',
                    'source_id'   => $setoran->id
                ]);

                // 15. Notifikasi Selesai ke Nasabah
                Notifikasi::create([
                    'user_id' => $setoran->nasabah_id,
                    'judul'   => 'Setoran Selesai',
                    'pesan'   => 'Terima kasih ' . $setoran->nasabah->nama . ', setoran Anda telah diterima. Saldo bertambah Rp ' . number_format($totalHarga)
                ]);

                return response()->json(['status' => 'success', 'message' => 'Transaksi Penjemputan Selesai']);
            });
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}
