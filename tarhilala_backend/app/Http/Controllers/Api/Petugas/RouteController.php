<?php

namespace App\Http\Controllers\Api\Petugas;

use App\Http\Controllers\Controller;
use App\Models\Setoran;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class RouteController extends Controller
{
    public function index()
    {
        $petugasId = Auth::id();
        $hariIni = strtolower(Carbon::now()->translatedFormat('l'));

        $rute = Setoran::with(['nasabah', 'jadwal.rute'])
            ->whereHas('jadwal', function($q) use ($petugasId, $hariIni) {
                $q->where('driver_id', $petugasId)
                  ->where('hari', $hariIni);
            })
            ->whereIn('STATUS', ['menunggu', 'diproses', 'dijemput'])
            ->get()
            ->map(function($item) {
                return [
                    'id' => $item->id,
                    'nama_nasabah' => $item->nasabah->nama,
                    'telepon' => $item->nasabah->nomor_telepon,
                    'alamat' => $item->catatan ?? $item->jadwal->rute->wilayah,
                    'status' => $item->STATUS,
                    'wilayah_rute' => $item->jadwal->rute->nama_rute
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $rute
        ]);
    }
}
