<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AdminAuthController;
use App\Http\Controllers\Api\UserAuthController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Admin\ProductController;
use App\Http\Controllers\Api\BeritaController;
use App\Http\Controllers\Api\NasabahSetoranController;
use App\Http\Controllers\Admin\RewardController;
use App\Models\Reward;

Route::post('/admin/login', [AdminAuthController::class, 'login']);
Route::post('/user/login', [UserAuthController::class, 'login']);
Route::post('/user/register', [UserAuthController::class, 'register']);
Route::post('/forgot-password', [PasswordResetController::class, 'sendOtp']);
Route::post('/verify-otp', [PasswordResetController::class, 'verifyOtp']);
Route::post('/reset-password', [PasswordResetController::class, 'resetPassword']);
Route::get('/harga-sampah', [ProductController::class, 'apiIndex']);
Route::get('/berita', [BeritaController::class, 'index']);

Route::middleware('auth:sanctum')->get('/profile', function (Request $request) {
    return $request->user();
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/chat/room', [ChatController::class, 'getRoom']);
    Route::get('/chat/messages/{id}', [ChatController::class, 'getMessages']);
    Route::post('/chat/send', [ChatController::class, 'sendMessage']);
});

Route::prefix('nasabah')->group(function () {
    // 1. Ambil semua riwayat setoran milik nasabah tertentu
    Route::get('/setoran/{nasabah_id}', [NasabahSetoranController::class, 'index']);

    // 2. Buat request penjemputan baru (Langkah 1-5 alur Anda)
    Route::post('/setoran/store', [NasabahSetoranController::class, 'store']);

    // 3. Lihat detail satu setoran (termasuk detail jenis sampah & tracking)
    Route::get('/setoran/detail/{id}', [NasabahSetoranController::class, 'show']);

    // 4. Batalkan request (Hanya jika status masih 'menunggu')
    Route::put('/setoran/cancel/{id}', [NasabahSetoranController::class, 'cancel']);
});

// Master data untuk dropdown di Flutter
Route::get('/jenis-sampah', function() {
    return App\Models\JenisSampah::all();
});

Route::get('/rewards', [RewardController::class, 'apiRewards']);
