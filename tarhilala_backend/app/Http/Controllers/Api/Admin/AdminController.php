<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
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
        // Karena ini API, kita tidak kirim View, tapi kirim DATA
        // Contoh: Data statistik untuk dashboard
        return response()->json([
            'status' => 'success',
            'message' => 'Dashboard Data loaded',
            'data' => [
                'admin_info' => Auth::user(),
                'stats' => [
                    'total_nasabah' => User::where('role', 'nasabah')->count(),
                    'total_petugas' => User::where('role', 'petugas')->count(),
                    // Tambahkan statistik lainnya di sini
                ]
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
