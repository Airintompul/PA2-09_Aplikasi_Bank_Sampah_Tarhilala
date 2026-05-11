<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Setoran;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;

class AdminController extends Controller
{
    /**
     * PROSES LOGIN (Mendapatkan Token)
     */
    public function login(Request $request)
    {
        // Validasi input
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        // 1. Cek User & Password
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Email atau Password salah'
            ], 401);
        }

        // 2. Cek Role (Hanya Admin)
        if ($user->role !== 'admin') {
            return response()->json([
                'status' => 'error',
                'message' => 'Akses ditolak. Anda bukan Admin.'
            ], 403);
        }

        // 3. Generate Token (Sanctum)
        $token = $user->createToken('admin_token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Login Berhasil',
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'nama' => $user->nama,
                    'email' => $user->email,
                    'role' => $user->role,
                ],
                'token' => $token
            ]
        ], 200);
    }

    /**
     * DATA DASHBOARD (Protected by Sanctum)
     */
    public function dashboard()
{
    // Statistik Summary
    $nasabah = \App\Models\User::where('role', 'nasabah')->count();
    $petugas = \App\Models\User::where('role', 'petugas')->count();
    $pickup = \App\Models\Setoran::count();

    // 1. DATA GRAFIK BAR: Tren Penjemputan (7 Hari Terakhir)
    $chartData = \App\Models\Setoran::selectRaw('DATE(tanggal_pengajuan) as date, COUNT(*) as total')
        ->groupBy('date')->orderBy('date', 'asc')->take(7)->get();

    // 2. DATA GRAFIK PIE: Komposisi Sampah Terbanyak (Berdasarkan Berat)
    $komposisi = \DB::table('detail_setoran')
        ->join('jenis_sampah', 'detail_setoran.jenis_sampah_id', '=', 'jenis_sampah.id')
        ->select('jenis_sampah.nama', \DB::raw('SUM(detail_setoran.berat) as total_berat'))
        ->groupBy('jenis_sampah.nama')
        ->orderBy('total_berat', 'desc')
        ->get();

    return response()->json([
        'status' => 'success',
        'data' => [
            'total_nasabah' => $nasabah,
            'total_petugas' => $petugas,
            'pickup_selesai' => $pickup,
            'chart_labels' => $chartData->pluck('date'),
            'chart_values' => $chartData->pluck('total'),
            // Data untuk Pie Chart
            'pie_labels' => $komposisi->pluck('nama'),
            'pie_values' => $komposisi->pluck('total_berat'),
        ]
    ]);
}

    /**
     * PROSES LOGOUT (Hapus Token)
     */
    public function logout(Request $request)
    {
        // Hapus token yang sedang digunakan
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Logout berhasil, token telah dihapus'
        ]);
    }
}
