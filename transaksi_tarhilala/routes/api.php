<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\InternalFinanceController;
use App\Http\Controllers\Api\Admin\AdminWithdrawalController;

/*
|--------------------------------------------------------------------------
| Finance Service API Routes (PORT 8001)
|--------------------------------------------------------------------------
*/

// Endpoint untuk Admin (Web Vue.js)
Route::prefix('admin')->group(function () {
    Route::get('/penarikan', [AdminWithdrawalController::class, 'index']);
    Route::put('/penarikan/{id}', [AdminWithdrawalController::class, 'update']);
    Route::get('/finance-stats', [AdminWithdrawalController::class, 'getFinanceStats']);
});

// Endpoint untuk dipanggil Main App (Port 8000)
Route::prefix('internal')->group(function () {
    Route::post('/add-balance', [InternalFinanceController::class, 'addBalance']);
    Route::get('/balance/{user_id}', [InternalFinanceController::class, 'getBalance']);
    Route::post('/deduct-points', [InternalFinanceController::class, 'deductPoints']);

    // --- PENGAJUAN PENARIKAN (POST) ---
    Route::post('/withdrawal-request', [InternalFinanceController::class, 'addWithdrawalRequest']);

    // --- AMBIL RIWAYAT PENARIKAN (GET) - INI YANG TADI KURANG ---
    Route::get('/withdrawal-history/{user_id}', [InternalFinanceController::class, 'withdrawalHistory']);

    // --- UPDATE STATUS (DIPANGGIL ADMIN VIA PROXY 8000) ---
    Route::put('/withdrawal-update/{id}', [InternalFinanceController::class, 'updateWithdrawalStatus']);
});
