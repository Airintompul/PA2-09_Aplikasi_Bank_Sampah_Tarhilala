<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// --- IMPORT CONTROLLER NASABAH/USER (FLUTTER) ---
use App\Http\Controllers\Api\UserAuthController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\BeritaController;
use App\Http\Controllers\Api\NasabahSetoranController;
use App\Http\Controllers\Api\NotificationController;

use App\Http\Controllers\Api\Nasabah\RedeemController;
use App\Http\Controllers\Api\Nasabah\WithdrawalController;

// --- IMPORT CONTROLLER ADMIN (VUE.JS) ---
// Kita gunakan alias 'as' agar tidak bentrok jika ada nama class yang sama
use App\Http\Controllers\Api\Admin\AdminController;
use App\Http\Controllers\Api\Admin\ProductController;
use App\Http\Controllers\Api\Admin\EmployeeController;
use App\Http\Controllers\Api\Admin\CustomerController;
use App\Http\Controllers\Api\Admin\RewardController;
use App\Http\Controllers\Api\Admin\LibraryController;
use App\Http\Controllers\Api\Admin\LocationController;
use App\Http\Controllers\Api\Admin\MessageController;
use App\Http\Controllers\Api\Admin\SetoranController;
use App\Http\Controllers\Api\Admin\RedemptionController;

/*
|--------------------------------------------------------------------------
| PUBLIC ROUTES (TANPA TOKEN)
|--------------------------------------------------------------------------
*/

// Auth Nasabah & Petugas (Mobile)
Route::post('/user/login', [UserAuthController::class, 'login']);
Route::post('/user/register', [UserAuthController::class, 'register']);
Route::post('/forgot-password', [PasswordResetController::class, 'sendOtp']);
Route::post('/verify-otp', [PasswordResetController::class, 'verifyOtp']);
Route::post('/reset-password', [PasswordResetController::class, 'resetPassword']);
Route::get('/harga-sampah', [App\Http\Controllers\Api\Admin\ProductController::class, 'index']);

// Master Data Public
Route::get('/berita', [BeritaController::class, 'index']);
Route::get('/jenis-sampah', fn() => \App\Models\JenisSampah::all());

// Auth Admin (Web Vue) - PASTIKAN PAKAI ADMINCONTROLLER HASIL REFACTOR
Route::post('/admin/login', [AdminController::class, 'login']);


