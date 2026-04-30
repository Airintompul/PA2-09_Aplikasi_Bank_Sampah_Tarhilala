<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\PenukaranReward; // Import Model
use Illuminate\Http\Request;

class RedemptionController extends Controller
{
    public function index()
    {
        try {
            // Mengambil data penukaran dengan relasi user dan reward
            $data = PenukaranReward::with(['user', 'reward'])
                    ->orderBy('tanggal_penukaran', 'desc')
                    ->get();

            return response()->json([
                'status' => 'success',
                'data'   => $data
            ], 200);

        } catch (\Exception $e) {
            // Jika error, kirim pesan errornya agar bisa dibaca di console browser
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate(['status' => 'required|in:selesai,ditolak']);

        $redemption = PenukaranReward::findOrFail($id);
        $redemption->update(['status' => $request->status]);

        return response()->json([
            'status' => 'success',
            'message' => 'Status Berhasil Diperbarui'
        ]);
    }
}
