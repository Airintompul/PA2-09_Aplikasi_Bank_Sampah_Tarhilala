<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use App\Mail\SendOtpMail;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use App\Models\PoinLog;
use Illuminate\Support\Facades\Http;

class UserAuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'nama' => 'required',
            'email' => 'required|email|unique:users,email',
            'nomor_telepon' => 'required',
            'password' => 'required|min:6'
        ]);

        $user = User::create([
            'nama' => $request->nama,
            'email' => $request->email,
            'nomor_telepon' => $request->nomor_telepon,
            'password' => Hash::make($request->password),
            'role' => 'nasabah'
        ]);

        return response()->json([
            'message' => 'Register berhasil',
            'data' => $user
        ]);
    }

    public function login(Request $request)
    {
    $user = User::where('email', $request->email)
                ->whereIn('role', ['nasabah', 'petugas'])
                ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Email atau password salah'
            ], 401);
        }

        $token= $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil',
            'token' => $token,
            'data' => $user
        ]);
    }

        public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                "success" => false,
                "message" => "Email tidak terdaftar",
                "data"    => null
            ], 404);
        }

        $otp = rand(100000, 999999);

        \DB::table('password_resets')->updateOrInsert(
            ['email' => $request->email],
            [
                'email' => $request->email,
                'token' => $otp,
                'created_at' => now()
            ]
        );

        \Mail::to($request->email)->send(new \App\Mail\SendOtpMail($otp));

        return response()->json([
            "success" => true,
            "message" => "Kode OTP telah dikirim ke email Anda",
            "data" => [
                "email" => $request->email
            ]
        ]);
    }

        public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp' => 'required'
        ]);

        $check = \DB::table('password_resets')
            ->where('email', $request->email)
            ->where('token', $request->otp)
            ->first();

        if (!$check) {
            return response()->json([
                "success" => false,
                "message" => "OTP salah",
                "data"    => null
            ], 400);
        }

        return response()->json([
            "success" => true,
            "message" => "OTP valid",
            "data" => [
                "email" => $request->email
            ]
        ]);
    }

        public function resetPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|min:6'
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                "success" => false,
                "message" => "Email tidak ditemukan",
                "data" => null
            ], 404);
        }

        $user->update([
            'password' => bcrypt($request->password)
        ]);

        \DB::table('password_resets')->where('email', $request->email)->delete();

        return response()->json([
            "success" => true,
            "message" => "Password berhasil direset",
            "data" => null
        ]);
    }

    // tarhilala_backend (Port 8000)

    public function profile(Request $request) {
        $user = $request->user();

        // 1. HITUNG POIN LANGSUNG DARI TABEL poin_log (Lokal Port 8000)
        // Ini solusi tanpa menambah kolom/migrasi di tabel users
        $poin = \App\Models\PoinLog::where('user_id', $user->id)->sum('poin');

        // 2. AMBIL SALDO
        $saldo = 0;
        try {
            $headers = ['X-Internal-Key' => env('INTERNAL_API_KEY')];
            $resSaldo = Http::withHeaders($headers)->get("http://127.0.0.1:8001/api/internal/balance/{$user->id}?type=saldo");

            if ($resSaldo->successful()) {
                $saldo = $resSaldo->json('balance');
            } else {
                // Jika Microservice 8001 gagal, hitung saldo dari tabel setoran lokal sebagai backup
                $saldo = \App\Models\Setoran::where('nasabah_id', $user->id)
                            ->where('status', 'selesai')
                            ->sum('total_harga');
            }
        } catch (\Exception $e) {
            // Jika koneksi ke 8001 mati total, gunakan data lokal
            $saldo = \App\Models\Setoran::where('nasabah_id', $user->id)
                        ->where('status', 'selesai')
                        ->sum('total_harga');
            \Log::error("Koneksi 8001 gagal, menggunakan perhitungan lokal.");
        }

        return response()->json([
            'nama'  => $user->nama,
            'saldo' => $saldo,
            'poin'  => (int)$poin, // Sekarang poin diambil dari tabel log lokal Anda
        ]);
    }
}