/*
|--------------------------------------------------------------------------
| PROTECTED ROUTES (WAJIB TOKEN SANCTUM)
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->group(function () {

    // --- AREA NASABAH (FLUTTER) ---
    Route::get('/profile', [UserAuthController::class, 'profile']);

    Route::prefix('nasabah')->group(function () {
        Route::get('/setoran/{nasabah_id}', [NasabahSetoranController::class, 'index']);
        Route::post('/setoran/store', [NasabahSetoranController::class, 'store']);
        Route::get('/setoran/detail/{id}', [NasabahSetoranController::class, 'show']);
        Route::post('/setoran/{id}/cancel', [NasabahSetoranController::class, 'cancel']);

        Route::get('/jadwal-nasabah', [LocationController::class, 'index']);

        Route::post('/redeem', [RedeemController::class, 'redeem']);
        Route::get('/riwayat-reward', [RedeemController::class, 'riwayat']);

        Route::post('/tarik-saldo', [WithdrawalController::class, 'store']);
        Route::get('/riwayat-penarikan', [WithdrawalController::class, 'history']);

        // Chat Nasabah
        Route::get('/chat/room', [ChatController::class, 'getRoom']);
        Route::get('/chat/messages/{id}', [ChatController::class, 'getMessages']);
        Route::post('/chat/send', [ChatController::class, 'sendMessage']);
        Route::middleware('auth:sanctum')->post('/nasabah/redeem', [RedeemController::class, 'redeem']);

        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    });

    // Route untuk Petugas/Driver
    Route::middleware('auth:sanctum')->prefix('petugas')->group(function () {
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    });

    // --- AREA ADMIN (VUE.JS) ---
    // Sesuai dengan baseURL di Vue: /api/admin
    Route::prefix('admin')->group(function () {

        // Dashboard & Logout
        Route::get('/dashboard', [AdminController::class, 'dashboard']);
        Route::post('/logout', [AdminController::class, 'logout']);

        // CRUD Utama (JSON)
        Route::get('/products', [ProductController::class, 'index']);
        Route::post('/products', [ProductController::class, 'store']);
        Route::post('/products/{id}', [ProductController::class, 'update']); // Untuk multipart
        Route::delete('/products/{id}', [ProductController::class, 'destroy']);

        Route::get('/employees', [EmployeeController::class, 'index']);
        Route::post('/employees', [EmployeeController::class, 'store']);
        Route::put('/employees/{id}', [EmployeeController::class, 'update']);
        Route::delete('/employees/{id}', [EmployeeController::class, 'destroy']);

        Route::get('/redemptions', [App\Http\Controllers\Api\Admin\RedemptionController::class, 'index']);
        Route::put('/redemptions/{id}', [App\Http\Controllers\Api\Admin\RedemptionController::class, 'updateStatus']);

        Route::get('/setoran/{id}/invoice', [SetoranController::class, 'downloadInvoice']);

        Route::get('/customers', [CustomerController::class, 'index']);
        Route::post('/customers', [CustomerController::class, 'store']);
        Route::put('/customers/{id}', [CustomerController::class, 'update']);
        Route::delete('/customers/{id}', [CustomerController::class, 'destroy']);

        Route::get('/rewards', [RewardController::class, 'index']);
        Route::post('/rewards', [RewardController::class, 'store']);
        Route::post('/rewards/{id}', [RewardController::class, 'update']); // Untuk multipart
        Route::delete('/rewards/{id}', [RewardController::class, 'destroy']);

        Route::get('/library', [LibraryController::class, 'index']);
        Route::post('/library', [LibraryController::class, 'store']);
        Route::post('/library/{id}', [LibraryController::class, 'update']); // Untuk multipart
        Route::delete('/library/{id}', [LibraryController::class, 'destroy']);

        // Location & Schedules
        Route::get('/location', [LocationController::class, 'index']);
        Route::post('/location/rute', [LocationController::class, 'storeRoute']);
        Route::put('/location/rute/{id}', [LocationController::class, 'updateRoute']);
        Route::delete('/location/rute/{id}', [LocationController::class, 'destroyRoute']);
        Route::post('/location/jadwal', [LocationController::class, 'storeSchedule']);
        Route::put('/location/jadwal/{id}', [LocationController::class, 'updateSchedule']);
        Route::delete('/location/jadwal/{id}', [LocationController::class, 'destroySchedule']);

        // Setoran & Live Tracking
        Route::get('/setoran', [SetoranController::class, 'index']);
        Route::put('/setoran/{id}', [SetoranController::class, 'update']);
        Route::post('setoran/{id}/verify-ai', [SetoranController::class, 'verifyAi']);
        Route::get('/driver-location/{driver_id}', [SetoranController::class, 'getDriverLocation']);

        // Admin Inbox Messages
        Route::get('/messages', [MessageController::class, 'index']);
        Route::get('/messages/{id}', [MessageController::class, 'show']);
        Route::post('/messages/{id}/send', [MessageController::class, 'store']);
        Route::patch('/messages/{id}/status', [MessageController::class, 'updateStatus']);

        Route::get('/notifications', [AdminController::class, 'getNotifications']);
        Route::put('/notifications/{id}/read', [AdminController::class, 'markAsRead']);
    });

    Route::middleware('auth:sanctum')->prefix('admin')->group(function () {
    Route::post('/penarikan-update/{id}', [App\Http\Controllers\Api\Nasabah\WithdrawalController::class, 'updateStatus']);
    });
});
