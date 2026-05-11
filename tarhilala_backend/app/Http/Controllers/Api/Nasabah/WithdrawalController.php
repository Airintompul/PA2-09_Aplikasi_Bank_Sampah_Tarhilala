<?php

namespace App\Http\Controllers\Api\Nasabah;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WithdrawalController extends Controller
{
    /**
     * Nasabah: Mengajukan penarikan
     */
    public function store(Request $request)
    {
        $request->validate([
            'jumlah'        => 'required|numeric|min:50000',
            'metode'        => 'required|string',
            'nomor_tujuan'  => 'required',
            'nama_penerima' => 'required',
        ]);

        $user = auth()->user();

        try {
            // Mengirim request ke Port 8001
            $response = Http::withHeaders([
                'X-Internal-Key' => env('INTERNAL_API_KEY', 'TarhilalaSecretFinanceKey2024'),
                'Accept' => 'application/json'
            ])->post("http://127.0.0.1:8001/api/internal/withdrawal-request", [
                'user_id'       => $user->id,
                'jumlah'        => $request->jumlah,
                'metode'        => $request->metode,
                'nomor_tujuan'  => $request->nomor_tujuan,
                'nama_penerima' => $request->nama_penerima,
            ]);

            return response()->json($response->json(), $response->status());
        } catch (\Exception $e) {
            Log::error("Store Withdrawal Gagal: " . $e->getMessage());
            return response()->json(['message' => 'Layanan Keuangan Sedang Gangguan'], 500);
        }
    }

public function updateStatus(Request $request, $id) {
    $file = $request->file('bukti_transfer');

    try {
        $req = Http::asMultipart()->withHeaders([
            'X-Internal-Key' => env('INTERNAL_API_KEY', 'TarhilalaSecretFinanceKey2024')
        ]);

        if ($file) {
            $req->attach('bukti_transfer', file_get_contents($file), $file->getClientOriginalName());
        }

        // Tembak ke Port 8001
        $response = $req->post("http://127.0.0.1:8001/api/internal/withdrawal-update/$id", [
            'status' => $request->status,
            '_method' => 'PUT'
        ]);

        return response()->json($response->json(), $response->status());
    } catch (\Exception $e) {
        return response()->json(['message' => 'Gagal meneruskan file: ' . $e->getMessage()], 500);
    }
}

    public function history()
    {
        $user = auth()->user();

        try {
            $response = Http::withHeaders([
                'X-Internal-Key' => env('INTERNAL_API_KEY', 'TarhilalaSecretFinanceKey2024'),
                'Accept'         => 'application/json'
            ])->get("http://127.0.0.1:8001/api/internal/withdrawal-history/{$user->id}");

            if ($response->failed()) {
                return response()->json([
                    'status' => 'error',
                    'server_message' => $response->body(), // Biar ketahuan errornya apa
                    'data' => []
                ], $response->status());
            }

            return response()->json($response->json(), 200);

        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}
